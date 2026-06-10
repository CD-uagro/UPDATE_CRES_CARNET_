import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:drift/drift.dart' show Value, OrderingTerm, OrderingMode;
import '../data/db.dart';
import '../data/auth_service.dart';
import '../data/recent_activity_service.dart';
import '../data/sync_service.dart';
import '../data/cache_service.dart'; // Para invalidar caché después de guardar
// QUITA: import '../data/cloudant_query.dart';
import 'nueva_nota_screen.dart';
import 'package:cres_carnets_ibmcloud/ui/uagro_widgets.dart' hide SectionCard;
import '../data/api_service.dart'; // AGREGA esto para usar FastAPI
// Imports para diseño institucional UAGro
import '../ui/brand.dart';
import '../ui/app_theme.dart';
import '../ui/responsive.dart';
import '../ui/feedback.dart';

class FormScreen extends StatefulWidget {
  final AppDatabase db;
  final String? matriculaInicial; // Para precargar desde "Agregar notas"
  final bool lockMatricula; // Bloquea edición de matrícula
  final Map<String, dynamic>?
      carnetExistente; // Para precargar datos en edición

  const FormScreen({
    super.key,
    required this.db,
    this.matriculaInicial,
    this.lockMatricula = false,
    this.carnetExistente,
  });

  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  final _form = GlobalKey<FormState>();
  final _ctrl = <String, TextEditingController>{};

  String? _sexo;
  String? _categoria;
  String? _programa;
  String? _escuelaUnidadAcademica;
  String? _discapacidad;
  String? _tipoSangre;
  String? _unidadMedica;
  String? _usoSeguro;
  String? _donante;

  bool _lockMatricula = false;
  bool _guardandoCarnet = false;
  bool _busy = false;

  // Control de secciones expandidas
  bool _identidadExpandida = true;
  bool _academicosExpandida = false;
  bool _saludExpandida = false;
  bool _seguroExpandida = false;
  bool _emergenciaExpandida = false;

  // Catálogos
  static const List<String> kSexo = [
    'Femenino',
    'Masculino',
    'Otro',
    'Prefiero no decir'
  ];
  static const List<String> kCategoria = [
    'Administrativo e intendente',
    'Académico',
    'Alumno (a)',
    'Otra…'
  ];
  static const List<String> kPrograma = [
    'Ciencias Ambientales',
    'Ciencias de la Educación',
    'Cultura Física y Deporte',
    'Economía',
    'Nutrición',
    'Maestría en Economía Social',
    'Odontologia',
    'Educación Nivel Básico',
    'Coordinación CRES',
    'Otra…'
  ];
  static const String kEscuelaNoEspecificada = 'No especificada';
  static const String kProgramaNoAplica = 'No aplica';
  static const String kProgramaOtra = 'Otra…';
  static const List<String> kEscuelasUnidadAcademica = [
    kEscuelaNoEspecificada,
    'CRES Llano Largo',
    'Preparatoria No. 27',
    'Preparatoria No. 48',
    'Facultad de Medicina',
    'Facultad de Enfermería',
    'Facultad de Odontología',
    'Facultad de Derecho',
    'Facultad de Contaduría y Administración',
    'Facultad de Ciencias Químico Biológicas',
    'Otra',
  ];
  static const List<String> kSiNo_Mayus_SI = ['SI', 'No'];
  static const List<String> kSangre = [
    'O +',
    'O -',
    'A +',
    'A -',
    'B +',
    'B -',
    'AB +',
    'AB -',
    'Desconozco'
  ];
  static const List<String> kUnidad = [
    'Clínica IMSS',
    'ISSSTE',
    'Ninguno',
    'Otra…'
  ];
  static const List<String> kUsoSeguro = ['No', 'Sí', 'Otra…'];
  static const List<String> kSiNo_Acento = ['Sí', 'No'];

  @override
  void initState() {
    super.initState();
    for (final k in [
      'matricula',
      'nombre',
      'correo',
      'edad',
      'alergias',
      'enfermedad',
      'numero_afiliacion',
      'emergencia_tel',
      'emergencia_contacto',
      'categoria_otra',
      'programa_otra',
      'grupo',
      'unidad_otra',
      'uso_otra',
      'expediente_notas',
      'tipo_discapacidad',
    ]) {
      _ctrl[k] = TextEditingController();
    }

    if (widget.matriculaInicial != null &&
        widget.matriculaInicial!.trim().isNotEmpty) {
      _ctrl['matricula']!.text = widget.matriculaInicial!.trim();
    }
    _lockMatricula = widget.lockMatricula;

    // Precargar datos de carnet existente si se proporcionan
    if (widget.carnetExistente != null) {
      _cargarDatosExistentes(widget.carnetExistente!);
    } else if (_ctrl['matricula']!.text.isNotEmpty) {
      _precargarCarnet(_ctrl['matricula']!.text);
    }
  }

  @override
  void dispose() {
    for (final c in _ctrl.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ---------- Precarga de datos existentes ----------
  void _cargarDatosExistentes(Map<String, dynamic> carnet) {
    print('[DEBUG] Cargando datos existentes: $carnet');
    print('[DEBUG] ID del carnet: ${carnet['id']}');

    // Cargar campos de texto (usando nombres correctos del backend)
    _ctrl['matricula']?.text = carnet['matricula']?.toString() ?? '';
    _ctrl['nombre']?.text = carnet['nombreCompleto']?.toString() ?? '';
    _ctrl['correo']?.text = carnet['correo']?.toString() ?? '';
    _ctrl['edad']?.text = carnet['edad']?.toString() ?? '';
    _ctrl['alergias']?.text = carnet['alergias']?.toString() ?? '';
    _ctrl['enfermedad']?.text = carnet['enfermedadCronica']?.toString() ?? '';
    _ctrl['numero_afiliacion']?.text =
        carnet['numeroAfiliacion']?.toString() ?? '';
    _ctrl['emergencia_tel']?.text =
        carnet['emergenciaTelefono']?.toString() ?? '';
    _ctrl['emergencia_contacto']?.text =
        carnet['emergenciaContacto']?.toString() ?? '';
    _ctrl['expediente_notas']?.text =
        carnet['expedienteNotas']?.toString() ?? '';
    _ctrl['tipo_discapacidad']?.text =
        carnet['tipoDiscapacidad']?.toString() ?? '';
    _ctrl['grupo']?.text = carnet['grupo']?.toString() ?? '';

    // Cargar dropdowns/selects (usando nombres correctos del backend)
    _sexo = carnet['sexo']?.toString();
    _categoria = carnet['categoria']?.toString();
    _setEscuelaDesdeValor(carnet['escuelaUnidadAcademica']?.toString());
    _setProgramaDesdeValor(carnet['programa']?.toString());
    _discapacidad = _normalizeDropdownValue(
        carnet['discapacidad']?.toString(), kSiNo_Acento);
    _tipoSangre = carnet['tipoSangre']?.toString();
    _unidadMedica = carnet['unidadMedica']?.toString();
    _usoSeguro = carnet['usoSeguroUniversitario']?.toString();
    _donante =
        _normalizeDropdownValue(carnet['donante']?.toString(), kSiNo_Acento);

    print(
        '[DEBUG] Datos cargados - Nombre: ${_ctrl['nombre']?.text}, Edad: ${_ctrl['edad']?.text}');
    print(
        '[DEBUG] Dropdown values - Discapacidad: $_discapacidad, Donante: $_donante');
  }

  // Método auxiliar para normalizar valores de dropdown
  String? _normalizeDropdownValue(String? value, List<String> allowedValues) {
    if (value == null || value.isEmpty) return null;

    // Normalizar valores comunes
    final normalized = value.toLowerCase().trim();

    for (String allowed in allowedValues) {
      if (allowed.toLowerCase().replaceAll('í', 'i').replaceAll('ó', 'o') ==
          normalized.replaceAll('í', 'i').replaceAll('ó', 'o')) {
        return allowed;
      }
    }

    // Si no encuentra coincidencia, intentar mapeo directo
    switch (normalized) {
      case 'si':
        return allowedValues.contains('Sí') ? 'Sí' : 'Si';
      case 'no':
        return allowedValues.contains('No') ? 'No' : 'no';
      default:
        return allowedValues.contains(value) ? value : null;
    }
  }

  // ---------- Navegación entre secciones ----------
  // ignore: unused_element
  void _expandirSiguienteSeccion() {
    setState(() {
      if (_identidadExpandida && !_academicosExpandida) {
        _academicosExpandida = true;
      } else if (_academicosExpandida && !_saludExpandida) {
        _saludExpandida = true;
      } else if (_saludExpandida && !_seguroExpandida) {
        _seguroExpandida = true;
      } else if (_seguroExpandida && !_emergenciaExpandida) {
        _emergenciaExpandida = true;
      }
    });
  }

  // Helper para operaciones con loader
  Future<T> runWithLoader<T>(Future<T> Function() op) async {
    if (mounted) setState(() => _busy = true);
    try {
      return await op();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // Helper para layout responsivo
  Widget twoCols(Widget left, Widget right) {
    final mobile = isMobile(context);
    if (mobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [left, const SizedBox(height: 12), right],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 24),
        Expanded(child: right)
      ],
    );
  }

  void _alternarSeccion(String seccion, bool expandir) {
    setState(() {
      switch (seccion) {
        case 'identidad':
          _identidadExpandida = expandir;
          break;
        case 'academicos':
          _academicosExpandida = expandir;
          break;
        case 'salud':
          _saludExpandida = expandir;
          break;
        case 'seguro':
          _seguroExpandida = expandir;
          break;
        case 'emergencia':
          _emergenciaExpandida = expandir;
          break;
      }
    });
  }

  // ---------- Normalización y matching “inteligente” ----------
  String _normalize(String? s,
      {bool removeSpaces = false, bool toUpper = false}) {
    if (s == null) return '';
    var t = s.trim();
    const from = 'áéíóúÁÉÍÓÚñÑ';
    const to = 'aeiouAEIOUnN';
    for (int i = 0; i < from.length; i++) {
      t = t.replaceAll(from[i], to[i]);
    }
    if (removeSpaces) t = t.replaceAll(' ', '');
    if (toUpper) t = t.toUpperCase();
    return t;
  }

  String? _pickAllowed(String? raw, List<String> allowed,
      {bool removeSpaces = false, bool forceUpperCompare = false}) {
    final normRaw =
        _normalize(raw, removeSpaces: removeSpaces, toUpper: forceUpperCompare);
    for (final a in allowed) {
      final normA =
          _normalize(a, removeSpaces: removeSpaces, toUpper: forceUpperCompare);
      if (normA == normRaw) return a;
    }
    if (allowed.contains('Sí')) {
      if (normRaw == 'SI' ||
          normRaw == 'SÍ' ||
          normRaw == 'SI.' ||
          normRaw == 'S') {
        return 'Sí';
      }
    }
    if (allowed.contains('SI')) {
      if (normRaw == 'SI' ||
          normRaw == 'SÍ' ||
          normRaw == 'SI.' ||
          normRaw == 'S') {
        return 'SI';
      }
    }
    if (allowed.contains('No')) {
      if (normRaw == 'NO' || normRaw == 'N' || normRaw == 'NO.') return 'No';
    }
    if (allowed.contains('Desconozco')) {
      if (normRaw == 'DESCONOZCO' || normRaw == 'DESCONOCIDO')
        return 'Desconozco';
    }
    return null;
  }

  bool _programaDebeSerNoAplica(String? escuela) {
    return escuela == 'Preparatoria No. 27' ||
        escuela == 'Preparatoria No. 48' ||
        (escuela?.startsWith('Facultad') ?? false);
  }

  List<String> get _programasDisponibles {
    if (_programaDebeSerNoAplica(_escuelaUnidadAcademica)) {
      return const [kProgramaNoAplica];
    }
    return kPrograma;
  }

  bool get _mostrarProgramaOtra =>
      _programa == kProgramaOtra &&
      !_programaDebeSerNoAplica(_escuelaUnidadAcademica);

  void _normalizarProgramaPorEscuela() {
    if (_programaDebeSerNoAplica(_escuelaUnidadAcademica)) {
      _programa = kProgramaNoAplica;
      _ctrl['programa_otra']?.clear();
      return;
    }

    if (_programa == kProgramaNoAplica) {
      _programa = null;
    }
  }

  void _onEscuelaChanged(String? value) {
    setState(() {
      _escuelaUnidadAcademica = value;
      _normalizarProgramaPorEscuela();
    });
  }

  void _onProgramaChanged(String? value) {
    setState(() => _programa = value);
  }

  void _setEscuelaDesdeValor(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) {
      _escuelaUnidadAcademica = kEscuelaNoEspecificada;
      return;
    }
    _escuelaUnidadAcademica =
        _pickAllowed(value, kEscuelasUnidadAcademica) ?? kEscuelaNoEspecificada;
  }

  void _setProgramaDesdeValor(String? raw) {
    final value = raw?.trim();
    if (_programaDebeSerNoAplica(_escuelaUnidadAcademica)) {
      _programa = kProgramaNoAplica;
      _ctrl['programa_otra']?.clear();
      return;
    }
    if (value == null || value.isEmpty) {
      _programa = null;
      return;
    }
    final allowed = _pickAllowed(value, kPrograma);
    if (allowed != null) {
      _programa = allowed;
      return;
    }
    _programa = kProgramaOtra;
    _ctrl['programa_otra']?.text = value;
  }

  String _escuelaValueForSave() {
    final value = _escuelaUnidadAcademica?.trim();
    return value == null || value.isEmpty ? kEscuelaNoEspecificada : value;
  }

  String _grupoValueForSave() => _ctrl['grupo']?.text.trim() ?? '';

  String _programaValueForSave() {
    if (_programaDebeSerNoAplica(_escuelaUnidadAcademica)) {
      return kProgramaNoAplica;
    }
    if (_programa == kProgramaOtra) {
      return _ctrl['programa_otra']!.text.trim();
    }
    return _programa ?? '';
  }

  // ---------- Data helpers ----------
  Future<void> _precargarCarnet(String m) async {
    try {
      final local = await _getRecordByMatricula(m);
      if (local != null) {
        _ctrl['nombre']!.text = local.nombreCompleto;
        _ctrl['correo']!.text = local.correo;
        _ctrl['edad']!.text = (local.edad ?? '').toString();

        _sexo = _pickAllowed(local.sexo, kSexo);
        _categoria = _pickAllowed(local.categoria, kCategoria);
        _setEscuelaDesdeValor(local.escuelaUnidadAcademica);
        _setProgramaDesdeValor(local.programa);
        _ctrl['grupo']!.text = local.grupo;
        _discapacidad = _pickAllowed(local.discapacidad, kSiNo_Mayus_SI,
            forceUpperCompare: true);
        _ctrl['tipo_discapacidad']!.text = local.tipoDiscapacidad ?? '';
        _ctrl['alergias']!.text = local.alergias ?? '';
        _tipoSangre =
            _pickAllowed(local.tipoSangre, kSangre, removeSpaces: true);
        _ctrl['enfermedad']!.text = local.enfermedadCronica ?? '';
        _unidadMedica = _pickAllowed(local.unidadMedica, kUnidad);
        _ctrl['numero_afiliacion']!.text = local.numeroAfiliacion ?? '';
        _usoSeguro = _pickAllowed(local.usoSeguroUniversitario, kUsoSeguro);
        _donante = _pickAllowed(local.donante, kSiNo_Acento);
        _ctrl['emergencia_tel']!.text = local.emergenciaTelefono ?? '';
        _ctrl['emergencia_contacto']!.text = local.emergenciaContacto ?? '';
        setState(() {});
        return;
      }

      // ===== NUBE: precarga por matrícula usando FASTAPI =====
      try {
        final pac = await ApiService.getExpedienteByMatricula(m);
        if (pac != null) {
          _ctrl['nombre']!.text = (pac['nombreCompleto'] ?? '') as String;
          _ctrl['correo']!.text = (pac['correo'] ?? '') as String;
          _ctrl['edad']!.text = '${pac['edad'] ?? ''}';

          _sexo = _pickAllowed(pac['sexo'] as String?, kSexo);
          _categoria = _pickAllowed(pac['categoria'] as String?, kCategoria);
          _setEscuelaDesdeValor(pac['escuelaUnidadAcademica']?.toString());
          _setProgramaDesdeValor(pac['programa']?.toString());
          _ctrl['grupo']!.text = pac['grupo']?.toString() ?? '';
          _discapacidad = _pickAllowed(
              pac['discapacidad'] as String?, kSiNo_Mayus_SI,
              forceUpperCompare: true);

          _ctrl['tipo_discapacidad']!.text =
              (pac['tipoDiscapacidad'] ?? '') as String;
          _ctrl['alergias']!.text = (pac['alergias'] ?? '') as String;
          _tipoSangre = _pickAllowed(pac['tipoSangre'] as String?, kSangre,
              removeSpaces: true);
          _ctrl['enfermedad']!.text =
              (pac['enfermedadCronica'] ?? '') as String;
          _unidadMedica = _pickAllowed(pac['unidadMedica'] as String?, kUnidad);
          _ctrl['numero_afiliacion']!.text =
              (pac['numeroAfiliacion'] ?? '') as String;
          _usoSeguro = _pickAllowed(
              pac['usoSeguroUniversitario'] as String?, kUsoSeguro);
          _donante = _pickAllowed(pac['donante'] as String?, kSiNo_Acento);
          _ctrl['emergencia_tel']!.text =
              (pac['emergenciaTelefono'] ?? '') as String;
          _ctrl['emergencia_contacto']!.text =
              (pac['emergenciaContacto'] ?? '') as String;
          setState(() {});
        }
      } catch (_) {}
    } catch (_) {}
  }

  Future<HealthRecord?> _getRecordByMatricula(String m) async {
    final q = widget.db.select(widget.db.healthRecords)
      ..where((t) => t.matricula.equals(m))
      ..orderBy([
        (t) => OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc)
      ])
      ..limit(1);
    final list = await q.get();
    return list.isEmpty ? null : list.first;
  }

  Future<int> _upsertRecord(HealthRecordsCompanion data) async {
    // 1. Guardar local primero
    final existing = await _getRecordByMatricula(data.matricula.value);
    int recordId;

    if (existing == null) {
      recordId = await widget.db.into(widget.db.healthRecords).insert(data);
    } else {
      recordId = (await (widget.db.update(widget.db.healthRecords)
                    ..where((t) => t.id.equals(existing.id)))
                  .write(HealthRecordsCompanion(
                timestamp: data.timestamp,
                matricula: Value(existing.matricula),
                nombreCompleto: data.nombreCompleto,
                correo: data.correo,
                edad: data.edad,
                sexo: data.sexo,
                categoria: data.categoria,
                programa: data.programa,
                escuelaUnidadAcademica: data.escuelaUnidadAcademica,
                grupo: data.grupo,
                discapacidad: data.discapacidad,
                tipoDiscapacidad: data.tipoDiscapacidad,
                alergias: data.alergias,
                tipoSangre: data.tipoSangre,
                enfermedadCronica: data.enfermedadCronica,
                unidadMedica: data.unidadMedica,
                numeroAfiliacion: data.numeroAfiliacion,
                usoSeguroUniversitario: data.usoSeguroUniversitario,
                donante: data.donante,
                emergenciaTelefono: data.emergenciaTelefono,
                emergenciaContacto: data.emergenciaContacto,
                expedienteNotas: data.expedienteNotas,
                expedienteAdjuntos: data.expedienteAdjuntos,
                synced: const Value(false),
              ))) >
              0
          ? existing.id
          : 0;
    }

    // 2. Intentar sincronizar con la nube
    try {
      final carnetData = {
        'matricula': data.matricula.value,
        'nombreCompleto': data.nombreCompleto.value,
        'correo': data.correo.value,
        'edad': data.edad.value,
        'sexo': data.sexo.value,
        'categoria': data.categoria.value,
        'programa': data.programa.value,
        'escuelaUnidadAcademica': data.escuelaUnidadAcademica.value,
        'grupo': data.grupo.value,
        'discapacidad': data.discapacidad.value,
        'tipoDiscapacidad': data.tipoDiscapacidad.value,
        'alergias': data.alergias.value,
        'tipoSangre': data.tipoSangre.value,
        'enfermedadCronica': data.enfermedadCronica.value,
        'unidadMedica': data.unidadMedica.value,
        'numeroAfiliacion': data.numeroAfiliacion.value,
        'usoSeguroUniversitario': data.usoSeguroUniversitario.value,
        'donante': data.donante.value,
        'emergenciaTelefono': data.emergenciaTelefono.value,
        'emergenciaContacto': data.emergenciaContacto.value,
        'expedienteNotas': data.expedienteNotas.value,
        'expedienteAdjuntos': data.expedienteAdjuntos.value,
      };

      // IMPORTANTE: Si estamos editando un carnet existente, incluir su ID
      if (widget.carnetExistente != null &&
          widget.carnetExistente!['id'] != null) {
        carnetData['id'] = widget.carnetExistente!['id'];
        print(
            '[SYNC] Editando carnet existente con ID: ${widget.carnetExistente!['id']}');
      } else {
        print('[SYNC] Creando nuevo carnet (sin ID)');
      }

      print('[SYNC] Payload completo a enviar: $carnetData');
      final cloudOk = await ApiService.pushSingleCarnet(carnetData);
      print('[SYNC] ===== RESULTADO SYNC ANÁLISIS DETALLADO =====');
      print('[SYNC] cloudOk devuelto por API: $cloudOk');
      print('[SYNC] Tipo de cloudOk: ${cloudOk.runtimeType}');
      print('[SYNC] cloudOk == true: ${cloudOk == true}');
      print('[SYNC] ==============================================');

      if (cloudOk) {
        // Marcar como sincronizado si fue exitoso
        await widget.db.markRecordAsSynced(recordId);
        // 🚀 Invalidar caché para que próxima búsqueda obtenga datos frescos
        await CacheService.invalidateCarnet(data.matricula.value);
        print('[SYNC] Carnet guardado y sincronizado: ${data.matricula.value}');
      } else {
        print(
            '[SYNC] ℹ️ Carnet guardado localmente, pendiente de sincronización');
      }

      if (mounted) {
        if (cloudOk) {
          showOk(context, 'Carnet guardado y sincronizado con la nube');
        } else {
          showOk(context,
              'Carnet guardado localmente\n(Se sincronizará cuando haya internet)');
        }
      }
    } catch (e) {
      print('[SYNC] Error al sincronizar carnet ${data.matricula.value}: $e');
      if (mounted) {
        showErr(context,
            'Guardado local OK - Error: ${e.toString().length > 30 ? e.toString().substring(0, 30) + "..." : e.toString()}');
      }
    }

    return recordId;
  }

  Future<void> _recordRecentCarnetActivity(String accion) async {
    try {
      final user = await AuthService.getCurrentUser();
      if (user == null) return;

      final area = user.departamento.trim().isNotEmpty
          ? user.departamento
          : AuthService.formatRoleName(user.rol);

      await RecentActivityService.recordPatientActivity(
        user: user,
        matricula: _ctrl['matricula']?.text.trim() ?? '',
        nombreCompleto: _ctrl['nombre']?.text.trim() ?? '',
        areaResponsable: area,
        accion: accion,
      );
    } catch (e, st) {
      debugPrint('No se pudo registrar actividad reciente de carnet: $e\n$st');
    }
  }

  // ---------- LIMPIAR: ahora SIEMPRE borra TODO Y DESBLOQUEA MATRÍCULA ----------
  Future<void> _confirmAndReset() async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Limpiar formulario'),
        content:
            const Text('¿Desea limpiar TODOS los campos del carnet actual?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sí, limpiar'),
          ),
        ],
      ),
    );

    if (sure == true) {
      _resetAll();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Formulario limpiado')),
      );
    }
  }

  void _resetAll() {
    _form.currentState?.reset();
    setState(() {
      _sexo = _categoria = _programa = _discapacidad =
          _tipoSangre = _unidadMedica = _usoSeguro = _donante = null;
      _escuelaUnidadAcademica = null;
      _lockMatricula =
          false; // ✅ desbloquear siempre para poder iniciar nuevo proceso
    });
    _ctrl.forEach((k, c) => c.clear());
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final mobile = isMobile(context);
    // Detectar plataforma: SOLO mostrar franja en Windows/Mac/Linux (NO en Android/iOS)
    final isMobilePlatform = Platform.isAndroid || Platform.isIOS;
    final showBanner =
        !isMobilePlatform && MediaQuery.sizeOf(context).width >= 1200;

    return Scaffold(
      appBar: uagroAppBar(
          'CRES Carnets', 'Rellenar / Editar carnet', null, context, widget.db),
      body: Stack(
        children: [
          SafeArea(
            child: LayoutBuilder(
              builder: (context, _) {
                if (MediaQuery.sizeOf(context).width >= 0) {
                  return _buildCarnetWorkspace(context, mobile);
                }
                if (showBanner) {
                  // PC Windows/Mac/Linux: mantener layout con franja
                  return Column(
                    children: [
                      // Franja superior institucional UAGro (NUNCA en Android/iOS)
                      Container(
                        width: double.infinity,
                        height: 80,
                        decoration: const BoxDecoration(
                          color: UAGroColors.blue,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 16),
                          child: Row(
                            children: [
                              // Logo UAGro a la izquierda
                              maybeUAGroLogo(size: 48),
                              const SizedBox(width: 16),
                              // Información institucional
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'Universidad Autónoma de Guerrero',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      'SASU - Sistema de Atención en Salud Universitaria',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Contenido principal (sin cambios de lógica)
                      Expanded(
                        child: SafeArea(
                          child: SingleChildScrollView(
                            padding: AppTheme.contentPadding,
                            child: Form(
                              key: _form,
                              // NO CAMBIAR LÓGICA: mantener callbacks/estados intactos
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Carnet universitario — Captura',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge,
                                      ),
                                      const Spacer(),
                                      OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          minimumSize: const Size(0, 32),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 6),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                        onPressed: _confirmAndReset,
                                        icon:
                                            const Icon(Icons.refresh, size: 18),
                                        label: const Text('Limpiar',
                                            style: TextStyle(fontSize: 12)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  // Indicador de progreso de guardado
                                  if (_guardandoCarnet)
                                    LinearProgressIndicator(
                                      color: UAGroColors.blue,
                                      backgroundColor:
                                          UAGroColors.blue.withOpacity(0.2),
                                    ),
                                  const SizedBox(height: 8),

                                  // Sección 1: Identidad
                                  _buildSeccionExpandible(
                                    'identidad',
                                    'Información de Identidad',
                                    Icons.person,
                                    _identidadExpandida,
                                    [
                                      Row(children: [
                                        Expanded(
                                          child: _field(
                                              'Matrícula', _ctrl['matricula']!,
                                              required: true,
                                              enabled: !_lockMatricula),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _field('Nombre completo',
                                              _ctrl['nombre']!,
                                              required: true),
                                        ),
                                      ]),
                                      const SizedBox(height: 12),
                                      Row(children: [
                                        Expanded(
                                            child: _field(
                                                'Correo', _ctrl['correo']!,
                                                required: true,
                                                type: TextInputType
                                                    .emailAddress)),
                                        const SizedBox(width: 12),
                                        Expanded(
                                            child: _field(
                                                'Edad', _ctrl['edad']!,
                                                required: true,
                                                type: TextInputType.number)),
                                      ]),
                                      const SizedBox(height: 12),
                                      _select(
                                          'Sexo',
                                          _sexo,
                                          (v) => setState(() => _sexo = v),
                                          kSexo,
                                          required: true),
                                    ],
                                    proximaSeccion: 'academicos',
                                  ),

                                  const SizedBox(height: 8),

                                  // Sección 2: Datos Académicos
                                  _buildSeccionExpandible(
                                    'academicos',
                                    'Datos Académicos',
                                    Icons.school,
                                    _academicosExpandida,
                                    [
                                      _select(
                                          'Escuela o Unidad Académica',
                                          _escuelaUnidadAcademica,
                                          _onEscuelaChanged,
                                          kEscuelasUnidadAcademica,
                                          required: true),
                                      const SizedBox(height: 12),
                                      _field('Grupo', _ctrl['grupo']!),
                                      const SizedBox(height: 12),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          _select(
                                              'Categoría',
                                              _categoria,
                                              (v) => setState(
                                                  () => _categoria = v),
                                              kCategoria,
                                              required: true),
                                          if (_categoria == 'Otra…')
                                            Padding(
                                              padding:
                                                  const EdgeInsets.only(top: 8),
                                              child: _field('Otra categoría',
                                                  _ctrl['categoria_otra']!,
                                                  required: true),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            _select(
                                                'Programa',
                                                _programa,
                                                _onProgramaChanged,
                                                _programasDisponibles,
                                                required: true),
                                            if (_mostrarProgramaOtra)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 8),
                                                child: _field('Otro programa',
                                                    _ctrl['programa_otra']!,
                                                    required: true),
                                              ),
                                          ]),
                                    ],
                                    proximaSeccion: 'salud',
                                  ),

                                  const SizedBox(height: 8),

                                  // Sección 3: Información de Salud
                                  _buildSeccionExpandible(
                                    'salud',
                                    'Información de Salud',
                                    Icons.medical_services,
                                    _saludExpandida,
                                    [
                                      Row(children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              _select(
                                                  '¿Discapacidad?',
                                                  _discapacidad,
                                                  (v) => setState(
                                                      () => _discapacidad = v),
                                                  kSiNo_Mayus_SI,
                                                  required: true),
                                              if (_discapacidad == 'SI')
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 8),
                                                  child: _select(
                                                    'Tipo de discapacidad',
                                                    _ctrl['tipo_discapacidad']!
                                                            .text
                                                            .isEmpty
                                                        ? null
                                                        : _ctrl['tipo_discapacidad']!
                                                            .text,
                                                    (v) => setState(() => _ctrl[
                                                            'tipo_discapacidad']!
                                                        .text = v ?? ''),
                                                    const [
                                                      'Física o motriz',
                                                      'Sensorial (Auditiva, visual...)',
                                                      'Intelectual',
                                                      'Psicosocial (transtornos que afectan el comportamiento e interacción social)',
                                                      'De lenguaje y comunicación',
                                                      'Discapacidad Múltiple',
                                                      'Ninguna'
                                                    ],
                                                    required: true,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              _field('Alergias',
                                                  _ctrl['alergias']!,
                                                  required: true),
                                              const SizedBox(height: 8),
                                              _select(
                                                  'Tipo de sangre',
                                                  _tipoSangre,
                                                  (v) => setState(
                                                      () => _tipoSangre = v),
                                                  kSangre,
                                                  required: true),
                                            ],
                                          ),
                                        ),
                                      ]),
                                      const SizedBox(height: 12),
                                      _field(
                                          'Enfermedad Crónico Degenerativa / Congénita',
                                          _ctrl['enfermedad']!,
                                          required: true,
                                          lines: 2),
                                    ],
                                    proximaSeccion: 'seguro',
                                  ),

                                  const SizedBox(height: 8),

                                  // Sección 4: Información de Seguro
                                  _buildSeccionExpandible(
                                    'seguro',
                                    'Seguro Médico',
                                    Icons.health_and_safety,
                                    _seguroExpandida,
                                    [
                                      Row(children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              _select(
                                                  'Unidad médica',
                                                  _unidadMedica,
                                                  (v) => setState(
                                                      () => _unidadMedica = v),
                                                  kUnidad,
                                                  required: true),
                                              if (_unidadMedica == 'Otra…')
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 8),
                                                  child: _field('Otra unidad',
                                                      _ctrl['unidad_otra']!,
                                                      required: true),
                                                ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _field(
                                              'Número de Afiliación (IMSS/ISSSTE/SEDENA/MARINA)',
                                              _ctrl['numero_afiliacion']!,
                                              required: true),
                                        ),
                                      ]),
                                      const SizedBox(height: 12),
                                      Row(children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              _select(
                                                  '¿Usa seguro universitario?',
                                                  _usoSeguro,
                                                  (v) => setState(
                                                      () => _usoSeguro = v),
                                                  kUsoSeguro,
                                                  required: true),
                                              if (_usoSeguro == 'Otra…')
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 8),
                                                  child: _field('Especifica',
                                                      _ctrl['uso_otra']!,
                                                      required: true),
                                                ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _select(
                                              '¿Eres donante de órganos y tejidos?',
                                              _donante,
                                              (v) =>
                                                  setState(() => _donante = v),
                                              kSiNo_Acento,
                                              required: true),
                                        ),
                                      ]),
                                    ],
                                    proximaSeccion: 'emergencia',
                                  ),

                                  const SizedBox(height: 8),

                                  // Sección 5: Contacto de Emergencia
                                  _buildSeccionExpandible(
                                    'emergencia',
                                    'Contacto de Emergencia',
                                    Icons.emergency,
                                    _emergenciaExpandida,
                                    [
                                      Row(children: [
                                        Expanded(
                                          child: _field(
                                              'Teléfono en caso de urgencia',
                                              _ctrl['emergencia_tel']!,
                                              required: true,
                                              type: TextInputType.phone),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _field(
                                              'Nombre, parentesco y domicilio del contacto',
                                              _ctrl['emergencia_contacto']!,
                                              required: true,
                                              lines: 2),
                                        ),
                                      ]),
                                    ],
                                  ),

                                  const SizedBox(height: 24),
                                ], // children del Column del Form
                              ), // Column del Form
                            ), // Form
                          ), // SingleChildScrollView
                        ), // SafeArea
                      ), // Expanded
                    ],
                  ); // Cierre del Column del body (PC)
                }

                // Móvil/Tablet: layout responsivo SIN franja azul
                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                      horizontal: mobile ? 8 : 24, vertical: mobile ? 4 : 16),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                          maxWidth: mobile ? double.infinity : 1200),
                      child: Padding(
                        padding: EdgeInsets.only(
                            bottom: MediaQuery.of(context).viewInsets.bottom),
                        child: Form(
                          key: _form,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header móvil
                              Text(
                                'Carnet universitario — Captura',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      color: UAGroColors.blue,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              const SizedBox(height: 8),

                              // Botones de acción (móvil usa Wrap)
                              mobile
                                  ? Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            minimumSize: const Size(0, 32),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 6),
                                            visualDensity:
                                                VisualDensity.compact,
                                          ),
                                          onPressed: _confirmAndReset,
                                          icon: const Icon(Icons.refresh,
                                              size: 18),
                                          label: const Text('Limpiar',
                                              style: TextStyle(fontSize: 12)),
                                        ),
                                      ],
                                    )
                                  : Row(
                                      children: [
                                        OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            minimumSize: const Size(0, 32),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 6),
                                            visualDensity:
                                                VisualDensity.compact,
                                          ),
                                          onPressed: _confirmAndReset,
                                          icon: const Icon(Icons.refresh,
                                              size: 18),
                                          label: const Text('Limpiar',
                                              style: TextStyle(fontSize: 12)),
                                        ),
                                      ],
                                    ),
                              const SizedBox(height: 12),

                              // Indicador de progreso de guardado
                              if (_guardandoCarnet)
                                LinearProgressIndicator(
                                  color: UAGroColors.blue,
                                  backgroundColor:
                                      UAGroColors.blue.withOpacity(0.2),
                                ),
                              const SizedBox(height: 8),

                              // Secciones expandibles (mismo contenido para móvil)
                              _buildSeccionExpandible(
                                'identidad',
                                'Información de Identidad',
                                Icons.person,
                                _identidadExpandida,
                                [
                                  twoCols(
                                    _field('Matrícula', _ctrl['matricula']!,
                                        required: true,
                                        enabled: !_lockMatricula),
                                    _field('Nombre completo', _ctrl['nombre']!,
                                        required: true),
                                  ),
                                  const SizedBox(height: 12),
                                  twoCols(
                                    _field('Correo', _ctrl['correo']!,
                                        required: true,
                                        type: TextInputType.emailAddress),
                                    _field('Edad', _ctrl['edad']!,
                                        required: true,
                                        type: TextInputType.number),
                                  ),
                                  const SizedBox(height: 12),
                                  twoCols(
                                    _select('Sexo', _sexo,
                                        (v) => setState(() => _sexo = v), kSexo,
                                        required: true),
                                    Container(),
                                  ),
                                ],
                              ),

                              _buildSeccionExpandible(
                                'academicos',
                                'Datos Académicos',
                                Icons.school,
                                _academicosExpandida,
                                [
                                  twoCols(
                                    _select(
                                        'Escuela o Unidad Académica',
                                        _escuelaUnidadAcademica,
                                        _onEscuelaChanged,
                                        kEscuelasUnidadAcademica,
                                        required: true),
                                    _field('Grupo', _ctrl['grupo']!),
                                  ),
                                  const SizedBox(height: 12),
                                  twoCols(
                                    _select(
                                        'Categoría',
                                        _categoria,
                                        (v) => setState(() => _categoria = v),
                                        kCategoria,
                                        required: true),
                                    _categoria == 'Otra…'
                                        ? _field('Especificar categoría',
                                            _ctrl['categoria_otra']!,
                                            required: true)
                                        : Container(),
                                  ),
                                  const SizedBox(height: 12),
                                  twoCols(
                                    _select(
                                        'Programa académico',
                                        _programa,
                                        _onProgramaChanged,
                                        _programasDisponibles,
                                        required: true),
                                    _mostrarProgramaOtra
                                        ? _field('Especificar programa',
                                            _ctrl['programa_otra']!,
                                            required: true)
                                        : Container(),
                                  ),
                                ],
                              ),

                              _buildSeccionExpandible(
                                'salud',
                                'Información de Salud',
                                Icons.medical_services,
                                _saludExpandida,
                                [
                                  twoCols(
                                    _field(
                                        'Alergias (medicamentos, alimentos, etc.)',
                                        _ctrl['alergias']!,
                                        lines: 2),
                                    _field('Enfermedad crónica o padecimiento',
                                        _ctrl['enfermedad']!,
                                        lines: 2),
                                  ),
                                  const SizedBox(height: 12),
                                  twoCols(
                                    _select(
                                        'Discapacidad',
                                        _discapacidad,
                                        (v) =>
                                            setState(() => _discapacidad = v),
                                        kSiNo_Acento),
                                    _select(
                                        'Tipo de sangre',
                                        _tipoSangre,
                                        (v) => setState(() => _tipoSangre = v),
                                        kSangre),
                                  ),
                                  const SizedBox(height: 12),
                                  twoCols(
                                    _select(
                                        '¿Es donante de órganos?',
                                        _donante,
                                        (v) => setState(() => _donante = v),
                                        kSiNo_Acento),
                                    Container(),
                                  ),
                                ],
                              ),

                              _buildSeccionExpandible(
                                'seguro',
                                'Información de Seguro',
                                Icons.health_and_safety,
                                _seguroExpandida,
                                [
                                  twoCols(
                                    _field('Número de afiliación',
                                        _ctrl['numero_afiliacion']!),
                                    _select(
                                        'Unidad médica de adscripción',
                                        _unidadMedica,
                                        (v) =>
                                            setState(() => _unidadMedica = v),
                                        kUnidad),
                                  ),
                                  const SizedBox(height: 12),
                                  twoCols(
                                    _select(
                                        'Uso del seguro',
                                        _usoSeguro,
                                        (v) => setState(() => _usoSeguro = v),
                                        kUsoSeguro),
                                    _usoSeguro == 'Otra…'
                                        ? _field('Especificar uso',
                                            _ctrl['uso_otra']!)
                                        : Container(),
                                  ),
                                ],
                              ),

                              _buildSeccionExpandible(
                                'emergencia',
                                'Contacto de Emergencia',
                                Icons.emergency,
                                _emergenciaExpandida,
                                [
                                  twoCols(
                                    _field('Teléfono de urgencia',
                                        _ctrl['emergencia_tel']!,
                                        required: true,
                                        type: TextInputType.phone),
                                    _field(
                                        'Nombre, parentesco y domicilio del contacto',
                                        _ctrl['emergencia_contacto']!,
                                        required: true,
                                        lines: 2),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          busyOverlay(context, _busy),
        ],
      ),
      // ActionBar fija en la parte inferior
      bottomNavigationBar: _buildActionBar(),
    );
  }

  Widget _buildCarnetWorkspace(BuildContext context, bool mobile) {
    final horizontalPadding = mobile ? 16.0 : 28.0;

    return ColoredBox(
      color: const Color(0xFFF4F7FB),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          mobile ? 14 : 24,
          horizontalPadding,
          MediaQuery.of(context).viewInsets.bottom + 28,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1480),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeroHeader(mobile),
                  const SizedBox(height: 16),
                  _buildProgressSteps(mobile),
                  if (_guardandoCarnet) ...[
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      color: UAGroColors.blue,
                      backgroundColor: UAGroColors.blue.withOpacity(0.14),
                    ),
                  ],
                  const SizedBox(height: 18),
                  if (mobile)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildMainFormColumn(),
                        const SizedBox(height: 16),
                        _buildSummaryPanel(),
                      ],
                    )
                  else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 4, child: _buildMainFormColumn()),
                        const SizedBox(width: 20),
                        SizedBox(width: 330, child: _buildSummaryPanel()),
                      ],
                    ),
                  const SizedBox(height: 12),
                  _buildFooterBrand(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroHeader(bool mobile) {
    return Container(
      decoration: _cardDecoration(),
      padding: EdgeInsets.all(mobile ? 18 : 24),
      child: mobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroTitle(),
                const SizedBox(height: 14),
                _buildResetButton(),
              ],
            )
          : Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: UAGroColors.blue,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: UAGroColors.blue.withOpacity(0.18),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.badge_outlined,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(child: _buildHeroTitle()),
                const SizedBox(width: 16),
                _buildResetButton(),
              ],
            ),
    );
  }

  Widget _buildHeroTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Universidad Autónoma de Guerrero',
          style: TextStyle(
            color: UAGroColors.blue,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Crear Carnet Universitario',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: UAGroColors.blue,
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          'Registro estudiantil y datos básicos de salud',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: UAGroColors.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  Widget _buildResetButton() {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: UAGroColors.blue,
        side: BorderSide(color: UAGroColors.blue.withOpacity(0.35)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: _confirmAndReset,
      icon: const Icon(Icons.refresh_rounded, size: 18),
      label: const Text('Limpiar'),
    );
  }

  Widget _buildProgressSteps(bool mobile) {
    final stepIcons = <IconData>[
      Icons.person_outline,
      Icons.school_outlined,
      Icons.favorite_border,
      Icons.health_and_safety_outlined,
      Icons.call_outlined,
    ];
    final stepLabels = <String>[
      'Identidad',
      'Académico',
      'Salud',
      'Seguro médico',
      'Emergencia',
    ];

    return Container(
      decoration: _cardDecoration(),
      padding: EdgeInsets.symmetric(
        horizontal: mobile ? 14 : 24,
        vertical: mobile ? 14 : 18,
      ),
      child: mobile
          ? Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (var i = 0; i < stepLabels.length; i++)
                  _buildProgressChip(i + 1, stepLabels[i], i == 0),
              ],
            )
          : Row(
              children: [
                for (var i = 0; i < stepLabels.length; i++) ...[
                  Expanded(
                    child: _buildProgressStep(
                      i + 1,
                      stepIcons[i],
                      stepLabels[i],
                      i == 0,
                    ),
                  ),
                  if (i < stepLabels.length - 1)
                    Container(
                      width: 42,
                      height: 1,
                      color: UAGroColors.outlineVariant,
                    ),
                ],
              ],
            ),
    );
  }

  Widget _buildProgressStep(
    int number,
    IconData icon,
    String label,
    bool active,
  ) {
    final color = active ? UAGroColors.blue : UAGroColors.onSurfaceVariant;

    return Column(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: active ? UAGroColors.blue : Colors.white,
            borderRadius: BorderRadius.circular(21),
            border: Border.all(
              color: active ? UAGroColors.blue : UAGroColors.outline,
            ),
          ),
          child: Center(
            child: active
                ? Text(
                    '$number',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  )
                : Icon(icon, color: color, size: 20),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: active ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressChip(int number, String label, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: active ? UAGroColors.blue : const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: active ? UAGroColors.blue : UAGroColors.outlineVariant,
        ),
      ),
      child: Text(
        '$number. $label',
        style: TextStyle(
          color: active ? Colors.white : UAGroColors.blue,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildMainFormColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildIdentityCard(),
        const SizedBox(height: 12),
        _buildSeccionExpandible(
          'academicos',
          'Datos Académicos',
          Icons.school_outlined,
          _academicosExpandida,
          _academicFields(),
          proximaSeccion: 'salud',
        ),
        const SizedBox(height: 10),
        _buildSeccionExpandible(
          'salud',
          'Información de Salud',
          Icons.monitor_heart_outlined,
          _saludExpandida,
          _healthFields(),
          proximaSeccion: 'seguro',
        ),
        const SizedBox(height: 10),
        _buildSeccionExpandible(
          'seguro',
          'Seguro Médico',
          Icons.health_and_safety_outlined,
          _seguroExpandida,
          _insuranceFields(),
          proximaSeccion: 'emergencia',
        ),
        const SizedBox(height: 10),
        _buildSeccionExpandible(
          'emergencia',
          'Contacto de Emergencia',
          Icons.phone_in_talk_outlined,
          _emergenciaExpandida,
          _emergencyFields(),
        ),
      ],
    );
  }

  Widget _buildIdentityCard() {
    return Container(
      decoration: _cardDecoration(),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionHeader(
              Icons.people_alt_outlined, 'Identificación del estudiante'),
          const SizedBox(height: 18),
          twoCols(
            _field(
              'Matrícula',
              _ctrl['matricula']!,
              required: true,
              enabled: !_lockMatricula,
            ),
            _field('Nombre completo', _ctrl['nombre']!, required: true),
          ),
          const SizedBox(height: 14),
          twoCols(
            _field(
              'Correo',
              _ctrl['correo']!,
              required: true,
              type: TextInputType.emailAddress,
            ),
            _field(
              'Edad',
              _ctrl['edad']!,
              required: true,
              type: TextInputType.number,
            ),
          ),
          const SizedBox(height: 14),
          twoCols(
            _select(
              'Sexo',
              _sexo,
              (v) => setState(() => _sexo = v),
              kSexo,
              required: true,
            ),
            const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  List<Widget> _academicFields() {
    return [
      twoCols(
        _select(
          'Escuela o Unidad Académica',
          _escuelaUnidadAcademica,
          _onEscuelaChanged,
          kEscuelasUnidadAcademica,
          required: true,
        ),
        _field('Grupo', _ctrl['grupo']!),
      ),
      const SizedBox(height: 14),
      twoCols(
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _select(
              'Categoría',
              _categoria,
              (v) => setState(() => _categoria = v),
              kCategoria,
              required: true,
            ),
            if (_categoria == 'Otra…')
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: _field(
                  'Otra categoría',
                  _ctrl['categoria_otra']!,
                  required: true,
                ),
              ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _select(
              'Programa',
              _programa,
              _onProgramaChanged,
              _programasDisponibles,
              required: true,
            ),
            if (_mostrarProgramaOtra)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: _field(
                  'Otro programa',
                  _ctrl['programa_otra']!,
                  required: true,
                ),
              ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _healthFields() {
    return [
      twoCols(
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _select(
              '¿Discapacidad?',
              _discapacidad,
              (v) => setState(() => _discapacidad = v),
              kSiNo_Mayus_SI,
              required: true,
            ),
            if (_discapacidad == 'SI')
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: _select(
                  'Tipo de discapacidad',
                  _ctrl['tipo_discapacidad']!.text.isEmpty
                      ? null
                      : _ctrl['tipo_discapacidad']!.text,
                  (v) => setState(
                    () => _ctrl['tipo_discapacidad']!.text = v ?? '',
                  ),
                  const [
                    'Física o motriz',
                    'Sensorial (Auditiva, visual...)',
                    'Intelectual',
                    'Psicosocial (transtornos que afectan el comportamiento e interacción social)',
                    'De lenguaje y comunicación',
                    'Discapacidad Múltiple',
                    'Ninguna',
                  ],
                  required: true,
                ),
              ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _field('Alergias', _ctrl['alergias']!, required: true),
            const SizedBox(height: 10),
            _select(
              'Tipo de sangre',
              _tipoSangre,
              (v) => setState(() => _tipoSangre = v),
              kSangre,
              required: true,
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      _field(
        'Enfermedad Crónico Degenerativa / Congénita',
        _ctrl['enfermedad']!,
        required: true,
        lines: 2,
      ),
    ];
  }

  List<Widget> _insuranceFields() {
    return [
      twoCols(
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _select(
              'Unidad médica',
              _unidadMedica,
              (v) => setState(() => _unidadMedica = v),
              kUnidad,
              required: true,
            ),
            if (_unidadMedica == 'Otra…')
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: _field(
                  'Otra unidad',
                  _ctrl['unidad_otra']!,
                  required: true,
                ),
              ),
          ],
        ),
        _field(
          'Número de Afiliación (IMSS/ISSSTE/SEDENA/MARINA)',
          _ctrl['numero_afiliacion']!,
          required: true,
        ),
      ),
      const SizedBox(height: 14),
      twoCols(
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _select(
              '¿Usa seguro universitario?',
              _usoSeguro,
              (v) => setState(() => _usoSeguro = v),
              kUsoSeguro,
              required: true,
            ),
            if (_usoSeguro == 'Otra…')
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: _field('Especifica', _ctrl['uso_otra']!, required: true),
              ),
          ],
        ),
        _select(
          '¿Eres donante de órganos y tejidos?',
          _donante,
          (v) => setState(() => _donante = v),
          kSiNo_Acento,
          required: true,
        ),
      ),
    ];
  }

  List<Widget> _emergencyFields() {
    return [
      twoCols(
        _field(
          'Teléfono en caso de urgencia',
          _ctrl['emergencia_tel']!,
          required: true,
          type: TextInputType.phone,
        ),
        _field(
          'Nombre, parentesco y domicilio del contacto',
          _ctrl['emergencia_contacto']!,
          required: true,
          lines: 2,
        ),
      ),
    ];
  }

  Widget _buildSummaryPanel() {
    final listenable = Listenable.merge([
      _ctrl['matricula']!,
      _ctrl['nombre']!,
      _ctrl['programa_otra']!,
    ]);

    return AnimatedBuilder(
      animation: listenable,
      builder: (context, _) {
        return Container(
          decoration: _cardDecoration(),
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _sectionHeader(Icons.badge_outlined, 'Resumen del registro'),
              const SizedBox(height: 22),
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 112,
                      height: 112,
                      decoration: BoxDecoration(
                        color: UAGroColors.blue.withOpacity(0.06),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: UAGroColors.blue.withOpacity(0.18),
                          width: 3,
                        ),
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        size: 58,
                        color: UAGroColors.blue,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _summaryValue(_ctrl['nombre']!.text) == 'No registrado'
                          ? 'Sin fotografía'
                          : _summaryValue(_ctrl['nombre']!.text),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: UAGroColors.blue,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                      label: const Text('Agregar fotografía'),
                      style: OutlinedButton.styleFrom(
                        disabledForegroundColor: UAGroColors.blue,
                        side: BorderSide(
                            color: UAGroColors.blue.withOpacity(0.28)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _summaryRow(
                Icons.format_list_numbered,
                'Matrícula',
                _summaryValue(_ctrl['matricula']!.text),
              ),
              _summaryRow(
                Icons.person_outline,
                'Nombre',
                _summaryValue(_ctrl['nombre']!.text),
              ),
              _summaryRow(
                Icons.school_outlined,
                'Programa',
                _summaryValue(_programaValueForSave()),
              ),
              _summaryRow(
                Icons.apartment_outlined,
                'Campus',
                _summaryValue(_escuelaValueForSave()),
              ),
              _summaryRow(
                Icons.calendar_today_outlined,
                'Fecha de registro',
                _formattedNow(),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: UAGroColors.blue, size: 22),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Completa todas las secciones para crear el carnet universitario.',
                        style: TextStyle(
                          color: UAGroColors.blue,
                          fontSize: 12,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: UAGroColors.blue.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: UAGroColors.blue, size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: UAGroColors.blue,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: UAGroColors.blue, size: 19),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: UAGroColors.blue,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    color: value == 'No registrado'
                        ? UAGroColors.onSurfaceVariant
                        : const Color(0xFF102A56),
                    fontSize: 13,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterBrand() {
    return const Padding(
      padding: EdgeInsets.only(top: 6, bottom: 2),
      child: Center(
        child: Text(
          '© 2026 Universidad Autónoma de Guerrero  |  Dirección de Innovación en la Gestión de la Salud Universitaria',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: UAGroColors.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: UAGroColors.outlineVariant),
      boxShadow: [
        BoxShadow(
          color: UAGroColors.blue.withOpacity(0.07),
          blurRadius: 22,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  String _summaryValue(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? 'No registrado' : trimmed;
  }

  String _formattedNow() {
    final now = DateTime.now();
    return '${_twoDigits(now.day)}/${_twoDigits(now.month)}/${now.year} '
        '${_twoDigits(now.hour)}:${_twoDigits(now.minute)}';
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');

  // ---------- Widgets ----------
  Widget _field(
    String label,
    TextEditingController c, {
    bool required = false,
    TextInputType? type,
    int lines = 1,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: c,
      keyboardType: type,
      minLines: lines,
      maxLines: lines,
      enabled: enabled,
      style: const TextStyle(
        color: Color(0xFF102A56),
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: enabled ? Colors.white : const Color(0xFFF4F7FB),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: UAGroColors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: UAGroColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: UAGroColors.blue, width: 1.6),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: UAGroColors.outlineVariant),
        ),
      ),
      validator: (v) =>
          required && (v == null || v.trim().isEmpty) ? 'Requerido' : null,
    );
  }

  Widget _select(
    String label,
    String? value,
    ValueChanged<String?> onChanged,
    List<String> items, {
    bool required = false,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: UAGroColors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: UAGroColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: UAGroColors.blue, width: 1.6),
        ),
      ),
      borderRadius: BorderRadius.circular(12),
      items:
          items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
      validator: (v) =>
          required && (v == null || v.isEmpty) ? 'Requerido' : null,
    );
  }

  // ---------- Guardado ----------
  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;

    setState(() => _guardandoCarnet = true);

    try {
      if (_sexo == null ||
          _categoria == null ||
          _escuelaUnidadAcademica == null ||
          _programa == null ||
          _discapacidad == null ||
          _tipoSangre == null ||
          _unidadMedica == null ||
          _usoSeguro == null ||
          _donante == null ||
          (_discapacidad == 'SI' && _ctrl['tipo_discapacidad']!.text.isEmpty)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Completa todos los campos obligatorios'),
                ],
              ),
              backgroundColor: Colors.orange.shade700,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      final matriculaTxt = _ctrl['matricula']!.text.trim();

      // Si NO estamos bloqueando matrícula (alta), verifica existencia en nube por matrícula
      // PERO solo si hay conexión a internet (para evitar bloqueo de 60 segundos offline)
      if (!_lockMatricula) {
        // 🚀 Verificación rápida de conexión (3 segundos max)
        final hasInternet = await ApiService.hasInternetConnection();

        if (hasInternet) {
          // Solo verificar duplicados si HAY internet
          try {
            final pac = await ApiService.getExpedienteByMatricula(matriculaTxt);
            if (pac != null) {
              if (!mounted) return;
              await showDialog<void>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Matrícula existente en la nube'),
                  content: Text(
                      'La matrícula "$matriculaTxt" ya existe en el servidor.\n\n'
                      'Agrega notas desde "Nueva nota" o entra con el botón "Editar carnet" para modificar datos.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Entendido')),
                  ],
                ),
              );
              return;
            }
          } catch (_) {}
        } else {
          // Sin internet: guardar directo sin verificar duplicados
          print(
              '[OFFLINE] Sin internet detectado - guardando directo sin verificación');
        }
      }

      final existingLocalRecord = await _getRecordByMatricula(matriculaTxt);
      final activityAction = widget.carnetExistente != null ||
              existingLocalRecord != null ||
              _lockMatricula
          ? 'modified'
          : 'created';

      final comp = HealthRecordsCompanion.insert(
        timestamp: Value(DateTime.now()),
        matricula: _ctrl['matricula']!.text,
        nombreCompleto: _ctrl['nombre']!.text,
        correo: _ctrl['correo']!.text,
        edad: Value(int.tryParse(_ctrl['edad']!.text)),
        sexo: Value(_sexo),
        categoria: Value(
            _categoria == 'Otra…' ? _ctrl['categoria_otra']!.text : _categoria),
        programa: Value(_programaValueForSave()),
        escuelaUnidadAcademica: Value(_escuelaValueForSave()),
        grupo: Value(_grupoValueForSave()),
        discapacidad: Value(_discapacidad),
        tipoDiscapacidad: Value(_ctrl['tipo_discapacidad']!.text),
        alergias: Value(_ctrl['alergias']!.text),
        tipoSangre: Value(_tipoSangre),
        enfermedadCronica: Value(_ctrl['enfermedad']!.text),
        unidadMedica: Value(_unidadMedica == 'Otra…'
            ? _ctrl['unidad_otra']!.text
            : _unidadMedica),
        numeroAfiliacion: Value(_ctrl['numero_afiliacion']!.text),
        usoSeguroUniversitario:
            Value(_usoSeguro == 'Otra…' ? _ctrl['uso_otra']!.text : _usoSeguro),
        donante: Value(_donante),
        emergenciaTelefono: Value(_ctrl['emergencia_tel']!.text),
        emergenciaContacto: Value(_ctrl['emergencia_contacto']!.text),
        expedienteNotas: Value(_ctrl['expediente_notas']!.text),
        expedienteAdjuntos: const Value('[]'),
        synced: const Value(false),
      );

      await _upsertRecord(comp);
      await _recordRecentCarnetActivity(activityAction);

      if (!mounted) return;

      // El mensaje de éxito ya se muestra en _upsertRecord

      // Tras guardar:
      // - en modo edición: NO limpiar (mantener en pantalla)
      // - en modo creación: limpiar silenciosamente para capturar otro
      if (!_lockMatricula) {
        _resetAll();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Listo para capturar otro carnet'),
                ],
              ),
              backgroundColor: UAGroColors.success,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _guardandoCarnet = false);
      }
    }
  }

  // ---------- Métodos auxiliares para secciones ----------
  Widget _buildSeccionExpandible(
    String seccionId,
    String titulo,
    IconData icono,
    bool expandida,
    List<Widget> contenido, {
    String? proximaSeccion,
  }) {
    return Container(
      decoration: _cardDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: UAGroColors.blue.withOpacity(0.05),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          childrenPadding: EdgeInsets.zero,
          initiallyExpanded: expandida,
          onExpansionChanged: (expanded) =>
              _alternarSeccion(seccionId, expanded),
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: UAGroColors.blue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icono, color: UAGroColors.blue, size: 21),
          ),
          title: Text(
            titulo,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: UAGroColors.blue,
                ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 6, 22, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ...contenido,
                  if (proximaSeccion != null) ...[
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _alternarSeccion(proximaSeccion, true);
                          Future.delayed(const Duration(milliseconds: 300), () {
                            // Scroll suave hacia la siguiente sección
                            Scrollable.ensureVisible(
                              context,
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeInOut,
                            );
                          });
                        },
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('Siguiente sección'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: UAGroColors.blue,
                          side: BorderSide(
                              color: UAGroColors.blue.withOpacity(0.45)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: UAGroColors.blue.withOpacity(0.10),
            blurRadius: 16,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      child: Row(
        children: [
          // Botón principal: Guardar carnet
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              onPressed:
                  _guardandoCarnet ? null : () => runWithLoader(() => _save()),
              icon: _guardandoCarnet
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(_guardandoCarnet ? 'Guardando...' : 'Guardar carnet'),
              style: FilledButton.styleFrom(
                backgroundColor: UAGroColors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Botón secundario: Agregar nota
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _guardandoCarnet
                  ? null
                  : () async {
                      final ok = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => NuevaNotaScreen(
                            db: widget.db,
                            matriculaInicial:
                                _ctrl['matricula']!.text.trim().isEmpty
                                    ? null
                                    : _ctrl['matricula']!.text.trim(),
                          ),
                        ),
                      );
                      if (ok == true && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.white),
                                SizedBox(width: 8),
                                Text('Nota guardada'),
                              ],
                            ),
                            backgroundColor: UAGroColors.success,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
              icon: const Icon(Icons.note_add_outlined),
              label: const Text('Agregar nota'),
              style: OutlinedButton.styleFrom(
                foregroundColor: UAGroColors.blue,
                side: BorderSide(color: UAGroColors.blue.withOpacity(0.50)),
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Botón terciario: Sincronizar
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _guardandoCarnet
                  ? null
                  : () async {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Row(
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              ),
                              SizedBox(width: 8),
                              Text('Sincronizando registros pendientes...'),
                            ],
                          ),
                          backgroundColor: UAGroColors.blue,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                      try {
                        final syncService = SyncService(widget.db);
                        final result = await syncService.syncAll();
                        if (!mounted) return;

                        if (result.hasErrors) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.warning,
                                      color: Colors.white),
                                  const SizedBox(width: 8),
                                  Expanded(
                                      child: Text(
                                          '${result.totalSynced} sincronizados, ${result.totalErrors} con error')),
                                ],
                              ),
                              backgroundColor: Colors.orange.shade700,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        } else if (result.hasSuccess) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.check_circle,
                                      color: Colors.white),
                                  const SizedBox(width: 8),
                                  Text(
                                      '${result.totalSynced} registros sincronizados'),
                                ],
                              ),
                              backgroundColor: UAGroColors.success,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Row(
                                children: [
                                  Icon(Icons.info, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text('No hay registros pendientes'),
                                ],
                              ),
                              backgroundColor: UAGroColors.blue,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.error, color: Colors.white),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: Text(
                                        'Error de sincronización: ${e.toString().length > 20 ? e.toString().substring(0, 20) + "..." : e.toString()}')),
                              ],
                            ),
                            backgroundColor: Colors.red.shade700,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    },
              icon: const Icon(Icons.sync),
              label: const Text('Sincronizar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: UAGroColors.blue,
                side: BorderSide(color: UAGroColors.blue.withOpacity(0.50)),
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
