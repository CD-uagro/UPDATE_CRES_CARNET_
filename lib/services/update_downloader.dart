import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart' as crypto;

/// Callback para reportar progreso de descarga
/// [received] - Bytes descargados
/// [total] - Bytes totales del archivo
typedef ProgressCallback = void Function(int received, int total);

/// Manejador de descargas de actualizaciones
class UpdateDownloader {
  final Dio _dio;
  CancelToken? _cancelToken;

  UpdateDownloader()
      : _dio = Dio(
          BaseOptions(
            connectTimeout: const Duration(minutes: 2), // Tiempo para conectar
            receiveTimeout:
                const Duration(minutes: 15), // Tiempo para recibir datos
            sendTimeout: const Duration(minutes: 2), // Tiempo para enviar
          ),
        );

  /// Descarga el instalador de actualización
  ///
  /// [downloadUrl] - URL del instalador
  /// [onProgress] - Callback para reportar progreso (opcional)
  ///
  /// Retorna la ruta del archivo descargado
  Future<String> downloadUpdate({
    required String downloadUrl,
    ProgressCallback? onProgress,
  }) async {
    try {
      // Obtener directorio temporal
      final tempDir = await getTemporaryDirectory();
      final fileName = path.basename(Uri.parse(downloadUrl).path);
      final savePath = path.join(tempDir.path, fileName);

      debugPrint('📥 Iniciando descarga...');
      debugPrint('   URL: $downloadUrl');
      debugPrint('   Destino: $savePath');

      // Crear token de cancelación
      _cancelToken = CancelToken();

      // Descargar archivo con seguimiento de progreso
      await _dio.download(
        downloadUrl,
        savePath,
        cancelToken: _cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = (received / total * 100).toStringAsFixed(0);
            debugPrint('   Progreso: $progress% ($received/$total bytes)');

            onProgress?.call(received, total);
          }
        },
        options: Options(
          headers: {
            'Accept': 'application/octet-stream',
          },
          receiveTimeout: const Duration(
              minutes: 15), // Timeout generoso para archivos grandes
          sendTimeout: const Duration(minutes: 2),
        ),
      );

      debugPrint('✅ Descarga completada: $savePath');

      // Verificar que el archivo existe
      final file = File(savePath);
      if (!await file.exists()) {
        throw Exception('El archivo descargado no existe');
      }

      // Verificar tamaño
      final fileSize = await file.length();
      debugPrint('   Tamaño del archivo: ${_formatFileSize(fileSize)}');

      return savePath;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        debugPrint('⚠️ Descarga cancelada por el usuario');
        throw Exception('Descarga cancelada');
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        debugPrint('⚠️ Tiempo de espera agotado');
        throw Exception('Tiempo de espera agotado. Verifica tu conexión.');
      } else if (e.type == DioExceptionType.badResponse) {
        debugPrint('❌ Error del servidor: ${e.response?.statusCode}');
        throw Exception('Error al descargar: ${e.response?.statusCode}');
      } else {
        debugPrint('❌ Error de conexión: ${e.message}');
        throw Exception('Error de conexión: ${e.message}');
      }
    } catch (e) {
      debugPrint('❌ Error inesperado: $e');
      rethrow;
    }
  }

  /// Cancela la descarga en curso
  void cancelDownload() {
    if (_cancelToken != null && !_cancelToken!.isCancelled) {
      debugPrint('⏹️ Cancelando descarga...');
      _cancelToken!.cancel('Cancelado por el usuario');
    }
  }

  /// Verifica checksum SHA256 del archivo descargado
  ///
  /// [filePath] - Ruta del archivo a verificar
  /// [expectedChecksum] - Checksum esperado (SHA256)
  ///
  /// Retorna `true` si el checksum coincide, `false` en caso contrario
  Future<bool> verifyChecksum(String filePath, String expectedChecksum) async {
    try {
      final normalizedExpected = expectedChecksum.trim().toLowerCase();
      if (normalizedExpected.isEmpty) {
        debugPrint('Checksum inválido. La actualización no se ejecutará.');
        debugPrint('   Motivo: checksum esperado vacío');
        return false;
      }

      final file = File(filePath);

      if (!await file.exists()) {
        debugPrint('❌ Archivo no encontrado para verificación');
        return false;
      }

      // Leer archivo y calcular SHA256
      final bytes = await file.readAsBytes();
      final digest = crypto.sha256.convert(bytes);
      final checksum = digest.toString();

      debugPrint('🔐 Verificando checksum...');
      debugPrint('   Esperado: $expectedChecksum');

      debugPrint('   Calculado: $checksum');

      final isValid = checksum.toLowerCase() == normalizedExpected;
      if (!isValid) {
        debugPrint('Checksum inválido. La actualización no se ejecutará.');
      }

      return isValid;
    } catch (e) {
      debugPrint('❌ Error al verificar checksum: $e');
      return false;
    }
  }

  /// Ejecuta el instalador descargado
  ///
  /// [installerPath] - Ruta del instalador (puede ser ZIP o EXE)
  /// [closeApp] - Si debe cerrar la app después de ejecutar (default: true)
  Future<void> executeInstaller(String installerPath,
      {bool closeApp = true}) async {
    try {
      final file = File(installerPath);

      if (!await file.exists()) {
        throw Exception('Instalador no encontrado: $installerPath');
      }

      String exePath = installerPath;

      // Si es un ZIP, extraerlo primero
      if (installerPath.toLowerCase().endsWith('.zip')) {
        debugPrint('� Extrayendo archivo ZIP...');

        final tempDir = await getTemporaryDirectory();
        final extractDir = Directory(path.join(tempDir.path,
            'cres_update_${DateTime.now().millisecondsSinceEpoch}'));

        // Extraer ZIP
        await extractDir.create(recursive: true);
        final inputStream = InputFileStream(installerPath);
        final archive = ZipDecoder().decodeBuffer(inputStream);

        for (final file in archive.files) {
          final filename = file.name;
          final data = file.content as List<int>;
          final outFile = File(path.join(extractDir.path, filename));

          if (file.isFile) {
            await outFile.create(recursive: true);
            await outFile.writeAsBytes(data);
            debugPrint('   Extraído: $filename');
          } else {
            await Directory(path.join(extractDir.path, filename))
                .create(recursive: true);
          }
        }

        inputStream.close();

        // Buscar el ejecutable principal
        final exeFiles = await extractDir
            .list(recursive: true)
            .where((entity) =>
                entity is File && entity.path.toLowerCase().endsWith('.exe'))
            .map((entity) => entity as File)
            .toList();

        if (exeFiles.isEmpty) {
          throw Exception('No se encontró ningún ejecutable en el ZIP');
        }

        // Buscar el ejecutable principal (el más grande, que es la app)
        // Ignorar ejecutables pequeños como DLLs auxiliares
        exeFiles.sort((a, b) => b.lengthSync().compareTo(a.lengthSync()));

        // Filtrar solo ejecutables > 10 MB (la app principal es ~35 MB)
        final mainExe = exeFiles.firstWhere(
          (exe) => exe.lengthSync() > 10 * 1024 * 1024,
          orElse: () => exeFiles.first,
        );

        exePath = mainExe.path;
        debugPrint('✅ Archivo extraído');
        debugPrint('   Ejecutable principal: ${path.basename(exePath)}');
        debugPrint('   Tamaño: ${_formatFileSize(mainExe.lengthSync())}');
      }

      debugPrint('🚀 Ejecutando instalador...');
      debugPrint('   Ruta: $exePath');

      // Ejecutar instalador en Windows
      await Process.start(
        exePath,
        [],
        mode: ProcessStartMode.detached,
      );

      debugPrint('✅ Instalador ejecutado');

      if (closeApp) {
        debugPrint('👋 Cerrando aplicación...');
        await Future.delayed(const Duration(seconds: 1));
        exit(0);
      }
    } catch (e) {
      debugPrint('❌ Error al ejecutar instalador: $e');
      rethrow;
    }
  }

  /// Limpia archivos temporales de actualizaciones anteriores
  Future<void> cleanupOldUpdates() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final files = tempDir.listSync();

      debugPrint('🧹 Limpiando actualizaciones antiguas...');

      int deleted = 0;
      for (final file in files) {
        if (file is File) {
          final name = path.basename(file.path).toLowerCase();
          // Eliminar instaladores antiguos
          if (name.contains('setup') && name.endsWith('.exe')) {
            try {
              await file.delete();
              deleted++;
              debugPrint('   Eliminado: ${path.basename(file.path)}');
            } catch (e) {
              debugPrint(
                  '   ⚠️ No se pudo eliminar: ${path.basename(file.path)}');
            }
          }
        }
      }

      debugPrint('✅ Limpieza completada: $deleted archivos eliminados');
    } catch (e) {
      debugPrint('⚠️ Error al limpiar archivos: $e');
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Libera recursos
  void dispose() {
    _cancelToken?.cancel();
    _dio.close();
  }
}
