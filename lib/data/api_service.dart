import 'dart:convert';
import 'package:http/http.dart' as http;
import 'cache_service.dart';
import 'auth_service.dart' as auth;
import '../models/ticket_admin_model.dart';
import '../utils/sync_logger.dart';
import '../utils/clinical_datetime.dart';

/// URL del backend, configurable via environment o fallback
const String baseUrl = String.fromEnvironment('API_BASE_URL',
    defaultValue: 'https://fastapi-backend-o7ks.onrender.com');

class ApiService {
  /// Timeout para requests normales (aumentado para cold start)
  static const Duration _normalTimeout = Duration(seconds: 60);

  /// Timeout para verificación rápida de conexión (no bloquear guardado)
  /// AUMENTADO a 10 segundos para cold starts de Render.com en Windows
  static const Duration _quickCheckTimeout = Duration(seconds: 10);

  /// Timeout para health check (wake-up)
  static const Duration _healthTimeout = Duration(seconds: 15);

  /// Flag para saber si el backend está caliente
  static bool _isBackendWarm = false;

  /// Verificación rápida de conectividad (para no bloquear guardado)
  /// NOTA: En Windows con Render.com dormido puede tardar 5-8 segundos
  static Future<bool> hasInternetConnection() async {
    try {
      final url = Uri.parse('$baseUrl/health');
      final resp = await http.get(url).timeout(_quickCheckTimeout);
      _isBackendWarm = true; // Marcar como caliente si respondió
      return resp.statusCode == 200;
    } catch (e) {
      print('⚠️ [INTERNET_CHECK] Timeout o sin conexión: $e');
      return false; // Sin internet o backend no responde
    }
  }

  /// Wake up del backend con health check
  static Future<bool> wakeUpBackend() async {
    if (_isBackendWarm) return true;

    try {
      print('🔥 Intentando despertar backend...');
      final url = Uri.parse('$baseUrl/health');
      final resp = await http.get(url).timeout(_healthTimeout);
      _isBackendWarm = resp.statusCode == 200;
      if (_isBackendWarm) {
        print('✅ Backend está listo');
      }
      return _isBackendWarm;
    } catch (e) {
      print('⚠️ Backend aún no responde: $e');
      return false;
    }
  }

  /// Test de conexión al backend (para diagnósticos)
  static Future<bool> testConnection() async {
    try {
      final url = Uri.parse('$baseUrl/health');
      final resp = await http.get(url).timeout(const Duration(seconds: 10));
      return resp.statusCode == 200;
    } catch (e) {
      print('❌ Test de conexión falló: $e');
      return false;
    }
  }

  // Consulta un expediente por ID (QR)
  static Future<Map<String, dynamic>?> getExpedienteById(String id) async {
    try {
      // DRY-RUN: Intento A → GET /carnet/{id}
      final urlA = Uri.parse('$baseUrl/carnet/$id');
      print('[DRY-RUN] Intento A: $urlA');
      final respA = await http.get(urlA);
      print('[DRY-RUN] Status A: ${respA.statusCode}');
      print('[DRY-RUN] Body A: ${respA.body}');

      if (respA.statusCode == 200) {
        final data = jsonDecode(respA.body);
        if (data != null && data is Map && data.isNotEmpty) {
          final normalized =
              _normalizeCarnetData(Map<String, dynamic>.from(data));
          print('[DRY-RUN] Llaves nivel 1: ${normalized.keys.toList()}');
          print('[DRY-RUN] ID encontrado: ${normalized['id']}');
          _logDataTypes(normalized);
          return normalized;
        }
      }

      // DRY-RUN: Intento B → GET /carnet/carnet:{id} (si id no empieza con carnet:)
      if (!id.startsWith('carnet:')) {
        final urlB = Uri.parse('$baseUrl/carnet/carnet:$id');
        print('[DRY-RUN] Intento B: $urlB');
        final respB = await http.get(urlB);
        print('[DRY-RUN] Status B: ${respB.statusCode}');
        print('[DRY-RUN] Body B: ${respB.body}');

        if (respB.statusCode == 200) {
          final data = jsonDecode(respB.body);
          if (data != null && data is Map && data.isNotEmpty) {
            final normalized =
                _normalizeCarnetData(Map<String, dynamic>.from(data));
            print('[DRY-RUN] Llaves nivel 1: ${normalized.keys.toList()}');
            print('[DRY-RUN] ID encontrado: ${normalized['id']}');
            _logDataTypes(normalized);
            return normalized;
          }
        }
      }

      print('[DRY-RUN] No se encontró carnet válido');
      return null;
    } catch (e) {
      print('Error en getExpedienteById: $e');
      return null;
    }
  }

  // Sube una nota para una matrícula
  static Future<bool> pushSingleNote({
    required String matricula,
    required String departamento,
    required String cuerpo,
    required String tratante,
    String? idOverride,
    DateTime? createdAt,
  }) async {
    try {
      // Obtener token JWT (opcional para /notas, pero recomendado)
      final token = await auth.AuthService.getToken();

      final url = Uri.parse('$baseUrl/notas');
      final payload = {
        'matricula': matricula,
        'departamento': departamento,
        'cuerpo': cuerpo,
        'tratante': tratante,
        if (idOverride != null) 'id': idOverride,
        if (createdAt != null)
          'createdAt': ClinicalDateTime.toUtcIsoStringWithZone(createdAt),
      };

      print('[SYNC] 📤 Enviando nota a servidor...');
      print('[SYNC]   - Matrícula: $matricula');
      print('[SYNC]   - ID override: $idOverride');
      ClinicalDateTime.debugLog('[NOTES] SAVE_REMOTE');
      final createdAtUtc = createdAt == null
          ? null
          : ClinicalDateTime.toUtcIsoStringWithZone(createdAt);
      print('[SYNC]   - CreatedAt UTC: $createdAtUtc');

      final headers = {
        'Content-Type': 'application/json',
        if (token != null && !token.startsWith('offline_'))
          'Authorization': 'Bearer $token',
      };

      final resp = await http
          .post(
        url,
        headers: headers,
        body: jsonEncode(payload),
      )
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Timeout: El servidor no respondió en 30 segundos');
        },
      );

      print('[SYNC] 📥 Respuesta del servidor: ${resp.statusCode}');

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        String? remoteId;
        try {
          final decoded = jsonDecode(resp.body);
          if (decoded is Map) {
            final data = decoded['data'];
            remoteId = (decoded['id'] ??
                    (data is Map ? data['id'] : null) ??
                    idOverride)
                ?.toString();
          }
        } catch (_) {}
        ClinicalDateTime.debugLog(
            '[NOTES] SAVE_REMOTE_OK id=${remoteId ?? idOverride ?? "(sin id)"}');
        print('[SYNC] ✅ Nota sincronizada exitosamente');
        await CacheService.invalidateNotas(matricula);
        return true;
      } else {
        print('[SYNC] ❌ Error del servidor: ${resp.statusCode} - ${resp.body}');
        return false;
      }
    } catch (e) {
      print('[SYNC] ❌ Error en pushSingleNote: $e');
      return false;
    }
  }

  // Resultado detallado de la sincronización
  // Crea un carnet desde el formulario y lo guarda en la nube
  static Future<bool> pushSingleCarnet(Map<String, dynamic> data) async {
    try {
      // Obtener token JWT para autenticación
      final token = await auth.AuthService.getToken();
      if (token == null) {
        print('[CARNET] ⚠️ No hay token JWT, no se puede sincronizar');
        return false;
      }

      // Si está en modo offline, retornar FALSE para que quede pendiente de sincronización
      if (token.startsWith('offline_')) {
        print(
            '[CARNET] ℹ️ Modo offline detectado - marcando como NO sincronizado (pendiente)');
        return false; // Dejarlo pendiente para sincronizar cuando haya internet
      }

      data['escuelaUnidadAcademica'] =
          (data['escuelaUnidadAcademica']?.toString().trim().isNotEmpty ??
                  false)
              ? data['escuelaUnidadAcademica'].toString().trim()
              : 'No especificada';
      data['grupo'] = data['grupo']?.toString() ?? '';

      // Determinar si es creación (sin ID) o edición (con ID)
      final isEdit = data.containsKey('id') && data['id'] != null;
      final Uri url;
      final String method;

      if (isEdit) {
        // Editar carnet existente: PUT /carnet/{id}
        url = Uri.parse('$baseUrl/carnet/${data['id']}');
        method = 'PUT';
      } else {
        // Crear carnet nuevo: POST /carnet
        url = Uri.parse('$baseUrl/carnet');
        method = 'POST';
      }

      print('=== SYNC CARNET DEBUG ===');
      print('$method $url');
      print('Payload: $data');
      print('Es edición: $isEdit');
      print('ID: ${data.containsKey('id') ? data['id'] : 'NO'}');

      // Log detallado para diagnóstico
      SyncLogger.log('=== SINCRONIZACIÓN DE CARNET ===');
      SyncLogger.log('Método: $method');
      SyncLogger.log('URL: $url');
      SyncLogger.log('Matrícula: ${data['matricula']}');
      SyncLogger.log('Nombre: ${data['nombreCompleto']}');
      SyncLogger.log('Es edición: $isEdit');

      final http.Response resp;
      if (isEdit) {
        resp = await http.put(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(data),
        );
      } else {
        resp = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(data),
        );
      }

      print('Status: ${resp.statusCode}');
      print('Response Body: ${resp.body}');
      print('Response Headers: ${resp.headers}');

      SyncLogger.log('Status HTTP: ${resp.statusCode}');
      SyncLogger.log('Response Body: ${resp.body}');

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        print('[CARNET] ✅ RESPUESTA EXITOSA - Status: ${resp.statusCode}');
        SyncLogger.log('✅ ÉXITO - Carnet sincronizado correctamente');
        try {
          final responseData = jsonDecode(resp.body);
          print(
              '[CARNET] Guardado exitoso - Respuesta parseada: $responseData');
          if (responseData.containsKey('id')) {
            print('[CARNET] ID del carnet en respuesta: ${responseData['id']}');
            SyncLogger.log(
                'ID asignado por el servidor: ${responseData['id']}');
          }
          return true;
        } catch (e) {
          print(
              '[CARNET] Warning: respuesta no JSON pero status OK - Error: $e');
          print('[CARNET] ✅ CONSIDERANDO COMO ÉXITO por status 2xx');
          SyncLogger.log(
              '⚠️ Respuesta no JSON pero status 2xx - considerando éxito');
          return true; // Status 2xx = éxito aunque no sea JSON válido
        }
      } else if (resp.statusCode == 401 || resp.statusCode == 403) {
        print(
            '[CARNET] ⚠️ Token expirado o sin permisos - Status: ${resp.statusCode}');
        print('[CARNET] ⚠️ Respuesta del servidor: ${resp.body}');
        SyncLogger.log(
            '❌ ERROR ${resp.statusCode} - Token expirado o sin permisos');
        SyncLogger.log('Respuesta: ${resp.body}');

        // Intentar renovar token automáticamente si es 401
        if (resp.statusCode == 401) {
          print('[CARNET] 🔄 Intentando renovar token automáticamente...');
          SyncLogger.log('🔄 Intentando renovar token automáticamente...');

          final renewed = await auth.AuthService.renewTokenIfExpired();
          if (renewed) {
            print('[CARNET] ✅ Token renovado - reintentando sincronización...');
            SyncLogger.log('✅ Token renovado exitosamente - reintentando...');

            // Reintentar la solicitud con el nuevo token
            final newToken = await auth.AuthService.getToken();
            final http.Response retryResp;

            if (isEdit) {
              retryResp = await http.put(
                url,
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer $newToken',
                },
                body: jsonEncode(data),
              );
            } else {
              retryResp = await http.post(
                url,
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer $newToken',
                },
                body: jsonEncode(data),
              );
            }

            SyncLogger.log('Status HTTP (reintento): ${retryResp.statusCode}');

            if (retryResp.statusCode == 200 || retryResp.statusCode == 201) {
              print(
                  '[CARNET] ✅ Sincronización exitosa después de renovar token');
              SyncLogger.log('✅ ÉXITO después de renovar token');
              return true;
            } else {
              print(
                  '[CARNET] ❌ Fallo después de renovar token: ${retryResp.statusCode}');
              SyncLogger.log(
                  '❌ Fallo después de renovar token: ${retryResp.statusCode}');
              return false;
            }
          } else {
            print('[CARNET] ❌ No se pudo renovar token');
            SyncLogger.log(
                '❌ No se pudo renovar token - requiere login manual');
          }
        }

        return false;
      } else {
        print('[CARNET] ❌ ERROR HTTP ${resp.statusCode}');
        print('[CARNET] ❌ Body completo: ${resp.body}');
        print('[CARNET] ❌ Método: $method | URL: $url');
        SyncLogger.log('❌ ERROR HTTP ${resp.statusCode}');
        SyncLogger.log('Body: ${resp.body}');
        SyncLogger.log('Este error indica:');
        if (resp.statusCode == 400) {
          SyncLogger.log('  → Datos mal formateados o inválidos');
        } else if (resp.statusCode == 422) {
          SyncLogger.log(
              '  → Validación fallida (ej: matrícula duplicada, campos requeridos faltantes)');
        } else if (resp.statusCode == 404) {
          SyncLogger.log('  → Recurso no encontrado (endpoint incorrecto)');
        } else if (resp.statusCode >= 500) {
          SyncLogger.log('  → Error interno del servidor');
        }
        return false;
      }
    } catch (e) {
      print('ERROR CRÍTICO en pushSingleCarnet: $e');
      print('Stack trace: ${StackTrace.current}');
      SyncLogger.log('❌ ERROR CRÍTICO: $e');
      SyncLogger.log('Stack trace: ${StackTrace.current}');
      return false;
    }
  }

// Consulta un expediente por matrícula
  static Future<Map<String, dynamic>?> getExpedienteByMatricula(
      String matricula) async {
    try {
      print('BUSCANDO CARNET');
      print('Parametro recibido: $matricula');
      print('Tipo: ${matricula.runtimeType}');

      // 🚀 Primero intentar obtener del caché
      final cached = await CacheService.getCarnet(matricula);
      if (cached != null) {
        print('⚡ Carnet obtenido del caché (instantáneo)');
        return cached;
      }

      // 🚀 OPTIMIZACIÓN: Intentar ambas URLs en paralelo usando Future.any
      // Devuelve la primera respuesta exitosa, cancelando la otra
      final urlA = Uri.parse('$baseUrl/carnet/$matricula');
      final urlB = matricula.startsWith('carnet:')
          ? null
          : Uri.parse('$baseUrl/carnet/carnet:$matricula');

      print('[CARNET-LOOKUP] URL A exacta: $urlA');
      print('[CARNET-LOOKUP] URL B exacta: ${urlB ?? "(no aplica)"}');
      print('[PARALELO] Intentando: $urlA ${urlB != null ? "y $urlB" : ""}');

      // Crear lista de futures (solo agregar urlB si existe)
      final futures = <Future<http.Response>>[
        http.get(urlA).timeout(_normalTimeout),
        if (urlB != null) http.get(urlB).timeout(_normalTimeout),
      ];

      // Procesar respuestas conforme lleguen
      for (final future in futures) {
        try {
          final resp = await future;
          final bodyPreview = resp.body.length > 1000
              ? '${resp.body.substring(0, 1000)}...'
              : resp.body;
          print('[CARNET-LOOKUP] Respuesta del servidor');
          print('[CARNET-LOOKUP] URL respondida: ${resp.request?.url}');
          print('[CARNET-LOOKUP] Status: ${resp.statusCode}');
          print('[CARNET-LOOKUP] Body: $bodyPreview');
          if (resp.statusCode == 200) {
            final data = jsonDecode(resp.body);

            // Procesar Map directo
            if (data != null && data is Map && data.isNotEmpty) {
              final normalized =
                  _normalizeCarnetData(Map<String, dynamic>.from(data));
              if (normalized['id'] != null) {
                print(
                    '[PARALELO] ✅ Carnet encontrado - ID: ${normalized['id']}');
                await CacheService.saveCarnet(matricula, normalized);
                return normalized;
              }
            }

            // Procesar lista de carnets
            if (data is List && data.isNotEmpty) {
              final carnets = data
                  .where((item) =>
                      item is Map &&
                      item['id'] != null &&
                      item['id'].toString().startsWith('carnet:') &&
                      !item.containsKey('inicio') &&
                      !item.containsKey('fin'))
                  .toList();

              if (carnets.isNotEmpty) {
                carnets.sort((a, b) {
                  final tsA = a['_ts'] ?? 0;
                  final tsB = b['_ts'] ?? 0;
                  return tsB.compareTo(tsA);
                });
                final normalized = _normalizeCarnetData(
                    Map<String, dynamic>.from(carnets.first));
                print('[PARALELO] ✅ Carnet filtrado - ID: ${normalized['id']}');
                await CacheService.saveCarnet(matricula, normalized);
                return normalized;
              }
            }
          }
        } catch (e) {
          print('[PARALELO] ⚠️ Request falló: $e');
          continue; // Intentar siguiente URL
        }
      }

      print('[PARALELO] ❌ No se encontró carnet válido para matrícula');
      return null;
    } catch (e) {
      print('Error en getExpedienteByMatricula: $e');
      return null;
    }
  }

// Buscar expediente por nombre (búsqueda parcial)
  static Future<Map<String, dynamic>?> searchExpedienteByName(
      String nombre) async {
    if (nombre.trim().isNotEmpty || nombre.trim().isEmpty) {
      final results = await searchExpedientesByName(nombre);
      return results.isNotEmpty ? results.first : null;
    }

    try {
      print('[BUSCAR-NOMBRE] Buscando: $nombre');

      // Endpoint de búsqueda por nombre en el backend
      final url = Uri.parse('$baseUrl/carnet/search').replace(
        queryParameters: {'nombre': nombre},
      );

      print('[BUSCAR-NOMBRE] URL: $url');
      final resp = await http.get(url).timeout(_normalTimeout);

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);

        // Si devuelve una lista, tomar el primer resultado
        if (data is List && data.isNotEmpty) {
          final normalized =
              _normalizeCarnetData(Map<String, dynamic>.from(data.first));
          print(
              '[BUSCAR-NOMBRE] ✅ Encontrado: ${normalized['nombreCompleto']} - ${normalized['matricula']}');
          return normalized;
        }

        // Si devuelve un objeto directo
        if (data is Map && data.isNotEmpty) {
          final normalized =
              _normalizeCarnetData(Map<String, dynamic>.from(data));
          print(
              '[BUSCAR-NOMBRE] ✅ Encontrado: ${normalized['nombreCompleto']} - ${normalized['matricula']}');
          return normalized;
        }
      }

      print('[BUSCAR-NOMBRE] ❌ No se encontró expediente');
      return null;
    } catch (e) {
      print('Error en searchExpedienteByName: $e');
      return null;
    }
  }

// Consulta todas las notas para una matrícula
  static Future<List<Map<String, dynamic>>> searchExpedientesByName(
      String nombre) async {
    try {
      final query = nombre.trim();
      if (query.isEmpty) return [];

      print('[BUSCAR-NOMBRE] Buscando en nube: $query');
      print('[BUSCAR-NOMBRE] Tipo parametro: ${nombre.runtimeType}');

      final url = Uri.parse('$baseUrl/carnet/search').replace(
        queryParameters: {'nombre': query},
      );

      print('[BUSCAR-NOMBRE] URL: $url');
      final resp = await http.get(url).timeout(_normalTimeout);

      if (resp.statusCode != 200) {
        print('[BUSCAR-NOMBRE] status=${resp.statusCode} body=${resp.body}');
        return [];
      }

      final data = jsonDecode(resp.body);
      final rawResults = _extractCarnetSearchResults(data);
      final normalizedResults = <Map<String, dynamic>>[];
      final seen = <String>{};

      for (final raw in rawResults) {
        final normalized = _normalizeCarnetData(raw);
        final key = (normalized['matricula'] ??
                normalized['id'] ??
                normalized['nombreCompleto'] ??
                '')
            .toString()
            .trim();
        if (key.isEmpty || seen.contains(key)) continue;
        seen.add(key);
        normalizedResults.add(normalized);
      }

      normalizedResults.sort((a, b) {
        final tsA = int.tryParse((a['_ts'] ?? '0').toString()) ?? 0;
        final tsB = int.tryParse((b['_ts'] ?? '0').toString()) ?? 0;
        return tsB.compareTo(tsA);
      });

      print('[BUSCAR-NOMBRE] Resultados nube: ${normalizedResults.length}');
      return normalizedResults;
    } catch (e) {
      print('Error en searchExpedientesByName: $e');
      return [];
    }
  }

  static List<Map<String, dynamic>> _extractCarnetSearchResults(dynamic data) {
    Iterable<dynamic> items;

    if (data is List) {
      items = data;
    } else if (data is Map) {
      final wrapped = data['data'] ??
          data['results'] ??
          data['items'] ??
          data['carnets'] ??
          data['expedientes'];
      items = wrapped is List ? wrapped : [data];
    } else {
      items = const [];
    }

    return items
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .where((item) {
      final id = item['id']?.toString() ?? '';
      final isCita = id.startsWith('cita:') ||
          item.containsKey('inicio') ||
          item.containsKey('fin');
      final hasCarnetIdentity = id.startsWith('carnet:') ||
          item.containsKey('matricula') ||
          item.containsKey('matr\u00edcula') ||
          item.containsKey('matricula_alumno') ||
          item.containsKey('numeroCuenta') ||
          item.containsKey('numero_cuenta') ||
          item.containsKey('nombreCompleto') ||
          item.containsKey('nombre_completo') ||
          item.containsKey('nombre') ||
          item.containsKey('fullName') ||
          item.containsKey('full_name');
      return !isCita && hasCarnetIdentity;
    }).toList();
  }

  static Future<List<Map<String, dynamic>>> getNotasForMatricula(
      String matricula) async {
    try {
      // 🚀 Primero intentar obtener del caché
      var cached = await CacheService.getNotas(matricula);
      if (cached != null) {
        cached = _normalizeNotasData(cached);
        await CacheService.saveNotas(matricula, cached);
        print('⚡ Notas obtenidas del caché (instantáneo)');
        return cached;
      }

      final url = Uri.parse('$baseUrl/notas/$matricula');
      print('Consultando notas en: $url');
      final resp = await http.get(url).timeout(_normalTimeout);
      print('Status: ${resp.statusCode}');
      print('Body: ${resp.body}');
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data is List) {
          print('Notas decodificadas: $data');
          final notas = _normalizeNotasData(
            data.map<Map<String, dynamic>>(
              (e) => Map<String, dynamic>.from(e),
            ),
          );

          // 💾 Guardar en caché
          await CacheService.saveNotas(matricula, notas);

          return notas;
        } else {
          print('La respuesta de la API no es una lista');
        }
      } else {
        print('Error al consultar notas: Status ${resp.statusCode}');
      }
      return [];
    } catch (e) {
      print('Error en getNotasForMatricula: $e');
      return [];
    }
  }

  static Map<String, dynamic> _normalizeNotaData(Map<String, dynamic> data) {
    final normalized = Map<String, dynamic>.from(data);
    final parsed = ClinicalDateTime.parseServerValue(normalized['createdAt']);
    if (parsed != null) {
      normalized['createdAt'] = ClinicalDateTime.toUtcIsoString(parsed);
    }
    return normalized;
  }

  static List<Map<String, dynamic>> _normalizeNotasData(
    Iterable<Map<String, dynamic>> notes,
  ) {
    final unique = <Map<String, dynamic>>[];
    for (final note in notes.map(_normalizeNotaData)) {
      final existingIndex =
          unique.indexWhere((item) => _isSameNotaData(item, note));
      if (existingIndex == -1) {
        unique.add(note);
      } else {
        unique[existingIndex] = _preferredNotaData(unique[existingIndex], note);
      }
    }
    return unique;
  }

  static bool _isSameNotaData(
    Map<String, dynamic> a,
    Map<String, dynamic> b,
  ) {
    final aId = (a['id'] ?? '').toString().trim();
    final bId = (b['id'] ?? '').toString().trim();
    if (aId.isNotEmpty && bId.isNotEmpty && aId == bId) return true;

    final aDate = ClinicalDateTime.parseServerValue(a['createdAt']);
    final bDate = ClinicalDateTime.parseServerValue(b['createdAt']);
    if (aDate == null || bDate == null) return false;

    if (!ClinicalDateTime.isSameClinicalMoment(aDate, bDate)) return false;

    return _notaSignature(a) == _notaSignature(b);
  }

  static Map<String, dynamic> _preferredNotaData(
    Map<String, dynamic> a,
    Map<String, dynamic> b,
  ) {
    final aDate = ClinicalDateTime.parseServerValue(a['createdAt']);
    final bDate = ClinicalDateTime.parseServerValue(b['createdAt']);
    if (aDate == null || bDate == null) return a;

    final now = DateTime.now().add(const Duration(minutes: 5));
    final aFuture = aDate.isAfter(now);
    final bFuture = bDate.isAfter(now);
    if (aFuture != bFuture) return aFuture ? b : a;

    return aDate.isAfter(bDate) ? a : b;
  }

  static String _notaSignature(Map<String, dynamic> note) {
    String clean(dynamic value) =>
        value
            ?.toString()
            .trim()
            .toLowerCase()
            .replaceAll(RegExp(r'\s+'), ' ') ??
        '';

    return [
      clean(note['matricula']),
      clean(note['departamento']),
      clean(note['tratante']),
      clean(note['cuerpo']),
    ].join('|');
  }

// Sube una cita para una matrícula
  static Future<bool> pushSingleCita({
    required String matricula,
    required String inicio,
    required String fin,
    required String motivo,
    String? departamento,
    String? idOverride,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/citas');
      final payload = {
        'matricula': matricula,
        'inicio': inicio,
        'fin': fin,
        'motivo': motivo,
        if (departamento != null && departamento.isNotEmpty)
          'departamento': departamento,
        if (idOverride != null) 'id': idOverride,
      };

      // DRY-RUN logs
      print('[DRY-RUN Flutter] API_BASE_URL: $baseUrl');
      print(
          '[DRY-RUN Flutter] POST /citas, Headers: Content-Type: application/json');
      print(
          '[DRY-RUN Flutter] Payload - matricula: ${payload['matricula']}, inicio: ${payload['inicio']}, fin: ${payload['fin']}, motivo: ${payload['motivo']}');
      print(
          '[DRY-RUN Flutter] Payload keys: ${payload.keys.toList()} (no requiere id ni cita - backend genera automáticamente)');

      final resp = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      print('[DRY-RUN Flutter] Status: ${resp.statusCode}');
      print(
          '[DRY-RUN Flutter] Body keys: ${jsonDecode(resp.body).keys.toList()}');

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        try {
          final response = jsonDecode(resp.body);
          // Log new_cita_id si está presente
          final newId = response['id'] ?? response['data']?['id'];
          if (newId != null) {
            print('[DRY-RUN Flutter] new_cita_id=$newId');
          }
          // Convertir éxito basado en status 200/201 o presencia de id/_etag
          final hasId =
              response['id'] != null || response['data']?['id'] != null;
          final hasEtag =
              response['_etag'] != null || response['data']?['_etag'] != null;
          final success = response['status'] == 'created' || hasId || hasEtag;
          print(
              '[DRY-RUN Flutter] Success conversion: $success (hasId: $hasId, hasEtag: $hasEtag)');
          return success;
        } catch (e) {
          // Si no es JSON válido pero status es 2xx, considerar éxito
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Error en pushSingleCita: $e');
      return false;
    }
  }

// Consulta todas las citas para una matrícula
  static Future<List<Map<String, dynamic>>> getCitasForMatricula(
      String matricula) async {
    try {
      // 🚀 Primero intentar obtener del caché
      final cached = await CacheService.getCitas(matricula);
      if (cached != null) {
        print('⚡ Citas obtenidas del caché (instantáneo)');
        return cached;
      }

      final url = Uri.parse('$baseUrl/citas/por-matricula/$matricula');
      print('[DRY-RUN Flutter] GET /citas/por-matricula/$matricula');
      final resp = await http.get(url).timeout(_normalTimeout);
      print('[DRY-RUN Flutter] Status: ${resp.statusCode}');
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data is List) {
          print('[DRY-RUN Flutter] Cantidad de citas: ${data.length}');
          final citas = data
              .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
              .toList();

          // 💾 Guardar en caché
          await CacheService.saveCitas(matricula, citas);

          return citas;
        } else {
          print('La respuesta de la API no es una lista');
        }
      } else {
        print('Error al consultar citas: Status ${resp.statusCode}');
      }
      return [];
    } catch (e) {
      print('Error en getCitasForMatricula: $e');
      return [];
    }
  }

// (Opcional) Consulta una cita específica por ID
  static Future<Map<String, dynamic>?> getCitaById(String citaId) async {
    try {
      final url = Uri.parse('$baseUrl/citas/$citaId');
      print('[DRY-RUN Flutter] GET /citas/$citaId');
      final resp = await http.get(url);
      print('[DRY-RUN Flutter] Status: ${resp.statusCode}');
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data is Map) {
          print('[DRY-RUN Flutter] Cita encontrada: ${data['id']}');
          return Map<String, dynamic>.from(data);
        }
      } else if (resp.statusCode == 404) {
        print('[DRY-RUN Flutter] Cita no encontrada');
      }
      return null;
    } catch (e) {
      print('Error en getCitaById: $e');
      return null;
    }
  }

  // Normaliza los datos del carnet con alias de claves y tipos mixtos
  static Map<String, dynamic> _normalizeCarnetData(Map<String, dynamic> data) {
    final normalized = <String, dynamic>{};

    // Copiar datos tal como vienen
    normalized.addAll(data);

    // Alias de claves (usar la primera disponible)
    normalized['matricula'] ??= data['matr\u00edcula'] ??
        data['matricula_alumno'] ??
        data['numeroCuenta'] ??
        data['numero_cuenta'] ??
        data['studentId'] ??
        data['student_id'];
    normalized['nombreCompleto'] ??= data['nombre_completo'];
    normalized['nombreCompleto'] ??=
        data['nombre'] ?? data['fullName'] ?? data['full_name'] ?? data['name'];
    normalized['tipoSangre'] ??= data['tipo_sangre'];
    normalized['enfermedadCronica'] ??= data['enfermedad_cronica'];
    normalized['numeroAfiliacion'] ??= data['numero_afiliacion'];
    normalized['usoSeguroUniversitario'] ??= data['uso_seguro_universitario'];
    normalized['emergenciaTelefono'] ??= data['emergencia_telefono'];
    normalized['escuelaUnidadAcademica'] ??= data['escuela_unidad_academica'] ??
        data['escuela'] ??
        data['unidadAcademica'];

    if (normalized['escuelaUnidadAcademica'] == null ||
        normalized['escuelaUnidadAcademica'].toString().trim().isEmpty) {
      normalized['escuelaUnidadAcademica'] = 'No especificada';
    } else {
      normalized['escuelaUnidadAcademica'] =
          normalized['escuelaUnidadAcademica'].toString().trim();
    }
    normalized['grupo'] = normalized['grupo']?.toString() ?? '';

    // Normalizar edad: aceptar int/double/String → int?
    if (normalized['edad'] != null) {
      if (normalized['edad'] is String) {
        normalized['edad'] = int.tryParse(normalized['edad'].toString());
      } else if (normalized['edad'] is double) {
        normalized['edad'] = (normalized['edad'] as double).round();
      }
    }

    // Normalizar expedienteAdjuntos: String "[]" → List
    if (normalized['expedienteAdjuntos'] != null) {
      if (normalized['expedienteAdjuntos'] is String) {
        final str = normalized['expedienteAdjuntos'].toString().trim();
        if (str.isEmpty || str == '[]') {
          normalized['expedienteAdjuntos'] = <dynamic>[];
        } else {
          try {
            normalized['expedienteAdjuntos'] = jsonDecode(str);
          } catch (e) {
            normalized['expedienteAdjuntos'] = <dynamic>[];
          }
        }
      } else if (normalized['expedienteAdjuntos'] is! List) {
        normalized['expedienteAdjuntos'] = <dynamic>[];
      }
    }

    // Aceptar id con prefijo carnet: sin modificarlo
    // (ya está en los datos originales)

    return normalized;
  }

  // Log de tipos de datos para DRY-RUN
  static void _logDataTypes(Map<String, dynamic> data) {
    if (data['edad'] != null) {
      print(
          '[DRY-RUN] Tipo edad: ${data['edad'].runtimeType} = ${data['edad']}');
    }
    if (data['expedienteAdjuntos'] != null) {
      print(
          '[DRY-RUN] Tipo expedienteAdjuntos: ${data['expedienteAdjuntos'].runtimeType} = ${data['expedienteAdjuntos']}');
    }
  }

  // === MÉTODOS DE CITAS ===

  /// Crear una nueva cita
  /// POST $API/citas (Content-Type: application/json)
  /// No requiere id; el backend lo genera automáticamente
  /// Éxito por status 200/201 y/o presencia de id/_etag
  static Future<Map<String, dynamic>?> createCita(
      Map<String, dynamic> payload) async {
    try {
      final url = Uri.parse('$baseUrl/citas');
      print('[CITAS] POST $url');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      print('[CITAS] Status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final data = jsonDecode(response.body);
          // Verificar éxito por presencia de id/_etag o status created
          final hasId = data['id'] != null || data['data']?['id'] != null;
          final hasEtag =
              data['_etag'] != null || data['data']?['_etag'] != null;
          final isCreated = data['status'] == 'created';

          if (hasId || hasEtag || isCreated) {
            print('[CITAS] ✅ Cita creada exitosamente');
            return Map<String, dynamic>.from(data);
          }
        } catch (e) {
          print('[CITAS] ⚠️ Respuesta no JSON pero status OK');
          return {'status': 'created'}; // Status 2xx = éxito
        }
      } else {
        print('[CITAS] ❌ Error: ${response.statusCode}');
      }
      return null;
    } catch (e) {
      print('[CITAS] ❌ Error en createCita: $e');
      return null;
    }
  }

  /// Consultar citas por matrícula
  /// GET $API/citas/por-matricula/$m
  static Future<List<Map<String, dynamic>>> getCitasByMatricula(
      String matricula) async {
    try {
      final url =
          Uri.parse('$baseUrl/citas/por-matricula/$matricula').toString();
      print('[CITAS_FETCH] GET $url');

      final response = await http.get(Uri.parse(url));
      print('[CITAS_FETCH] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<Map<String, dynamic>> list = [];

        if (data is List) {
          // Respuesta directa como array
          list = data
              .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
              .toList();
        } else if (data is Map && data['data'] is List) {
          // Respuesta envuelta en { data: [...] }
          list = (data['data'] as List)
              .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
              .toList();
        }

        print('[CITAS_FETCH] m=$matricula len=${list.length}');
        return list;
      } else {
        print('[CITAS_FETCH][ERROR] status=${response.statusCode} url=$url');
        return [];
      }
    } catch (e) {
      print('[CITAS_FETCH][ERROR] Exception: $e');
      return [];
    }
  }

  // Métodos para promociones de salud
  static Future<Map<String, dynamic>?> createPromocionSalud(
      Map<String, dynamic> promocionData) async {
    try {
      final url = '$baseUrl/promociones-salud/';
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(promocionData),
      );

      print('[PROMOCION_SALUD_CREATE] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Map<String, dynamic>.from(data);
      } else {
        print(
            '[PROMOCION_SALUD_CREATE][ERROR] status=${response.statusCode} body=${response.body}');
        return null;
      }
    } catch (e) {
      print('[PROMOCION_SALUD_CREATE][ERROR] Exception: $e');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getPromocionesSalud() async {
    try {
      final url = '$baseUrl/promociones-salud/';
      final response = await http.get(Uri.parse(url));

      print('[PROMOCIONES_SALUD_FETCH] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<Map<String, dynamic>> list = [];

        if (data is List) {
          list = data
              .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
              .toList();
        }

        print('[PROMOCIONES_SALUD_FETCH] len=${list.length}');
        return list;
      } else {
        print('[PROMOCIONES_SALUD_FETCH][ERROR] status=${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('[PROMOCIONES_SALUD_FETCH][ERROR] Exception: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> validateSupervisorKey(String key) async {
    try {
      final url = '$baseUrl/promociones-salud/validate-supervisor';
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'key': key}),
      );

      print('[SUPERVISOR_VALIDATE] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Map<String, dynamic>.from(data);
      } else {
        print('[SUPERVISOR_VALIDATE][ERROR] status=${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('[SUPERVISOR_VALIDATE][ERROR] Exception: $e');
      return null;
    }
  }

  /// Guarda una aplicación de vacuna en el expediente del estudiante
  /// Se almacena en Cosmos DB como parte del documento del carnet
  /// Ruta: /carnet/{matricula}/vacunacion
  static Future<bool> guardarAplicacionVacuna({
    required String matricula,
    required String campana,
    required String vacuna,
    required int dosis,
    required String fechaAplicacion,
    String? lote,
    String? aplicadoPor,
    String? observaciones,
    String? nombreEstudiante,
  }) async {
    try {
      // Crear ID único para esta aplicación
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final idAplicacion = 'vacuna_${matricula}_$timestamp';

      final url = Uri.parse('$baseUrl/carnet/$matricula/vacunacion');
      final payload = {
        'id': idAplicacion,
        'matricula': matricula,
        'nombreEstudiante': nombreEstudiante ?? '',
        'campana': campana,
        'vacuna': vacuna,
        'dosis': dosis,
        'lote': lote ?? '',
        'aplicadoPor': aplicadoPor ?? '',
        'fechaAplicacion': fechaAplicacion,
        'observaciones': observaciones ?? '',
        'timestamp': DateTime.now().toIso8601String(),
      };

      print('[VACUNACION] Guardando aplicación: $idAplicacion');
      print('[VACUNACION] Payload: ${jsonEncode(payload)}');

      // Obtener token JWT
      final token = await auth.AuthService.getToken();
      if (token == null) {
        print('[VACUNACION] ⚠️ No hay token JWT, guardando solo localmente');
        return false;
      }

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(payload),
          )
          .timeout(_normalTimeout);

      print('[VACUNACION] Status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('[VACUNACION] ✅ Guardado exitoso en Cosmos DB');
        return true;
      } else if (response.statusCode == 401) {
        print(
            '[VACUNACION] ⚠️ Token expirado o inválido, se guardó solo localmente');
        return false;
      } else if (response.statusCode == 404) {
        print('[VACUNACION] ⚠️ Endpoint no existe, se guardó solo localmente');
        return false;
      } else {
        print('[VACUNACION] ❌ Error ${response.statusCode}: ${response.body}');
        return false;
      }
    } catch (e) {
      print('[VACUNACION] ❌ Exception: $e');
      return false;
    }
  }

  /// Obtiene el historial de vacunación de un estudiante
  static Future<List<Map<String, dynamic>>> getHistorialVacunacion(
      String matricula) async {
    try {
      // Obtener token JWT
      final token = await auth.AuthService.getToken();
      if (token == null) {
        print('[VACUNACION] ⚠️ No hay token JWT para obtener historial');
        return [];
      }

      final url = Uri.parse('$baseUrl/carnet/$matricula/vacunacion');
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(_normalTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
      }
      return [];
    } catch (e) {
      print('[VACUNACION] Error al obtener historial: $e');
      return [];
    }
  }

  /// Crea un registro de vacunación individual en el servidor
  static Future<Map<String, dynamic>?> createVacunacion(
      Map<String, dynamic> payload) async {
    try {
      // Obtener token JWT
      final token = await auth.AuthService.getToken();
      if (token == null) {
        print('[VACUNACION] ⚠️ No hay token JWT para crear vacunación');
        return null;
      }

      final matricula = payload['matricula'];
      if (matricula == null || matricula.isEmpty) {
        print('[VACUNACION] ⚠️ Matrícula requerida');
        return null;
      }

      final url = Uri.parse('$baseUrl/carnet/$matricula/vacunacion');
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(payload),
          )
          .timeout(_normalTimeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        print(
            '[VACUNACION] Error HTTP ${response.statusCode}: ${response.body}');
        return null;
      }
    } catch (e) {
      print('[VACUNACION] Error al crear vacunación: $e');
      return null;
    }
  }

  static Future<List<TicketAdminModel>> getTickets({
    String? status,
    String? category,
    String? priority,
    String? campus,
    String? matricula,
    String? studentId,
    String? unidadAcademica,
    String? preparatoria,
  }) async {
    final token = await _requireOnlineToken('consultar tickets');
    final query = <String, String>{
      if (_hasText(status)) 'status': status!.trim(),
      if (_hasText(category)) 'category': category!.trim(),
      if (_hasText(priority)) 'priority': priority!.trim(),
      if (_hasText(campus)) 'campus': campus!.trim(),
      if (_hasText(matricula)) 'matricula': matricula!.trim(),
      if (_hasText(studentId)) 'student_id': studentId!.trim(),
      if (_hasText(unidadAcademica))
        'unidad_academica': unidadAcademica!.trim(),
      if (_hasText(preparatoria)) 'preparatoria': preparatoria!.trim(),
    };
    final url = Uri.parse('$baseUrl/tickets').replace(queryParameters: query);

    final response = await http
        .get(
          url,
          headers: _jsonAuthHeaders(token),
        )
        .timeout(_normalTimeout);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final items = data is List
          ? data
          : data is Map && data['data'] is List
              ? data['data'] as List
              : const [];
      return items
          .whereType<Map>()
          .map((item) => TicketAdminModel.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .toList();
    }

    throw Exception(_httpErrorMessage('consultar tickets', response));
  }

  static Future<TicketDetailModel> getTicketDetail(String ticketId) async {
    final token = await _requireOnlineToken('consultar detalle de ticket');
    final url = Uri.parse('$baseUrl/tickets/$ticketId');

    final response = await http
        .get(
          url,
          headers: _jsonAuthHeaders(token),
        )
        .timeout(_normalTimeout);

    if (response.statusCode == 200) {
      return TicketDetailModel.fromJson(
        Map<String, dynamic>.from(jsonDecode(response.body) as Map),
      );
    }

    throw Exception(_httpErrorMessage('consultar detalle de ticket', response));
  }

  static Future<TicketAdminModel> updateTicketStatus({
    required String ticketId,
    required String status,
  }) async {
    final token = await _requireOnlineToken('cambiar estado de ticket');
    final url = Uri.parse('$baseUrl/tickets/$ticketId/status');

    final response = await http
        .patch(
          url,
          headers: _jsonAuthHeaders(token),
          body: jsonEncode({'estado': status}),
        )
        .timeout(_normalTimeout);

    if (response.statusCode == 200) {
      return TicketAdminModel.fromJson(
        Map<String, dynamic>.from(jsonDecode(response.body) as Map),
      );
    }

    throw Exception(_httpErrorMessage('cambiar estado de ticket', response));
  }

  static Future<TicketFollowupModel> addTicketFollowup({
    required String ticketId,
    required String message,
    required String visibility,
  }) async {
    final token = await _requireOnlineToken('agregar seguimiento');
    final url = Uri.parse('$baseUrl/tickets/$ticketId/followups');

    final response = await http
        .post(
          url,
          headers: _jsonAuthHeaders(token),
          body: jsonEncode({
            'message': message,
            'visibility': visibility,
          }),
        )
        .timeout(_normalTimeout);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return TicketFollowupModel.fromJson(
        Map<String, dynamic>.from(jsonDecode(response.body) as Map),
      );
    }

    throw Exception(_httpErrorMessage('agregar seguimiento', response));
  }

  static Future<String> _requireOnlineToken(String action) async {
    final token = await auth.AuthService.getToken();
    if (token == null || token.isEmpty || token.startsWith('offline_')) {
      throw Exception(
        'No hay una sesion en linea para $action. Inicia sesion con conexion.',
      );
    }
    return token;
  }

  static Map<String, String> _jsonAuthHeaders(String token) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static bool _hasText(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  static String _httpErrorMessage(String action, http.Response response) {
    var detail = response.body;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['detail'] != null) {
        detail = decoded['detail'].toString();
      }
    } catch (_) {}
    return 'No se pudo $action (${response.statusCode}): $detail';
  }
// CIERRA la clase
}
