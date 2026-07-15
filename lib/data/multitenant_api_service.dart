import 'dart:async';
import 'dart:convert';

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
  final String refreshToken;
  final String tenantId;
  final String userId;
  final bool requiresPasswordChange;

  const MultitenantSession({
    required this.accessToken,
    required this.refreshToken,
    required this.tenantId,
    required this.userId,
    required this.requiresPasswordChange,
  });

  factory MultitenantSession.fromJson(Map<String, dynamic> json) {
    return MultitenantSession(
      accessToken: json['access_token'] as String? ?? '',
      refreshToken: json['refresh_token'] as String? ?? '',
      tenantId: json['tenant_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      requiresPasswordChange: json['requires_password_change'] == true,
    );
  }
}

class MultitenantApiService {
  MultitenantApiService({http.Client? client})
      : _client = client ?? http.Client();

  static const _storage = FlutterSecureStorage();
  static const _accessTokenKey = 'sasu_multitenant_access_token';
  static const _refreshTokenKey = 'sasu_multitenant_refresh_token';
  static const _tenantKey = 'sasu_multitenant_tenant_id';
  static const _brandingKey = 'sasu_multitenant_branding_cache';

  final http.Client _client;

  Uri _uri(String path) {
    final baseUrl = AppConfig.current.backendBaseUrl.trim();
    if (!AppConfig.isMultitenant || baseUrl.isEmpty) {
      throw StateError(
        'La variante MULTITENANT requiere MULTITENANT_API_BASE_URL.',
      );
    }
    return Uri.parse('$baseUrl$path');
  }

  Future<InstitutionBranding> resolveInstitution(String institutionCode) async {
    final response = await _client
        .post(
          _uri('/v2/public/institution/resolve'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'institution_code': institutionCode.trim()}),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw StateError('No se pudo resolver la institucion.');
    }
    final branding = InstitutionBranding.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
    await _storage.write(key: _brandingKey, value: response.body);
    return branding;
  }

  Future<MultitenantSession> login({
    required String institutionCode,
    required String username,
    required String password,
  }) async {
    final response = await _client
        .post(
          _uri('/v2/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'institution_code': institutionCode.trim(),
            'username': username.trim(),
            'password': password,
          }),
        )
        .timeout(const Duration(seconds: 25));
    if (response.statusCode != 200) {
      throw StateError('Credenciales invalidas.');
    }
    final session = MultitenantSession.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
    await saveSession(session);
    return session;
  }

  Future<MultitenantSession> refresh() async {
    final refreshToken = await _storage.read(key: _refreshTokenKey);
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
    final token = await _storage.read(key: _accessTokenKey);
    if (token != null && token.isNotEmpty) {
      await _client.post(
        _uri('/v2/auth/logout'),
        headers: {'Authorization': 'Bearer $token'},
      );
    }
    await clearSession();
  }

  Future<void> saveSession(MultitenantSession session) async {
    await _storage.write(key: _accessTokenKey, value: session.accessToken);
    await _storage.write(key: _refreshTokenKey, value: session.refreshToken);
    await _storage.write(key: _tenantKey, value: session.tenantId);
  }

  Future<bool> hasSession() async {
    final token = await _storage.read(key: _accessTokenKey);
    return token != null && token.isNotEmpty;
  }

  Future<void> clearSession() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _tenantKey);
  }
}
