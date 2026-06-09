import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:drift/drift.dart' show Value, OrderingMode, OrderingTerm;
import 'cita_form_screen.dart';

import '../data/db.dart' as DB;
import '../data/api_service.dart';

import 'dashboard_screen.dart';
import 'form_screen.dart';
import 'promocion_salud_screen.dart';
import 'vaccination_screen.dart';
import 'package:cres_carnets_ibmcloud/ui/uagro_widgets.dart' hide SectionCard;
import 'psychology/test_selection_screen.dart';
import 'odontology/odontogram_screen.dart';

// Imports para diseño institucional UAGro
import '../ui/brand.dart';
import '../ui/app_theme.dart';
import '../ui/uagro_theme.dart' as theme;
import '../ui/widgets/brand_sidebar.dart';
import '../ui/widgets/section_card.dart';

const String kSupervisorKey = 'UAGROcres2025';

class _LocalNoteAttachment {
  final String name;
  final String path;
  final String type;

  const _LocalNoteAttachment({
    required this.name,
    required this.path,
    this.type = 'local',
  });
}

class NuevaNotaScreen extends StatefulWidget {
  final DB.AppDatabase db;
  final String? matriculaInicial;
  const NuevaNotaScreen({super.key, required this.db, this.matriculaInicial});

  @override
  State<NuevaNotaScreen> createState() => _NuevaNotaScreenState();
}

class _NuevaNotaScreenState extends State<NuevaNotaScreen>
    with WidgetsBindingObserver {
  static const String _observatoryUrl = String.fromEnvironment(
    'SASU_OBSERVATORIO_URL',
    defaultValue: '',
  );

  final _id = TextEditingController();
  final _mat = TextEditingController();
  final _depto = TextEditingController();
  final _tratante = TextEditingController();
  final _cuerpo = TextEditingController();
  final _diagnostico = TextEditingController();

  final _peso = TextEditingController();
  final _talla = TextEditingController();
  final _cintura = TextEditingController();
  final _cadera = TextEditingController();
  final _escuelaFiltro = TextEditingController();
  final _grupoFiltro = TextEditingController();
  final _psicoEscuela = TextEditingController();
  final _psicoGrupo = TextEditingController();
  final _psicoParticipantes = TextEditingController();
  final _psicoTema = TextEditingController();
  final _psicoPoblacion = TextEditingController();
  final _psicoLugar = TextEditingController();
  final _searchFocus = FocusNode();
  final _noteFocus = FocusNode();

  String? _tipoConsulta;
  String _tipoAtencionPsicologica = 'Individual';
  final List<PlatformFile> _adjuntos = [];

  bool _cargando = false;
  String? _error;
  bool _busquedaIntegradaRealizada = false;
  List<_StudentSearchResult> _studentSearchResults = const [];
  String? _studentSearchResultsTitle;
  List<_StudentSearchResult> _studentSearchResultsBase = const [];
  String? _studentSearchResultsBaseTitle;

  // Flag para detectar si volvemos del background
  bool _isInBackground = false;

  // Control de guardado para prevenir duplicados
  bool _guardandoNota = false;
  DateTime? _ultimoGuardado;

  bool _showAllCloud = false;
  bool _showAllLocal = false;
  static const int _limit = 5;

  Map<String, dynamic>? _expedienteCloud;
  List<Map<String, dynamic>> _notasCloud = const [];

  DB.HealthRecord? _expedienteLocal;
  List<DB.Note> _notasLocal = const [];

  bool _atencionIntegral = false;

  // Estado aislado para citas del cloud
  List<Map<String, dynamic>> _citasCloud = [];
  bool _cargandoCitas = false;
  String? _errorCitas;

  // ⚡ Timer para debouncing de búsqueda
  Timer? _debounceTimer;

  // Alias mínimo para compatibilidad con código legado
  // Prioriza expediente local sobre nube para consistencia con lógica existente
  DB.HealthRecord? get _carnetActual => _expedienteLocal;

  String? _deptChoice;
  final List<String> _deptOpciones = const [
    'Departamento psicopedagógico',
    'Consultorio médico',
    'Consultorio de Nutrición',
    'Consultorio de Odontología',
    'Atención estudiantil',
    'Otra',
  ];

  @override
  void initState() {
    super.initState();

    // Registrar observer para detectar cambios de lifecycle
    WidgetsBinding.instance.addObserver(this);

    // 🔥 Wake up backend en background
    _wakeUpBackend();

    if (widget.matriculaInicial != null &&
        widget.matriculaInicial!.trim().isNotEmpty) {
      _mat.text = widget.matriculaInicial!.trim();
      _buscarExpedienteIntegrado();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Detectar cuando la app vuelve al foreground
    if (state == AppLifecycleState.resumed && _isInBackground) {
      _isInBackground = false;
      // Refrescar si hay una matrícula cargada
      if (_mat.text.trim().isNotEmpty) {
        print('[REFRESH] 🔄 App volvió al foreground, refrescando notas...');
        _buscarNotasMatricula();
      }
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _isInBackground = true;
    }
  }

  /// Despierta el backend en background para reducir cold start
  Future<void> _wakeUpBackend() async {
    try {
      await ApiService.wakeUpBackend();
    } catch (e) {
      print('⚠️ Error al despertar backend: $e');
    }
  }

  void _refresh() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    // Remover observer antes de limpiar
    WidgetsBinding.instance.removeObserver(this);

    // Limpiar timer de debouncing
    _debounceTimer?.cancel();

    // Limpiar controladores
    _id.dispose();
    _mat.dispose();
    _depto.dispose();
    _tratante.dispose();
    _cuerpo.dispose();
    _diagnostico.dispose();
    _peso.dispose();
    _talla.dispose();
    _cintura.dispose();
    _cadera.dispose();
    _escuelaFiltro.dispose();
    _grupoFiltro.dispose();
    _psicoEscuela.dispose();
    _psicoGrupo.dispose();
    _psicoParticipantes.dispose();
    _psicoTema.dispose();
    _psicoPoblacion.dispose();
    _psicoLugar.dispose();
    _searchFocus.dispose();
    _noteFocus.dispose();

    super.dispose();
  }

  String _fmtDate(DateTime? dt) {
    if (dt == null) return '-';
    return DateFormat('yyyy-MM-dd HH:mm').format(dt.toLocal());
  }

  String _show(dynamic v) {
    if (v == null) return 'N/A';
    if (v is String && v.trim().isEmpty) return 'N/A';
    return '$v';
  }

  Widget _line(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text('$label: ${_show(value)}'),
    );
  }

  Widget _lineRaw(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text('$label: ${value ?? ''}'),
    );
  }

  // ================= BUSCAR CARNET Y NOTAS =================

  Future<void> _buscarCarnetId() async {
    final id = _id.text.trim();
    if (id.isEmpty) {
      setState(() {
        _expedienteCloud = null;
        _error = 'Escribe un ID (QR) para buscar el carnet.';
      });
      return;
    }
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final pac = await ApiService.getExpedienteById(id);
      if (!mounted) return;
      print('[DEBUG] Expediente recibido de la nube: $pac');
      print('[DEBUG] ID del expediente: ${pac?['id']}');
      setState(() {
        _expedienteCloud = pac;
      });

      final mFromCarnet = (pac?['matricula'] ?? '').toString().trim();
      if (_mat.text.trim().isEmpty && mFromCarnet.isNotEmpty) {
        _mat.text = mFromCarnet;
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Nube (carnet): $e');
    } finally {
      if (!mounted) return;
      setState(() => _cargando = false);
    }
  }

  // ⚡ Función de debouncing para búsqueda (evita llamadas excesivas)
  void _onMatriculaChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (value.trim().isNotEmpty) {
        _buscarNotasMatricula();
      }
    });
  }

  Future<void> _buscarExpedienteIntegrado() async {
    final searchText = _mat.text.trim();
    if (searchText.isEmpty) {
      setState(() {
        _busquedaIntegradaRealizada = true;
        _expedienteCloud = null;
        _notasCloud = const [];
        _expedienteLocal = null;
        _notasLocal = const [];
        _studentSearchResults = const [];
        _studentSearchResultsTitle = null;
        _studentSearchResultsBase = const [];
        _studentSearchResultsBaseTitle = null;
        _atencionIntegral = false;
        _error = 'Escribe una matrícula o nombre para buscar el expediente.';
      });
      return;
    }

    final esMatricula = RegExp(r'^\d+$').hasMatch(searchText);
    print('[BUSQUEDA-INTEGRADA] Parametro recibido: $searchText');
    print('[BUSQUEDA-INTEGRADA] Tipo: ${searchText.runtimeType}');
    print(
        '[BUSQUEDA-INTEGRADA] Clasificado como matricula numerica: $esMatricula');
    if (esMatricula) {
      await _cargarExpedientePorMatricula(searchText);
      return;
    }

    await _buscarEstudiantesPorNombre(searchText);
  }

  Future<void> _cargarExpedientePorMatricula(String matricula) async {
    final searchText = matricula.trim();
    _mat.text = searchText;
    print('[CARGAR-EXPEDIENTE] Parametro recibido: $searchText');
    print('[CARGAR-EXPEDIENTE] Tipo: ${searchText.runtimeType}');
    if (searchText.isEmpty) {
      setState(() {
        _busquedaIntegradaRealizada = true;
        _expedienteCloud = null;
        _notasCloud = const [];
        _expedienteLocal = null;
        _notasLocal = const [];
        _atencionIntegral = false;
        _error = 'Escribe una matrícula para buscar el expediente.';
      });
      return;
    }

    final esMatricula = RegExp(r'^\d+$').hasMatch(searchText);
    if (searchText.isEmpty && !esMatricula) {
      setState(() {
        _busquedaIntegradaRealizada = true;
        _expedienteCloud = null;
        _notasCloud = const [];
        _expedienteLocal = null;
        _notasLocal = const [];
        _atencionIntegral = false;
        _error =
            'La matrícula seleccionada no es válida para cargar expediente.';
      });
      return;
    }

    setState(() {
      _cargando = true;
      _error = null;
      _busquedaIntegradaRealizada = true;
      _studentSearchResults = const [];
      _studentSearchResultsTitle = null;
      _studentSearchResultsBase = const [];
      _studentSearchResultsBaseTitle = null;
    });

    Map<String, dynamic>? expedienteCloud;
    String? carnetError;
    try {
      expedienteCloud = await ApiService.getExpedienteByMatricula(searchText);
    } catch (e) {
      carnetError = 'Nube (carnet): $e';
    }

    await _buscarNotasMatricula(forceMatricula: true);
    if (!mounted) return;

    setState(() {
      _expedienteCloud = expedienteCloud;
      _cargando = false;
      if (carnetError != null && _error == null) {
        _error = carnetError;
      }
    });
  }

  Future<void> _buscarEstudiantesPorNombre(String nombre) async {
    final query = nombre.trim();
    if (query.isEmpty) return;

    setState(() {
      _cargando = true;
      _error = null;
      _busquedaIntegradaRealizada = true;
      _expedienteCloud = null;
      _notasCloud = const [];
      _expedienteLocal = null;
      _notasLocal = const [];
      _studentSearchResults = const [];
      _studentSearchResultsTitle = null;
      _studentSearchResultsBase = const [];
      _studentSearchResultsBaseTitle = null;
      _atencionIntegral = false;
    });

    final resultsByMatricula = <String, _StudentSearchResult>{};

    try {
      final cloudResults = await ApiService.searchExpedientesByName(query);
      for (final cloud in cloudResults) {
        final result = _StudentSearchResult.fromCloud(cloud);
        if (result.matricula.isNotEmpty) {
          resultsByMatricula[result.matricula] = result;
        }
      }
    } catch (e) {
      debugPrint('Busqueda por nombre en nube no disponible: $e');
    }

    try {
      final localRecords = await _buscarRegistrosLocalesPorNombre(query);
      for (final record in localRecords) {
        if (!resultsByMatricula.containsKey(record.matricula)) {
          resultsByMatricula[record.matricula] =
              _StudentSearchResult.fromLocal(record);
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = 'Local (nombre): $e';
      });
      return;
    }

    if (!mounted) return;

    final results = resultsByMatricula.values.toList();

    if (results.isEmpty) {
      setState(() {
        _cargando = false;
        _error =
            'No se encontraron estudiantes con el nombre "$query" en nube SASU Azure ni en caché local.';
      });
      return;
    }

    setState(() {
      _cargando = false;
      final title = 'Coincidencias por nombre: ${results.length}';
      _studentSearchResults = results;
      _studentSearchResultsTitle = title;
      _studentSearchResultsBase = results;
      _studentSearchResultsBaseTitle = title;
    });
  }

  Future<List<DB.HealthRecord>> _buscarRegistrosLocalesPorNombre(
      String nombre) async {
    final normalizedQuery = _normalizeLookup(nombre);
    final qExp = widget.db.select(widget.db.healthRecords)
      ..orderBy([
        (t) => OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc),
      ]);
    final records = await qExp.get();
    return records
        .where((record) =>
            _normalizeLookup(record.nombreCompleto).contains(normalizedQuery))
        .toList();
  }

  Future<void> _filtrarEstudiantesPorEscuelaGrupo() async {
    final escuela = _escuelaFiltro.text.trim();
    final grupo = _grupoFiltro.text.trim();

    if (escuela.isEmpty && grupo.isEmpty) {
      setState(() {
        _busquedaIntegradaRealizada = true;
        _studentSearchResults = const [];
        _studentSearchResultsTitle = null;
        _error = 'Captura escuela/unidad académica o grupo para filtrar.';
      });
      return;
    }

    setState(() {
      _cargando = true;
      _error = null;
      _busquedaIntegradaRealizada = true;
      _expedienteCloud = null;
      _notasCloud = const [];
      _expedienteLocal = null;
      _notasLocal = const [];
      _atencionIntegral = false;
    });

    try {
      final normalizedEscuela = _normalizeLookup(escuela);
      final normalizedGrupo = _normalizeLookup(grupo);
      var baseResults = _studentSearchResultsBase;
      var baseTitle = _studentSearchResultsBaseTitle;

      if (baseResults.isEmpty && _studentSearchResults.isNotEmpty) {
        baseResults = _studentSearchResults;
        baseTitle = _studentSearchResultsTitle;
      }

      if (baseResults.isEmpty) {
        final qExp = widget.db.select(widget.db.healthRecords)
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc),
          ]);
        final records = await qExp.get();
        baseResults = records.map(_StudentSearchResult.fromLocal).toList();
        baseTitle = 'Estudiantes locales: ${baseResults.length}';
      }

      final results = baseResults
          .where((result) => _matchesAcademicFilters(
                result,
                normalizedEscuela,
                normalizedGrupo,
              ))
          .toList();

      if (!mounted) return;

      if (results.isEmpty) {
        setState(() {
          _cargando = false;
          _studentSearchResultsBase = baseResults;
          _studentSearchResultsBaseTitle = baseTitle;
          _studentSearchResults = const [];
          _studentSearchResultsTitle = 'Estudiantes por escuela/grupo: 0';
          _error = 'No se encontraron estudiantes para los filtros indicados.';
        });
        return;
      }

      setState(() {
        _cargando = false;
        _studentSearchResultsBase = baseResults;
        _studentSearchResultsBaseTitle = baseTitle;
        _studentSearchResults = results;
        _studentSearchResultsTitle =
            'Estudiantes por escuela/grupo: ${results.length}';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = 'Local (escuela/grupo): $e';
      });
    }
  }

  Future<void> _onStudentResultSelected(_StudentSearchResult result) async {
    await _cargarExpedientePorMatricula(result.matricula);
  }

  String _normalizeLookup(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll('\u00e1', 'a')
        .replaceAll('\u00e9', 'e')
        .replaceAll('\u00ed', 'i')
        .replaceAll('\u00f3', 'o')
        .replaceAll('\u00fa', 'u')
        .replaceAll('\u00fc', 'u')
        .replaceAll('\u00f1', 'n');
  }

  bool _matchesAcademicFilters(
    _StudentSearchResult result,
    String normalizedEscuela,
    String normalizedGrupo,
  ) {
    final school = _normalizeLookup(result.escuelaUnidadAcademica);
    final group = _normalizeLookup(result.grupo);
    final matchesSchool =
        normalizedEscuela.isEmpty || school.contains(normalizedEscuela);
    final matchesGroup =
        normalizedGrupo.isEmpty || group.contains(normalizedGrupo);
    return matchesSchool && matchesGroup;
  }

  Future<void> _buscarNotasMatricula({bool forceMatricula = false}) async {
    final searchText = _mat.text.trim();
    if (searchText.isEmpty) {
      setState(() {
        _notasCloud = const [];
        _expedienteLocal = null;
        _notasLocal = const [];
        _atencionIntegral = false;
        _error = 'Escribe una matrícula o nombre para buscar.';
      });
      return;
    }

    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      // Detectar si es búsqueda por matrícula (numérico) o nombre (texto)
      final esMatricula =
          forceMatricula || RegExp(r'^\d+$').hasMatch(searchText);

      // 🚀 OPTIMIZACIÓN: Ejecutar llamadas en paralelo con Future.wait
      final results = await Future.wait([
        // Llamada a la API (nube) - solo para matrícula
        (() async {
          if (esMatricula) {
            return ApiService.getNotasForMatricula(searchText).catchError((e) {
              _error = 'Nube (notas): $e';
              return <Map<String, dynamic>>[];
            });
          } else {
            // Búsqueda por nombre: solo local (nube requiere matrícula)
            return <Map<String, dynamic>>[];
          }
        })(),
        // Query expediente local - buscar por matrícula o nombre
        (() async {
          if (esMatricula) {
            final qExp = widget.db.select(widget.db.healthRecords)
              ..where((t) => t.matricula.equals(searchText))
              ..orderBy([
                (t) => OrderingTerm(
                    expression: t.timestamp, mode: OrderingMode.desc),
              ])
              ..limit(1);
            final expList = await qExp.get();
            return expList.isNotEmpty ? expList.first : null;
          } else {
            // Buscar por nombre - obtener todos y filtrar en memoria
            final qExp = widget.db.select(widget.db.healthRecords)
              ..orderBy([
                (t) => OrderingTerm(
                    expression: t.timestamp, mode: OrderingMode.desc),
              ]);
            final allExp = await qExp.get();
            final searchLower = searchText.toLowerCase();
            final matched = allExp
                .where((exp) =>
                    exp.nombreCompleto.toLowerCase().contains(searchLower))
                .toList();
            return matched.isNotEmpty ? matched.first : null;
          }
        })(),
        // Query notas locales - buscar por matrícula del expediente encontrado
        (() async {
          if (esMatricula) {
            final qNotas = widget.db.select(widget.db.notes)
              ..where((t) => t.matricula.equals(searchText))
              ..orderBy([
                (t) => OrderingTerm(
                    expression: t.createdAt, mode: OrderingMode.desc),
              ]);
            return await qNotas.get();
          } else {
            // Primero buscar expediente por nombre - obtener todos y filtrar
            final qExp = widget.db.select(widget.db.healthRecords).get();
            final allExp = await qExp;
            final searchLower = searchText.toLowerCase();
            final matched = allExp
                .where((exp) =>
                    exp.nombreCompleto.toLowerCase().contains(searchLower))
                .toList();

            if (matched.isEmpty) return <DB.Note>[];

            final matricula = matched.first.matricula;
            final qNotas = widget.db.select(widget.db.notes)
              ..where((t) => t.matricula.equals(matricula))
              ..orderBy([
                (t) => OrderingTerm(
                    expression: t.createdAt, mode: OrderingMode.desc),
              ]);
            return await qNotas.get();
          }
        })(),
      ]);

      final notasNube = results[0] as List<Map<String, dynamic>>;
      final expLocal = results[1] as DB.HealthRecord?;
      final notasLocal = results[2] as List<DB.Note>;

      // Calcular atención integral
      final servicios = <String>{};
      for (final n in notasNube) {
        final d = (n['departamento'] ?? '').toString().trim();
        if (d.isNotEmpty) servicios.add(d);
      }
      for (final n in notasLocal) {
        final d = n.departamento.trim();
        if (d.isNotEmpty) servicios.add(d);
      }
      final integral = servicios.length >= 2;

      // 🎯 OPTIMIZACIÓN: Una sola llamada a setState con todos los datos
      if (!mounted) return;
      setState(() {
        _notasCloud = notasNube;
        _expedienteLocal = expLocal;
        _notasLocal = notasLocal;
        _atencionIntegral = integral;
        _cargando = false;

        // Mensaje informativo para búsqueda por nombre
        if (!esMatricula && expLocal != null) {
          _error =
              'ℹ️ Búsqueda local: "${expLocal.nombreCompleto}". Para ver datos de nube, busca por matrícula: ${expLocal.matricula}';
        } else if (!esMatricula && expLocal == null) {
          _error =
              'No se encontró ningún expediente local con ese nombre. Para buscar en nube, usa la matrícula.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _cargando = false;
      });
    }
  }

  // ================== ADJUNTOS Y CAMPOS NUTRICIÓN ==================

  Future<void> _pickAdjuntos() async {
    try {
      final res = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );
      if (res == null) return;
      setState(() {
        _adjuntos.addAll(res.files);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudieron seleccionar archivos: $e')),
      );
    }
  }

  Future<List<String>> _guardarAdjuntosLocal(String matricula) async {
    final List<String> rutas = [];
    if (_adjuntos.isEmpty) return rutas;

    try {
      final baseDir = await getApplicationSupportDirectory();
      final dir = Directory(p.join(baseDir.path, 'adjuntos', matricula));
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      for (final f in _adjuntos) {
        try {
          if (f.path == null) continue;
          final safeName = f.name.replaceAll(RegExp(r'[/\\:*?"<>|]'), '_');
          final dstName = '${DateTime.now().microsecondsSinceEpoch}_$safeName';
          final dst = File(p.join(dir.path, dstName));
          await File(f.path!).copy(dst.path);
          rutas.add(dst.path);
        } catch (e) {
          print('No se pudo copiar adjunto ${f.name}: $e');
        }
      }
    } catch (e) {
      print('Error creando carpeta de adjuntos: $e');
      return [];
    }
    return rutas;
  }

  /// Obtener matrícula: primero del carnet, luego del input, si no hay ninguna retorna null
  String? _obtenerMatricula() {
    // Preferir carnet cargado
    if (_carnetActual != null) {
      return _carnetActual!.matricula;
    }
    // Si no hay carnet, usar texto del input
    final textoMatricula = _mat.text.trim();
    if (textoMatricula.isNotEmpty) {
      return textoMatricula;
    }
    return null;
  }

  /// Navegar a pantalla de agendar cita
  Future<void> _agendarCita() async {
    final matricula = _obtenerMatricula();
    if (matricula == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Busca un carnet primero para agendar una cita.')),
      );
      return;
    }

    // Navegar al formulario de citas
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CitaFormScreen(matricula: matricula, db: widget.db),
      ),
    );

    // Si se guardó una cita, mostrar confirmación
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cita agendada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  /// Obtener matrícula desde controlador o carnet cargado
  String _currentMatricula() {
    // 1. Controlador del campo de matrícula de búsqueda/notas
    final matField = _mat.text.trim();
    if (matField.isNotEmpty) return matField;

    // 2. Matrícula del carnet cargado (local preferido)
    if (_carnetActual != null) {
      final carnetMat = _carnetActual!.matricula.trim();
      if (carnetMat.isNotEmpty) return carnetMat;
    }

    // 3. Matrícula del expediente cloud
    if (_expedienteCloud != null) {
      final cloudMat = (_expedienteCloud!['matricula'] ?? '').toString().trim();
      if (cloudMat.isNotEmpty) return cloudMat;
    }

    return '';
  }

  /// Mostrar citas del cloud para la matrícula actual
  Future<void> _mostrarCitas() async {
    final m = _currentMatricula();
    if (m.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa matrícula para buscar citas')),
      );
      return;
    }

    await _mostrarCitasImpl(m);
  }

  /// Implementación de mostrar citas con matrícula específica
  Future<void> _mostrarCitasImpl(String m) async {
    setState(() {
      _cargandoCitas = true;
      _errorCitas = null;
    });

    try {
      final list = await ApiService.getCitasByMatricula(m);
      print('[CITAS_FETCH] m=$m len=${list.length}');

      setState(() {
        _citasCloud = list;
        _cargandoCitas = false;
      });
    } catch (e) {
      setState(() {
        _errorCitas = 'Error: $e';
        _cargandoCitas = false;
      });
    }
  }

  double? get _pesoVal {
    final v = double.tryParse(_peso.text.replaceAll(',', '.'));
    if (v == null || v <= 0) return null;
    return v;
  }

  double? get _tallaVal {
    final v = double.tryParse(_talla.text.replaceAll(',', '.'));
    if (v == null || v <= 0) return null;
    return v;
  }

  double? get _imcVal {
    final p = _pesoVal, t = _tallaVal;
    if (p == null || t == null || t == 0) return null;
    return p / (t * t);
  }

  double? get _cinturaVal {
    final v = double.tryParse(_cintura.text.replaceAll(',', '.'));
    if (v == null || v <= 0) return null;
    return v;
  }

  double? get _caderaVal {
    final v = double.tryParse(_cadera.text.replaceAll(',', '.'));
    if (v == null || v <= 0) return null;
    return v;
  }

  double? get _iccVal {
    final c = _cinturaVal, ca = _caderaVal;
    if (c == null || ca == null || ca == 0) return null;
    return c / ca;
  }

  String _activeDepartmentText() {
    return (_deptChoice == 'Otra' ? _depto.text.trim() : (_deptChoice ?? ''))
        .trim();
  }

  bool _isPsychologyDepartment(String departamento) {
    final normalized = _normalizeLookup(departamento);
    return normalized.contains('psico') ||
        normalized.contains('psicopedag') ||
        normalized.contains('psych');
  }

  bool get _isPsychologyAttention =>
      _isPsychologyDepartment(_activeDepartmentText());

  String _cleanKeyPart(String value, {String fallback = 'GENERAL'}) {
    final clean = _normalizeLookup(value)
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    return clean.isEmpty ? fallback : clean;
  }

  String _psychologyOperationalMatricula(DateTime now) {
    if (!_isPsychologyAttention || _tipoAtencionPsicologica == 'Individual') {
      return _mat.text.trim();
    }

    if (_tipoAtencionPsicologica == 'Grupal') {
      final escuela = _cleanKeyPart(_psicoEscuela.text);
      final grupo = _cleanKeyPart(_psicoGrupo.text);
      return 'PSICO-GRUPAL_${escuela}_$grupo';
    }

    final fecha = DateFormat('yyyyMMddHHmmss').format(now);
    final tema = _cleanKeyPart(_psicoTema.text, fallback: 'ACTIVIDAD');
    return 'PSICO-COLECTIVA_${tema}_$fecha';
  }

  void _appendPsychologyMetadata(StringBuffer buffer) {
    if (!_isPsychologyAttention) return;

    buffer.writeln('Tipo de atencion psicologica: $_tipoAtencionPsicologica');

    if (_tipoAtencionPsicologica == 'Grupal') {
      buffer.writeln('Escuela/Unidad Academica: ${_psicoEscuela.text.trim()}');
      buffer.writeln('Grupo: ${_psicoGrupo.text.trim()}');
      buffer.writeln(
          'Participantes aproximados: ${_psicoParticipantes.text.trim()}');
      buffer.writeln('Tema: ${_psicoTema.text.trim()}');
    } else if (_tipoAtencionPsicologica == 'Colectiva') {
      buffer.writeln('Poblacion atendida: ${_psicoPoblacion.text.trim()}');
      buffer.writeln(
          'Participantes aproximados: ${_psicoParticipantes.text.trim()}');
      buffer.writeln('Tema: ${_psicoTema.text.trim()}');
      final lugar = _psicoLugar.text.trim();
      if (lugar.isNotEmpty) {
        buffer.writeln('Lugar/contexto: $lugar');
      }
    }

    buffer.writeln();
  }

  // ================ GUARDAR NOTA (FASTAPI) ================

  Future<void> _guardarNota() async {
    // ========== PROTECCIÓN CONTRA GUARDADOS DUPLICADOS ==========
    // Prevenir múltiples clics mientras se está guardando
    if (_guardandoNota) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⏳ Ya se está guardando la nota, espera...'),
            duration: Duration(seconds: 1),
          ),
        );
      }
      return;
    }

    // Prevenir guardados muy seguidos (menos de 2 segundos)
    if (_ultimoGuardado != null) {
      final diferencia = DateTime.now().difference(_ultimoGuardado!);
      if (diferencia.inSeconds < 2) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Espera un momento antes de guardar otra nota'),
              duration: Duration(seconds: 1),
            ),
          );
        }
        return;
      }
    }

    // ========== VALIDACIÓN DE CAMPOS OBLIGATORIOS ==========
    final dep =
        (_deptChoice == 'Otra' ? _depto.text.trim() : (_deptChoice ?? ''))
            .trim();
    final now = DateTime.now();
    final isPsychology = _isPsychologyDepartment(dep);
    final isPsychologyIndividual =
        !isPsychology || _tipoAtencionPsicologica == 'Individual';
    final m = isPsychologyIndividual
        ? _mat.text.trim()
        : _psychologyOperationalMatricula(now);
    final t = _tratante.text.trim();
    final dx = _diagnostico.text.trim();
    final tc = _tipoConsulta?.trim() ?? '';
    final c = _cuerpo.text.trim();

    final missing = <String>[];
    if (m.isEmpty) missing.add('Matrícula');
    if (dep.isEmpty) missing.add('Departamento / área');
    if (t.isEmpty) missing.add('Tratante');
    final requiereDx = isPsychologyIndividual &&
        !(dep == 'Atención estudiantil' || _deptChoice == 'Otra');
    if (requiereDx && dx.isEmpty) missing.add('Diagnóstico');
    if (tc.isEmpty) missing.add('Consulta (Primera/Subsecuente)');
    if (isPsychology && _tipoAtencionPsicologica == 'Grupal') {
      if (_psicoEscuela.text.trim().isEmpty) {
        missing.add('Escuela / Unidad Academica');
      }
      if (_psicoGrupo.text.trim().isEmpty) missing.add('Grupo');
      if (_psicoParticipantes.text.trim().isEmpty) {
        missing.add('Participantes aproximados');
      }
      if (_psicoTema.text.trim().isEmpty) missing.add('Tema de la sesion');
    }
    if (isPsychology && _tipoAtencionPsicologica == 'Colectiva') {
      if (_psicoPoblacion.text.trim().isEmpty) {
        missing.add('Poblacion atendida');
      }
      if (_psicoParticipantes.text.trim().isEmpty) {
        missing.add('Participantes aproximados');
      }
      if (_psicoTema.text.trim().isEmpty) missing.add('Tema de la actividad');
    }
    if (c.isEmpty) missing.add('Cuerpo de la nota');

    if (missing.isNotEmpty) {
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Completa los campos obligatorios'),
          content: Text('Faltan: ${missing.join(', ')}'),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK')),
          ],
        ),
      );
      return;
    }

    if (!isPsychologyIndividual) {
      _mat.text = m;
    }

    // ========== INICIAR GUARDADO ==========
    setState(() => _guardandoNota = true);

    // Mostrar indicador de progreso inmediatamente
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text('💾 Guardando nota...'),
            ],
          ),
          duration:
              Duration(seconds: 30), // Duración larga, se cerrará manualmente
        ),
      );
    }

    try {
      // ========== PASO 1: GUARDAR ADJUNTOS ==========
      final rutasAdj = await _guardarAdjuntosLocal(m);

      // ========== PASO 2: CONSTRUIR CUERPO DE LA NOTA ==========
      final buffer = StringBuffer();
      if (requiereDx) buffer.writeln('Diagnóstico: $dx');
      buffer.writeln('Consulta: $tc');
      _appendPsychologyMetadata(buffer);

      if (dep == 'Consultorio de Nutrición') {
        final imcStr = _imcVal == null ? 'N/A' : _imcVal!.toStringAsFixed(2);
        final iccStr = _iccVal == null ? 'N/A' : _iccVal!.toStringAsFixed(2);
        buffer.writeln('NUTRICIÓN:');
        buffer.writeln(
            '• Peso (kg): ${_peso.text.trim().isEmpty ? 'N/A' : _peso.text.trim()}');
        buffer.writeln(
            '• Talla (m): ${_talla.text.trim().isEmpty ? 'N/A' : _talla.text.trim()}');
        buffer.writeln('• IMC: $imcStr');
        buffer.writeln(
            '• Cintura (cm): ${_cintura.text.trim().isEmpty ? 'N/A' : _cintura.text.trim()}');
        buffer.writeln(
            '• Cadera (cm): ${_cadera.text.trim().isEmpty ? 'N/A' : _cadera.text.trim()}');
        buffer.writeln('• Índice Cintura/Cadera: $iccStr');
      }

      buffer.writeln();
      buffer.writeln(c);

      if (rutasAdj.isNotEmpty) {
        buffer.writeln('\nAdjuntos locales:');
        for (final r in rutasAdj) {
          buffer.writeln('* nombre: ${p.basename(r)}');
          buffer.writeln('  ruta: $r');
          buffer.writeln('  tipo: local');
        }
      }
      final cuerpoFinal = buffer.toString();

      // ========== PASO 3: GUARDAR EN BASE DE DATOS LOCAL ==========
      final comp = DB.NotesCompanion.insert(
        matricula: m,
        departamento: dep.isEmpty ? 'Nota' : dep,
        cuerpo: cuerpoFinal,
        tratante: Value(t),
        createdAt: Value(DateTime.now()),
        synced: const Value(false),
      );

      final rowId = await widget.db.insertNote(comp);
      print(
          '✅ [GUARDADO LOCAL] Nota insertada rowId=$rowId para matrícula=$m depto=$dep');

      // ========== PASO 4: INTENTAR SUBIR A LA NUBE ==========
      bool subioNube = false;
      String? errorNube;

      try {
        final ok = await ApiService.pushSingleNote(
          matricula: m,
          departamento: dep,
          cuerpo: cuerpoFinal,
          tratante: t,
        );
        subioNube = ok;

        if (ok) {
          // Marcar como sincronizado si fue exitoso
          await widget.db.markNoteAsSynced(rowId);
          print(
              '✅ [SINCRONIZACIÓN] Nota $rowId subida y marcada como sincronizada');
        } else {
          print(
              '⚠️ [SINCRONIZACIÓN] Nota $rowId guardada local, respuesta false de la nube');
        }
      } catch (e) {
        errorNube = e.toString();
        print('❌ [SINCRONIZACIÓN] Error al sincronizar nota $rowId: $e');
      }

      // ========== PASO 5: CERRAR INDICADOR Y MOSTRAR RESULTADO ==========
      if (!mounted) return;

      // Cerrar el SnackBar de "Guardando..."
      ScaffoldMessenger.of(context).clearSnackBars();

      // Mostrar resultado con emoji y color según el estado
      final SnackBar resultSnackBar;
      if (subioNube) {
        resultSnackBar = SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  '✅ Nota guardada localmente y sincronizada con la nube',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade700,
          duration: const Duration(seconds: 3),
        );
      } else {
        resultSnackBar = SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.cloud_off, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '💾 Nota guardada localmente',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                errorNube != null
                    ? '⚠️ Error al subir: ${errorNube.length > 50 ? '${errorNube.substring(0, 50)}...' : errorNube}'
                    : '⚠️ Se sincronizará automáticamente cuando haya conexión',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          backgroundColor: Colors.orange.shade700,
          duration: const Duration(seconds: 4),
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(resultSnackBar);

      // ========== PASO 6: LIMPIAR FORMULARIO ==========
      if (_deptChoice == 'Otra') _depto.clear();
      _tratante.clear();
      _cuerpo.clear();
      _diagnostico.clear();
      _tipoConsulta = null;
      _adjuntos.clear();

      _peso.clear();
      _talla.clear();
      _cintura.clear();
      _cadera.clear();

      _tipoAtencionPsicologica = 'Individual';
      _psicoEscuela.clear();
      _psicoGrupo.clear();
      _psicoParticipantes.clear();
      _psicoTema.clear();
      _psicoPoblacion.clear();
      _psicoLugar.clear();

      // Registrar tiempo del último guardado
      _ultimoGuardado = DateTime.now();

      // ========== PASO 7: ACTUALIZAR UI ==========
      setState(() {});
      await _buscarNotasMatricula(forceMatricula: !isPsychologyIndividual);
    } catch (e, st) {
      print('❌ [ERROR CRÍTICO] Error al guardar nota: $e\n$st');

      if (!mounted) return;

      // Cerrar indicador de progreso
      ScaffoldMessenger.of(context).clearSnackBars();

      // Mostrar error detallado
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.error, color: Colors.white),
                  SizedBox(width: 12),
                  Text(
                    '❌ Error al guardar nota',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                e.toString().length > 100
                    ? '${e.toString().substring(0, 100)}...'
                    : e.toString(),
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Detalles',
            textColor: Colors.white,
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Error detallado'),
                  content: SingleChildScrollView(
                    child: Text('$e\n\nStack trace:\n$st'),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cerrar'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    } finally {
      // ========== SIEMPRE LIBERAR EL FLAG DE GUARDADO ==========
      if (mounted) {
        setState(() => _guardandoNota = false);
      }
    }
  }

  // =============== SINCRONIZACIÓN DE NOTAS PENDIENTES =================

  Future<void> _sincronizarNotasPendientes() async {
    try {
      setState(() => _cargando = true);

      // Mostrar indicador de progreso inmediato
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 12),
                Text('🔄 Verificando notas pendientes...'),
              ],
            ),
            duration: Duration(seconds: 30),
          ),
        );
      }

      final pendingNotes = await widget.db.getPendingNotes();

      if (pendingNotes.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('✅ No hay notas pendientes de sincronizar'),
                ],
              ),
              backgroundColor: Colors.green.shade700,
              duration: const Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      // Actualizar mensaje con cantidad encontrada
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Text('🔄 Sincronizando ${pendingNotes.length} notas...'),
              ],
            ),
            duration: const Duration(seconds: 30),
          ),
        );
      }

      int sincronizadas = 0;
      int errores = 0;
      final List<String> erroresDetalle = [];

      for (final nota in pendingNotes) {
        try {
          final ok = await ApiService.pushSingleNote(
            matricula: nota.matricula,
            departamento: nota.departamento,
            cuerpo: nota.cuerpo,
            tratante: nota.tratante ?? '',
            idOverride: 'nota_local_${nota.id}',
          );

          if (ok) {
            await widget.db.markNoteAsSynced(nota.id);
            sincronizadas++;
            print('✅ [SYNC] Nota ${nota.id} sincronizada exitosamente');
          } else {
            errores++;
            erroresDetalle.add('Nota ${nota.id}: Respuesta negativa');
            print(
                '⚠️ [SYNC] Error al sincronizar nota ${nota.id}: respuesta false');
          }
        } catch (e) {
          errores++;
          erroresDetalle.add('Nota ${nota.id}: $e');
          print('❌ [SYNC] Error sincronizando nota ${nota.id}: $e');
        }
      }

      if (mounted) {
        // Cerrar indicador de progreso
        ScaffoldMessenger.of(context).clearSnackBars();

        // Mostrar resultado detallado
        if (errores == 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '✅ $sincronizadas ${sincronizadas == 1 ? 'nota sincronizada' : 'notas sincronizadas'} correctamente',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green.shade700,
              duration: const Duration(seconds: 3),
            ),
          );
        } else if (sincronizadas > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '⚠️ Sincronización parcial: $sincronizadas OK, $errores errores',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  if (erroresDetalle.isNotEmpty &&
                      erroresDetalle.length <= 3) ...[
                    const SizedBox(height: 4),
                    ...erroresDetalle.take(3).map((e) => Text(
                          '• ${e.length > 60 ? '${e.substring(0, 60)}...' : e}',
                          style: const TextStyle(fontSize: 11),
                        )),
                  ],
                ],
              ),
              backgroundColor: Colors.orange.shade700,
              duration: const Duration(seconds: 5),
              action: erroresDetalle.length > 3
                  ? SnackBarAction(
                      label: 'Ver todos',
                      textColor: Colors.white,
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: Text('Errores de sincronización ($errores)'),
                            content: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: erroresDetalle
                                    .map((e) => Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 8),
                                          child: Text('• $e',
                                              style: const TextStyle(
                                                  fontSize: 12)),
                                        ))
                                    .toList(),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Cerrar'),
                              ),
                            ],
                          ),
                        );
                      },
                    )
                  : null,
            ),
          );
        } else {
          // Solo errores
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.error, color: Colors.white),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '❌ Error: No se pudo sincronizar ninguna nota',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Verifica tu conexión a internet y el token de autenticación',
                    style: TextStyle(fontSize: 11),
                  ),
                ],
              ),
              backgroundColor: Colors.red.shade700,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Detalles',
                textColor: Colors.white,
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Errores de sincronización'),
                      content: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: erroresDetalle
                              .map((e) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Text('• $e',
                                        style: const TextStyle(fontSize: 12)),
                                  ))
                              .toList(),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cerrar'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        }

        await _buscarNotasMatricula(); // Refrescar la vista
      }
    } catch (e, st) {
      print('❌ [ERROR CRÍTICO] Error al sincronizar notas pendientes: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.error, color: Colors.white),
                    SizedBox(width: 12),
                    Text(
                      '❌ Error al sincronizar',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  e.toString().length > 80
                      ? '${e.toString().substring(0, 80)}...'
                      : e.toString(),
                  style: const TextStyle(fontSize: 11),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  // =============== AUTORIZACIÓN SUPERVISOR =================

  Future<bool> _askSupervisorPass() async {
    final ctrl = TextEditingController();
    bool ok = false;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Autorización de supervisor'),
        content: TextField(
          controller: ctrl,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Clave',
            helperText: 'Ingrese la clave de supervisor para editar',
          ),
          onSubmitted: (_) => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              if (ctrl.text.trim() == kSupervisorKey) {
                ok = true;
              }
              Navigator.of(context).pop();
            },
            child: const Text('Validar'),
          ),
        ],
      ),
    );
    return ok;
  }

  // ================== EDITAR NOTA LOCAL ===================

  Future<void> _editLocalNote(DB.Note n) async {
    final allowed = await _askSupervisorPass();
    if (!allowed) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Clave incorrecta o cancelado.')),
      );
      return;
    }

    final depCtrl = TextEditingController(text: n.departamento);
    final tratCtrl = TextEditingController(text: n.tratante ?? '');
    final cuerpoCtrl = TextEditingController(text: n.cuerpo);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Editar nota (LOCAL)',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
                controller: depCtrl,
                decoration: const InputDecoration(labelText: 'Departamento')),
            const SizedBox(height: 8),
            TextField(
                controller: tratCtrl,
                decoration: const InputDecoration(labelText: 'Tratante')),
            const SizedBox(height: 8),
            TextField(
                controller: cuerpoCtrl,
                minLines: 6,
                maxLines: 12,
                decoration: const InputDecoration(labelText: 'Cuerpo')),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Cancelar'))),
                const SizedBox(width: 12),
                Expanded(
                    child: FilledButton(
                  onPressed: () async {
                    await (widget.db.update(widget.db.notes)
                          ..where((t) => t.id.equals(n.id)))
                        .write(DB.NotesCompanion(
                      departamento: Value(depCtrl.text.trim()),
                      tratante: Value(tratCtrl.text.trim()),
                      cuerpo: Value(cuerpoCtrl.text),
                    ));
                    if (mounted) Navigator.of(ctx).pop();
                    await _buscarNotasMatricula();
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Nota local actualizada.')),
                    );
                  },
                  child: const Text('Guardar cambios'),
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ================== GENERAR PDF Y EXPORTAR ===================

  Future<Uint8List> _buildNotePdf({
    required String title,
    required String matricula,
    required String? tratante,
    required String createdAtStr,
    required String cuerpo,
    String? diagnostico,
    String? tipoConsulta,
    List<String>? adjuntos,
  }) async {
    final doc = pw.Document();

    pw.Widget rowKV(String k, String v) => pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              width: 120,
              child: pw.Text(k,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Expanded(child: pw.Text(v)),
          ],
        );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter.copyWith(
          marginLeft: 36,
          marginRight: 36,
          marginTop: 36,
          marginBottom: 36,
        ),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('CRES Carnets – Nota clínica',
                    style: pw.TextStyle(
                        fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text(title),
              ],
            ),
          ),
          pw.SizedBox(height: 8),
          rowKV('Matrícula', matricula),
          rowKV('Tratante', tratante ?? 'N/A'),
          rowKV('Fecha', createdAtStr),
          if (diagnostico != null && diagnostico.trim().isNotEmpty)
            rowKV('Diagnóstico', diagnostico.trim()),
          if (tipoConsulta != null && tipoConsulta.trim().isNotEmpty)
            rowKV('Consulta', tipoConsulta.trim()),
          pw.SizedBox(height: 12),
          pw.Text('Cuerpo',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text(cuerpo),
          if (adjuntos != null && adjuntos.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            pw.Text('Adjuntos',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children:
                  adjuntos.map<pw.Widget>((a) => pw.Bullet(text: a)).toList(),
            ),
          ],
          pw.SizedBox(height: 24),
          pw.Divider(),
          pw.Text('Generado por CRES Carnets',
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
        ],
      ),
    );

    return doc.save();
  }

  Map<String, String?> _extractDxConsulta(String cuerpo) {
    String? dx;
    String? tc;
    final lines = cuerpo.split('\n');
    if (lines.isNotEmpty && lines[0].toLowerCase().startsWith('diagnóstico:')) {
      dx = lines[0].substring('diagnóstico:'.length).trim();
    }
    if (lines.length > 1 && lines[1].toLowerCase().startsWith('consulta:')) {
      tc = lines[1].substring('consulta:'.length).trim();
    }
    return {'dx': dx, 'tc': tc};
  }

  String _attachmentDisplayName(String rawPathOrName) {
    final clean = rawPathOrName.trim();
    if (clean.isEmpty) return 'archivo adjunto';
    final base = p.basename(clean);
    return base.trim().isEmpty ? clean : base;
  }

  List<_LocalNoteAttachment> _extraerAdjuntosDesdeCuerpoNota(String cuerpo) {
    final out = <_LocalNoteAttachment>[];
    String? currentName;
    String? currentPath;
    String currentType = 'local';
    var inStructuredBlock = false;
    var inLegacyBlock = false;

    void flushStructuredAttachment() {
      final path = currentPath?.trim() ?? '';
      if (path.isNotEmpty) {
        out.add(_LocalNoteAttachment(
          name: (currentName?.trim().isNotEmpty ?? false)
              ? currentName!.trim()
              : _attachmentDisplayName(path),
          path: path,
          type: currentType.trim().isEmpty ? 'local' : currentType.trim(),
        ));
      }
      currentName = null;
      currentPath = null;
      currentType = 'local';
    }

    for (final rawLine in cuerpo.split('\n')) {
      final line = rawLine.trim();
      final normalized = _normalizeLookup(line);

      if (normalized == 'adjuntos locales:') {
        flushStructuredAttachment();
        inStructuredBlock = true;
        inLegacyBlock = false;
        continue;
      }

      if (normalized == 'adjuntos:') {
        flushStructuredAttachment();
        inStructuredBlock = false;
        inLegacyBlock = true;
        continue;
      }

      if (inStructuredBlock) {
        if (line.isEmpty) continue;

        final startsAttachment =
            line.startsWith('* nombre:') || line.startsWith('- nombre:');
        if (startsAttachment) {
          flushStructuredAttachment();
          currentName = line.substring(line.indexOf(':') + 1).trim();
          continue;
        }

        final separator = line.indexOf(':');
        if (separator <= 0) continue;

        final key = _normalizeLookup(line.substring(0, separator));
        final value = line.substring(separator + 1).trim();
        if (key == 'nombre') {
          currentName = value;
        } else if (key == 'ruta') {
          currentPath = value;
        } else if (key == 'tipo') {
          currentType = value.isEmpty ? 'local' : value;
        }
        continue;
      }

      if (inLegacyBlock && line.startsWith('- ')) {
        final legacyPath = line.substring(2).trim();
        if (legacyPath.isNotEmpty) {
          out.add(_LocalNoteAttachment(
            name: _attachmentDisplayName(legacyPath),
            path: legacyPath,
          ));
        }
      }
    }

    flushStructuredAttachment();
    return out;
  }

  String _cuerpoSinBloqueAdjuntosLocales(String cuerpo) {
    final visibleLines = <String>[];
    for (final rawLine in cuerpo.split('\n')) {
      final normalized = _normalizeLookup(rawLine.trim());
      if (normalized == 'adjuntos locales:' || normalized == 'adjuntos:') {
        break;
      }
      visibleLines.add(rawLine);
    }
    return visibleLines.join('\n').trimRight();
  }

  List<String> _extractAdjuntos(String cuerpo) {
    return _extraerAdjuntosDesdeCuerpoNota(cuerpo)
        .map((adjunto) => adjunto.name)
        .toList();
  }

  bool _existeArchivoLocal(String path) {
    if (path.trim().isEmpty) return false;
    try {
      return File(path).existsSync();
    } catch (_) {
      return false;
    }
  }

  Future<void> _abrirAdjuntoLocal(String path) async {
    if (!_existeArchivoLocal(path)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Adjunto no disponible en esta computadora.'),
        ),
      );
      return;
    }

    try {
      final result = await OpenFilex.open(path);
      if (!mounted || result.type == ResultType.done) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.message.isEmpty
                ? 'No se pudo abrir el adjunto local.'
                : result.message,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo abrir el adjunto local: $e')),
      );
    }
  }

  Widget _buildAdjuntosLocalesSection(
    List<_LocalNoteAttachment> adjuntos, {
    bool compact = false,
    Color? accent,
  }) {
    if (adjuntos.isEmpty) return const SizedBox.shrink();

    final color = accent ?? UAGroColors.blue;
    return Container(
      margin: EdgeInsets.only(top: compact ? 8 : 14),
      padding: EdgeInsets.all(compact ? 10 : 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .055),
        borderRadius: BorderRadius.circular(compact ? 10 : 14),
        border: Border.all(color: color.withValues(alpha: .16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.attach_file_rounded, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                'Adjuntos locales',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: compact ? 12 : 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: adjuntos
                .map((adjunto) => _buildAdjuntoLocalCard(
                      adjunto,
                      compact: compact,
                      accent: color,
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          Text(
            'Los adjuntos de SASU 2.5 se almacenan localmente en este equipo. Para disponibilidad institucional se requiere habilitar contenedor Azure Blob.',
            style: TextStyle(
              color: UAGroColors.onSurfaceVariant,
              fontSize: compact ? 10.5 : 11.5,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdjuntoLocalCard(
    _LocalNoteAttachment adjunto, {
    required bool compact,
    required Color accent,
  }) {
    final exists = _existeArchivoLocal(adjunto.path);
    return Container(
      constraints: BoxConstraints(
        minWidth: compact ? 220 : 260,
        maxWidth: compact ? 320 : 430,
      ),
      padding: EdgeInsets.all(compact ? 9 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              exists ? accent.withValues(alpha: .20) : const Color(0xFFFFC7C7),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .035),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 30 : 36,
            height: compact ? 30 : 36,
            decoration: BoxDecoration(
              color: exists
                  ? accent.withValues(alpha: .10)
                  : const Color(0xFFFFEFEF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              exists ? Icons.insert_drive_file_outlined : Icons.link_off,
              color: exists ? accent : const Color(0xFFC62828),
              size: compact ? 17 : 20,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  adjunto.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: UAGroColors.blue,
                    fontWeight: FontWeight.w900,
                    fontSize: compact ? 12 : 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  exists
                      ? 'Adjunto local'
                      : 'Adjunto no disponible en esta computadora',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: exists
                        ? UAGroColors.onSurfaceVariant
                        : const Color(0xFFC62828),
                    fontSize: compact ? 10.5 : 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: exists ? () => _abrirAdjuntoLocal(adjunto.path) : null,
            style: OutlinedButton.styleFrom(
              visualDensity: compact ? VisualDensity.compact : null,
              foregroundColor: accent,
              side: BorderSide(color: accent.withValues(alpha: .32)),
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 9 : 12,
                vertical: compact ? 6 : 9,
              ),
            ),
            child: const Text('Abrir'),
          ),
        ],
      ),
    );
  }

  Future<void> _printPdf(Uint8List bytes) async {
    await Printing.layoutPdf(onLayout: (format) async => bytes);
  }

  Future<void> _sharePdf(Uint8List bytes, String filename) async {
    await Printing.sharePdf(bytes: bytes, filename: filename);
  }

  Future<void> _exportCloudNote(Map<String, dynamic> n) async {
    final dep = (n['departamento'] ?? '-') as String;
    final cuerpo = (n['cuerpo'] ?? '') as String;
    final trat = (n['tratante'] ?? '') as String?;
    final fecha = (n['createdAt'] ?? '') as String;
    final mat = _mat.text.trim();

    final ex = _extractDxConsulta(cuerpo);
    final atts = _extractAdjuntos(cuerpo);
    final cuerpoVisible = _cuerpoSinBloqueAdjuntosLocales(cuerpo);

    final pdfBytes = await _buildNotePdf(
      title: dep,
      matricula: mat,
      tratante: trat,
      createdAtStr: fecha,
      cuerpo: cuerpoVisible,
      diagnostico: ex['dx'],
      tipoConsulta: ex['tc'],
      adjuntos: atts,
    );

    await _showPdfActions(pdfBytes, 'nota_${mat}_$dep.pdf');
  }

  Future<void> _exportLocalNote(DB.Note n) async {
    final dep = n.departamento;
    final cuerpo = n.cuerpo;
    final trat = n.tratante;
    final fecha = _fmtDate(n.createdAt);
    final mat = _mat.text.trim();

    final ex = _extractDxConsulta(cuerpo);
    final atts = _extractAdjuntos(cuerpo);
    final cuerpoVisible = _cuerpoSinBloqueAdjuntosLocales(cuerpo);

    final pdfBytes = await _buildNotePdf(
      title: dep,
      matricula: mat,
      tratante: trat,
      createdAtStr: fecha,
      cuerpo: cuerpoVisible,
      diagnostico: ex['dx'],
      tipoConsulta: ex['tc'],
      adjuntos: atts,
    );

    await _showPdfActions(pdfBytes, 'nota_${mat}_$dep.pdf');
  }

  Future<void> _showPdfActions(Uint8List pdfBytes, String fileName) async {
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Exportar / Imprimir',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await _printPdf(pdfBytes);
                      },
                      icon: const Icon(Icons.print),
                      label: const Text('Imprimir'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await _sharePdf(pdfBytes, fileName);
                      },
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Exportar PDF'),
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

  // ================ UI: NOTAS CLOUD, LOCAL, NUEVA NOTA ================

  Widget _buildCloudNotesAccordion() {
    final cs = Theme.of(context).colorScheme;

    if (_notasCloud.isEmpty) {
      return Text(
        'Sin notas en nube para esta matrícula.',
        style: TextStyle(color: cs.onSurface.withOpacity(.75)),
      );
    }

    final total = _notasCloud.length;
    final slice =
        _showAllCloud ? _notasCloud : _notasCloud.take(_limit).toList();

    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => setState(() => _showAllCloud = !_showAllCloud),
            icon:
                Icon(_showAllCloud ? Icons.filter_alt_off : Icons.expand_more),
            label: Text(
                _showAllCloud ? 'Ver últimas $_limit' : 'Ver todas ($total)'),
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: slice.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final n = slice[i];
            final dep = (n['departamento'] ?? '-').toString();
            final cuerpo = (n['cuerpo'] ?? '').toString();
            final trat = (n['tratante'] ?? '').toString();
            final fecha = (n['createdAt'] ?? '').toString();
            final adjuntos = _extraerAdjuntosDesdeCuerpoNota(cuerpo);
            final cuerpoVisible = _cuerpoSinBloqueAdjuntosLocales(cuerpo);

            return ExpansionTile(
              leading: const Icon(Icons.cloud_done),
              title: Text(dep,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Row(
                children: [
                  if (trat.isNotEmpty) Text(trat),
                  if (trat.isNotEmpty && fecha.isNotEmpty)
                    const SizedBox(width: 8),
                  if (fecha.isNotEmpty)
                    Text(
                      fecha,
                      style: TextStyle(
                          fontSize: 12, color: cs.onSurface.withOpacity(.6)),
                    ),
                ],
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                  child: SelectableText(cuerpoVisible),
                ),
                if (adjuntos.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: _buildAdjuntosLocalesSection(adjuntos),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _exportCloudNote(n),
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('Exportar / Imprimir'),
                      ),
                      FilledButton.icon(
                        onPressed: () => ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(
                                content: Text(
                                    'Edición en nube deshabilitada. Solo edición local.'))),
                        icon: const Icon(Icons.edit),
                        label: const Text('No editable'),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildLocalNotesAccordion() {
    final cs = Theme.of(context).colorScheme;

    if (_notasLocal.isEmpty) {
      return Text(
        'Sin notas locales para esta matrícula.',
        style: TextStyle(color: cs.onSurface.withOpacity(.75)),
      );
    }

    final total = _notasLocal.length;
    final slice =
        _showAllLocal ? _notasLocal : _notasLocal.take(_limit).toList();

    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => setState(() => _showAllLocal = !_showAllLocal),
            icon:
                Icon(_showAllLocal ? Icons.filter_alt_off : Icons.expand_more),
            label: Text(
                _showAllLocal ? 'Ver últimas $_limit' : 'Ver todas ($total)'),
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: slice.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final n = slice[i];
            final dep = n.departamento;
            final cuerpo = n.cuerpo;
            final trat = n.tratante ?? '';
            final fecha = _fmtDate(n.createdAt);
            final adjuntos = _extraerAdjuntosDesdeCuerpoNota(cuerpo);
            final cuerpoVisible = _cuerpoSinBloqueAdjuntosLocales(cuerpo);

            return ExpansionTile(
              leading: const Icon(Icons.folder_outlined),
              title: Text(dep,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Row(
                children: [
                  if (trat.isNotEmpty) Text(trat),
                  if (trat.isNotEmpty && fecha.isNotEmpty)
                    const SizedBox(width: 8),
                  if (fecha.isNotEmpty)
                    Text(
                      fecha,
                      style: TextStyle(
                          fontSize: 12, color: cs.onSurface.withOpacity(.6)),
                    ),
                ],
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                  child: SelectableText(cuerpoVisible),
                ),
                if (adjuntos.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: _buildAdjuntosLocalesSection(adjuntos),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _exportLocalNote(n),
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('Exportar / Imprimir'),
                      ),
                      FilledButton.icon(
                        onPressed: () => _editLocalNote(n),
                        icon: const Icon(Icons.edit),
                        label: const Text('Editar'),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _cardNube(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SectionCard(
      icon: Icons.cloud_outlined,
      title: 'Expediente y notas (NUBE)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_atencionIntegral)
            Align(
              alignment: Alignment.topRight,
              child: Tooltip(
                message: 'Atención integral: 2 o más servicios activos',
                child: Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.green.withOpacity(.4), blurRadius: 6)
                    ],
                  ),
                ),
              ),
            ),
          if (_expedienteCloud == null)
            Text('No hay carnet en la nube para esta matrícula.',
                style: TextStyle(color: cs.onSurface.withOpacity(.75)))
          else ...[
            _line('Nombre', _expedienteCloud!['nombreCompleto']),
            _line('Correo', _expedienteCloud!['correo']),
            _line('Edad', _expedienteCloud!['edad']),
            _line('Sexo', _expedienteCloud!['sexo']),
            _line('Programa', _expedienteCloud!['programa']),
            _line('Categoría', _expedienteCloud!['categoria']),
            _line(
              'Escuela o Unidad Académica',
              _expedienteCloud!['escuelaUnidadAcademica'] ?? 'No especificada',
            ),
            _lineRaw('Grupo', _expedienteCloud!['grupo'] ?? ''),
            _line('Alergias', _expedienteCloud!['alergias']),
            _line('Tipo de sangre', _expedienteCloud!['tipoSangre']),
            _line('Enfermedad', _expedienteCloud!['enfermedadCronica']),
            _line('Discapacidad', _expedienteCloud!['discapacidad']),
            _line(
                'Tipo de discapacidad', _expedienteCloud!['tipoDiscapacidad']),
            _line('Unidad médica', _expedienteCloud!['unidadMedica']),
            _line('Núm. de afiliación', _expedienteCloud!['numeroAfiliacion']),
            _line('Uso Seguro Universitario',
                _expedienteCloud!['usoSeguroUniversitario']),
            _line('Donante', _expedienteCloud!['donante']),
            _line('Teléfono de emergencia',
                _expedienteCloud!['emergenciaTelefono']),
            _line('Contacto de emergencia',
                _expedienteCloud!['emergenciaContacto']),
            const SizedBox(height: 6),
            _line('Actualizado', _expedienteCloud!['timestamp']),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.notes_outlined, size: 18),
              const SizedBox(width: 6),
              Text('Notas en nube · ${_notasCloud.length}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          _buildCloudNotesAccordion(),
        ],
      ),
    );
  }

  Widget _cardLocal(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SectionCard(
      icon: Icons.storage_outlined,
      title: 'Respaldo LOCAL',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_atencionIntegral)
            Align(
              alignment: Alignment.topRight,
              child: Tooltip(
                message: 'Atención integral: 2 o más servicios activos',
                child: Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: const BoxDecoration(
                      color: Colors.green, shape: BoxShape.circle),
                ),
              ),
            ),
          if (_expedienteLocal == null) ...[
            Text('No hay carnet local para esta matrícula.',
                style: TextStyle(color: cs.onSurface.withOpacity(.75))),
          ] else ...[
            Text('Nombre: ${_expedienteLocal!.nombreCompleto}'),
            Text('Correo: ${_expedienteLocal!.correo}'),
            Text('Edad: ${_expedienteLocal!.edad ?? '-'}'),
            Text('Sexo: ${_expedienteLocal!.sexo ?? '-'}'),
            Text('Programa: ${_expedienteLocal!.programa ?? '-'}'),
            Text('Categoría: ${_expedienteLocal!.categoria ?? '-'}'),
            Text('Alergias: ${_expedienteLocal!.alergias ?? '-'}'),
            Text('Tipo de sangre: ${_expedienteLocal!.tipoSangre ?? '-'}'),
            Text('Enfermedad: ${_expedienteLocal!.enfermedadCronica ?? '-'}'),
            const SizedBox(height: 6),
            Text('Actualizado: ${_fmtDate(_expedienteLocal!.timestamp)}'),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.notes_outlined, size: 18),
              const SizedBox(width: 6),
              Text('Notas locales · ${_notasLocal.length}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          _buildLocalNotesAccordion(),
        ],
      ),
    );
  }

  bool get _hayCarnetEncontrado =>
      _expedienteLocal != null || _expedienteCloud != null;

  bool get _hayNotasEncontradas =>
      _notasLocal.isNotEmpty || _notasCloud.isNotEmpty;

  Widget _buildBusquedaIntegrada(ColorScheme cs) {
    return SectionCard(
      icon: Icons.manage_search_rounded,
      title: 'Buscar carnet / notas',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _mat,
                  decoration: const InputDecoration(
                    labelText: 'Buscar por matrícula o nombre',
                    hintText: 'Ej: 2021001',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                  onSubmitted: (_) => _buscarExpedienteIntegrado(),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 56),
                  backgroundColor: UAGroColors.blue,
                  foregroundColor: Colors.white,
                ),
                onPressed: _cargando ? null : _buscarExpedienteIntegrado,
                icon: _cargando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.folder_open_rounded),
                label: const Text('Buscar expediente'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 56),
                  foregroundColor: UAGroColors.blue,
                  side: const BorderSide(color: UAGroColors.blue),
                ),
                onPressed: _abrirEdicionCarnet,
                icon: const Icon(Icons.edit_note_outlined),
                label: const Text('Editar carnet'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Busca por matrícula o nombre. Para escuela/grupo usa los filtros inferiores.',
            style:
                TextStyle(color: cs.onSurface.withOpacity(.70), fontSize: 12),
          ),
          if (_cargando) ...[
            const SizedBox(height: 12),
            LinearProgressIndicator(
              color: UAGroColors.blue,
              backgroundColor: UAGroColors.blue.withOpacity(.12),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.errorContainer.withOpacity(.55),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(_error!, style: TextStyle(color: cs.error)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResumenAtenciones(ColorScheme cs) {
    final totalNotas = _notasCloud.length + _notasLocal.length;
    final tieneCarnetLocal = _expedienteLocal != null;
    final tieneCarnetNube = _expedienteCloud != null;
    final mensaje = !_busquedaIntegradaRealizada
        ? 'Captura una matrícula para consultar expediente y atenciones.'
        : _hayCarnetEncontrado && !_hayNotasEncontradas
            ? 'Sin atenciones registradas.'
            : !_hayCarnetEncontrado && !_hayNotasEncontradas
                ? 'No se encontró carnet ni notas para esta matrícula.'
                : !tieneCarnetLocal && _hayNotasEncontradas
                    ? 'No se encontró carnet local. Se muestran las notas disponibles.'
                    : 'Expediente consultado correctamente.';

    return SectionCard(
      icon: Icons.analytics_outlined,
      title: 'Resumen de atenciones',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _metricChip(Icons.badge_outlined, 'Carnet local',
                  tieneCarnetLocal ? 'Encontrado' : 'No registrado'),
              _metricChip(Icons.cloud_done_outlined, 'Carnet nube',
                  tieneCarnetNube ? 'Encontrado' : 'No registrado'),
              _metricChip(Icons.note_alt_outlined, 'Notas locales',
                  '${_notasLocal.length}'),
              _metricChip(Icons.cloud_queue_outlined, 'Notas nube',
                  '${_notasCloud.length}'),
              _metricChip(Icons.medical_services_outlined, 'Total atenciones',
                  '$totalNotas'),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: UAGroColors.blue.withOpacity(.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: UAGroColors.blue.withOpacity(.14)),
            ),
            child: Text(
              mensaje,
              style: const TextStyle(
                color: UAGroColors.blue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricChip(IconData icon, String label, String value) {
    return Container(
      constraints: const BoxConstraints(minWidth: 150),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: UAGroColors.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: UAGroColors.blue, size: 20),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: UAGroColors.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: UAGroColors.blue,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEstadoVacioInstitucional() {
    if (!_busquedaIntegradaRealizada ||
        _hayCarnetEncontrado ||
        _hayNotasEncontradas) {
      return const SizedBox.shrink();
    }

    return SectionCard(
      icon: Icons.search_off_rounded,
      title: 'Sin resultados',
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F7FB),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No hay expediente ni atenciones registradas para esta matrícula.',
              style: TextStyle(
                color: UAGroColors.blue,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Verifica la matrícula o crea un carnet nuevo antes de registrar la atención.',
              style: TextStyle(color: UAGroColors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  void _abrirEdicionCarnet() {
    if (_mat.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe una matrícula')),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FormScreen(
          db: widget.db,
          matriculaInicial: _mat.text.trim(),
          lockMatricula: true,
          carnetExistente: _expedienteCloud,
        ),
      ),
    );
  }

  Widget _buildExpedientesDashboard(ColorScheme cs) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final desktop = constraints.maxWidth >= 1050 &&
              !(Platform.isAndroid || Platform.isIOS);
          return Row(
            children: [
              if (desktop) _buildExpedientesSidebar(),
              Expanded(
                child: Stack(
                  children: [
                    Positioned(
                      right: -80,
                      top: -100,
                      child: _InstitutionalWaves(width: desktop ? 460 : 280),
                    ),
                    SafeArea(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          desktop ? 28 : 16,
                          desktop ? 24 : 16,
                          desktop ? 28 : 16,
                          24,
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1500),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildExpedientesHeader(cs, desktop),
                              if (_studentSearchResults.isNotEmpty) ...[
                                const SizedBox(height: 14),
                                _buildStudentSearchResultsCard(),
                              ],
                              const SizedBox(height: 14),
                              if (_error != null) _buildSearchMessage(cs),
                              if (_error != null) const SizedBox(height: 14),
                              if (_busquedaIntegradaRealizada &&
                                  !_hayCarnetEncontrado &&
                                  !_hayNotasEncontradas &&
                                  _studentSearchResults.isEmpty)
                                _buildNoExpedienteCard()
                              else ...[
                                _buildStudentSummaryCard(),
                                const SizedBox(height: 16),
                                _buildKpiStrip(),
                                const SizedBox(height: 18),
                                if (desktop)
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        flex: 10,
                                        child: _buildClinicalTimelineCard(),
                                      ),
                                      const SizedBox(width: 20),
                                      Expanded(
                                        flex: 9,
                                        child: Column(
                                          children: [
                                            _highlightedNoteComposer(cs),
                                            const SizedBox(height: 16),
                                            _buildBottomMiniCards(),
                                          ],
                                        ),
                                      ),
                                    ],
                                  )
                                else
                                  Column(
                                    children: [
                                      _buildClinicalTimelineCard(),
                                      const SizedBox(height: 16),
                                      _highlightedNoteComposer(cs),
                                      const SizedBox(height: 16),
                                      _buildBottomMiniCards(),
                                    ],
                                  ),
                              ],
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
      ),
    );
  }

  Widget _buildExpedientesSidebar() {
    final items = [
      (Icons.home_outlined, 'Inicio', false),
      (Icons.folder_shared_outlined, 'Expedientes', true),
      (Icons.search_rounded, 'Buscar carnet / notas', true),
      (Icons.badge_outlined, 'Crear Carnet', false),
      (Icons.note_add_outlined, 'Nueva Nota', false),
      (Icons.volunteer_activism_outlined, 'Promoción de Salud', false),
      (Icons.vaccines_outlined, 'Vacunación', false),
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
                  maybeUAGroLogo(size: 44),
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
                    final active = item.$2 == 'Buscar carnet / notas';
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: active
                            ? const Color(0xFF0D4FBD)
                            : item.$3
                                ? Colors.white.withOpacity(.055)
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: active
                            ? Border.all(
                                color: Colors.white.withOpacity(.18),
                                width: 1,
                              )
                            : null,
                        boxShadow: active
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(.18),
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
                              color: UAGroColors.red,
                              borderRadius: BorderRadius.horizontal(
                                right: Radius.circular(999),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Material(
                              color: Colors.transparent,
                              child: ListTile(
                                onTap: () => _handleSidebarTap(item.$2),
                                hoverColor: Colors.white.withOpacity(.08),
                                splashColor: Colors.white.withOpacity(.10),
                                dense: true,
                                visualDensity: VisualDensity.compact,
                                leading: Icon(item.$1,
                                    color: Colors.white, size: 22),
                                title: Text(
                                  item.$2,
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
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.06),
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
                      '07/06/2026 10:45 a. m.',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    const SizedBox(height: 14),
                    const Icon(Icons.cloud_sync_outlined,
                        color: Colors.white, size: 24),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Text(
                        'v2.5.0',
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

  Widget _buildExpedientesHeader(ColorScheme cs, bool desktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Expedientes',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: UAGroColors.blue,
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
            IconButton(
              tooltip: 'Refrescar',
              onPressed: _mat.text.trim().isEmpty || _cargando
                  ? null
                  : _buscarExpedienteIntegrado,
              icon: const Icon(Icons.notifications_none_rounded),
              color: UAGroColors.blue,
            ),
            IconButton(
              tooltip: 'Ver citas',
              onPressed: _mostrarCitas,
              icon: const Icon(Icons.cloud_upload_outlined),
              color: UAGroColors.blue,
            ),
            const SizedBox(width: 10),
            const CircleAvatar(
              radius: 24,
              backgroundColor: Colors.white,
              child: Text(
                'DR',
                style: TextStyle(
                  color: UAGroColors.blue,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 10),
            if (desktop)
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dr. Administrador',
                    style: TextStyle(
                      color: UAGroColors.blue,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'CRES Llano Largo',
                    style: TextStyle(color: UAGroColors.onSurfaceVariant),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (desktop)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 7, child: _buildHeaderSearchField()),
              FilledButton(
                onPressed: _cargando ? null : _buscarExpedienteIntegrado,
                style: FilledButton.styleFrom(
                  backgroundColor: UAGroColors.blue,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.horizontal(
                      right: Radius.circular(9),
                    ),
                  ),
                ),
                child: _cargando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Buscar'),
              ),
              const SizedBox(width: 12),
              _buildClearSearchButton(),
              const SizedBox(width: 12),
              _buildAdvancedSearchButton(),
            ],
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeaderSearchField(),
              const SizedBox(height: 10),
              FilledButton(
                onPressed: _cargando ? null : _buscarExpedienteIntegrado,
                style: FilledButton.styleFrom(
                  backgroundColor: UAGroColors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _cargando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Buscar'),
              ),
              const SizedBox(height: 10),
              _buildClearSearchButton(),
              const SizedBox(height: 10),
              _buildAdvancedSearchButton(),
            ],
          ),
        const SizedBox(height: 6),
        Text(
          'Busca por matrícula, nombre o CURP.',
          style: TextStyle(color: cs.onSurface.withOpacity(.62), fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildClearSearchButton() {
    return OutlinedButton(
      onPressed: _cargando
          ? null
          : () {
              setState(() {
                _mat.clear();
                _escuelaFiltro.clear();
                _grupoFiltro.clear();
                _studentSearchResults = const [];
                _studentSearchResultsTitle = null;
                _studentSearchResultsBase = const [];
                _studentSearchResultsBaseTitle = null;
                _error = null;
              });
            },
      style: OutlinedButton.styleFrom(
        foregroundColor: UAGroColors.blue,
        backgroundColor: Colors.white,
        side: BorderSide(color: UAGroColors.blue.withValues(alpha: .45)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(9),
        ),
      ),
      child: const Text('Limpiar'),
    );
  }

  void _handleSidebarTap(String label) {
    switch (label) {
      case 'Inicio':
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => DashboardScreen(db: widget.db),
          ),
        );
        return;
      case 'Expedientes':
        return;
      case 'Buscar carnet / notas':
        _searchFocus.requestFocus();
        return;
      case 'Crear Carnet':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => FormScreen(db: widget.db),
          ),
        );
        return;
      case 'Nueva Nota':
        _noteFocus.requestFocus();
        return;
      case 'Promoción de Salud':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PromocionSaludScreen(db: widget.db),
          ),
        );
        return;
      case 'Vacunación':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const VaccinationScreen(),
          ),
        );
        return;
      case 'Reportes':
        _showSidebarSnack('Módulo en desarrollo');
        return;
      case 'Observatorio SASU':
        _openObservatoryFromSidebar();
        return;
      case 'Configuración':
        _showSidebarSnack('Módulo en desarrollo');
        return;
    }
  }

  Future<void> _openObservatoryFromSidebar() async {
    if (_observatoryUrl.trim().isEmpty) {
      _showSidebarSnack('Observatorio SASU pendiente de vinculación');
      return;
    }

    final uri = Uri.tryParse(_observatoryUrl);
    if (uri == null) {
      _showSidebarSnack('Observatorio SASU pendiente de vinculación');
      return;
    }

    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched && mounted) {
      _showSidebarSnack('Observatorio SASU pendiente de vinculación');
    }
  }

  void _showSidebarSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildSearchMessage(ColorScheme cs) {
    final isNameMessage =
        _error!.contains('búsqueda por nombre') || _error!.contains('nombre');
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isNameMessage
            ? const Color(0xFFFFF6E6)
            : cs.errorContainer.withOpacity(.55),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isNameMessage ? const Color(0xFFE6A11C) : cs.error,
          width: .8,
        ),
      ),
      child: Text(
        _error!,
        style: TextStyle(
          color: isNameMessage ? const Color(0xFF875800) : cs.error,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildHeaderSearchField() {
    return TextField(
      controller: _mat,
      focusNode: _searchFocus,
      decoration: InputDecoration(
        hintText: 'Buscar por nombre, matrícula o CURP...',
        prefixIcon: const Icon(Icons.search_rounded),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: UAGroColors.blue),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: BorderSide(color: UAGroColors.blue.withOpacity(.45)),
        ),
      ),
      onSubmitted: (_) => _buscarExpedienteIntegrado(),
    );
  }

  Widget _buildAdvancedSearchButton() {
    return OutlinedButton.icon(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Búsqueda avanzada pendiente de integración.'),
          ),
        );
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: UAGroColors.blue,
        backgroundColor: Colors.white,
        side: const BorderSide(color: UAGroColors.blue),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 17),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(9),
        ),
      ),
      icon: const Icon(Icons.filter_list_rounded),
      label: const Text('Búsqueda avanzada'),
    );
  }

  // ignore: unused_element
  Widget _buildSchoolGroupFilters(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _dashboardCardDecoration(radius: 14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          final schoolField = _filterTextField(
            controller: _escuelaFiltro,
            label: 'Escuela / Unidad Académica',
            hint: 'Ej. CRES Llano Largo',
            icon: Icons.account_balance_outlined,
          );
          final groupField = _filterTextField(
            controller: _grupoFiltro,
            label: 'Grupo',
            hint: 'Ej. 101',
            icon: Icons.groups_2_outlined,
          );

          final actions = [
            FilledButton.icon(
              onPressed: _cargando ? null : _filtrarEstudiantesPorEscuelaGrupo,
              style: FilledButton.styleFrom(
                backgroundColor: UAGroColors.blue,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              ),
              icon: const Icon(Icons.filter_alt_outlined),
              label: const Text('Filtrar estudiantes'),
            ),
            const SizedBox(width: 8, height: 8),
            OutlinedButton(
              onPressed: _cargando
                  ? null
                  : () {
                      setState(() {
                        _escuelaFiltro.clear();
                        _grupoFiltro.clear();
                        _studentSearchResults = _studentSearchResultsBase;
                        _studentSearchResultsTitle =
                            _studentSearchResultsBaseTitle;
                        _error = null;
                      });
                    },
              style: OutlinedButton.styleFrom(
                foregroundColor: UAGroColors.blue,
                side:
                    BorderSide(color: UAGroColors.blue.withValues(alpha: .45)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              child: const Text('Limpiar'),
            ),
          ];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF0FB),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.school_outlined,
                      color: UAGroColors.blue,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Filtros por escuela y grupo',
                          style: TextStyle(
                            color: UAGroColors.blue,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'Usa los datos académicos existentes para encontrar estudiantes.',
                          style: TextStyle(
                            color: UAGroColors.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (compact) ...[
                schoolField,
                const SizedBox(height: 10),
                groupField,
                const SizedBox(height: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: actions,
                ),
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(flex: 3, child: schoolField),
                    const SizedBox(width: 12),
                    Expanded(flex: 2, child: groupField),
                    const SizedBox(width: 12),
                    ...actions,
                  ],
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _filterTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      onSubmitted: (_) => _filtrarEstudiantesPorEscuelaGrupo(),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: UAGroColors.blue),
        filled: true,
        fillColor: const Color(0xFFF8FAFE),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD9E1EE)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD9E1EE)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: UAGroColors.blue, width: 1.4),
        ),
      ),
    );
  }

  Widget _buildStudentSearchResultsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _dashboardCardDecoration(radius: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.manage_search_rounded,
                  color: UAGroColors.blue, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _studentSearchResultsTitle ?? 'Estudiantes encontrados',
                  style: const TextStyle(
                    color: UAGroColors.blue,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                'Selecciona para abrir expediente',
                style: TextStyle(
                  color: UAGroColors.onSurfaceVariant.withValues(alpha: .86),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final twoColumns = constraints.maxWidth >= 980;
              if (!twoColumns) {
                return Column(
                  children: [
                    for (final result in _studentSearchResults) ...[
                      _buildStudentResultTile(result),
                      const SizedBox(height: 10),
                    ],
                  ],
                );
              }

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final result in _studentSearchResults)
                    SizedBox(
                      width: (constraints.maxWidth - 12) / 2,
                      child: _buildStudentResultTile(result),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStudentResultTile(_StudentSearchResult result) {
    return Material(
      color: const Color(0xFFF8FAFE),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: _cargando ? null : () => _onStudentResultSelected(result),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFDDE5F2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EEF9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.person_search_rounded,
                    color: UAGroColors.blue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            result.nombre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: UAGroColors.blue,
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        _resultSourceChip(result.source),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _resultMeta(Icons.badge_outlined, result.matricula),
                        _resultMeta(
                          Icons.account_balance_outlined,
                          result.escuelaUnidadAcademica,
                        ),
                        _resultMeta(
                          Icons.groups_2_outlined,
                          result.grupo.isEmpty ? 'Sin grupo' : result.grupo,
                        ),
                        _resultMeta(Icons.place_outlined, result.campus),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.chevron_right_rounded, color: UAGroColors.blue),
            ],
          ),
        ),
      ),
    );
  }

  Widget _resultMeta(IconData icon, String text) {
    final value = text.trim().isEmpty ? 'No registrado' : text.trim();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: UAGroColors.blue),
          const SizedBox(width: 5),
          Text(
            value,
            style: const TextStyle(
              color: UAGroColors.blue,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultSourceChip(String source) {
    final isCloud = source == 'Nube';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isCloud ? const Color(0xFFEAF7EF) : const Color(0xFFEAF0FB),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        source,
        style: TextStyle(
          color: isCloud ? const Color(0xFF087A3F) : UAGroColors.blue,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildStudentSummaryCard() {
    final nombre = _studentValue('nombre');
    final matricula = _studentValue('matricula');
    final programa = _studentValue('programa');
    final campus = _studentValue('campus');
    final categoria = _studentValue('categoria');
    final sangre = _studentValue('sangre');
    final edad = _studentValue('edad');
    final sexo = _studentValue('sexo');
    final correo = _studentValue('correo');
    final telefono = _studentValue('telefono');
    final seguro = _studentValue('seguro');
    final donante = _studentValue('donante');
    final ultimaAtencion = _latestAttentionDateLabel();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _dashboardCardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 102,
            height: 102,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFE8EEF9),
              border: Border.all(color: Colors.white, width: 4),
            ),
            child: const Icon(Icons.person_rounded,
                color: UAGroColors.blue, size: 62),
          ),
          const SizedBox(width: 22),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  style: const TextStyle(
                    color: UAGroColors.blue,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 18,
                  runSpacing: 12,
                  children: [
                    _studentDataBlock('Matrícula', matricula),
                    _studentDataBlock('Programa', programa),
                    _studentDataBlock('Campus', campus),
                    _studentDataBlock('Categoría', categoria),
                    _studentDataBlock('Grupo sanguíneo', sangre),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    _studentPill(Icons.diversity_3_outlined, 'Edad: $edad'),
                    _studentPill(Icons.person_outline, 'Sexo: $sexo'),
                    _studentInfoChip(
                      Icons.alternate_email_outlined,
                      'Correo',
                      correo,
                    ),
                    _studentInfoChip(
                      Icons.phone_outlined,
                      'Teléfono',
                      telefono,
                    ),
                    _studentInfoChip(
                      Icons.health_and_safety_outlined,
                      'Seguro',
                      seguro,
                      color: const Color(0xFF008C73),
                    ),
                    _studentInfoChip(
                      Icons.bloodtype_outlined,
                      'Donante',
                      donante,
                      color: const Color(0xFFE66A00),
                    ),
                    _studentInfoChip(
                      Icons.event_available_outlined,
                      'Última atención',
                      ultimaAtencion,
                      color: const Color(0xFF7B2CBF),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _abrirEdicionCarnet,
                style: OutlinedButton.styleFrom(
                  foregroundColor: UAGroColors.blue,
                  side: BorderSide(color: UAGroColors.blue.withOpacity(.35)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.badge_outlined),
                label: const Text('Ver carnet'),
              ),
              IconButton.outlined(
                onPressed: () {},
                color: UAGroColors.blue,
                icon: const Icon(Icons.more_vert_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _studentDataBlock(String label, String value) {
    return Container(
      constraints: const BoxConstraints(minWidth: 130),
      padding: const EdgeInsets.only(right: 18),
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: Color(0xFFE1E6F0))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: UAGroColors.onSurfaceVariant, fontSize: 12)),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              color: UAGroColors.blue,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _studentPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: UAGroColors.blue, size: 16),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: UAGroColors.blue,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _studentInfoChip(
    IconData icon,
    String label,
    String value, {
    Color color = UAGroColors.blue,
  }) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Flexible(
            child: RichText(
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: const TextStyle(
                  color: UAGroColors.blue,
                  fontSize: 12,
                ),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  TextSpan(
                    text: value,
                    style: const TextStyle(
                      color: Color(0xFF31415F),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiStrip() {
    final kpis = [
      _KpiData(
        icon: Icons.description_outlined,
        title: 'Notas clínicas',
        count: _allTimelineItems().length,
        subtitle: 'Última atención: ${_latestAttentionDateLabel()}',
        color: const Color(0xFF1D4FAD),
      ),
      _kpiFor(
          'Medicina',
          Icons.medical_services_outlined,
          const Color(0xFF0C4CC2),
          (dep) => _containsAny(dep, ['medic', 'consultorio médico'])),
      _kpiFor('Nutrición', Icons.apple_outlined, const Color(0xFF009B75),
          (dep) => _containsAny(dep, ['nutric'])),
      _kpiFor('Psicología', Icons.psychology_outlined, const Color(0xFF8E24AA),
          (dep) => _containsAny(dep, ['psico'])),
      _kpiFor('Vacunación', Icons.vaccines_outlined, const Color(0xFF008197),
          (dep) => _containsAny(dep, ['vacun'])),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = constraints.maxWidth >= 900
            ? (constraints.maxWidth - 64) / 5
            : constraints.maxWidth >= 560
                ? (constraints.maxWidth - 16) / 2
                : constraints.maxWidth;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            for (final kpi in kpis)
              SizedBox(
                width: itemWidth,
                child: _buildKpiCard(kpi),
              ),
          ],
        );
      },
    );
  }

  Widget _buildKpiCard(_KpiData data) {
    final isLatest = data.subtitle.startsWith('Última');
    final subtitleValue =
        isLatest ? data.subtitle.replaceFirst('Última atención: ', '') : '';

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: _dashboardCardDecoration(radius: 12),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: data.color.withOpacity(.12),
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
                  '${data.count}',
                  style: TextStyle(
                    color: data.color,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  data.title,
                  style: const TextStyle(
                    color: UAGroColors.blue,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                if (isLatest)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Última atención:',
                        style: TextStyle(
                          color: UAGroColors.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        subtitleValue,
                        style: const TextStyle(
                          color: Color(0xFF31415F),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    data.subtitle,
                    style: const TextStyle(
                      color: UAGroColors.onSurfaceVariant,
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

  Widget _buildClinicalTimelineCard() {
    final items = _allTimelineItems();

    return Container(
      decoration: _dashboardCardDecoration(),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.event_note_outlined, color: UAGroColors.blue),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Historial clínico',
                  style: TextStyle(
                    color: UAGroColors.blue,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.filter_list_rounded, size: 18),
                label: const Text('Todos los departamentos'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: UAGroColors.blue,
                  side: BorderSide(color: UAGroColors.blue.withOpacity(.18)),
                  backgroundColor: const Color(0xFFF7F9FF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F8FC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Sin atenciones registradas.',
                style: TextStyle(
                  color: UAGroColors.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
            ListView.separated(
              itemCount: items.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              separatorBuilder: (_, __) => const Divider(height: 18),
              itemBuilder: (context, index) =>
                  _buildTimelineItem(items[index], index),
            ),
          if (items.length > _limit) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => setState(() => _showAllLocal = !_showAllLocal),
              child: const Text('Cargar más notas'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _timelineMetaChip(Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(.16)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildTimelineItem(Map<String, dynamic> item, int index) {
    final color = _departmentColor(item['departamento'] as String);
    final date = item['date'] as DateTime?;
    final day = date == null ? '--' : DateFormat('dd').format(date);
    final month =
        date == null ? '' : DateFormat('MMM').format(date).replaceAll('.', '');
    final year = date == null ? '' : DateFormat('yyyy').format(date);
    final time = date == null ? '' : DateFormat('hh:mm a').format(date);
    final isCloud = item['source'] == 'cloud';
    final psicoTipo = (item['psicoTipo'] ?? '').toString();
    final psicoTema = (item['psicoTema'] ?? '').toString();
    final psicoParticipantes = (item['psicoParticipantes'] ?? '').toString();
    final adjuntos = (item['adjuntosLocales'] as List<_LocalNoteAttachment>?) ??
        const <_LocalNoteAttachment>[];
    final attachmentHeight =
        adjuntos.isEmpty ? 0.0 : (42.0 + (adjuntos.length - 1) * 22.0);
    final timelineHeight =
        (psicoTipo.isEmpty ? 112.0 : 142.0) + attachmentHeight;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 74,
          child: Column(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 9),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: color.withOpacity(.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(.14)),
                ),
                child: Column(
                  children: [
                    Text(
                      day,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      month.toUpperCase(),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                    Text(year, style: TextStyle(color: color, fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
            width: 2, height: timelineHeight, color: color.withOpacity(.24)),
        const SizedBox(width: 18),
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: color.withOpacity(.10),
            shape: BoxShape.circle,
          ),
          child: Icon(_departmentIcon(item['departamento'] as String),
              color: color, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item['departamento'] as String,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (time.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F8FC),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        time,
                        style: const TextStyle(
                          color: UAGroColors.onSurfaceVariant,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                item['titulo'] as String,
                style: const TextStyle(
                  color: UAGroColors.blue,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              if (psicoTipo.isNotEmpty) ...[
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _timelineMetaChip(color, 'Tipo: $psicoTipo'),
                    if (psicoTema.isNotEmpty)
                      _timelineMetaChip(color, 'Tema: $psicoTema'),
                    if (psicoParticipantes.isNotEmpty)
                      _timelineMetaChip(
                          color, 'Participantes: $psicoParticipantes'),
                  ],
                ),
                const SizedBox(height: 5),
              ],
              Text(
                item['descripcion'] as String,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF31415F), fontSize: 12),
              ),
              const SizedBox(height: 3),
              Text(
                'Tratante: ${item['tratante']}',
                style: const TextStyle(
                  color: Color(0xFF68758E),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              _buildAdjuntosLocalesSection(
                adjuntos,
                compact: true,
                accent: color,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        OutlinedButton(
          onPressed: () {
            final raw = item['raw'];
            if (isCloud && raw is Map<String, dynamic>) {
              _showCloudNoteDialog(raw);
            } else if (raw is DB.Note) {
              _showLocalNoteDialog(raw);
            }
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: UAGroColors.blue,
            side: BorderSide(color: UAGroColors.blue.withOpacity(.45)),
          ),
          child: const Text('Ver nota'),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, color: UAGroColors.blue),
          onSelected: (value) {
            final raw = item['raw'];
            if (value == 'export_cloud' && raw is Map<String, dynamic>) {
              _exportCloudNote(raw);
            }
            if (value == 'export_local' && raw is DB.Note) {
              _exportLocalNote(raw);
            }
            if (value == 'edit_local' && raw is DB.Note) {
              _editLocalNote(raw);
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              value: isCloud ? 'export_cloud' : 'export_local',
              child: const Text('Exportar / Imprimir'),
            ),
            if (!isCloud)
              const PopupMenuItem(
                value: 'edit_local',
                child: Text('Editar'),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomMiniCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 620;
        final cards = [
          _miniInfoCard(
            icon: Icons.notes_outlined,
            title: 'Notas locales',
            count: '${_notasLocal.length}',
            status: _notasLocal.isEmpty
                ? 'Sin notas locales'
                : 'Historial disponible',
            buttonLabel: 'Ver notas locales',
            onPressed: () => setState(() => _showAllLocal = true),
          ),
          _miniInfoCard(
            icon: Icons.event_available_outlined,
            title: 'Citas del Cloud',
            count: '${_citasCloud.length}',
            status:
                _citasCloud.isEmpty ? 'Sin citas próximas' : 'Agenda activa',
            buttonLabel: 'Ver citas',
            onPressed: _mostrarCitas,
          ),
        ];

        if (compact) {
          return Column(
            children: [
              for (final card in cards) ...[
                card,
                if (card != cards.last) const SizedBox(height: 12),
              ],
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: cards.first),
            const SizedBox(width: 14),
            Expanded(child: cards.last),
          ],
        );
      },
    );
  }

  Widget _miniInfoCard({
    required IconData icon,
    required String title,
    required String count,
    required String status,
    required String buttonLabel,
    required VoidCallback onPressed,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
      decoration: _dashboardCardDecoration(radius: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: UAGroColors.blue, size: 23),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: UAGroColors.blue,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 12),
                    children: [
                      TextSpan(
                        text: count,
                        style: const TextStyle(
                          color: UAGroColors.blue,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const TextSpan(text: '  '),
                      TextSpan(
                        text: status,
                        style: const TextStyle(
                          color: UAGroColors.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: UAGroColors.blue,
              side: BorderSide(color: UAGroColors.blue.withOpacity(.35)),
            ),
            child: Text(buttonLabel),
          ),
        ],
      ),
    );
  }

  Widget _buildNoExpedienteCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: _dashboardCardDecoration(),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: Color(0xFFEAF0FB),
            child: Icon(Icons.search_off_rounded,
                color: UAGroColors.blue, size: 34),
          ),
          SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No se encontró expediente',
                  style: TextStyle(
                    color: UAGroColors.blue,
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Verifica la matrícula o crea un carnet nuevo.',
                  style: TextStyle(
                    color: UAGroColors.onSurfaceVariant,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _dashboardCardDecoration({double radius = 16}) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: const Color(0xFFE3E8F2)),
      boxShadow: [
        BoxShadow(
          color: UAGroColors.blue.withOpacity(.06),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  String _studentValue(String field) {
    String clean(dynamic value) {
      final text = value?.toString().trim() ?? '';
      return text.isEmpty ? 'No registrado' : text;
    }

    switch (field) {
      case 'nombre':
        return clean(_expedienteLocal?.nombreCompleto ??
            _expedienteCloud?['nombreCompleto']);
      case 'matricula':
        return clean(_expedienteLocal?.matricula ??
            _expedienteCloud?['matricula'] ??
            _mat.text);
      case 'programa':
        return clean(
            _expedienteLocal?.programa ?? _expedienteCloud?['programa']);
      case 'campus':
        return clean(_expedienteLocal?.escuelaUnidadAcademica ??
            _expedienteCloud?['escuelaUnidadAcademica']);
      case 'categoria':
        return clean(
            _expedienteLocal?.categoria ?? _expedienteCloud?['categoria']);
      case 'sangre':
        return clean(
            _expedienteLocal?.tipoSangre ?? _expedienteCloud?['tipoSangre']);
      case 'edad':
        return clean(_expedienteLocal?.edad ?? _expedienteCloud?['edad']);
      case 'sexo':
        return clean(_expedienteLocal?.sexo ?? _expedienteCloud?['sexo']);
      case 'correo':
        return clean(_expedienteLocal?.correo ?? _expedienteCloud?['correo']);
      case 'telefono':
        return clean(_expedienteLocal?.emergenciaTelefono ??
            _expedienteCloud?['emergenciaTelefono']);
      case 'seguro':
        return clean(_expedienteLocal?.unidadMedica ??
            _expedienteCloud?['unidadMedica']);
      case 'donante':
        return clean(_expedienteLocal?.donante ?? _expedienteCloud?['donante']);
    }
    return 'No registrado';
  }

  List<Map<String, dynamic>> _allTimelineItems() {
    final items = <Map<String, dynamic>>[];
    for (final n in _notasCloud) {
      final dep = (n['departamento'] ?? 'Atención').toString();
      final cuerpo = (n['cuerpo'] ?? '').toString();
      final diagnostico = (n['diagnostico'] ?? '').toString();
      final psicoMeta = _psychologyMetaFromBody(cuerpo);
      final adjuntos = _extraerAdjuntosDesdeCuerpoNota(cuerpo);
      final cuerpoVisible = _cuerpoSinBloqueAdjuntosLocales(cuerpo);
      final titleFallback =
          diagnostico.isEmpty ? _firstLine(cuerpoVisible) : diagnostico;
      items.add({
        'source': 'cloud',
        'raw': n,
        'departamento': dep.isEmpty ? 'Atención' : dep,
        'titulo': _timelineTitleForBody(cuerpo, titleFallback),
        'descripcion':
            cuerpoVisible.isEmpty ? 'Sin descripción' : cuerpoVisible,
        'tratante': (n['tratante'] ?? 'No registrado').toString(),
        'date': _parseCloudDate(n['createdAt'] ?? n['timestamp']),
        'psicoTipo': psicoMeta['tipo'] ?? '',
        'psicoTema': psicoMeta['tema'] ?? '',
        'psicoParticipantes': psicoMeta['participantes'] ?? '',
        'adjuntosLocales': adjuntos,
      });
    }
    for (final n in _notasLocal) {
      final psicoMeta = _psychologyMetaFromBody(n.cuerpo);
      final adjuntos = _extraerAdjuntosDesdeCuerpoNota(n.cuerpo);
      final cuerpoVisible = _cuerpoSinBloqueAdjuntosLocales(n.cuerpo);
      items.add({
        'source': 'local',
        'raw': n,
        'departamento': n.departamento.isEmpty ? 'Atención' : n.departamento,
        'titulo': _timelineTitleForBody(n.cuerpo, _firstLine(cuerpoVisible)),
        'descripcion':
            cuerpoVisible.isEmpty ? 'Sin descripción' : cuerpoVisible,
        'tratante': (n.tratante ?? '').isEmpty ? 'No registrado' : n.tratante,
        'date': n.createdAt,
        'psicoTipo': psicoMeta['tipo'] ?? '',
        'psicoTema': psicoMeta['tema'] ?? '',
        'psicoParticipantes': psicoMeta['participantes'] ?? '',
        'adjuntosLocales': adjuntos,
      });
    }
    items.sort((a, b) {
      final ad = a['date'] as DateTime?;
      final bd = b['date'] as DateTime?;
      if (ad == null && bd == null) return 0;
      if (ad == null) return 1;
      if (bd == null) return -1;
      return bd.compareTo(ad);
    });
    return items;
  }

  String _latestAttentionDateLabel() {
    final latest = _allTimelineItems()
        .map((n) => n['date'] as DateTime?)
        .whereType<DateTime>()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    if (latest.isEmpty) return 'Sin registro';
    return DateFormat('dd/MM/yyyy').format(latest.first);
  }

  _KpiData _kpiFor(
    String title,
    IconData icon,
    Color color,
    bool Function(String dep) matcher,
  ) {
    final items = _allTimelineItems()
        .where((n) => matcher((n['departamento'] as String).toLowerCase()))
        .toList();
    final latest = items
        .map((n) => n['date'] as DateTime?)
        .whereType<DateTime>()
        .toList()
      ..sort((a, b) => b.compareTo(a));
    return _KpiData(
      icon: icon,
      title: title,
      count: items.length,
      subtitle: latest.isEmpty
          ? 'Sin registros'
          : 'Última atención: ${DateFormat('dd/MM/yyyy').format(latest.first)}',
      color: color,
    );
  }

  Map<String, String> _psychologyMetaFromBody(String body) {
    final meta = <String, String>{};

    for (final rawLine in body.split('\n')) {
      final line = rawLine.trim();
      final separator = line.indexOf(':');
      if (separator <= 0) continue;

      final key = _normalizeLookup(line.substring(0, separator));
      final value = line.substring(separator + 1).trim();
      if (value.isEmpty) continue;

      if (key.contains('tipo de atencion psicologica')) {
        meta['tipo'] = value;
      } else if (key == 'tema') {
        meta['tema'] = value;
      } else if (key.contains('participantes aproximados')) {
        meta['participantes'] = value;
      } else if (key.contains('escuela') || key.contains('unidad academica')) {
        meta['escuela'] = value;
      } else if (key == 'grupo') {
        meta['grupo'] = value;
      } else if (key.contains('poblacion atendida')) {
        meta['poblacion'] = value;
      } else if (key.contains('lugar') || key.contains('contexto')) {
        meta['lugar'] = value;
      }
    }

    return meta.containsKey('tipo') ? meta : const {};
  }

  String _timelineTitleForBody(String body, String fallback) {
    final meta = _psychologyMetaFromBody(body);
    final tema = meta['tema'] ?? '';
    if (tema.isNotEmpty) return tema;
    return fallback;
  }

  bool _containsAny(String value, List<String> tokens) {
    final normalized = value.toLowerCase();
    return tokens.any((token) => normalized.contains(token));
  }

  DateTime? _parseCloudDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  String _firstLine(String text) {
    final clean = text.trim();
    if (clean.isEmpty) return 'Consulta registrada';
    return clean.split('\n').first.trim();
  }

  Color _departmentColor(String departamento) {
    final dep = departamento.toLowerCase();
    if (_containsAny(dep, ['nutric'])) return const Color(0xFF009B75);
    if (_containsAny(dep, ['psico'])) return const Color(0xFF8E24AA);
    if (_containsAny(dep, ['promoción', 'promocion'])) {
      return const Color(0xFFE66A00);
    }
    if (_containsAny(dep, ['vacun'])) return const Color(0xFF008197);
    return const Color(0xFF0C4CC2);
  }

  IconData _departmentIcon(String departamento) {
    final dep = departamento.toLowerCase();
    if (_containsAny(dep, ['nutric'])) return Icons.apple_outlined;
    if (_containsAny(dep, ['psico'])) return Icons.psychology_outlined;
    if (_containsAny(dep, ['vacun'])) return Icons.vaccines_outlined;
    if (_containsAny(dep, ['promoción', 'promocion'])) {
      return Icons.health_and_safety_outlined;
    }
    return Icons.medical_services_outlined;
  }

  void _showCloudNoteDialog(Map<String, dynamic> note) {
    final cuerpo = (note['cuerpo'] ?? '').toString();
    final adjuntos = _extraerAdjuntosDesdeCuerpoNota(cuerpo);
    final cuerpoVisible = _cuerpoSinBloqueAdjuntosLocales(cuerpo);
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text((note['departamento'] ?? 'Nota en nube').toString()),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectableText(cuerpoVisible),
              _buildAdjuntosLocalesSection(adjuntos),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
          FilledButton.icon(
            onPressed: () => _exportCloudNote(note),
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Exportar'),
          ),
        ],
      ),
    );
  }

  void _showLocalNoteDialog(DB.Note note) {
    final adjuntos = _extraerAdjuntosDesdeCuerpoNota(note.cuerpo);
    final cuerpoVisible = _cuerpoSinBloqueAdjuntosLocales(note.cuerpo);
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(note.departamento),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectableText(cuerpoVisible),
              _buildAdjuntosLocalesSection(adjuntos),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              _editLocalNote(note);
            },
            icon: const Icon(Icons.edit),
            label: const Text('Editar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Listeners para Nutrición (IMC/ICC)
    _peso.removeListener(_refresh);
    _talla.removeListener(_refresh);
    _cintura.removeListener(_refresh);
    _cadera.removeListener(_refresh);
    _peso.addListener(_refresh);
    _talla.addListener(_refresh);
    _cintura.addListener(_refresh);
    _cadera.addListener(_refresh);

    return _buildExpedientesDashboard(cs);

    // ignore: dead_code
    return Scaffold(
      appBar: uagroAppBar(
        'CRES Carnets',
        'Agregar nota clínica',
        [
          IconButton(
            tooltip: 'Refrescar notas desde servidor',
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () async {
              if (_mat.text.trim().isNotEmpty) {
                await _buscarNotasMatricula();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✓ Notas actualizadas')),
                  );
                }
              }
            },
          ),
          IconButton(
            tooltip: 'Ver citas',
            icon: const Icon(Icons.event_rounded, color: Colors.white),
            onPressed: _mostrarCitas,
          ),
        ],
        context,
        widget.db,
      ),
      body: Row(
        children: [
          // Barra lateral institucional UAGro - OCULTA en Android/iOS
          if (!(Platform.isAndroid || Platform.isIOS)) const BrandSidebar(),
          // Contenido principal (sin cambios de lógica)
          Expanded(
            child: SingleChildScrollView(
              padding: AppTheme.contentPadding,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // NO CAMBIAR LÓGICA: mantener callbacks/estados intactos
                    // Encabezado + indicador integral
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            'CRES Carnets - Nueva Nota Clínica',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                        if (_atencionIntegral)
                          Tooltip(
                            message:
                                'Atención integral detectada (=2 servicios)',
                            child: Container(
                              width: 14,
                              height: 14,
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(
                                color: UAGroColors.success,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                      color:
                                          UAGroColors.success.withOpacity(.35),
                                      blurRadius: 6)
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacing),

                    _buildBusquedaIntegrada(cs),
                    const SizedBox(height: 12),
                    _buildResumenAtenciones(cs),
                    const SizedBox(height: 12),
                    _buildEstadoVacioInstitucional(),
                    if (_busquedaIntegradaRealizada &&
                        !_hayCarnetEncontrado &&
                        !_hayNotasEncontradas)
                      const SizedBox(height: 12),

                    // Buscadores anteriores: se conservan montados pero ocultos.
                    // La acción visible integrada reutiliza sus funciones actuales.
                    Visibility(
                      visible: false,
                      maintainState: true,
                      child: Column(
                        children: [
                          // Buscar carnet por ID (QR)
                          SectionCard(
                            icon: Icons.qr_code_scanner,
                            title: 'Buscar carnet por ID (QR)',
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _id,
                                        decoration: const InputDecoration(
                                            labelText: 'ID del carnet (QR)'),
                                        onSubmitted: (_) => _buscarCarnetId(),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    FilledButton.icon(
                                      style: FilledButton.styleFrom(
                                          minimumSize: const Size(0, 40)),
                                      onPressed:
                                          _cargando ? null : _buscarCarnetId,
                                      icon: const Icon(Icons.search),
                                      label: const Text('Buscar carnet'),
                                    ),
                                  ],
                                ),
                                if (_cargando) ...[
                                  const SizedBox(height: 12),
                                  const LinearProgressIndicator(),
                                ],
                                if (_error != null) ...[
                                  const SizedBox(height: 8),
                                  Text(_error!,
                                      style: TextStyle(color: cs.error)),
                                ],
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Buscar NOTAS por matrícula o nombre
                          SectionCard(
                            icon: Icons.search,
                            title: 'Buscar notas por matrícula o nombre',
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _mat,
                                        decoration: const InputDecoration(
                                          labelText: 'Matrícula o Nombre',
                                          hintText: 'Ej: 2021001 o Juan Pérez',
                                        ),
                                        onChanged: _onMatriculaChanged,
                                        onSubmitted: (_) =>
                                            _buscarNotasMatricula(),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    FilledButton.icon(
                                      style: FilledButton.styleFrom(
                                          minimumSize: const Size(0, 40)),
                                      onPressed: _cargando
                                          ? null
                                          : _buscarNotasMatricula,
                                      icon: const Icon(Icons.notes),
                                      label: const Text('Buscar notas'),
                                    ),
                                    const SizedBox(width: 8),
                                    OutlinedButton.icon(
                                      onPressed: () {
                                        if (_mat.text.trim().isEmpty) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    'Escribe una matrícula')),
                                          );
                                          return;
                                        }
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => FormScreen(
                                              db: widget.db,
                                              matriculaInicial:
                                                  _mat.text.trim(),
                                              lockMatricula: true,
                                              carnetExistente: _expedienteCloud,
                                            ),
                                          ),
                                        );
                                      },
                                      icon:
                                          const Icon(Icons.edit_note_outlined),
                                      label: const Text('Editar carnet'),
                                    ),
                                  ],
                                ),
                                if (_cargando) ...[
                                  const SizedBox(height: 12),
                                  const LinearProgressIndicator(),
                                ],
                                if (_error != null) ...[
                                  const SizedBox(height: 8),
                                  Text(_error!,
                                      style: TextStyle(color: cs.error)),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),
                    _cardNube(context),
                    const SizedBox(height: 12),

                    // NUEVA NOTA – resaltada
                    _highlightedNoteComposer(cs),

                    const SizedBox(height: 12),
                    _cardLocal(context),
                    const SizedBox(height: 12),
                    _buildCitasCloud(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPsychologyAttentionSection(ColorScheme cs) {
    const accent = Color(0xFF8E24AA);

    Widget field(
      TextEditingController controller,
      String label, {
      TextInputType? keyboardType,
      int maxLines = 1,
    }) {
      return TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: const Color(0xFFF8F6FC),
        ),
      );
    }

    Widget fields(List<Widget> children) {
      return LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 520) {
            return Column(
              children: [
                for (final child in children) ...[
                  child,
                  if (child != children.last) const SizedBox(height: 10),
                ],
              ],
            );
          }

          final rows = <Widget>[];
          for (var i = 0; i < children.length; i += 2) {
            rows.add(
              Row(
                children: [
                  Expanded(child: children[i]),
                  if (i + 1 < children.length) ...[
                    const SizedBox(width: 10),
                    Expanded(child: children[i + 1]),
                  ] else
                    const Expanded(child: SizedBox.shrink()),
                ],
              ),
            );
            if (i + 2 < children.length) rows.add(const SizedBox(height: 10));
          }
          return Column(children: rows);
        },
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF8FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withOpacity(.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accent.withOpacity(.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.psychology_alt_outlined,
                    color: accent, size: 21),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Tipo de atencion psicologica',
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['Individual', 'Grupal', 'Colectiva'].map((type) {
              final selected = _tipoAtencionPsicologica == type;
              return ChoiceChip(
                label: Text(type),
                selected: selected,
                selectedColor: accent.withOpacity(.16),
                labelStyle: TextStyle(
                  color: selected ? accent : UAGroColors.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                ),
                onSelected: (_) {
                  setState(() => _tipoAtencionPsicologica = type);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          if (_tipoAtencionPsicologica == 'Individual')
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE8EAF3)),
              ),
              child: const Text(
                'La atencion individual usa el flujo actual y queda ligada a la matricula del expediente.',
                style: TextStyle(
                  color: UAGroColors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            )
          else if (_tipoAtencionPsicologica == 'Grupal')
            fields([
              field(_psicoEscuela, 'Escuela / Unidad Academica *'),
              field(_psicoGrupo, 'Grupo *'),
              field(
                _psicoParticipantes,
                'Participantes aproximados *',
                keyboardType: TextInputType.number,
              ),
              field(_psicoTema, 'Tema de la sesion *'),
            ])
          else
            fields([
              field(_psicoPoblacion, 'Poblacion atendida *', maxLines: 2),
              field(
                _psicoParticipantes,
                'Participantes aproximados *',
                keyboardType: TextInputType.number,
              ),
              field(_psicoTema, 'Tema de la actividad *'),
              field(_psicoLugar, 'Lugar o contexto'),
            ]),
        ],
      ),
    );
  }

  // =============== NUEVA NOTA UI DESTACADA ================

  Widget _highlightedNoteComposer(ColorScheme cs) {
    final isNutricion = _deptChoice == 'Consultorio de Nutrición';
    final isPsicologia = _isPsychologyAttention;
    final isOtra = _deptChoice == 'Otra';
    final requiereDx = (!isPsicologia ||
            _tipoAtencionPsicologica == 'Individual') &&
        !((_deptChoice == 'Otra') || (_deptChoice == 'Atención estudiantil'));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: UAGroColors.blue.withOpacity(.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          )
        ],
        border: Border.all(color: const Color(0xFFE3E8F2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Encabezado
          Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: UAGroColors.blue.withOpacity(.08),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(Icons.assignment_outlined,
                      color: UAGroColors.blue, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nueva nota de atención',
                        style: TextStyle(
                          color: UAGroColors.blue,
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Registra diagnóstico, tratante y seguimiento clínico.',
                        style: TextStyle(
                          color: UAGroColors.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9EEF8),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  child: const Text(
                    'Obligatoria*',
                    style: TextStyle(
                      color: UAGroColors.blue,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Contenido
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Datos de la atención',
                  style: TextStyle(
                    color: UAGroColors.blue,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                // Departamento / área
                DropdownButtonFormField<String>(
                  value: _deptChoice,
                  items: _deptOpciones
                      .map((e) =>
                          DropdownMenuItem<String>(value: e, child: Text(e)))
                      .toList(),
                  decoration: const InputDecoration(
                      labelText: 'Departamento / área *',
                      border: OutlineInputBorder()),
                  onChanged: (v) => setState(() {
                    _deptChoice = v;
                  }),
                ),
                if (isOtra) ...[
                  const SizedBox(height: 12),
                  TextField(
                      controller: _depto,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                          labelText: 'Especifica otra área *')),
                ],
                const SizedBox(height: 12),

                // Tratante
                TextField(
                    controller: _tratante,
                    decoration: const InputDecoration(labelText: 'Tratante *')),
                const SizedBox(height: 12),

                // Diagnóstico (condicional)
                if (requiereDx) ...[
                  TextField(
                      controller: _diagnostico,
                      decoration:
                          const InputDecoration(labelText: 'Diagnóstico *')),
                  const SizedBox(height: 12),
                ],

                // Tipo de consulta
                DropdownButtonFormField<String>(
                  value: _tipoConsulta,
                  items: const [
                    DropdownMenuItem(
                        value: 'Primera vez', child: Text('Primera vez')),
                    DropdownMenuItem(
                        value: 'Subsecuente', child: Text('Subsecuente')),
                  ],
                  decoration: const InputDecoration(
                      labelText: 'Consulta *', border: OutlineInputBorder()),
                  onChanged: (v) => setState(() => _tipoConsulta = v),
                ),
                const SizedBox(height: 14),

                if (isPsicologia) ...[
                  _buildPsychologyAttentionSection(cs),
                  const SizedBox(height: 14),
                ],

                // Nutrición: bloque extra
                if (isNutricion) ...[
                  const Divider(height: 24),
                  Text('Datos antropométricos (Nutrición)',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface.withOpacity(.9))),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _peso,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration:
                              const InputDecoration(labelText: 'Peso (kg)'),
                          onChanged: (_) => _refresh(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _talla,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration:
                              const InputDecoration(labelText: 'Talla (m)'),
                          onChanged: (_) => _refresh(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _cintura,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: const InputDecoration(
                              labelText: 'Cintura abdominal (cm)'),
                          onChanged: (_) => _refresh(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _cadera,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration:
                              const InputDecoration(labelText: 'Cadera (cm)'),
                          onChanged: (_) => _refresh(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Builder(
                    builder: (_) {
                      final imc =
                          _imcVal == null ? 'N/A' : _imcVal!.toStringAsFixed(2);
                      final icc =
                          _iccVal == null ? 'N/A' : _iccVal!.toStringAsFixed(2);
                      return Text(
                          'IMC: $imc    ·    Índice Cintura/Cadera: $icc',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface.withOpacity(.9)));
                    },
                  ),
                  const Divider(height: 24),
                ],

                // Psicología: tests psicológicos disponibles
                if (isPsicologia &&
                    _tipoAtencionPsicologica == 'Individual') ...[
                  const Divider(height: 24),
                  Row(
                    children: [
                      Icon(Icons.psychology,
                          color: theme.UAGroColors.azulMarino, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Tests Psicológicos',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface.withOpacity(.9),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 2,
                    color: theme.UAGroColors.azulMarino.withOpacity(0.05),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Instrumentos de evaluación disponibles:',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: cs.onSurface.withOpacity(.8),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () async {
                              // Verificar que haya una matrícula para asociar el test
                              final matricula = _mat.text.trim();
                              if (matricula.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Ingresa una matrícula para aplicar el test'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                return;
                              }

                              // Obtener nombre del paciente si existe
                              String nombrePaciente = 'Paciente';
                              if (_expedienteLocal != null) {
                                nombrePaciente =
                                    _expedienteLocal!.nombreCompleto;
                              } else if (_expedienteCloud != null &&
                                  _expedienteCloud!['nombreCompleto'] != null) {
                                nombrePaciente =
                                    _expedienteCloud!['nombreCompleto'];
                              }

                              // Navegar a la pantalla de selección de tests
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => TestSelectionScreen(
                                    matricula: matricula,
                                    nombrePaciente: nombrePaciente,
                                    db: widget.db,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.assignment),
                            label: const Text('Aplicar Tests Psicológicos'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.UAGroColors.azulMarino,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '• Test de Hamilton (Depresión)\n'
                            '• Test de Beck (Ansiedad)\n'
                            '• Test DASS-21 (Depresión, Ansiedad, Estrés)',
                            style: TextStyle(
                              fontSize: 13,
                              color: cs.onSurface.withOpacity(.6),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 24),
                ],

                // Sección específica de Odontología: Odontograma - Versión discreta
                if (_deptChoice == 'Consultorio de Odontología') ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.UAGroColors.azulMarino.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.UAGroColors.azulMarino.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:
                                theme.UAGroColors.azulMarino.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(Icons.medical_information_outlined,
                              color: theme.UAGroColors.azulMarino, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Odontograma Profesional',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: theme.UAGroColors.azulMarino,
                                ),
                              ),
                              Text(
                                '32 dientes • FDI • Diagnóstico por superficie • PDF',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: cs.onSurface.withOpacity(.55),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () async {
                            // Verificar que haya una matrícula
                            final matricula = _mat.text.trim();
                            if (matricula.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Ingresa una matrícula para crear el odontograma'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                              return;
                            }

                            // Obtener nombre del paciente
                            String nombrePaciente = 'Paciente';
                            if (_expedienteLocal != null) {
                              nombrePaciente = _expedienteLocal!.nombreCompleto;
                            } else if (_expedienteCloud != null &&
                                _expedienteCloud!['nombreCompleto'] != null) {
                              nombrePaciente =
                                  _expedienteCloud!['nombreCompleto'];
                            }

                            // Navegar a la pantalla del odontograma
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => OdontogramScreen(
                                  matricula: matricula,
                                  nombrePaciente: nombrePaciente,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.create, size: 18),
                          label: const Text('Crear'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.UAGroColors.azulMarino,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            textStyle: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                const Text(
                  'Descripción de la atención',
                  style: TextStyle(
                    color: UAGroColors.blue,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 10),
                // Cuerpo de la nota
                TextField(
                  controller: _cuerpo,
                  focusNode: _noteFocus,
                  minLines: 4,
                  maxLines: 6,
                  decoration:
                      const InputDecoration(labelText: 'Cuerpo de la nota *'),
                ),
                const SizedBox(height: 14),

                // Adjuntar (OPCIONAL) + Agendar cita + Mostrar citas
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.start,
                  children: [
                    FilledButton.icon(
                      onPressed: _pickAdjuntos,
                      icon: const Icon(Icons.attach_file),
                      label: const Text('Adjuntar archivo(s) (opcional)'),
                    ),
                    ElevatedButton.icon(
                      onPressed: _agendarCita,
                      icon: const Icon(Icons.calendar_today),
                      label: const Text('Agendar cita'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade100,
                        foregroundColor: Colors.teal.shade700,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _mostrarCitas,
                      icon: const Icon(Icons.list),
                      label: const Text('Mostrar citas'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blue.shade600,
                      ),
                    ),
                  ],
                ),
                if (_adjuntos.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child:
                        Text('${_adjuntos.length} adjunto(s) seleccionado(s)'),
                  ),

                if (_adjuntos.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _adjuntos.map((f) {
                      return Chip(
                        label: Text(f.name, overflow: TextOverflow.ellipsis),
                        onDeleted: () {
                          setState(() {
                            _adjuntos.remove(f);
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 16),
                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _guardandoNota ? null : _guardarNota,
                    style: FilledButton.styleFrom(
                      backgroundColor: UAGroColors.blue,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: _guardandoNota
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label:
                        Text(_guardandoNota ? 'Guardando...' : 'Guardar nota'),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: (_cargando || _guardandoNota)
                      ? null
                      : _sincronizarNotasPendientes,
                  icon: const Icon(Icons.sync),
                  label: const Text('Sincronizar notas pendientes'),
                ),
                const SizedBox(height: 4),
                Text(
                  'Campos obligatorios marcados con *. Los adjuntos son opcionales.',
                  style: TextStyle(
                      fontSize: 12, color: cs.onSurface.withOpacity(.6)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Widget para mostrar las citas del cloud
  Widget _buildCitasCloud() {
    if (_cargandoCitas) {
      return SectionCard(
        icon: Icons.event,
        title: 'Citas del Cloud',
        child: const Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 8),
            Text('Cargando citas del cloud...'),
          ],
        ),
      );
    }

    if (_errorCitas != null) {
      return SectionCard(
        icon: Icons.event,
        title: 'Citas del Cloud',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No fue posible cargar las citas.',
              style: TextStyle(
                color: Colors.red.shade600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (_citasCloud.isEmpty) {
      return SectionCard(
        icon: Icons.event,
        title: 'Citas del Cloud (0)',
        child: Text(
          'No hay citas para esta matrícula.',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
      );
    }

    // Debug temporal para confirmar claves
    if (_citasCloud.isNotEmpty) {
      print('[CITAS_KEYS] ${_citasCloud.first.keys.toList()}');
    }

    // Ordenar por inicio descendente
    final list = [..._citasCloud];
    list.sort((a, b) {
      final da = _parseIso(_str(a, 'inicio'));
      final db = _parseIso(_str(b, 'inicio'));
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return db.compareTo(da);
    });

    return SectionCard(
      icon: Icons.event,
      title: 'Citas del Cloud (${list.length})',
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = list[index];
          final motivo = _str(item, 'motivo');
          final dtIni = _parseIso(_str(item, 'inicio'));
          final (fecha, hora) = _fmtFechaHora(dtIni);
          final dep = _str(item, 'departamento');
          final est = _str(item, 'estado');

          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.shade300,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Icono izquierdo
                Icon(
                  Icons.event,
                  size: 18,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 12),
                // Contenido principal
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        motivo.isEmpty ? 'Sin asunto' : motivo,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Fecha: $fecha',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      Text(
                        'Hora: $hora',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      if (dep.isNotEmpty)
                        Text(
                          'Departamento: $dep',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                    ],
                  ),
                ),
                // Chip de estado a la derecha
                if (est.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _estadoColor(est),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      est,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: _estadoTextColor(est),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Helpers locales para citas
  String _str(Map m, String k) {
    final v = m[k];
    return (v == null) ? '' : v.toString().trim();
  }

  DateTime? _parseIso(String s) {
    if (s.isEmpty) return null;
    try {
      return DateTime.parse(s).toLocal();
    } catch (_) {
      return null;
    }
  }

  String _two(int n) => n < 10 ? '0$n' : '$n';

  (String, String) _fmtFechaHora(DateTime? dt) {
    if (dt == null) return ('No especificada', 'No especificada');
    final f = '${dt.year}-${_two(dt.month)}-${_two(dt.day)}';
    final h = '${_two(dt.hour)}:${_two(dt.minute)}';
    return (f, h);
  }

  Color _estadoColor(String estado) {
    final est = estado.toLowerCase();
    if (est.contains('programada')) return Colors.blue.shade100;
    if (est.contains('cancelada')) return Colors.red.shade100;
    if (est.contains('realizada') || est.contains('completada'))
      return Colors.green.shade100;
    return Colors.grey.shade100;
  }

  Color _estadoTextColor(String estado) {
    final est = estado.toLowerCase();
    if (est.contains('programada')) return Colors.blue.shade700;
    if (est.contains('cancelada')) return Colors.red.shade700;
    if (est.contains('realizada') || est.contains('completada'))
      return Colors.green.shade700;
    return Colors.grey.shade700;
  }
}

class _StudentSearchResult {
  final String nombre;
  final String matricula;
  final String escuelaUnidadAcademica;
  final String grupo;
  final String campus;
  final String source;

  const _StudentSearchResult({
    required this.nombre,
    required this.matricula,
    required this.escuelaUnidadAcademica,
    required this.grupo,
    required this.campus,
    required this.source,
  });

  factory _StudentSearchResult.fromLocal(DB.HealthRecord record) {
    return _StudentSearchResult(
      nombre: _clean(record.nombreCompleto, fallback: 'Sin nombre'),
      matricula: _clean(record.matricula),
      escuelaUnidadAcademica: _clean(
        record.escuelaUnidadAcademica,
        fallback: 'No especificada',
      ),
      grupo: _clean(record.grupo),
      campus: _clean(
        record.escuelaUnidadAcademica,
        fallback: 'No especificado',
      ),
      source: 'Local',
    );
  }

  factory _StudentSearchResult.fromCloud(Map<String, dynamic> data) {
    final escuela = _read(data, const [
      'escuelaUnidadAcademica',
      'escuela_unidad_academica',
      'escuela',
      'unidadAcademica',
      'unidad_academica',
    ]);
    return _StudentSearchResult(
      nombre: _clean(
        _read(data, const [
          'nombreCompleto',
          'nombre_completo',
          'nombre',
          'fullName',
          'full_name',
          'name',
        ]),
        fallback: 'Sin nombre',
      ),
      matricula: _clean(_read(data, const [
        'matricula',
        'matr\u00edcula',
        'matricula_alumno',
        'numeroCuenta',
        'numero_cuenta',
        'studentId',
        'student_id',
      ])),
      escuelaUnidadAcademica: _clean(escuela, fallback: 'No especificada'),
      grupo: _clean(_read(data, const ['grupo', 'group'])),
      campus: _clean(
        _read(data, const ['campus', 'sede', 'plantel']),
        fallback: escuela.trim().isEmpty ? 'No especificado' : escuela,
      ),
      source: 'Nube',
    );
  }

  static String _read(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  static String _clean(String value, {String fallback = ''}) {
    final clean = value.trim();
    return clean.isEmpty ? fallback : clean;
  }
}

class _KpiData {
  final IconData icon;
  final String title;
  final int count;
  final String subtitle;
  final Color color;

  const _KpiData({
    required this.icon,
    required this.title,
    required this.count,
    required this.subtitle,
    required this.color,
  });
}

class _InstitutionalWaves extends StatelessWidget {
  final double width;

  const _InstitutionalWaves({required this.width});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: width * .44,
      child: Stack(
        children: [
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: width,
              height: width * .36,
              decoration: BoxDecoration(
                color: UAGroColors.blue,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(width * .45),
                ),
              ),
            ),
          ),
          Positioned(
            right: width * .05,
            top: width * .19,
            child: Container(
              width: width * .88,
              height: width * .08,
              decoration: BoxDecoration(
                color: UAGroColors.red,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Positioned(
            right: width * .02,
            top: width * .04,
            child: Container(
              width: width * .72,
              height: width * .18,
              decoration: BoxDecoration(
                color: const Color(0xFF0B8FDB).withOpacity(.82),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(width * .34),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
