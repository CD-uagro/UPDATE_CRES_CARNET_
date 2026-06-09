import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import 'version_comparator.dart';

/// Modelo para la información de versión
class VersionInfo {
  final String version;
  final int buildNumber;
  final String releaseDate;
  final String downloadUrl;
  final int? fileSize;
  final String? checksum;
  final bool isMandatory;
  final List<String> changelog;

  VersionInfo({
    required this.version,
    required this.buildNumber,
    required this.releaseDate,
    required this.downloadUrl,
    this.fileSize,
    this.checksum,
    required this.isMandatory,
    required this.changelog,
  });

  factory VersionInfo.fromJson(Map<String, dynamic> json) {
    return VersionInfo(
      version: json['version'],
      buildNumber: json['build_number'] ?? json['buildNumber'],
      releaseDate: json['release_date'] ?? json['releaseDate'],
      downloadUrl: json['download_url'] ?? json['downloadUrl'],
      fileSize: json['file_size'] ?? json['fileSize'],
      checksum: json['sha256'] ?? json['checksum'],
      isMandatory: json['is_mandatory'] ?? json['isMandatory'] ?? false,
      changelog: List<String>.from(json['changelog'] ?? const []),
    );
  }
}

/// Modelo para la respuesta de verificación de actualizaciones
class UpdateCheckResponse {
  final bool updateAvailable;
  final String currentVersion;
  final VersionInfo? latestVersion;
  final String message;

  UpdateCheckResponse({
    required this.updateAvailable,
    required this.currentVersion,
    this.latestVersion,
    required this.message,
  });

  factory UpdateCheckResponse.fromJson(Map<String, dynamic> json) {
    return UpdateCheckResponse(
      updateAvailable: json['update_available'],
      currentVersion: json['current_version'],
      latestVersion: json['latest_version'] != null
          ? VersionInfo.fromJson(json['latest_version'])
          : null,
      message: json['message'],
    );
  }
}

/// Servicio para gestionar actualizaciones de la aplicación
class UpdateService {
  static const String baseUrl = 'https://fastapi-backend-o7ks.onrender.com';
  static const Duration timeout = Duration(seconds: 10);

  static UpdateCheckResponse _guardAgainstDowngrade({
    required UpdateCheckResponse response,
    required String currentVersion,
  }) {
    final latestVersion = response.latestVersion;

    if (latestVersion == null) {
      if (response.updateAvailable) {
        debugPrint(
            '⚠️ Respuesta de actualización inválida: update_available=true sin latest_version');
        return UpdateCheckResponse(
          updateAvailable: false,
          currentVersion: response.currentVersion,
          latestVersion: null,
          message: 'No se pudo validar la versión disponible.',
        );
      }

      return response;
    }

    final comparison =
        compareSemanticVersions(latestVersion.version, currentVersion);

    if (comparison > 0) {
      if (!response.updateAvailable) {
        debugPrint(
            '⚠️ Servidor reportó update_available=false, pero ${latestVersion.version} > $currentVersion');
      }

      return UpdateCheckResponse(
        updateAvailable: true,
        currentVersion: response.currentVersion,
        latestVersion: latestVersion,
        message: response.message,
      );
    }

    if (comparison == 0) {
      debugPrint(
          '✅ App actualizada: servidor y cliente están en $currentVersion');
      return UpdateCheckResponse(
        updateAvailable: false,
        currentVersion: response.currentVersion,
        latestVersion: null,
        message: 'Tu aplicación está actualizada.',
      );
    }

    debugPrint(
      '⚠️ Actualización bloqueada: el servidor anuncia ${latestVersion.version}, '
      'pero la app instalada es $currentVersion',
    );
    return UpdateCheckResponse(
      updateAvailable: false,
      currentVersion: response.currentVersion,
      latestVersion: null,
      message:
          'Actualización bloqueada: el servidor anuncia una versión anterior.',
    );
  }

  /// Verifica si hay actualizaciones disponibles
  ///
  /// Compara la versión actual con la última disponible en el servidor
  /// Retorna [UpdateCheckResponse] con información de actualización
  static Future<UpdateCheckResponse> checkForUpdates({
    required String currentVersion,
    required int currentBuild,
    String platform = 'windows',
  }) async {
    try {
      final url = Uri.parse('$baseUrl/updates/check');

      final body = jsonEncode({
        'current_version': currentVersion,
        'current_build': currentBuild,
        'platform': platform,
      });

      debugPrint('🔍 Verificando actualizaciones...');
      debugPrint('   Versión actual: $currentVersion (Build $currentBuild)');
      debugPrint('   URL: $url');

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: body,
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final updateResponse = _guardAgainstDowngrade(
          response: UpdateCheckResponse.fromJson(data),
          currentVersion: currentVersion,
        );

        if (updateResponse.updateAvailable) {
          debugPrint(
              '✅ Actualización disponible: ${updateResponse.latestVersion?.version}');
        } else {
          debugPrint('✅ App actualizada - versión más reciente');
        }

        return updateResponse;
      } else {
        debugPrint(
            '❌ Error al verificar actualizaciones: ${response.statusCode}');
        throw Exception(
            'Error al verificar actualizaciones: ${response.statusCode}');
      }
    } on SocketException {
      debugPrint('⚠️ Sin conexión a internet');
      throw Exception('No hay conexión a internet');
    } on http.ClientException {
      debugPrint('⚠️ Error de red');
      throw Exception('Error de conexión con el servidor');
    } catch (e) {
      debugPrint('❌ Error inesperado: $e');
      rethrow;
    }
  }

  /// Obtiene información de la última versión disponible
  ///
  /// No requiere versión actual, solo retorna la última versión
  static Future<VersionInfo> getLatestVersion() async {
    try {
      final url = Uri.parse('$baseUrl/updates/latest');

      debugPrint('📥 Obteniendo última versión...');

      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
        },
      ).timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final versionInfo = VersionInfo.fromJson(data);

        debugPrint(
            '✅ Última versión: ${versionInfo.version} (Build ${versionInfo.buildNumber})');

        return versionInfo;
      } else {
        debugPrint('❌ Error al obtener última versión: ${response.statusCode}');
        throw Exception(
            'Error al obtener última versión: ${response.statusCode}');
      }
    } on SocketException {
      debugPrint('⚠️ Sin conexión a internet');
      throw Exception('No hay conexión a internet');
    } catch (e) {
      debugPrint('❌ Error inesperado: $e');
      rethrow;
    }
  }

  /// Obtiene el changelog de versiones
  ///
  /// [version] - Versión específica (opcional)
  /// [limit] - Cantidad de versiones a obtener (opcional)
  static Future<List<Map<String, dynamic>>> getChangelog({
    String? version,
    int? limit,
  }) async {
    try {
      var url = Uri.parse('$baseUrl/updates/changelog');

      // Agregar parámetros de query si existen
      final queryParams = <String, String>{};
      if (version != null) queryParams['version'] = version;
      if (limit != null) queryParams['limit'] = limit.toString();

      if (queryParams.isNotEmpty) {
        url = url.replace(queryParameters: queryParams);
      }

      debugPrint('📜 Obteniendo changelog...');

      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
        },
      ).timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final versions = List<Map<String, dynamic>>.from(data['versions']);

        debugPrint('✅ Changelog obtenido: ${data['total_versions']} versiones');

        return versions;
      } else {
        debugPrint('❌ Error al obtener changelog: ${response.statusCode}');
        throw Exception('Error al obtener changelog: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error al obtener changelog: $e');
      rethrow;
    }
  }

  /// Verifica el estado del servicio de actualizaciones
  static Future<bool> checkServiceHealth() async {
    try {
      final url = Uri.parse('$baseUrl/updates/health');

      final response = await http.get(url).timeout(Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('✅ Servicio de actualizaciones: ${data['status']}');
        return data['status'] == 'ok';
      }
      return false;
    } catch (e) {
      debugPrint('⚠️ Servicio de actualizaciones no disponible');
      return false;
    }
  }
}
