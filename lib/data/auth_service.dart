// lib/data/auth_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'offline_manager.dart';
import 'sync_service.dart';
import 'db.dart';

/// Modelo de datos del usuario autenticado
class AuthUser {
  final String id;
  final String username;
  final String email;
  final String nombreCompleto;
  final String rol;
  final String campus;
  final String departamento;
  final bool activo;
  final String? fechaCreacion;
  final String? ultimoAcceso;

  AuthUser({
    required this.id,
    required this.username,
    required this.email,
    required this.nombreCompleto,
    required this.rol,
    required this.campus,
    required this.departamento,
    required this.activo,
    this.fechaCreacion,
    this.ultimoAcceso,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      nombreCompleto: json['nombre_completo'] ?? '',
      rol: json['rol'] ?? '',
      campus: json['campus'] ?? '',
      departamento: json['departamento'] ?? '',
      activo: json['activo'] ?? true,
      fechaCreacion: json['fecha_creacion'],
      ultimoAcceso: json['ultimo_acceso'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'nombre_completo': nombreCompleto,
      'rol': rol,
      'campus': campus,
      'departamento': departamento,
      'activo': activo,
      'fecha_creacion': fechaCreacion,
      'ultimo_acceso': ultimoAcceso,
    };
  }
}

/// Servicio de autenticación centralizado
class AuthService {
  static const String _baseUrl = 'https://fastapi-backend-o7ks.onrender.com';
  static const _storage = FlutterSecureStorage();

  // Keys para almacenamiento seguro
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';
  static const String _passwordKey =
      'cached_password'; // Para renovación automática

  /// Iniciar sesión con username, password y campus
  /// Modo híbrido MEJORADO: verifica cache primero, luego intenta online con timeout corto
  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
    String? campus,
  }) async {
    // Normalizar campus (asegurar que no sea null o vacío)
    final normalizedCampus = campus ?? 'cres-llano-largo';
    print('🔐 Iniciando login para: $username, campus: $normalizedCampus');

    // PASO 1: Verificar si existe cache válido
    final hasCache =
        await OfflineManager.hasCachedCredentials(username, normalizedCampus);
    print('💾 Cache disponible para usuario: $hasCache');

    // PASO 2: Si NO hay cache, DEBE intentar online (primera vez)
    if (!hasCache) {
      print('⚠️  Sin cache - se requiere conexión para primer login');
    }

    // PASO 3: Verificar conectividad de red (WiFi/Ethernet)
    final hasConnection = await OfflineManager.hasInternetConnection();
    print('🌐 Conectividad de red: $hasConnection');

    // PASO 4: Si hay cache Y no hay conexión de red -> IR DIRECTO A OFFLINE
    if (hasCache && !hasConnection) {
      print('📴 Sin red pero hay cache - login offline directo');
      return await _tryOfflineLogin(username, password, normalizedCampus);
    }

    // PASO 5: Si NO hay conexión y NO hay cache -> ERROR
    if (!hasConnection && !hasCache) {
      print('❌ Sin red y sin cache - imposible autenticar');
      return {
        'success': false,
        'error':
            'Sin conexión a internet.\n\nDebe conectarse a internet para el primer inicio de sesión.',
      };
    }

    // PASO 6: Intentar login online con timeout AMPLIADO (15 segundos para cold start)
    if (hasConnection) {
      print('🌍 Hay red - intentando login online...');
      print(
          '⏳ Esperando respuesta del servidor (puede tardar si está dormido)...');
      try {
        final response = await http
            .post(
          Uri.parse('$_baseUrl/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'username': username,
            'password': password,
            'campus': normalizedCampus,
          }),
        )
            .timeout(
          const Duration(
              seconds: 15), // AUMENTADO para cold start de Render.com
          onTimeout: () {
            print('⏱️ Timeout (15s) - backend no responde');
            throw TimeoutException('Backend no respondió en 15 segundos');
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          print('✅ Login online exitoso');

          // Guardar token y datos de usuario
          print('💾 Guardando token...');
          await _storage.write(key: _tokenKey, value: data['access_token']);

          print('💾 Guardando datos de usuario...');
          final userDataJson = jsonEncode(data['user']);
          print(
              '📦 Datos a guardar: ${userDataJson.substring(0, userDataJson.length > 100 ? 100 : userDataJson.length)}...');
          await _storage.write(key: _userKey, value: userDataJson);

          // Guardar contraseña (encriptada) para renovación automática de token
          print('🔐 Guardando credenciales para renovación automática...');
          await _storage.write(key: _passwordKey, value: password);

          // VERIFICACIÓN INMEDIATA: Leer lo que acabamos de escribir
          print('🔍 Verificando datos guardados...');
          final verifyToken = await _storage.read(key: _tokenKey);
          final verifyUser = await _storage.read(key: _userKey);

          if (verifyToken != null) {
            print('✅ Token verificado: ${verifyToken.substring(0, 20)}...');
          } else {
            print('❌ ERROR CRÍTICO: Token NO se guardó');
          }

          if (verifyUser != null) {
            print(
                '✅ Datos de usuario verificados: ${verifyUser.substring(0, 50)}...');
          } else {
            print('❌ ERROR CRÍTICO: Datos de usuario NO se guardaron');
          }

          // IMPORTANTE: Guardar hash de contraseña para acceso offline futuro
          // Usar el campus del backend para asegurar consistencia
          final campusToCache = data['user']['campus'] ?? normalizedCampus;
          print(
              '💾 Guardando cache con campus: $campusToCache (backend: ${data['user']['campus']}, enviado: $normalizedCampus)');

          await OfflineManager.savePasswordHash(
            username: username,
            password: password,
            campus: campusToCache,
          );

          // CRÍTICO: Esperar un momento para asegurar que FlutterSecureStorage
          // complete el flush de datos al disco (problema en Windows)
          print('⏳ Esperando flush de datos al disco...');
          await Future.delayed(const Duration(milliseconds: 500));
          print('✅ Flush completado');

          // Deshabilitar modo offline
          await OfflineManager.disableOfflineMode();

          // Intentar sincronizar datos pendientes en background
          _syncPendingData().then((_) {
            print('[SYNC] Sincronización en background completada');
          }).catchError((e) {
            print('[SYNC] Error en sincronización background: $e');
          });

          return {
            'success': true,
            'user': AuthUser.fromJson(data['user']),
            'token': data['access_token'],
            'mode': 'online',
          };
        } else if (response.statusCode == 401) {
          print('❌ Credenciales incorrectas - respuesta 401');
          // Credenciales incorrectas - NO intentar offline
          return {
            'success': false,
            'error': 'Usuario o contraseña incorrectos',
          };
        } else if (response.statusCode == 403) {
          print('🚫 Acceso denegado - respuesta 403');
          final error = jsonDecode(response.body);
          return {
            'success': false,
            'error': error['detail'] ?? 'Acceso denegado',
          };
        } else {
          print('⚠️ Error del servidor (${response.statusCode})');
          // Error del servidor - intentar offline si hay cache
          if (hasCache) {
            print('🔄 Fallback a offline (hay cache disponible)');
            return await _tryOfflineLogin(username, password, normalizedCampus);
          }
          return {
            'success': false,
            'error': 'Error del servidor (${response.statusCode})',
          };
        }
      } catch (e) {
        print('❌ Excepción en login online: $e');
        // Error de conexión - intentar offline si hay cache
        if (hasCache) {
          print('🔄 Fallback a offline (hay cache disponible)');
          return await _tryOfflineLogin(username, password, normalizedCampus);
        }
        return {
          'success': false,
          'error': 'No se pudo conectar al servidor.\n\n${e.toString()}',
        };
      }
    } else {
      // Sin conexión de red detectada
      print('📴 Sin red - usando modo offline');
      return await _tryOfflineLogin(username, password, normalizedCampus);
    }
  }

  /// Intenta login offline validando contra cache local
  static Future<Map<String, dynamic>> _tryOfflineLogin(
    String username,
    String password,
    String? campus,
  ) async {
    print('🔄 Intentando login offline...');
    print('   📋 Usuario: $username');
    print('   📋 Campus: $campus');

    final normalizedCampus = campus ?? 'cres-llano-largo';

    // DIAGNÓSTICO: Verificar QUÉ hay en el storage
    print('🔍 DIAGNÓSTICO: Verificando contenido de FlutterSecureStorage...');
    final tokenInStorage = await _storage.read(key: _tokenKey);
    final userInStorage = await _storage.read(key: _userKey);

    print(
        '   🔑 Token: ${tokenInStorage != null ? "SÍ existe (${tokenInStorage.substring(0, 20)}...)" : "NO existe"}');
    print(
        '   👤 User: ${userInStorage != null ? "SÍ existe (${userInStorage.substring(0, 50)}...)" : "NO existe"}');

    // CRÍTICO: Verificar PRIMERO si hay datos de usuario guardados
    // Si no hay datos de usuario, NO PUEDE hacer login offline
    final userJson = await _storage.read(key: _userKey);
    if (userJson == null) {
      print('❌ No hay datos de usuario guardados - login offline imposible');
      print(
          '   Usuario debe conectarse a internet y hacer login exitoso primero');
      return {
        'success': false,
        'error':
            'Sin conexión a internet.\n\nDebe iniciar sesión con internet al menos una vez antes de usar modo offline.',
      };
    }

    print('✅ Datos de usuario encontrados en cache');
    print(
        '   📦 Datos: ${userJson.substring(0, userJson.length > 100 ? 100 : userJson.length)}...');

    // ESTRATEGIA: Intentar validar con el campus proporcionado
    // Si falla, intentar buscar cache con cualquier campus para este usuario
    bool isValid = await OfflineManager.validateOfflineCredentials(
      username: username,
      password: password,
      campus: normalizedCampus,
    );

    // Si falla, intentar buscar cache con campus del usuario guardado
    if (!isValid) {
      print('⚠️ [CACHE] Validación falló con campus: $normalizedCampus');
      print('🔄 [CACHE] Intentando obtener campus del cache guardado...');

      final cachedCampus =
          await OfflineManager.getCachedCampusForUser(username);
      if (cachedCampus != null && cachedCampus != normalizedCampus) {
        print(
            '📦 [CACHE] Encontrado campus en cache: $cachedCampus, reintentando...');
        isValid = await OfflineManager.validateOfflineCredentials(
          username: username,
          password: password,
          campus: cachedCampus,
        );
      }
    }

    if (!isValid) {
      print('❌ Validación offline falló - credenciales incorrectas');
      return {
        'success': false,
        'error': 'Contraseña incorrecta.',
      };
    }

    final userData = jsonDecode(userJson);
    print('✅ Login offline exitoso para: ${userData['username']}');

    // Generar token temporal offline (no válido para backend)
    final offlineToken = 'offline_${DateTime.now().millisecondsSinceEpoch}';
    await _storage.write(key: _tokenKey, value: offlineToken);

    // Habilitar modo offline
    await OfflineManager.enableOfflineMode();

    return {
      'success': true,
      'user': AuthUser.fromJson(userData),
      'token': offlineToken,
      'mode': 'offline',
      'warning':
          'Modo sin conexión. Los datos se sincronizarán cuando tengas internet.',
    };
  }

  /// Sincroniza datos pendientes cuando hay conexión
  static Future<void> _syncPendingData() async {
    try {
      print(
          '\n[SYNC] 🔄 Iniciando sincronización automática de datos pendientes...');

      // Importar dinámicamente para evitar dependencias circulares
      final db = await _getDatabase();
      if (db == null) {
        print('[SYNC] ⚠️ No se pudo obtener instancia de base de datos');
        return;
      }

      // Usar SyncService para sincronizar todo
      final syncService = SyncService(db);
      final result = await syncService.syncAll();

      // Log del resultado
      if (result.hasSuccess) {
        print('[SYNC] ✅ Sincronización exitosa: ${result.totalSynced} items');
      }
      if (result.hasErrors) {
        print(
            '[SYNC] ⚠️ Errores en sincronización: ${result.totalErrors} items fallaron');
      }
      if (!result.hasSuccess && !result.hasErrors) {
        print('[SYNC] ℹ️ No había datos pendientes para sincronizar');
      }

      // Actualizar timestamp de última sincronización
      await OfflineManager.updateLastSyncTimestamp();
      print('[SYNC] 🏁 Proceso de sincronización completado\n');
    } catch (e) {
      print('[SYNC] ❌ Error en sincronización automática: $e');
    }
  }

  /// Obtiene la instancia de base de datos
  static Future<AppDatabase?> _getDatabase() async {
    try {
      return AppDatabase();
    } catch (e) {
      print('[SYNC] Error creando instancia de base de datos: $e');
      return null;
    }
  }

  /// Cerrar sesión (eliminar solo el token, mantener datos para offline)
  static Future<void> logout() async {
    print('🚪 Cerrando sesión...');
    await _storage.delete(key: _tokenKey);
    // NO borramos _userKey para permitir login offline posterior
    print('✅ Sesión cerrada (datos de usuario preservados para modo offline)');
  }

  /// Verificar si hay una sesión activa
  static Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: _tokenKey);
    return token != null && token.isNotEmpty;
  }

  /// Obtener el token JWT actual
  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  /// Renovar token automáticamente cuando expire
  /// Retorna true si se renovó exitosamente
  static Future<bool> renewTokenIfExpired() async {
    print('🔄 Verificando si el token necesita renovación...');

    // Obtener credenciales guardadas
    final user = await getCurrentUser();
    final cachedPassword = await _storage.read(key: _passwordKey);

    if (user == null || cachedPassword == null) {
      print('❌ No hay credenciales guardadas para renovar token');
      return false;
    }

    // Verificar conectividad
    final hasConnection = await OfflineManager.hasInternetConnection();
    if (!hasConnection) {
      print('📴 Sin conexión - no se puede renovar token');
      return false;
    }

    print('🔐 Renovando token para usuario: ${user.username}');

    try {
      // Intentar login silencioso con credenciales guardadas
      final response = await http
          .post(
            Uri.parse('$_baseUrl/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'username': user.username,
              'password': cachedPassword,
              'campus': user.campus,
            }),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw TimeoutException('Timeout renovando token'),
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newToken = data['access_token'];

        // Guardar nuevo token
        await _storage.write(key: _tokenKey, value: newToken);
        print('✅ Token renovado exitosamente');
        return true;
      } else {
        print('❌ Error renovando token: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Excepción renovando token: $e');
      return false;
    }
  }

  /// Obtener el usuario actual
  static Future<AuthUser?> getCurrentUser() async {
    final userJson = await _storage.read(key: _userKey);
    if (userJson == null) return null;

    try {
      final userData = jsonDecode(userJson);
      return AuthUser.fromJson(userData);
    } catch (e) {
      return null;
    }
  }

  /// Obtener el rol del usuario actual
  static Future<String?> getUserRole() async {
    final user = await getCurrentUser();
    return user?.rol;
  }

  /// Obtener el campus del usuario actual
  static Future<String?> getUserCampus() async {
    final user = await getCurrentUser();
    return user?.campus;
  }

  /// Verificar si el usuario tiene un permiso específico
  static Future<bool> hasPermission(String permission) async {
    final user = await getCurrentUser();
    if (user == null) return false;

    // Mapa de permisos por rol (sincronizado con backend)
    final Map<String, List<String>> rolePermissions = {
      'admin': [
        'carnets:read',
        'carnets:write',
        'notas:read',
        'notas:write',
        'citas:read',
        'citas:write',
        'users:manage',
        'audit:read',
        'promociones:read',
        'promociones:write',
        'vacunacion:read',
        'vacunacion:write',
        'tickets:read',
        'tickets:reply',
        'tickets:update_status'
      ],
      'medico': [
        'carnets:read',
        'carnets:write',
        'notas:read',
        'notas:write',
        'citas:read',
        'citas:write',
        'promociones:read',
        'promociones:write',
        'vacunacion:read',
        'vacunacion:write',
        'tickets:read',
        'tickets:reply',
        'tickets:update_status'
      ],
      'nutricion': [
        'carnets:read',
        'carnets:write',
        'notas:read',
        'notas:write',
        'citas:read',
        'citas:write',
        'promociones:read',
        'promociones:write',
        'vacunacion:read',
        'vacunacion:write',
        'tickets:read',
        'tickets:reply',
        'tickets:update_status'
      ],
      'psicologia': [
        'carnets:read',
        'carnets:write',
        'notas:read',
        'notas:write',
        'citas:read',
        'citas:write',
        'promociones:read',
        'promociones:write',
        'vacunacion:read',
        'vacunacion:write',
        'tickets:read',
        'tickets:reply',
        'tickets:update_status'
      ],
      'odontologia': [
        'carnets:read',
        'carnets:write',
        'notas:read',
        'notas:write',
        'citas:read',
        'citas:write',
        'promociones:read',
        'promociones:write',
        'vacunacion:read',
        'vacunacion:write',
        'tickets:read',
        'tickets:reply',
        'tickets:update_status'
      ],
      'enfermeria': [
        'carnets:read',
        'carnets:write',
        'notas:read',
        'notas:write',
        'citas:read',
        'citas:write',
        'promociones:read',
        'promociones:write',
        'vacunacion:read',
        'vacunacion:write',
        'tickets:read',
        'tickets:reply',
        'tickets:update_status'
      ],
      'recepcion': [
        'carnets:read',
        'carnets:write',
        'notas:read',
        'notas:write',
        'citas:read',
        'citas:write',
        'promociones:read',
        'promociones:write',
        'vacunacion:read',
        'vacunacion:write',
        'tickets:read',
        'tickets:reply',
        'tickets:update_status'
      ],
      'servicios_estudiantiles': [
        'carnets:read',
        'carnets:write',
        'notas:read',
        'notas:write',
        'citas:read',
        'citas:write',
        'promociones:read',
        'promociones:write',
        'vacunacion:read',
        'vacunacion:write',
        'tickets:read',
        'tickets:reply',
        'tickets:update_status'
      ],
      'lectura': ['carnets:read', 'tickets:read'],
    };

    final userPermissions = rolePermissions[user.rol] ?? [];
    return userPermissions.contains(permission);
  }

  /// Verificar si el token está próximo a expirar (menos de 1 hora)
  static Future<bool> isTokenExpiringSoon() async {
    final token = await getToken();
    if (token == null) return true;

    try {
      // Decodificar el JWT para obtener el tiempo de expiración
      final parts = token.split('.');
      if (parts.length != 3) return true;

      final payload =
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final payloadMap = jsonDecode(payload);

      if (payloadMap['exp'] != null) {
        final expirationDate = DateTime.fromMillisecondsSinceEpoch(
          payloadMap['exp'] * 1000,
        );
        final now = DateTime.now();
        final difference = expirationDate.difference(now);

        // Retorna true si expira en menos de 1 hora
        return difference.inHours < 1;
      }
    } catch (e) {
      // Si hay error al decodificar, asumir que está expirado
      return true;
    }

    return false;
  }

  /// Obtener el nombre formateado del campus (88 instituciones UAGro)
  static String formatCampusName(String campus) {
    final Map<String, String> campusNames = {
      // CRES - Centros Regionales de Educación Superior (6)
      'cres-cruz-grande': 'CRES Cruz Grande',
      'cres-zumpango': 'CRES Zumpango del Río',
      'cres-taxco-viejo': 'CRES Taxco el Viejo',
      'cres-huamuxtitlan': 'CRES Huamuxtitlán',
      'cres-llano-largo': 'CRES Llano Largo',
      'cres-tecpan': 'CRES Tecpan de Galeana',

      // Clínicas Universitarias (4)
      'clinica-chilpancingo': 'Clínica Universitaria Chilpancingo',
      'clinica-acapulco': 'Clínica Universitaria Acapulco',
      'clinica-iguala': 'Clínica Universitaria Iguala',
      'clinica-ometepec': 'Clínica Universitaria Ometepec',

      // Facultades (20)
      'fac-gobierno': 'Facultad de Ciencias Políticas y Gobierno',
      'fac-arquitectura': 'Facultad de Arquitectura y Urbanismo',
      'fac-quimico': 'Facultad de Ciencias Químico Biológicas',
      'fac-comunicacion': 'Facultad de Ciencias de la Comunicación',
      'fac-derecho-chil': 'Facultad de Derecho (Chilpancingo)',
      'fac-filosofia': 'Facultad de Filosofía y Letras',
      'fac-ingenieria': 'Facultad de Ingeniería',
      'fac-matematicas-centro': 'Facultad de Matemáticas (Centro)',
      'fac-contaduria': 'Facultad de Contaduría y Administración',
      'fac-derecho-aca': 'Facultad de Derecho (Acapulco)',
      'fac-ecologia': 'Facultad de Ecología Marina',
      'fac-economia': 'Facultad de Economía',
      'fac-enfermeria2': 'Facultad de Enfermería 2',
      'fac-matematicas-sur': 'Facultad de Matemáticas (Sur)',
      'fac-lenguas': 'Facultad de Lenguas Extranjeras',
      'fac-medicina': 'Facultad de Medicina',
      'fac-odontologia': 'Facultad de Odontología',
      'fac-turismo': 'Facultad de Turismo',
      'fac-agropecuarias': 'Facultad de Ciencias Agropecuarias',
      'fac-matematicas-norte': 'Facultad de Matemáticas (Norte)',

      // Preparatorias (50)
      'prep-1': 'Preparatoria 1',
      'prep-2': 'Preparatoria 2',
      'prep-3': 'Preparatoria 3',
      'prep-4': 'Preparatoria 4',
      'prep-5': 'Preparatoria 5',
      'prep-6': 'Preparatoria 6',
      'prep-7': 'Preparatoria 7',
      'prep-8': 'Preparatoria 8',
      'prep-9': 'Preparatoria 9',
      'prep-10': 'Preparatoria 10',
      'prep-11': 'Preparatoria 11',
      'prep-12': 'Preparatoria 12',
      'prep-13': 'Preparatoria 13',
      'prep-14': 'Preparatoria 14',
      'prep-15': 'Preparatoria 15',
      'prep-16': 'Preparatoria 16',
      'prep-17': 'Preparatoria 17',
      'prep-18': 'Preparatoria 18',
      'prep-19': 'Preparatoria 19',
      'prep-20': 'Preparatoria 20',
      'prep-21': 'Preparatoria 21',
      'prep-22': 'Preparatoria 22',
      'prep-23': 'Preparatoria 23',
      'prep-24': 'Preparatoria 24',
      'prep-25': 'Preparatoria 25',
      'prep-26': 'Preparatoria 26',
      'prep-27': 'Preparatoria 27',
      'prep-28': 'Preparatoria 28',
      'prep-29': 'Preparatoria 29',
      'prep-30': 'Preparatoria 30',
      'prep-31': 'Preparatoria 31',
      'prep-32': 'Preparatoria 32',
      'prep-33': 'Preparatoria 33',
      'prep-34': 'Preparatoria 34',
      'prep-35': 'Preparatoria 35',
      'prep-36': 'Preparatoria 36',
      'prep-37': 'Preparatoria 37',
      'prep-38': 'Preparatoria 38',
      'prep-39': 'Preparatoria 39',
      'prep-40': 'Preparatoria 40',
      'prep-41': 'Preparatoria 41',
      'prep-42': 'Preparatoria 42',
      'prep-43': 'Preparatoria 43',
      'prep-44': 'Preparatoria 44',
      'prep-45': 'Preparatoria 45',
      'prep-46': 'Preparatoria 46',
      'prep-47': 'Preparatoria 47',
      'prep-48': 'Preparatoria 48',
      'prep-49': 'Preparatoria 49',
      'prep-50': 'Preparatoria 50',

      // Rectoría y Coordinaciones Regionales (8)
      'rectoria': 'Rectoría',
      'coord-sur': 'Coordinación Regional Sur',
      'coord-centro': 'Coordinación Regional Centro',
      'coord-norte': 'Coordinación Regional Norte',
      'coord-costa-chica': 'Coordinación Regional Costa Chica',
      'coord-costa-grande': 'Coordinación Regional Costa Grande',
      'coord-montana': 'Coordinación Regional Montaña',
      'coord-tierra-caliente': 'Coordinación Regional Tierra Caliente',

      // Retrocompatibilidad con valores antiguos (por si acaso)
      'llano-largo': 'CRES Llano Largo',
      'acapulco': 'Acapulco',
      'chilpancingo': 'Chilpancingo',
      'taxco': 'Taxco',
      'iguala': 'Iguala',
      'zihuatanejo': 'Zihuatanejo',
    };
    return campusNames[campus] ?? campus;
  }

  /// Obtener el nombre formateado del rol
  static String formatRoleName(String rol) {
    final Map<String, String> rolNames = {
      'admin': 'Administrador',
      'medico': 'Médico',
      'nutricion': 'Nutrición',
      'psicologia': 'Psicología',
      'odontologia': 'Odontología',
      'enfermeria': 'Enfermería',
      'recepcion': 'Recepción',
      'servicios_estudiantiles': 'Servicios Estudiantiles',
      'lectura': 'Solo Lectura',
    };
    return rolNames[rol] ?? rol;
  }

  /// Verifica si está en modo offline
  static Future<bool> isOfflineMode() async {
    return await OfflineManager.isOfflineModeEnabled();
  }

  /// Obtiene información del estado de conexión y cache
  /// [db] - Opcional: instancia de AppDatabase para contar registros pendientes
  static Future<Map<String, dynamic>> getConnectionInfo({dynamic db}) async {
    final hasInternet = await OfflineManager.hasInternetConnection();
    final isOffline = await OfflineManager.isOfflineModeEnabled();
    final cacheInfo = await OfflineManager.getCacheInfo(db: db);

    return {
      'hasInternet': hasInternet,
      'isOfflineMode': isOffline,
      'cacheInfo': cacheInfo,
    };
  }

  /// Forzar sincronización manual
  static Future<bool> forceSyncNow() async {
    try {
      final hasConnection = await OfflineManager.hasInternetConnection();
      if (!hasConnection) {
        return false;
      }

      await _syncPendingData();

      // Si veníamos de un modo offline, deshabilitarlo ahora que hay conexión
      if (await OfflineManager.isOfflineModeEnabled()) {
        await OfflineManager.disableOfflineMode();
        print('[SYNC] 🌐 Conexión restaurada: modo offline deshabilitado');
      }
      return true;
    } catch (e) {
      print('Error en sincronización forzada: $e');
      return false;
    }
  }
}
