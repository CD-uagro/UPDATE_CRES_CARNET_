import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' as drift;
import 'package:url_launcher/url_launcher.dart';
import '../ui/uagro_theme.dart';
import '../ui/brand.dart' as brand;
import '../utils/vaccination_pdf_generator.dart';
import '../data/api_service.dart';
import '../data/db.dart' as DB;
import 'dashboard_screen.dart';
import 'form_screen.dart';
import 'nueva_nota_screen.dart';
import 'promocion_salud_screen.dart';
import '../data/sync_vacunaciones.dart';

/// Pantalla de gestión de campañas de vacunación
class VaccinationScreen extends StatefulWidget {
  const VaccinationScreen({Key? key}) : super(key: key);

  @override
  State<VaccinationScreen> createState() => _VaccinationScreenState();
}

class _VaccinationScreenState extends State<VaccinationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCampanaCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _matriculaCtrl = TextEditingController();
  final _nombreEstudianteCtrl = TextEditingController();
  final _loteCtrl = TextEditingController();
  final _aplicadoPorCtrl = TextEditingController();
  final _observacionesCtrl = TextEditingController();
  final _otraVacunaCtrl = TextEditingController(); // Para vacuna manual

  // Base de datos local para sincronización
  late DB.AppDatabase _db;

  // Variables de estado
  List<String> _vacunasSeleccionadasCampana =
      []; // Para crear campaña (múltiples)
  List<String> _vacunasSeleccionadasAplicacion =
      []; // Para aplicar a estudiante (múltiples)
  bool _mostrarCampoVacunaPersonalizada =
      false; // Para agregar vacuna personalizada en campaña
  int _dosisSeleccionada = 1;
  DateTime _fechaInicio = DateTime.now();
  DateTime _fechaAplicacion = DateTime.now();
  bool _isLoadingCampaigns = false;
  bool _isCreatingCampaign = false;
  bool _isCreatingRecord = false;

  // Datos
  List<dynamic> _campanas = [];
  String? _campanaActivaId;
  String? _campanaActivaNombre;
  List<dynamic> _registros = [];

  // Lista de vacunas comunes en México para universidades
  final List<String> _vacunasDisponibles = [
    'Influenza (Gripe)',
    'COVID-19',
    'Hepatitis B',
    'Tétanos y Difteria (Td)',
    'Triple Viral (SRP)',
    'Hepatitis A',
    'Varicela',
    'VPH (Papiloma Humano)',
    'Meningococo',
    'Neumococo',
    'BCG (Tuberculosis)',
    'Antirrábica',
  ];

  @override
  void initState() {
    super.initState();
    _db = DB.AppDatabase();
    _cargarCampanas();
    _sincronizarPendientes(); // Intentar sincronizar al inicio
  }

  @override
  void dispose() {
    _db.close();
    _nombreCampanaCtrl.dispose();
    _descripcionCtrl.dispose();
    _matriculaCtrl.dispose();
    _nombreEstudianteCtrl.dispose();
    _loteCtrl.dispose();
    _aplicadoPorCtrl.dispose();
    _observacionesCtrl.dispose();
    super.dispose();
  }

  /// Obtener la URL base del backend
  String get _apiBaseUrl {
    const envUrl = String.fromEnvironment('API_BASE_URL',
        defaultValue: 'https://fastapi-backend-o7ks.onrender.com');
    return envUrl;
  }

  /// Sincronizar vacunaciones pendientes
  Future<void> _sincronizarPendientes() async {
    try {
      final pendientes = await _db.getPendingVacunaciones();
      if (pendientes.isNotEmpty) {
        print(
            '🔄 Intentando sincronizar ${pendientes.length} vacunaciones pendientes...');
        await syncVacunacionesPendientes(_db);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${pendientes.length} vacunaciones sincronizadas'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('⚠️ No se pudieron sincronizar vacunaciones pendientes: $e');
    }
  }

  /// Cargar campañas desde el backend
  Future<void> _cargarCampanas() async {
    setState(() => _isLoadingCampaigns = true);
    try {
      final response = await http
          .get(
            Uri.parse('$_apiBaseUrl/vaccination-campaigns/'),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        setState(() {
          _campanas = data;
          // Seleccionar la primera campaña activa si existe
          final activa = data.firstWhere(
            (c) => c['activa'] == true,
            orElse: () => data.isNotEmpty ? data.first : null,
          );
          if (activa != null) {
            _campanaActivaId = activa['id'];
            _campanaActivaNombre = activa['nombre'];
            _cargarRegistrosCampana(_campanaActivaId!);
          }
        });
      } else if (response.statusCode == 404) {
        // Endpoint no existe aún, usar datos locales
        print('⚠️ Endpoint de campañas no implementado, usando modo local');
        setState(() => _campanas = []);
      } else {
        _mostrarError('Error al cargar campañas: ${response.statusCode}');
      }
    } catch (e) {
      // Error de conexión o endpoint no existe, trabajar en modo local
      print('⚠️ No se pudo conectar al backend: $e');
      setState(() => _campanas = []);
    } finally {
      setState(() => _isLoadingCampaigns = false);
    }
  }

  /// Cargar registros de una campaña específica
  Future<void> _cargarRegistrosCampana(String campanaId) async {
    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/vaccination-records/campaign/$campanaId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        setState(() => _registros = data);
      }
    } catch (e) {
      _mostrarError('Error al cargar registros: $e');
    }
  }

  /// Crear una nueva campaña de vacunación
  Future<void> _crearCampana() async {
    if (!_formKey.currentState!.validate()) return;
    if (_vacunasSeleccionadasCampana.isEmpty) {
      _mostrarError('Selecciona al menos una vacuna para la campaña');
      return;
    }

    setState(() => _isCreatingCampaign = true);
    try {
      final response = await http
          .post(
            Uri.parse('$_apiBaseUrl/vaccination-campaigns/'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'nombre': _nombreCampanaCtrl.text.trim(),
              'descripcion': _descripcionCtrl.text.trim(),
              'vacunas': _vacunasSeleccionadasCampana, // MÚLTIPLES VACUNAS
              'fechaInicio': _fechaInicio.toIso8601String(),
              'activa': true,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        _mostrarExito('Campaña creada exitosamente');
        _nombreCampanaCtrl.clear();
        _descripcionCtrl.clear();
        setState(() => _vacunasSeleccionadasCampana = []);
        await _cargarCampanas();
      } else if (response.statusCode == 404 ||
          response.statusCode == 422 ||
          response.statusCode >= 500) {
        // Endpoint no existe, datos incompatibles o error del servidor → guardar localmente
        print('⚠️ Backend error ${response.statusCode}, usando modo local');
        final nuevaCampana = {
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'nombre': _nombreCampanaCtrl.text.trim(),
          'descripcion': _descripcionCtrl.text.trim(),
          'vacunas': _vacunasSeleccionadasCampana,
          'fechaInicio': _fechaInicio.toIso8601String(),
          'activa': true,
        };
        setState(() {
          _campanas.add(nuevaCampana);
          _campanaActivaId = nuevaCampana['id'] as String;
          _campanaActivaNombre = nuevaCampana['nombre'] as String;
        });
        _mostrarExito('Campaña creada localmente (backend no compatible)');
        _nombreCampanaCtrl.clear();
        _descripcionCtrl.clear();
        setState(() => _vacunasSeleccionadasCampana = []);
      } else {
        _mostrarError('Error al crear campaña: ${response.statusCode}');
      }
    } catch (e) {
      // Error de conexión, guardar localmente
      print('⚠️ Sin conexión, guardando campaña localmente: $e');
      final nuevaCampana = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'nombre': _nombreCampanaCtrl.text.trim(),
        'descripcion': _descripcionCtrl.text.trim(),
        'vacunas': _vacunasSeleccionadasCampana,
        'fechaInicio': _fechaInicio.toIso8601String(),
        'activa': true,
      };
      setState(() {
        _campanas.add(nuevaCampana);
        _campanaActivaId = nuevaCampana['id'] as String;
        _campanaActivaNombre = nuevaCampana['nombre'] as String;
      });
      _mostrarExito('Campaña creada localmente (sin conexión al servidor)');
      _nombreCampanaCtrl.clear();
      _descripcionCtrl.clear();
      setState(() => _vacunasSeleccionadasCampana = []);
    } finally {
      setState(() => _isCreatingCampaign = false);
    }
  }

  /// Registrar aplicación de vacunas
  /// SIEMPRE guarda en el expediente del estudiante (Cosmos DB)
  /// Además guarda localmente para la lista de la campaña
  /// Ahora soporta MÚLTIPLES vacunas en una sola visita
  Future<void> _registrarVacunacion() async {
    if (_campanaActivaId == null) {
      _mostrarError('Selecciona una campaña activa');
      return;
    }
    if (_matriculaCtrl.text.trim().isEmpty) {
      _mostrarError('Ingresa la matrícula del estudiante');
      return;
    }
    if (_vacunasSeleccionadasAplicacion.isEmpty) {
      _mostrarError('Selecciona al menos una vacuna aplicada');
      return;
    }

    setState(() => _isCreatingRecord = true);

    final matricula = _matriculaCtrl.text.trim();
    final nombreEstudiante = _nombreEstudianteCtrl.text.trim();
    final dosis = _dosisSeleccionada;
    final lote = _loteCtrl.text.trim();
    final aplicadoPor = _aplicadoPorCtrl.text.trim();
    final observaciones = _observacionesCtrl.text.trim();
    final fechaAplicacion = _fechaAplicacion.toIso8601String();

    try {
      int exitosas = 0;
      int fallos = 0;

      // 🎯 ITERAR SOBRE CADA VACUNA SELECCIONADA
      for (final vacuna in _vacunasSeleccionadasAplicacion) {
        print('💉 Guardando $vacuna para $matricula');

        // PASO 1: Intentar guardar en EXPEDIENTE del estudiante (Cosmos DB)
        final guardadoEnExpediente = await ApiService.guardarAplicacionVacuna(
          matricula: matricula,
          campana: _campanaActivaNombre ?? 'Campana',
          vacuna: vacuna,
          dosis: dosis,
          fechaAplicacion: fechaAplicacion,
          lote: lote,
          aplicadoPor: aplicadoPor,
          observaciones: observaciones,
          nombreEstudiante: nombreEstudiante,
        );

        if (guardadoEnExpediente) {
          print('✅ $vacuna guardada en expediente (Cosmos DB)');
          exitosas++;
        } else {
          print(
              '⚠️ $vacuna NO se pudo guardar en nube, guardando en SQLite...');
          fallos++;
        }

        // SIEMPRE guardar en SQLite para sincronización (si no está en nube)
        if (!guardadoEnExpediente) {
          await _db.insertVacunacionPendiente(
            DB.VacunacionesPendientesCompanion(
              matricula: drift.Value(matricula),
              nombreEstudiante: drift.Value(nombreEstudiante),
              campana: drift.Value(_campanaActivaNombre ?? 'Campana'),
              vacuna: drift.Value(vacuna),
              dosis: drift.Value(dosis),
              lote: drift.Value(lote),
              aplicadoPor: drift.Value(aplicadoPor),
              fechaAplicacion: drift.Value(fechaAplicacion),
              observaciones: drift.Value(observaciones),
              createdAt: drift.Value(DateTime.now()),
              synced: drift.Value(false),
            ),
          );
          print('💾 $vacuna guardada en SQLite para sincronización posterior');
        }

        // PASO 2: Intentar guardar en lista de campaña (opcional)
        try {
          await http
              .post(
                Uri.parse('$_apiBaseUrl/vaccination-records/'),
                headers: {'Content-Type': 'application/json'},
                body: json.encode({
                  'campanaId': _campanaActivaId!,
                  'campanaNombre': _campanaActivaNombre ?? '',
                  'matricula': matricula,
                  'nombreEstudiante': nombreEstudiante,
                  'vacuna': vacuna,
                  'dosis': dosis,
                  'lote': lote,
                  'aplicadoPor': aplicadoPor,
                  'observaciones': observaciones,
                  'fechaAplicacion': fechaAplicacion,
                }),
              )
              .timeout(const Duration(seconds: 10));
        } catch (e) {
          // Ignorar error, no es crítico
        }

        // PASO 3: Guardar LOCALMENTE para la lista visual
        final nuevoRegistro = {
          'id': '${DateTime.now().millisecondsSinceEpoch}_${vacuna.hashCode}',
          'campanaId': _campanaActivaId!,
          'campanaNombre': _campanaActivaNombre ?? '',
          'matricula': matricula,
          'nombreEstudiante': nombreEstudiante,
          'vacuna': vacuna,
          'dosis': dosis,
          'lote': lote,
          'aplicadoPor': aplicadoPor,
          'observaciones': observaciones,
          'fechaAplicacion': fechaAplicacion,
        };
        setState(() => _registros.add(nuevoRegistro));

        // Pequeño delay entre vacunas para evitar race conditions
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // 🎉 Mostrar mensaje según resultado
      final totalVacunas = _vacunasSeleccionadasAplicacion.length;
      if (exitosas == totalVacunas) {
        _mostrarExito(
            '✅ $totalVacunas vacuna(s) registradas en expediente del estudiante');
      } else if (fallos == totalVacunas) {
        _mostrarExito(
            '💾 $totalVacunas vacuna(s) guardadas localmente - se sincronizarán cuando haya conexión');
      } else {
        _mostrarExito(
            '⚠️ $exitosas en expediente, $fallos locales (se sincronizarán después)');
      }

      // Limpiar formulario
      _matriculaCtrl.clear();
      _nombreEstudianteCtrl.clear();
      _loteCtrl.clear();
      _observacionesCtrl.clear();
      setState(() {
        _dosisSeleccionada = 1;
        _vacunasSeleccionadasAplicacion = [];
      });
    } catch (e) {
      print('❌ Error al registrar vacunación: $e');
      _mostrarError('Error al registrar: $e');
    } finally {
      setState(() => _isCreatingRecord = false);
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
    );
  }

  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.green),
    );
  }

  /// Generar y descargar PDF del reporte de vacunación
  Future<void> _generarPDF() async {
    if (_campanaActivaId == null || _registros.isEmpty) {
      _mostrarError('No hay registros para generar el reporte');
      return;
    }

    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Generando PDF...'),
                ],
              ),
            ),
          ),
        ),
      );

      // Obtener datos de la campaña
      final campana = _campanas.firstWhere(
        (c) => c['id'] == _campanaActivaId,
        orElse: () => {'nombre': 'Campaña', 'vacuna': 'Vacuna'},
      );

      // Generar PDF
      final file = await VaccinationPdfGenerator.generateCampaignReport(
        campaignName: campana['nombre'] ?? 'Campaña de Vacunación',
        vaccine: campana['vacuna'] ?? 'Vacuna',
        records: _registros,
        description: campana['descripcion'],
        startDate: campana['fechaInicio'] != null
            ? DateTime.parse(campana['fechaInicio'])
            : null,
      );

      // Cerrar diálogo de carga
      Navigator.of(context).pop();

      // Mostrar diálogo de éxito con opciones
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 12),
              Text('PDF Generado'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('El reporte PDF ha sido generado exitosamente.'),
              const SizedBox(height: 12),
              Text(
                'Ubicación:\n${file.path}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
            FilledButton.icon(
              onPressed: () async {
                Navigator.of(context).pop();
                // Abrir la carpeta de descargas
                if (Platform.isWindows) {
                  final dir = file.parent.path;
                  await Process.run('explorer', [dir]);
                }
              },
              icon: const Icon(Icons.folder_open),
              label: const Text('Abrir carpeta'),
            ),
          ],
        ),
      );
    } catch (e) {
      // Cerrar diálogo de carga si está abierto
      Navigator.of(context, rootNavigator: true).pop();
      _mostrarError('Error al generar PDF: $e');
    }
  }

  Widget _buildPremiumVaccinationDashboard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 980;
        return Row(
          children: [
            if (desktop) _buildVaccinationSidebar(),
            Expanded(
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    right: 0,
                    child: _VaccineInstitutionalWaves(
                      width: desktop ? 430 : constraints.maxWidth * .68,
                    ),
                  ),
                  SafeArea(
                    child: RefreshIndicator(
                      onRefresh: _cargarCampanas,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          desktop ? 24 : 16,
                          24,
                          desktop ? 28 : 16,
                          24,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (!desktop) ...[
                              _buildMobileTopBar(),
                              const SizedBox(height: 18),
                            ],
                            _buildVaccinationHeader(desktop),
                            const SizedBox(height: 24),
                            _buildVaccinationKpis(),
                            const SizedBox(height: 16),
                            _buildInternalTabs(),
                            const SizedBox(height: 16),
                            if (_isLoadingCampaigns)
                              const Padding(
                                padding: EdgeInsets.all(36),
                                child:
                                    Center(child: CircularProgressIndicator()),
                              )
                            else if (desktop)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 9,
                                    child: _buildPremiumCreateCampaignPanel(),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    flex: 10,
                                    child: _buildPremiumCampaignsPanel(),
                                  ),
                                ],
                              )
                            else
                              Column(
                                children: [
                                  _buildPremiumCreateCampaignPanel(),
                                  const SizedBox(height: 16),
                                  _buildPremiumCampaignsPanel(),
                                ],
                              ),
                            const SizedBox(height: 16),
                            _buildVaccinationBottomPanels(desktop),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMobileTopBar() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _premiumCardDecoration(radius: 14),
      child: Row(
        children: [
          brand.maybeUAGroLogo(size: 40),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'SASU - Sistema de Vacunación',
              style: TextStyle(
                color: brand.UAGroColors.blue,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Recargar',
            onPressed: _cargarCampanas,
            color: const Color(0xFF7B1FA2),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildVaccinationSidebar() {
    final items = [
      (Icons.home_outlined, 'Inicio', false),
      (Icons.folder_shared_outlined, 'Expedientes', false),
      (Icons.search_rounded, 'Buscar carnet / notas', false),
      (Icons.badge_outlined, 'Crear Carnet', false),
      (Icons.note_add_outlined, 'Nueva Nota', false),
      (Icons.campaign_outlined, 'Promoción de Salud', false),
      (Icons.vaccines_outlined, 'Vacunación', true),
      (Icons.assessment_outlined, 'Reportes', false),
      (Icons.monitor_heart_outlined, 'Observatorio SASU', false),
      (Icons.settings_outlined, 'Configuración', false),
    ];

    return Container(
      width: 248,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF061B45), Color(0xFF082F75)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  brand.maybeUAGroLogo(size: 44),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'UNIVERSIDAD AUTÓNOMA\nDE GUERRERO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        height: 1.25,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white24),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.health_and_safety_outlined,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SASU',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'Sistema de Atención\nen Salud Universitaria',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(height: 1, color: Colors.white12),
              const SizedBox(height: 14),
              Expanded(
                child: ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _vaccinationSidebarItem(
                      icon: item.$1,
                      label: item.$2,
                      active: item.$3,
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Sistema en línea',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        CircleAvatar(
                          radius: 5,
                          backgroundColor: Color(0xFF1ED760),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Última sincronización:',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '08/06/2026 10:30 a. m.',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    const SizedBox(height: 14),
                    FutureBuilder<List<DB.VacunacionesPendiente>>(
                      future: _db.getPendingVacunaciones(),
                      builder: (context, snapshot) {
                        final pendientes = snapshot.data?.length ?? 0;
                        return Row(
                          children: [
                            const Icon(
                              Icons.cloud_sync_outlined,
                              color: Colors.white,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              pendientes == 0
                                  ? 'Sin pendientes'
                                  : '$pendientes pendiente(s)',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Text(
                        'v2.5.1',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _vaccinationSidebarItem({
    required IconData icon,
    required String label,
    required bool active,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: active ? const Color(0xFF7B1FA2) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: active
            ? Border.all(color: Colors.white.withValues(alpha: .18), width: 1)
            : null,
        boxShadow: active
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .18),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: active ? 4 : 0,
            height: 42,
            decoration: const BoxDecoration(
              color: brand.UAGroColors.red,
              borderRadius: BorderRadius.horizontal(
                right: Radius.circular(999),
              ),
            ),
          ),
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: ListTile(
                onTap: () => _handleVaccinationSidebarTap(label),
                hoverColor: Colors.white.withValues(alpha: .08),
                splashColor: Colors.white.withValues(alpha: .10),
                dense: true,
                visualDensity: VisualDensity.compact,
                leading: Icon(icon, color: Colors.white, size: 22),
                title: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleVaccinationSidebarTap(String label) {
    switch (label) {
      case 'Inicio':
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => DashboardScreen(db: _db)),
        );
        return;
      case 'Expedientes':
      case 'Buscar carnet / notas':
      case 'Nueva Nota':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => NuevaNotaScreen(db: _db)),
        );
        return;
      case 'Crear Carnet':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => FormScreen(db: _db)),
        );
        return;
      case 'Promoción de Salud':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => PromocionSaludScreen(db: _db)),
        );
        return;
      case 'Vacunación':
        return;
      case 'Reportes':
      case 'Configuración':
        _mostrarModuloEnDesarrollo();
        return;
      case 'Observatorio SASU':
        _openVaccinationObservatory();
        return;
    }
  }

  Future<void> _openVaccinationObservatory() async {
    const url = String.fromEnvironment('SASU_OBSERVATORIO_URL');
    final uri = Uri.tryParse(url);
    if (url.trim().isEmpty || uri == null) {
      _mostrarError('Observatorio SASU pendiente de vinculación');
      return;
    }
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      _mostrarError('Observatorio SASU pendiente de vinculación');
    }
  }

  void _mostrarModuloEnDesarrollo() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Módulo en desarrollo')),
    );
  }

  Widget _buildVaccinationHeader(bool desktop) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sistema de Vacunación',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: const Color(0xFF6A1B9A),
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Gestión de campañas de vacunación y control de biológicos',
                style: TextStyle(
                  color: Color(0xFF31415F),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (desktop) ...[
          FutureBuilder<List<DB.VacunacionesPendiente>>(
            future: _db.getPendingVacunaciones(),
            builder: (context, snapshot) {
              final pendientes = snapshot.data?.length ?? 0;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    tooltip: pendientes > 0
                        ? 'Sincronizar pendientes'
                        : 'Sin pendientes',
                    onPressed: pendientes > 0 ? _sincronizarPendientes : null,
                    color: const Color(0xFF6A1B9A),
                    icon: const Icon(Icons.notifications_none_rounded),
                  ),
                  if (pendientes > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: CircleAvatar(
                        radius: 6,
                        backgroundColor: brand.UAGroColors.red,
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 12),
          const CircleAvatar(
            radius: 24,
            backgroundColor: Color(0xFFF1E5FF),
            child: Text(
              'DR',
              style: TextStyle(
                color: Color(0xFF6A1B9A),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dr. Administrador',
                style: TextStyle(
                  color: brand.UAGroColors.blue,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'CRES Llano Largo',
                style: TextStyle(color: brand.UAGroColors.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildVaccinationKpis() {
    final stats = _VaccinationStats.from(_campanas, _registros);
    final kpis = [
      _VaccineKpiData(
        Icons.vaccines_outlined,
        '${stats.activeCampaigns}',
        'Campañas activas',
        'En curso actualmente',
        const Color(0xFF7B1FA2),
      ),
      _VaccineKpiData(
        Icons.groups_2_outlined,
        NumberFormat.decimalPattern().format(stats.students),
        'Estudiantes vacunados',
        'Total registrados',
        const Color(0xFF0C62C9),
      ),
      _VaccineKpiData(
        Icons.health_and_safety_outlined,
        '${stats.vaccineTypes}',
        'Tipos de vacunas',
        'Disponibles',
        const Color(0xFF1A9D4F),
      ),
      _VaccineKpiData(
        Icons.medication_liquid_outlined,
        NumberFormat.decimalPattern().format(stats.appliedDoses),
        'Dosis aplicadas',
        'Este semestre',
        const Color(0xFFE66A00),
      ),
      _VaccineKpiData(
        Icons.calendar_month_outlined,
        '${stats.upcoming}',
        'Próximas jornadas',
        'Programadas',
        const Color(0xFFD81B60),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = constraints.maxWidth >= 1060
            ? (constraints.maxWidth - 64) / 5
            : constraints.maxWidth >= 660
                ? (constraints.maxWidth - 16) / 2
                : constraints.maxWidth;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            for (final kpi in kpis)
              SizedBox(width: itemWidth, child: _vaccinationKpiCard(kpi)),
          ],
        );
      },
    );
  }

  Widget _vaccinationKpiCard(_VaccineKpiData data) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _premiumCardDecoration(radius: 12),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: .12),
              shape: BoxShape.circle,
            ),
            child: Icon(data.icon, color: data.color, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.value,
                  style: TextStyle(
                    color: data.color,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  data.title,
                  style: const TextStyle(
                    color: brand.UAGroColors.blue,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.subtitle,
                  style: const TextStyle(
                    color: brand.UAGroColors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInternalTabs() {
    final tabs = [
      (Icons.add_box_outlined, 'Crear campaña', true),
      (Icons.event_available_outlined, 'Campañas activas', false),
      (Icons.assignment_outlined, 'Historial', false),
      (Icons.inventory_2_outlined, 'Inventario', false),
      (Icons.cases_outlined, 'Coberturas', false),
      (Icons.calendar_month_outlined, 'Calendario', false),
    ];

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: _premiumCardDecoration(radius: 9),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth = constraints.maxWidth >= 920
              ? (constraints.maxWidth - 12) / 6
              : null;
          return Wrap(
            spacing: 0,
            runSpacing: 4,
            children: [
              for (final tab in tabs)
                SizedBox(
                  width: tabWidth,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: tab.$3 ? null : _mostrarModuloEnDesarrollo,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: tab.$3
                            ? const Color(0xFFF1E5FF)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: tab.$3
                            ? const Border(
                                bottom: BorderSide(
                                  color: Color(0xFF7B1FA2),
                                  width: 3,
                                ),
                              )
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            tab.$1,
                            color: tab.$3
                                ? const Color(0xFF7B1FA2)
                                : const Color(0xFF31415F),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              tab.$2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: tab.$3
                                    ? const Color(0xFF7B1FA2)
                                    : const Color(0xFF31415F),
                                fontWeight:
                                    tab.$3 ? FontWeight.w900 : FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPremiumCreateCampaignPanel() {
    return Container(
      decoration: _premiumCardDecoration(),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.campaign_outlined, color: Color(0xFF7B1FA2)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Crear nueva campaña',
                    style: TextStyle(
                      color: Color(0xFF7B1FA2),
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _nombreCampanaCtrl,
              decoration: _premiumInputDecoration(
                hintText: 'Nombre de la campaña *',
                prefixIcon: Icons.folder_rounded,
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descripcionCtrl,
              maxLines: 2,
              decoration: _premiumInputDecoration(
                hintText: 'Descripción (opcional)',
                prefixIcon: Icons.description_rounded,
              ),
            ),
            const SizedBox(height: 12),
            _buildVaccineSelectionCard(),
            const SizedBox(height: 18),
            _buildDateSelectorTile(),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(child: _clearCampaignButton()),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: _createCampaignButton()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVaccineSelectionCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD7DDEB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.vaccines_outlined,
                  color: brand.UAGroColors.blue, size: 19),
              SizedBox(width: 8),
              Text(
                'Vacunas de la campaña *',
                style: TextStyle(
                  color: brand.UAGroColors.blue,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Selecciona una o más vacunas:',
            style: TextStyle(
              color: brand.UAGroColors.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final vacuna in _vacunasDisponibles)
                _vaccineChoiceChip(vacuna),
            ],
          ),
          if (_vacunasSeleccionadasCampana.isEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Selecciona al menos una vacuna',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 14),
          const Divider(height: 1),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              '¿Agregar vacuna personalizada?',
              style: TextStyle(
                color: brand.UAGroColors.blue,
                fontWeight: FontWeight.w800,
              ),
            ),
            subtitle: const Text('Si la vacuna no está en la lista'),
            value: _mostrarCampoVacunaPersonalizada,
            activeThumbColor: const Color(0xFF7B1FA2),
            onChanged: (value) {
              setState(() => _mostrarCampoVacunaPersonalizada = value);
            },
          ),
          if (_mostrarCampoVacunaPersonalizada)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _otraVacunaCtrl,
                    decoration: _premiumInputDecoration(
                      hintText: 'Nombre de la vacuna',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _agregarVacunaPersonalizada,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF7B1FA2),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar'),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _vaccineChoiceChip(String vacuna) {
    final selected = _vacunasSeleccionadasCampana.contains(vacuna);
    return FilterChip(
      label: Text(vacuna),
      selected: selected,
      showCheckmark: false,
      selectedColor: const Color(0xFFF1E5FF),
      backgroundColor: const Color(0xFFF7F9FF),
      side: BorderSide(
        color: selected ? const Color(0xFF7B1FA2) : const Color(0xFFD7DDEB),
      ),
      labelStyle: TextStyle(
        color: selected ? const Color(0xFF7B1FA2) : brand.UAGroColors.blue,
        fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
        fontSize: 12,
      ),
      avatar: selected
          ? const Icon(Icons.check_circle, size: 17, color: Color(0xFF7B1FA2))
          : null,
      onSelected: (value) {
        setState(() {
          if (value) {
            _vacunasSeleccionadasCampana.add(vacuna);
          } else {
            _vacunasSeleccionadasCampana.remove(vacuna);
          }
        });
      },
    );
  }

  void _agregarVacunaPersonalizada() {
    final vacuna = _otraVacunaCtrl.text.trim();
    if (vacuna.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa el nombre de la vacuna'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (_vacunasSeleccionadasCampana.contains(vacuna)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Esta vacuna ya está agregada'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    setState(() {
      _vacunasSeleccionadasCampana.add(vacuna);
      _otraVacunaCtrl.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Vacuna "$vacuna" agregada'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildDateSelectorTile() {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: _pickCampaignStartDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFD7DDEB)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, color: Color(0xFF31415F)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Fecha de inicio *',
                    style: TextStyle(
                      color: brand.UAGroColors.blue,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    DateFormat('dd/MM/yyyy').format(_fechaInicio),
                    style: const TextStyle(color: Color(0xFF31415F)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.edit_outlined, color: brand.UAGroColors.blue),
          ],
        ),
      ),
    );
  }

  Future<void> _pickCampaignStartDate() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaInicio,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (fecha != null) {
      setState(() => _fechaInicio = fecha);
    }
  }

  Widget _clearCampaignButton() {
    return SizedBox(
      height: 46,
      child: OutlinedButton.icon(
        onPressed: _isCreatingCampaign ? null : _confirmAndClearCampaignForm,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFE66A00),
          side: const BorderSide(color: brand.UAGroColors.blue),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        ),
        icon: const Icon(Icons.clear_all_rounded, size: 18),
        label: const Text('Limpiar'),
      ),
    );
  }

  Widget _createCampaignButton() {
    return SizedBox(
      height: 46,
      child: FilledButton.icon(
        onPressed: _isCreatingCampaign ? null : _crearCampana,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF7B1FA2),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
        ),
        icon: _isCreatingCampaign
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.add),
        label: Text(_isCreatingCampaign ? 'Creando...' : 'Crear campaña'),
      ),
    );
  }

  Future<void> _confirmAndClearCampaignForm() async {
    if (_nombreCampanaCtrl.text.isEmpty &&
        _descripcionCtrl.text.isEmpty &&
        _vacunasSeleccionadasCampana.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El formulario ya está vacío'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange),
            SizedBox(width: 12),
            Text('¿Limpiar formulario?'),
          ],
        ),
        content: const Text(
          '¿Estás seguro de que deseas limpiar todos los campos? '
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Sí, limpiar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      setState(() {
        _nombreCampanaCtrl.clear();
        _descripcionCtrl.clear();
        _vacunasSeleccionadasCampana.clear();
        _otraVacunaCtrl.clear();
        _mostrarCampoVacunaPersonalizada = false;
        _fechaInicio = DateTime.now();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Formulario limpiado'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildPremiumCampaignsPanel() {
    return Container(
      decoration: _premiumCardDecoration(),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.list_alt_outlined, color: Color(0xFF7B1FA2)),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Campañas disponibles',
                  style: TextStyle(
                    color: Color(0xFF7B1FA2),
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ),
              SizedBox(
                width: 230,
                child: TextField(
                  enabled: false,
                  decoration: _premiumInputDecoration(
                    hintText: 'Buscar campaña...',
                    prefixIcon: Icons.search_rounded,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                label: const Text('Todos los estados'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_campanas.isEmpty)
            _emptyVaccinationCampaignCard()
          else
            ListView.separated(
              itemCount: _campanas.length > 4 ? 4 : _campanas.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) =>
                  _premiumCampaignTile(_campanas[index]),
            ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _pageButton(Icons.chevron_left),
              _pageNumber('1', true),
              _pageNumber('2', false),
              _pageButton(Icons.chevron_right),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyVaccinationCampaignCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE1E6F0)),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            backgroundColor: Color(0xFFF1E5FF),
            child: Icon(Icons.vaccines_outlined, color: Color(0xFF7B1FA2)),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              'No hay campañas registradas todavía.',
              style: TextStyle(
                color: brand.UAGroColors.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _premiumCampaignTile(dynamic raw) {
    final campana = _VaccineCampaign.from(raw);
    final selected = campana.id == _campanaActivaId;
    final color = _vaccineColor(campana.vaccine);
    return InkWell(
      borderRadius: BorderRadius.circular(13),
      onTap: () {
        setState(() {
          _campanaActivaId = campana.id;
          _campanaActivaNombre = campana.name;
        });
        _cargarRegistrosCampana(campana.id);
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFBF7FF) : Colors.white,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: selected ? const Color(0xFFD9B8FF) : const Color(0xFFE1E6F0),
          ),
          boxShadow: [
            BoxShadow(
              color: brand.UAGroColors.blue.withValues(alpha: .04),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .12),
                shape: BoxShape.circle,
              ),
              child:
                  Icon(_vaccineIcon(campana.vaccine), color: color, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    campana.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: brand.UAGroColors.blue,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    campana.vaccine,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    campana.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF4C5B74),
                      fontSize: 12,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Responsable: ${campana.responsible}',
                    style: const TextStyle(
                      color: brand.UAGroColors.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 150,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _statusPill(campana.status),
                  const SizedBox(height: 8),
                  Text(
                    campana.dateLabel,
                    style: const TextStyle(
                      color: brand.UAGroColors.blue,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Dosis aplicadas: ${campana.doses}',
                    style: const TextStyle(
                      color: Color(0xFF31415F),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _campanaActivaId = campana.id;
                  _campanaActivaNombre = campana.name;
                });
                _cargarRegistrosCampana(campana.id);
              },
              child: const Text('Ver detalle'),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded,
                  color: brand.UAGroColors.blue),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'detail', child: Text('Ver detalle')),
              ],
              onSelected: (_) {
                setState(() {
                  _campanaActivaId = campana.id;
                  _campanaActivaNombre = campana.name;
                });
                _cargarRegistrosCampana(campana.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusPill(String status) {
    final lower = status.toLowerCase();
    final color = lower.contains('program')
        ? const Color(0xFFE66A00)
        : lower.contains('final')
            ? const Color(0xFF0C62C9)
            : const Color(0xFF1A9D4F);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _pageButton(IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: IconButton.outlined(
        onPressed: null,
        icon: Icon(icon, size: 17),
        constraints: const BoxConstraints.tightFor(width: 32, height: 32),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _pageNumber(String value, bool active) {
    return Container(
      width: 32,
      height: 32,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? const Color(0xFF7B1FA2) : Colors.white,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFFD7DDEB)),
      ),
      child: Text(
        value,
        style: TextStyle(
          color: active ? Colors.white : brand.UAGroColors.blue,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildVaccinationBottomPanels(bool desktop) {
    final notes = _vaccinationNotesPanel();
    final activity = _vaccinationActivityPanel();
    if (!desktop) {
      return Column(
        children: [
          notes,
          const SizedBox(height: 14),
          activity,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: notes),
        const SizedBox(width: 16),
        Expanded(child: activity),
      ],
    );
  }

  Widget _vaccinationNotesPanel() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _premiumCardDecoration(radius: 12).copyWith(
        border: Border.all(color: const Color(0xFFD9B8FF)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFF7B1FA2), size: 20),
              SizedBox(width: 8),
              Text(
                'Notas importantes',
                style: TextStyle(
                  color: Color(0xFF7B1FA2),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
              '• Verifica que la información de la campaña sea correcta antes de guardarla.'),
          SizedBox(height: 8),
          Text(
              '• Asegúrate de contar con el biológico disponible en inventario.'),
          SizedBox(height: 8),
          Text('• Las campañas finalizadas se archivan automáticamente.'),
        ],
      ),
    );
  }

  Widget _vaccinationActivityPanel() {
    final rows = _campanas.take(4).map(_VaccineCampaign.from).toList();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _premiumCardDecoration(radius: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.event_note_outlined,
                  color: Color(0xFF7B1FA2), size: 20),
              SizedBox(width: 8),
              Text(
                'Actividad reciente',
                style: TextStyle(
                  color: Color(0xFF7B1FA2),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (rows.isEmpty)
            const Text(
              'Sin actividad reciente registrada.',
              style: TextStyle(color: brand.UAGroColors.onSurfaceVariant),
            )
          else
            for (final row in rows) ...[
              Row(
                children: [
                  const Text('• ', style: TextStyle(color: Color(0xFF7B1FA2))),
                  Expanded(child: Text('${row.name} creada')),
                  Text(
                    row.shortDate,
                    style: const TextStyle(
                      color: brand.UAGroColors.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
            ],
        ],
      ),
    );
  }

  InputDecoration _premiumInputDecoration({
    String? hintText,
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
      filled: true,
      fillColor: const Color(0xFFFAFBFF),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: Color(0xFFD7DDEB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: Color(0xFFD7DDEB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: Color(0xFF7B1FA2), width: 1.4),
      ),
    );
  }

  BoxDecoration _premiumCardDecoration({double radius = 16}) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: const Color(0xFFE3E8F2)),
      boxShadow: [
        BoxShadow(
          color: brand.UAGroColors.blue.withValues(alpha: .06),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  Color _vaccineColor(String value) {
    final lower = value.toLowerCase();
    if (lower.contains('influenza')) return const Color(0xFF7B1FA2);
    if (lower.contains('covid')) return const Color(0xFF0C62C9);
    if (lower.contains('hepatitis')) return const Color(0xFF1A9D4F);
    if (lower.contains('vph')) return const Color(0xFFE66A00);
    return const Color(0xFF008197);
  }

  IconData _vaccineIcon(String value) {
    final lower = value.toLowerCase();
    if (lower.contains('covid')) return Icons.health_and_safety_outlined;
    if (lower.contains('hepatitis')) return Icons.medication_liquid_outlined;
    if (lower.contains('vph')) return Icons.diversity_3_outlined;
    return Icons.vaccines_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return _buildPremiumVaccinationDashboard();

    // ignore: dead_code
    return Scaffold(
      backgroundColor: UAGroColors.grisClaro,
      appBar: AppBar(
        title: const Text('Sistema de Vacunación'),
        backgroundColor: Colors.purple[700],
        actions: [
          // Botón de inicio sutil
          IconButton(
            icon: const Icon(Icons.home_outlined,
                color: Colors.white70, size: 22),
            tooltip: 'Ir al inicio',
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                    builder: (context) => DashboardScreen(db: _db)),
                (route) => false,
              );
            },
          ),
          FutureBuilder<List<DB.VacunacionesPendiente>>(
            future: _db.getPendingVacunaciones(),
            builder: (context, snapshot) {
              final pendientes = snapshot.data?.length ?? 0;
              if (pendientes > 0) {
                return Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.cloud_upload),
                      onPressed: _sincronizarPendientes,
                      tooltip: 'Sincronizar pendientes',
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          '$pendientes',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarCampanas,
            tooltip: 'Recargar',
          ),
        ],
      ),
      body: _isLoadingCampaigns
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sección: Crear Campaña
                  _buildSeccionCrearCampana(),

                  const SizedBox(height: 32),

                  // Sección: Campañas Activas
                  _buildSeccionCampanasActivas(),

                  const SizedBox(height: 32),

                  // Sección: Registrar Vacunación
                  if (_campanaActivaId != null) ...[
                    _buildSeccionRegistrarVacunacion(),

                    const SizedBox(height: 32),

                    // Sección: Registros de la Campaña
                    _buildSeccionRegistros(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildSeccionCrearCampana() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.campaign, color: Colors.purple[700], size: 28),
                  const SizedBox(width: 12),
                  Text(
                    'Crear Nueva Campaña',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple[700],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: _nombreCampanaCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la Campaña',
                  hintText: 'Ej: Campaña Influenza Otoño 2025',
                  prefixIcon: Icon(Icons.label),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Requerido' : null,
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _descripcionCtrl,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                  hintText: 'Breve descripción de la campaña',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 2,
              ),

              const SizedBox(height: 16),

              // Selector de múltiples vacunas
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.vaccines, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Vacunas de la Campaña',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Selecciona una o más vacunas:',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _vacunasDisponibles.map((vacuna) {
                          final seleccionada =
                              _vacunasSeleccionadasCampana.contains(vacuna);
                          return FilterChip(
                            label: Text(vacuna),
                            selected: seleccionada,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _vacunasSeleccionadasCampana.add(vacuna);
                                } else {
                                  _vacunasSeleccionadasCampana.remove(vacuna);
                                }
                              });
                            },
                            avatar: seleccionada
                                ? const Icon(Icons.check_circle, size: 18)
                                : null,
                          );
                        }).toList(),
                      ),
                      if (_vacunasSeleccionadasCampana.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Selecciona al menos una vacuna',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      if (_vacunasSeleccionadasCampana.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '${_vacunasSeleccionadasCampana.length} vacuna(s) seleccionada(s)',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                      // Opción para agregar vacuna personalizada
                      const SizedBox(height: 16),
                      const Divider(),
                      CheckboxListTile(
                        title: const Text('¿Agregar vacuna personalizada?'),
                        subtitle:
                            const Text('Si la vacuna no está en la lista'),
                        value: _mostrarCampoVacunaPersonalizada,
                        onChanged: (value) {
                          setState(() {
                            _mostrarCampoVacunaPersonalizada = value ?? false;
                          });
                        },
                      ),

                      if (_mostrarCampoVacunaPersonalizada)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _otraVacunaCtrl,
                                      decoration: const InputDecoration(
                                        labelText: 'Nombre de la vacuna',
                                        hintText: 'Ej: Vacuna Meningocócica B',
                                        border: OutlineInputBorder(),
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      final vacuna =
                                          _otraVacunaCtrl.text.trim();
                                      if (vacuna.isEmpty) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Ingresa el nombre de la vacuna'),
                                            backgroundColor: Colors.orange,
                                          ),
                                        );
                                        return;
                                      }

                                      if (_vacunasSeleccionadasCampana
                                          .contains(vacuna)) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Esta vacuna ya está agregada'),
                                            backgroundColor: Colors.orange,
                                          ),
                                        );
                                        return;
                                      }

                                      setState(() {
                                        _vacunasSeleccionadasCampana
                                            .add(vacuna);
                                        _otraVacunaCtrl.clear();
                                      });

                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content:
                                              Text('Vacuna "$vacuna" agregada'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.add),
                                    label: const Text('Agregar'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Fecha de Inicio'),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(_fechaInicio)),
                trailing: const Icon(Icons.edit),
                onTap: () async {
                  final fecha = await showDatePicker(
                    context: context,
                    initialDate: _fechaInicio,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (fecha != null) {
                    setState(() => _fechaInicio = fecha);
                  }
                },
              ),

              const SizedBox(height: 24),

              // Botones de acción
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isCreatingCampaign
                          ? null
                          : () async {
                              // Verificar si hay datos para limpiar
                              if (_nombreCampanaCtrl.text.isEmpty &&
                                  _descripcionCtrl.text.isEmpty &&
                                  _vacunasSeleccionadasCampana.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('El formulario ya está vacío'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                return;
                              }

                              // Mostrar confirmación
                              final confirmar = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Row(
                                    children: [
                                      Icon(Icons.warning_amber,
                                          color: Colors.orange),
                                      SizedBox(width: 12),
                                      Text('¿Limpiar formulario?'),
                                    ],
                                  ),
                                  content: const Text(
                                    '¿Estás seguro de que deseas limpiar todos los campos? '
                                    'Esta acción no se puede deshacer.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: const Text('Cancelar'),
                                    ),
                                    FilledButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: Colors.orange,
                                      ),
                                      child: const Text('Sí, limpiar'),
                                    ),
                                  ],
                                ),
                              );

                              if (confirmar == true) {
                                setState(() {
                                  _nombreCampanaCtrl.clear();
                                  _descripcionCtrl.clear();
                                  _vacunasSeleccionadasCampana.clear();
                                  _otraVacunaCtrl.clear();
                                  _mostrarCampoVacunaPersonalizada = false;
                                  _fechaInicio = DateTime.now();
                                });

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('✓ Formulario limpiado'),
                                    backgroundColor: Colors.green,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                      icon: const Icon(Icons.clear_all),
                      label: const Text('Limpiar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange[700],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: _isCreatingCampaign ? null : _crearCampana,
                      icon: _isCreatingCampaign
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.add),
                      label: Text(
                          _isCreatingCampaign ? 'Creando...' : 'Crear Campaña'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.purple[700],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeccionCampanasActivas() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.list_alt, color: UAGroColors.azulMarino, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Campañas Disponibles',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: UAGroColors.azulMarino,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_campanas.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.vaccines_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No hay campañas registradas',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Crea tu primera campaña de vacunación en la sección de arriba',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._campanas.map((campana) {
                final isSelected = campana['id'] == _campanaActivaId;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: isSelected ? Colors.purple[50] : Colors.white,
                  child: ListTile(
                    leading: Icon(
                      Icons.vaccines,
                      color: isSelected ? Colors.purple[700] : Colors.grey,
                    ),
                    title: Text(
                      campana['nombre'] ?? 'Sin nombre',
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (campana['vacunas'] != null &&
                            campana['vacunas'] is List)
                          Text('${(campana['vacunas'] as List).join(', ')}')
                        else if (campana['vacuna'] != null)
                          Text('${campana['vacuna']}'),
                        Text(
                          '${campana['totalAplicadas'] ?? 0} aplicadas',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    trailing: campana['activa'] == true
                        ? Chip(
                            label: const Text('Activa',
                                style: TextStyle(fontSize: 11)),
                            backgroundColor: Colors.green[100],
                          )
                        : null,
                    onTap: () {
                      setState(() {
                        _campanaActivaId = campana['id'];
                        _campanaActivaNombre = campana['nombre'];
                      });
                      _cargarRegistrosCampana(campana['id']);
                    },
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSeccionRegistrarVacunacion() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.medical_services,
                    color: UAGroColors.rojoEscudo, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Registrar Aplicación de Vacuna',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: UAGroColors.rojoEscudo,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Text(
              'Campaña: $_campanaActivaNombre',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),

            const SizedBox(height: 20),

            TextFormField(
              controller: _matriculaCtrl,
              decoration: const InputDecoration(
                labelText: 'Matrícula del Estudiante',
                hintText: 'Ej: 202012345',
                prefixIcon: Icon(Icons.badge),
              ),
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _nombreEstudianteCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre del Estudiante (opcional)',
                prefixIcon: Icon(Icons.person),
              ),
            ),

            const SizedBox(height: 16),

            // Selector de vacunas de la campaña (MÚLTIPLE)
            if (_campanaActivaId != null)
              Builder(
                builder: (context) {
                  // Obtener vacunas de la campaña activa
                  final campanaActiva = _campanas.firstWhere(
                    (c) => c['id'] == _campanaActivaId,
                    orElse: () => {},
                  );

                  List<String> vacunasCampana = [];
                  if (campanaActiva['vacunas'] != null &&
                      campanaActiva['vacunas'] is List) {
                    vacunasCampana =
                        List<String>.from(campanaActiva['vacunas']);
                  } else if (campanaActiva['vacuna'] != null) {
                    vacunasCampana = [campanaActiva['vacuna'] as String];
                  }

                  if (vacunasCampana.isEmpty) {
                    return const Text(
                        'Esta campaña no tiene vacunas asignadas');
                  }

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.vaccines, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Vacunas Aplicadas al Estudiante',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Selecciona todas las vacunas aplicadas en esta visita:',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[700],
                                    ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: vacunasCampana.map((vacuna) {
                              final seleccionada =
                                  _vacunasSeleccionadasAplicacion
                                      .contains(vacuna);
                              return FilterChip(
                                label: Text(vacuna),
                                selected: seleccionada,
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _vacunasSeleccionadasAplicacion
                                          .add(vacuna);
                                    } else {
                                      _vacunasSeleccionadasAplicacion
                                          .remove(vacuna);
                                    }
                                  });
                                },
                                avatar: seleccionada
                                    ? const Icon(Icons.check_circle, size: 18)
                                    : null,
                                selectedColor: Colors.green[100],
                              );
                            }).toList(),
                          ),
                          if (_vacunasSeleccionadasAplicacion.isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                'Selecciona al menos una vacuna aplicada',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          if (_vacunasSeleccionadasAplicacion.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                '${_vacunasSeleccionadasAplicacion.length} vacuna(s) seleccionada(s)',
                                style: TextStyle(
                                  color: Colors.green[700],
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _dosisSeleccionada,
                    decoration: const InputDecoration(
                      labelText: 'Número de Dosis',
                      prefixIcon: Icon(Icons.numbers),
                    ),
                    items: [1, 2, 3, 4].map((dosis) {
                      return DropdownMenuItem(
                        value: dosis,
                        child: Text('Dosis $dosis'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _dosisSeleccionada = value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _loteCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Lote (opcional)',
                      prefixIcon: Icon(Icons.qr_code),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _aplicadoPorCtrl,
              decoration: const InputDecoration(
                labelText: 'Aplicado por (opcional)',
                hintText: 'Nombre del personal médico',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),

            const SizedBox(height: 16),

            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Fecha de Aplicación'),
              subtitle: Text(DateFormat('dd/MM/yyyy').format(_fechaAplicacion)),
              trailing: const Icon(Icons.edit),
              onTap: () async {
                final fecha = await showDatePicker(
                  context: context,
                  initialDate: _fechaAplicacion,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (fecha != null) {
                  setState(() => _fechaAplicacion = fecha);
                }
              },
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _observacionesCtrl,
              decoration: const InputDecoration(
                labelText: 'Observaciones (opcional)',
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 2,
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isCreatingRecord ? null : _registrarVacunacion,
                icon: _isCreatingRecord
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(_isCreatingRecord
                    ? 'Guardando...'
                    : 'Registrar Vacunación'),
                style: FilledButton.styleFrom(
                  backgroundColor: UAGroColors.rojoEscudo,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeccionRegistros() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.table_chart, color: Colors.green[700], size: 28),
                    const SizedBox(width: 12),
                    Text(
                      'Registros de Vacunación',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
                if (_registros.isNotEmpty)
                  Chip(
                    label: Text('${_registros.length} registros'),
                    backgroundColor: Colors.green[100],
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_registros.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text('No hay registros en esta campaña'),
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Matrícula')),
                    DataColumn(label: Text('Estudiante')),
                    DataColumn(label: Text('Vacuna')),
                    DataColumn(label: Text('Dosis')),
                    DataColumn(label: Text('Fecha')),
                  ],
                  rows: _registros.map((registro) {
                    return DataRow(cells: [
                      DataCell(Text(registro['matricula'] ?? '')),
                      DataCell(Text(registro['nombreEstudiante'] ?? 'N/A')),
                      DataCell(Text(registro['vacuna'] ?? '')),
                      DataCell(Text(registro['dosis']?.toString() ?? '1')),
                      DataCell(Text(
                        registro['fechaAplicacion'] != null
                            ? DateFormat('dd/MM/yyyy').format(
                                DateTime.parse(registro['fechaAplicacion']))
                            : 'N/A',
                      )),
                    ]);
                  }).toList(),
                ),
              ),
            if (_registros.isNotEmpty) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _generarPDF,
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Descargar Reporte PDF'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green[700],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _VaccineKpiData {
  final IconData icon;
  final String value;
  final String title;
  final String subtitle;
  final Color color;

  const _VaccineKpiData(
    this.icon,
    this.value,
    this.title,
    this.subtitle,
    this.color,
  );
}

class _VaccinationStats {
  final int activeCampaigns;
  final int students;
  final int vaccineTypes;
  final int appliedDoses;
  final int upcoming;

  const _VaccinationStats({
    required this.activeCampaigns,
    required this.students,
    required this.vaccineTypes,
    required this.appliedDoses,
    required this.upcoming,
  });

  factory _VaccinationStats.from(
      List<dynamic> campaigns, List<dynamic> records) {
    final active = campaigns.where((c) {
      if (c is! Map) return false;
      return c['activa'] == true || c['activa'] == null;
    }).length;

    final vaccineSet = <String>{};
    for (final c in campaigns) {
      if (c is! Map) continue;
      final vacunas = c['vacunas'];
      if (vacunas is List) {
        vaccineSet.addAll(vacunas.map((e) => e.toString()));
      } else if (c['vacuna'] != null) {
        vaccineSet.add(c['vacuna'].toString());
      }
    }

    final students = records
        .whereType<Map>()
        .map((e) => (e['matricula'] ?? '').toString().trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .length;

    final applied = records.length;
    final upcoming = campaigns.where((c) {
      if (c is! Map) return false;
      final date = DateTime.tryParse((c['fechaInicio'] ?? '').toString());
      return date != null && date.isAfter(DateTime.now());
    }).length;

    return _VaccinationStats(
      activeCampaigns: campaigns.isEmpty ? 0 : active,
      students: students,
      vaccineTypes: vaccineSet.length,
      appliedDoses: applied,
      upcoming: upcoming,
    );
  }
}

class _VaccineCampaign {
  final String id;
  final String name;
  final String vaccine;
  final String description;
  final String responsible;
  final String status;
  final String dateLabel;
  final String shortDate;
  final int doses;

  const _VaccineCampaign({
    required this.id,
    required this.name,
    required this.vaccine,
    required this.description,
    required this.responsible,
    required this.status,
    required this.dateLabel,
    required this.shortDate,
    required this.doses,
  });

  factory _VaccineCampaign.from(dynamic raw) {
    final data = raw is Map ? raw : <String, dynamic>{};

    String text(String key, String fallback) {
      final value = data[key]?.toString().trim() ?? '';
      return value.isEmpty ? fallback : value;
    }

    final vacunas = data['vacunas'];
    final vaccine = vacunas is List && vacunas.isNotEmpty
        ? vacunas.first.toString()
        : text('vacuna', 'Vacuna');
    final start = DateTime.tryParse((data['fechaInicio'] ?? '').toString());
    final date =
        start == null ? 'Sin fecha' : DateFormat('dd/MM/yyyy').format(start);
    final active = data['activa'] == true || data['activa'] == null;
    final status = text('estado', active ? 'En curso' : 'Finalizada');
    final total = int.tryParse(
            (data['totalAplicadas'] ?? data['dosis'] ?? 0).toString()) ??
        0;

    return _VaccineCampaign(
      id: text('id', DateTime.now().millisecondsSinceEpoch.toString()),
      name: text('nombre', 'Campaña de vacunación'),
      vaccine: vaccine,
      description: text('descripcion', 'Campaña universitaria de vacunación.'),
      responsible: text('responsable', 'SASU'),
      status: status,
      dateLabel: date,
      shortDate: date,
      doses: total,
    );
  }
}

class _VaccineInstitutionalWaves extends StatelessWidget {
  final double width;

  const _VaccineInstitutionalWaves({required this.width});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: width * .34,
      child: Stack(
        children: [
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: width,
              height: width * .30,
              decoration: BoxDecoration(
                color: brand.UAGroColors.blue,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(width * .42),
                ),
              ),
            ),
          ),
          Positioned(
            right: width * .05,
            top: width * .17,
            child: Container(
              width: width * .86,
              height: width * .07,
              decoration: BoxDecoration(
                color: brand.UAGroColors.red,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Positioned(
            right: width * .03,
            top: width * .04,
            child: Container(
              width: width * .68,
              height: width * .15,
              decoration: BoxDecoration(
                color: const Color(0xFF0B8FDB).withValues(alpha: .80),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(width * .32),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
