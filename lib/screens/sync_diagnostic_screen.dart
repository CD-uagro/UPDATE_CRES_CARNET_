// lib/screens/sync_diagnostic_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/db.dart';
import '../data/api_service.dart';
import '../data/auth_service.dart';
import '../ui/uagro_theme.dart';
import '../utils/sync_logger.dart';

/// Pantalla de diagnóstico para resolver problemas de sincronización
class SyncDiagnosticScreen extends StatefulWidget {
  final AppDatabase db;
  final HealthRecord carnet;

  const SyncDiagnosticScreen({
    Key? key,
    required this.db,
    required this.carnet,
  }) : super(key: key);

  @override
  State<SyncDiagnosticScreen> createState() => _SyncDiagnosticScreenState();
}

class _SyncDiagnosticScreenState extends State<SyncDiagnosticScreen> {
  final List<DiagnosticStep> _steps = [];
  bool _running = false;
  bool _completed = false;
  bool _canRetry = false;

  @override
  void initState() {
    super.initState();
    _runDiagnostics();
  }

  Future<void> _runDiagnostics() async {
    setState(() {
      _steps.clear();
      _running = true;
      _completed = false;
      _canRetry = false;
    });

    // Iniciar logging
    SyncLogger.clear();
    SyncLogger.log('=== DIAGNÓSTICO INICIADO ===');
    SyncLogger.log(
        'Carnet: ${widget.carnet.matricula} - ${widget.carnet.nombreCompleto}');

    // Paso 1: Verificar token
    await _addStep('Verificando autenticación', () async {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('No hay token de autenticación');
      }
      if (token.startsWith('offline_')) {
        throw Exception(
            'Token offline detectado - reconecta a internet e inicia sesión nuevamente');
      }

      // Verificar si el token está expirado usando el servidor
      try {
        final response = await ApiService.testConnection();
        if (!response) {
          throw Exception(
              'No se puede verificar el token - servidor no responde');
        }
      } catch (e) {
        // El servidor está accesible pero puede que el token esté expirado
        // Lo verificaremos en el siguiente paso
      }

      return 'Token válido (${token.substring(0, 20)}...)';
    });

    // Paso 2: Verificar conectividad con backend
    await _addStep('Probando conexión al servidor', () async {
      try {
        final response = await ApiService.testConnection();
        if (!response) {
          throw Exception('Servidor no responde');
        }
        return 'Servidor accesible';
      } catch (e) {
        throw Exception('Error de red: $e');
      }
    });

    // Paso 3: Verificar datos del carnet
    await _addStep('Validando datos del carnet', () async {
      final data = _buildCarnetData();

      // Validaciones básicas
      if (data['matricula'] == null || data['matricula'].toString().isEmpty) {
        throw Exception('Matrícula vacía');
      }
      if (data['nombreCompleto'] == null ||
          data['nombreCompleto'].toString().isEmpty) {
        throw Exception('Nombre completo vacío');
      }

      return 'Datos válidos: ${data['matricula']} - ${data['nombreCompleto']}';
    });

    // Paso 4: Intentar sincronización real
    bool syncSuccess = false;
    String? errorDetail;
    await _addStep('Sincronizando con el servidor', () async {
      final data = _buildCarnetData();

      // Capturar logs en tiempo real
      print('🔍 [DIAGNÓSTICO] Iniciando sincronización...');
      print('🔍 [DIAGNÓSTICO] Datos a enviar: $data');

      final success = await ApiService.pushSingleCarnet(data);

      if (!success) {
        // Revisar si fue un error 401 (token expirado)
        final logs = SyncLogger.getAllLogs();
        if (logs.contains('Status HTTP: 401') || logs.contains('ERROR 401')) {
          errorDetail = '❌ TOKEN EXPIRADO\n\n'
              'Tu sesión ha caducado. Para resolver:\n'
              '1. Cierra esta ventana\n'
              '2. Cierra sesión en la app\n'
              '3. Vuelve a iniciar sesión\n'
              '4. Intenta sincronizar nuevamente\n\n'
              'Los carnets están guardados localmente y se sincronizarán después de renovar la sesión.';
        } else if (logs.contains('Status HTTP: 422')) {
          errorDetail = '❌ ERROR DE VALIDACIÓN (HTTP 422)\n\n'
              'El servidor rechazó los datos. Causas comunes:\n'
              '  • Matrícula duplicada\n'
              '  • Campos requeridos vacíos\n'
              '  • Formato de datos inválido\n\n'
              'Revisa los logs copiados para ver el detalle exacto.';
        } else if (logs.contains('Status HTTP: 400')) {
          errorDetail = '❌ DATOS INVÁLIDOS (HTTP 400)\n\n'
              'Los datos enviados no cumplen con el formato esperado.\n'
              'Revisa los logs copiados para más detalles.';
        } else {
          errorDetail =
              'Sincronización falló. Revisa el Output de Flutter para ver:\n'
              '  - Status HTTP (200, 400, 422, 500, etc.)\n'
              '  - Response Body del servidor\n'
              'Errores comunes:\n'
              '  • 400: Datos mal formateados\n'
              '  • 422: Validación fallida (ej: matrícula duplicada)\n'
              '  • 401/403: Token expirado\n'
              '  • 500: Error interno del servidor';
        }
        throw Exception(errorDetail);
      }

      syncSuccess = true;
      return 'Carnet sincronizado exitosamente';
    });

    // Paso 5: Marcar como sincronizado en DB local (SOLO si el paso 4 tuvo éxito)
    if (syncSuccess) {
      await _addStep('Actualizando base de datos local', () async {
        await widget.db.markRecordAsSynced(widget.carnet.id);
        return 'Registro marcado como sincronizado';
      });
    }

    setState(() {
      _running = false;
      _completed = true;
      _canRetry = _steps.any((s) => !s.success);
    });
  }

  Map<String, dynamic> _buildCarnetData() {
    final carnet = widget.carnet;
    return {
      'matricula': carnet.matricula,
      'nombreCompleto': carnet.nombreCompleto,
      'correo': carnet.correo,
      'edad': carnet.edad,
      'sexo': carnet.sexo,
      'categoria': carnet.categoria,
      'programa': carnet.programa,
      'discapacidad': carnet.discapacidad,
      'tipoDiscapacidad': carnet.tipoDiscapacidad,
      'alergias': carnet.alergias,
      'tipoSangre': carnet.tipoSangre,
      'enfermedadCronica': carnet.enfermedadCronica,
      'unidadMedica': carnet.unidadMedica,
      'numeroAfiliacion': carnet.numeroAfiliacion,
      'usoSeguroUniversitario': carnet.usoSeguroUniversitario,
      'donante': carnet.donante,
      'emergenciaTelefono': carnet.emergenciaTelefono,
      'emergenciaContacto': carnet.emergenciaContacto,
      'expedienteNotas': carnet.expedienteNotas,
      'expedienteAdjuntos': carnet.expedienteAdjuntos,
    };
  }

  Future<void> _addStep(String title, Future<String> Function() action) async {
    final step = DiagnosticStep(title: title);
    setState(() => _steps.add(step));

    try {
      await Future.delayed(
          const Duration(milliseconds: 300)); // Para visualización
      final result = await action();
      step.complete(true, result);
    } catch (e) {
      step.complete(false, e.toString());
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final hasErrors = _steps.any((s) => !s.success);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnóstico de Sincronización'),
        backgroundColor: UAGroColors.azulMarino,
      ),
      body: Column(
        children: [
          // Header con información del carnet
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: UAGroColors.azulMarino.withOpacity(0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.carnet.nombreCompleto,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Matrícula: ${widget.carnet.matricula}',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      widget.carnet.synced ? Icons.check_circle : Icons.pending,
                      size: 16,
                      color:
                          widget.carnet.synced ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.carnet.synced
                          ? 'Sincronizado'
                          : 'Pendiente de sincronización',
                      style: TextStyle(
                        color:
                            widget.carnet.synced ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Lista de pasos de diagnóstico
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _steps.length,
              itemBuilder: (context, index) {
                final step = _steps[index];
                return _buildStepCard(step, index + 1);
              },
            ),
          ),

          // Botones de acción
          if (_completed)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasErrors) ...[
                    Text(
                      '⚠️ Se encontraron ${_steps.where((s) => !s.success).length} error(es)',
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _canRetry ? _runDiagnostics : null,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reintentar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              padding: const EdgeInsets.all(16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _copyLogsToClipboard,
                            icon: const Icon(Icons.copy),
                            label: const Text('Copiar'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.all(16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _saveLogsToFile,
                            icon: const Icon(Icons.save),
                            label: const Text('Guardar'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.all(16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    const Icon(Icons.check_circle,
                        size: 48, color: Colors.green),
                    const SizedBox(height: 8),
                    const Text(
                      '✅ Sincronización completada',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.all(16),
                        ),
                        child: const Text('Cerrar'),
                      ),
                    ),
                  ],
                ],
              ),
            ),

          if (_running) const LinearProgressIndicator(),
        ],
      ),
    );
  }

  Widget _buildStepCard(DiagnosticStep step, int number) {
    IconData icon;
    Color color;

    if (step.isRunning) {
      icon = Icons.hourglass_empty;
      color = Colors.blue;
    } else if (step.success) {
      icon = Icons.check_circle;
      color = Colors.green;
    } else {
      icon = Icons.error;
      color = Colors.red;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: step.isRunning
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: color,
                            ),
                          )
                        : Icon(icon, size: 18, color: color),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '$number. ${step.title}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
            if (step.message != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: step.success
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  step.message!,
                  style: TextStyle(
                    fontSize: 13,
                    color: step.success
                        ? Colors.green.shade800
                        : Colors.red.shade800,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _copyLogsToClipboard() {
    final buffer = StringBuffer();
    buffer.writeln('=== DIAGNÓSTICO DE SINCRONIZACIÓN ===');
    buffer.writeln(
        'Carnet: ${widget.carnet.matricula} - ${widget.carnet.nombreCompleto}');
    buffer.writeln('Fecha: ${DateTime.now()}');
    buffer.writeln('');

    for (var i = 0; i < _steps.length; i++) {
      final step = _steps[i];
      buffer.writeln('${i + 1}. ${step.title}');
      buffer.writeln('   Estado: ${step.success ? "✓ ÉXITO" : "✗ ERROR"}');
      if (step.message != null) {
        buffer.writeln('   Mensaje: ${step.message}');
      }
      buffer.writeln('');
    }

    // Agregar logs detallados del SyncLogger
    buffer.writeln('');
    buffer.writeln('=== LOGS DETALLADOS ===');
    buffer.writeln(SyncLogger.getAllLogs());

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logs copiados al portapapeles')),
    );
  }

  Future<void> _saveLogsToFile() async {
    final filePath = await SyncLogger.saveToFile();
    if (filePath != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Log guardado en:\n$filePath'),
          duration: const Duration(seconds: 5),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al guardar el log'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class DiagnosticStep {
  final String title;
  bool isRunning = true;
  bool success = false;
  String? message;

  DiagnosticStep({required this.title});

  void complete(bool success, String message) {
    this.isRunning = false;
    this.success = success;
    this.message = message;
  }
}
