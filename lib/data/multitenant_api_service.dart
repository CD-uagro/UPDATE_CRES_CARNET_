import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class InstitutionBranding {
  final String institutionId;
  final String displayName;
  final String status;
  final Map<String, dynamic> branding;
  final List<String> enabledModules;
  final bool demo;

  const InstitutionBranding({
    required this.institutionId,
    required this.displayName,
    required this.status,
    required this.branding,
    required this.enabledModules,
    required this.demo,
  });

  factory InstitutionBranding.fromJson(Map<String, dynamic> json) {
    return InstitutionBranding(
      institutionId: json['institution_id'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
      status: json['status'] as String? ?? '',
      branding: Map<String, dynamic>.from(json['branding'] as Map? ?? {}),
      enabledModules:
          (json['enabled_modules'] as List? ?? []).map((e) => '$e').toList(),
      demo: json['demo'] == true,
    );
  }
}

class MultitenantSession {
  final String accessToken;
  final String? refreshToken;
  final String tokenType;
  final String tenantId;
  final String userId;
  final String? username;
  final List<String> roles;
  final List<String> permissions;
  final List<String> modules;
  final bool requiresPasswordChange;

  const MultitenantSession({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.tenantId,
    required this.userId,
    required this.username,
    required this.roles,
    required this.permissions,
    required this.modules,
    required this.requiresPasswordChange,
  });

  factory MultitenantSession.fromJson(Map<String, dynamic> json) {
    final accessToken = json['access_token'];
    final tokenType = json['token_type'];
    final tenantId = json['tenant_id'];
    final userId = json['user_id'];
    final roles = json['roles'];
    final permissions = json['permissions'];
    final modules = json['modules'] ?? json['enabled_modules'] ?? const [];
    final requiresPasswordChange = json['requires_password_change'];
    if (accessToken is! String ||
        accessToken.isEmpty ||
        tokenType is! String ||
        tenantId is! String ||
        userId is! String ||
        roles is! List ||
        permissions is! List ||
        modules is! List ||
        requiresPasswordChange is! bool) {
      throw const FormatException('Respuesta de login multitenant invalida.');
    }
    return MultitenantSession(
      accessToken: accessToken,
      refreshToken: json['refresh_token'] as String?,
      tokenType: tokenType,
      tenantId: tenantId,
      userId: userId,
      username: json['username'] as String?,
      roles: roles.map((role) => '$role').toList(),
      permissions: permissions.map((permission) => '$permission').toList(),
      modules: modules.map((module) => '$module').toList(),
      requiresPasswordChange: requiresPasswordChange,
    );
  }

  Map<String, dynamic> toJson() => {
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'token_type': tokenType,
        'tenant_id': tenantId,
        'user_id': userId,
        'username': username,
        'roles': roles,
        'permissions': permissions,
        'modules': modules,
        'requires_password_change': requiresPasswordChange,
      };
}

enum MultitenantAuthFailureType {
  invalidCredentials,
  serverUnavailable,
  invalidResponse,
  sessionUnavailable,
}

class MultitenantAuthException implements Exception {
  final MultitenantAuthFailureType type;
  final String message;

  const MultitenantAuthException(this.type, this.message);

  @override
  String toString() => message;
}

abstract class MultitenantTokenStore {
  Future<void> write({required String key, required String value});
  Future<String?> read({required String key});
  Future<void> delete({required String key});
}

class SecureMultitenantTokenStore implements MultitenantTokenStore {
  const SecureMultitenantTokenStore();

  static const _storage = FlutterSecureStorage();

  @override
  Future<void> write({required String key, required String value}) {
    return _storage.write(key: key, value: value);
  }

  @override
  Future<String?> read({required String key}) {
    return _storage.read(key: key);
  }

  @override
  Future<void> delete({required String key}) {
    return _storage.delete(key: key);
  }
}

class MultitenantApiService {
  MultitenantApiService({
    http.Client? client,
    MultitenantTokenStore? tokenStore,
    String? apiBaseUrl,
  })  : _client = client ?? http.Client(),
        _tokenStore = tokenStore ?? const SecureMultitenantTokenStore(),
        _apiBaseUrl = apiBaseUrl;

  static const accessTokenKey = 'sasu_multitenant_access_token';
  static const refreshTokenKey = 'sasu_multitenant_refresh_token';
  static const tenantKey = 'sasu_multitenant_tenant_id';
  static const sessionKey = 'sasu_multitenant_session';
  static const brandingKey = 'sasu_multitenant_branding_cache';

  final http.Client _client;
  final MultitenantTokenStore _tokenStore;
  final String? _apiBaseUrl;

  Uri _uri(String path) {
    final baseUrl = (_apiBaseUrl ?? AppConfig.current.backendBaseUrl).trim();
    if (baseUrl.isEmpty || (_apiBaseUrl == null && !AppConfig.isMultitenant)) {
      throw StateError(
        'La variante MULTITENANT requiere MULTITENANT_API_BASE_URL.',
      );
    }
    return Uri.parse('$baseUrl$path');
  }

  void _debugResponse(Uri uri, http.Response response) {
    if (!kDebugMode) return;
    Object fieldNames = const <String>[];
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        fieldNames = decoded.keys.toList()..sort();
      }
    } catch (_) {
      fieldNames = 'non-json';
    }
    debugPrint('MULTITENANT ${uri.path} statusCode=${response.statusCode}');
    debugPrint('MULTITENANT response fields=$fieldNames');
  }

  Future<InstitutionBranding> resolveInstitution(String institutionCode) async {
    final uri = _uri('/v2/public/institution/resolve');
    if (kDebugMode) {
      debugPrint('MULTITENANT request POST $uri');
    }
    final response = await _client
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'institution_code': institutionCode.trim()}),
        )
        .timeout(const Duration(seconds: 20));
    _debugResponse(uri, response);
    if (response.statusCode != 200) {
      throw StateError('No se pudo resolver la institucion.');
    }
    final branding = InstitutionBranding.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
    await _tokenStore.write(key: brandingKey, value: response.body);
    return branding;
  }

  Future<MultitenantSession> login({
    required String institutionCode,
    required String username,
    required String password,
  }) async {
    final uri = _uri('/v2/auth/login');
    if (kDebugMode) {
      debugPrint('MULTITENANT request POST $uri');
    }
    try {
      final response = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'institution_code': institutionCode.trim(),
              'username': username.trim(),
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 25));
      _debugResponse(uri, response);
      if (response.statusCode == 401) {
        throw const MultitenantAuthException(
          MultitenantAuthFailureType.invalidCredentials,
          'Credenciales invalidas.',
        );
      }
      if (response.statusCode != 200) {
        throw const MultitenantAuthException(
          MultitenantAuthFailureType.serverUnavailable,
          'Servidor no disponible.',
        );
      }
      try {
        final session = MultitenantSession.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
        await saveSession(session);
        return session;
      } catch (_) {
        throw const MultitenantAuthException(
          MultitenantAuthFailureType.invalidResponse,
          'Error de respuesta del servidor.',
        );
      }
    } on MultitenantAuthException {
      rethrow;
    } on TimeoutException {
      throw const MultitenantAuthException(
        MultitenantAuthFailureType.serverUnavailable,
        'Servidor no disponible.',
      );
    } on http.ClientException {
      throw const MultitenantAuthException(
        MultitenantAuthFailureType.serverUnavailable,
        'Servidor no disponible.',
      );
    }
  }

  Future<void> changeTemporaryPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final token = await _tokenStore.read(key: accessTokenKey);
    if (token == null || token.isEmpty) {
      throw const MultitenantAuthException(
        MultitenantAuthFailureType.sessionUnavailable,
        'Sesion no disponible.',
      );
    }
    final uri = _uri('/v2/auth/change-temporary-password');
    if (kDebugMode) {
      debugPrint('MULTITENANT request POST $uri');
    }
    try {
      final response = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'current_password': currentPassword,
              'new_password': newPassword,
            }),
          )
          .timeout(const Duration(seconds: 25));
      _debugResponse(uri, response);
      if (response.statusCode != 204) {
        throw const MultitenantAuthException(
          MultitenantAuthFailureType.invalidCredentials,
          'No se pudo cambiar la contrasena.',
        );
      }
      await clearSession();
    } on MultitenantAuthException {
      rethrow;
    } on TimeoutException {
      throw const MultitenantAuthException(
        MultitenantAuthFailureType.serverUnavailable,
        'Servidor no disponible.',
      );
    } on http.ClientException {
      throw const MultitenantAuthException(
        MultitenantAuthFailureType.serverUnavailable,
        'Servidor no disponible.',
      );
    }
  }

  Future<MultitenantSession> refresh() async {
    final refreshToken = await _tokenStore.read(key: refreshTokenKey);
    if (refreshToken == null || refreshToken.isEmpty) {
      throw StateError('No hay refresh token.');
    }
    final response = await _client.post(
      _uri('/v2/auth/refresh'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh_token': refreshToken}),
    );
    if (response.statusCode != 200) {
      await clearSession();
      throw StateError('Sesion expirada.');
    }
    final session = MultitenantSession.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
    await saveSession(session);
    return session;
  }

  Future<void> logout() async {
    final token = await _tokenStore.read(key: accessTokenKey);
    if (token != null && token.isNotEmpty) {
      await _client.post(
        _uri('/v2/auth/logout'),
        headers: {'Authorization': 'Bearer $token'},
      );
    }
    await clearSession();
  }

  Future<void> saveSession(MultitenantSession session) async {
    await _tokenStore.write(key: accessTokenKey, value: session.accessToken);
    await _tokenStore.write(
        key: sessionKey, value: jsonEncode(session.toJson()));
    final refreshToken = session.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      await _tokenStore.delete(key: refreshTokenKey);
    } else {
      await _tokenStore.write(key: refreshTokenKey, value: refreshToken);
    }
    await _tokenStore.write(key: tenantKey, value: session.tenantId);
  }

  Future<MultitenantSession?> readSession() async {
    final sessionJson = await _tokenStore.read(key: sessionKey);
    if (sessionJson == null || sessionJson.isEmpty) return null;
    try {
      return MultitenantSession.fromJson(
        jsonDecode(sessionJson) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  Future<InstitutionBranding?> readCachedBranding() async {
    final brandingJson = await _tokenStore.read(key: brandingKey);
    if (brandingJson == null || brandingJson.isEmpty) return null;
    try {
      return InstitutionBranding.fromJson(
        jsonDecode(brandingJson) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  Future<bool> hasSession() async {
    final token = await _tokenStore.read(key: accessTokenKey);
    return token != null && token.isNotEmpty;
  }

  Future<void> clearSession() async {
    await _tokenStore.delete(key: accessTokenKey);
    await _tokenStore.delete(key: refreshTokenKey);
    await _tokenStore.delete(key: tenantKey);
    await _tokenStore.delete(key: sessionKey);
  }
}
