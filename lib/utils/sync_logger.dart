// lib/utils/sync_logger.dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

/// Logger dedicado para capturar todos los detalles de sincronización
class SyncLogger {
  static final List<String> _logs = [];
  static bool _enabled = true;

  static void enable() => _enabled = true;
  static void disable() => _enabled = false;

  static void log(String message) {
    if (!_enabled) return;

    final timestamp = DateFormat('HH:mm:ss.SSS').format(DateTime.now());
    final logEntry = '[$timestamp] $message';
    _logs.add(logEntry);
    print(logEntry); // También imprimir en consola
  }

  static void clear() {
    _logs.clear();
  }

  static String getAllLogs() {
    return _logs.join('\n');
  }

  /// Guarda todos los logs en un archivo en el escritorio del usuario
  static Future<String?> saveToFile() async {
    try {
      // Obtener el directorio del usuario
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${directory.path}/sync_log_$timestamp.txt');

      final content = StringBuffer();
      content.writeln('='.padRight(80, '='));
      content.writeln('CRES CARNETS - LOG DE SINCRONIZACIÓN');
      content.writeln(
          'Generado: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}');
      content.writeln('='.padRight(80, '='));
      content.writeln('');
      content.writeln(_logs.join('\n'));
      content.writeln('');
      content.writeln('='.padRight(80, '='));
      content.writeln('FIN DEL LOG');
      content.writeln('='.padRight(80, '='));

      await file.writeAsString(content.toString());
      return file.path;
    } catch (e) {
      print('Error guardando log: $e');
      return null;
    }
  }
}
