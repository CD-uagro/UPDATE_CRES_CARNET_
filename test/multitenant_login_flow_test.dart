import 'dart:async';
import 'dart:convert';

import 'package:cres_carnets_ibmcloud/data/db.dart';
import 'package:cres_carnets_ibmcloud/data/multitenant_api_service.dart';
import 'package:cres_carnets_ibmcloud/screens/auth/multitenant_entry_screen.dart';
import 'package:cres_carnets_ibmcloud/screens/auth/temporary_password_change_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

const _loginResponse = {
  'access_token': 'test-token',
  'refresh_token': 'test-refresh',
  'token_type': 'bearer',
  'tenant_id': 'loyola-demo',
  'user_id': 'loyola-demo-admin-loyola',
  'username': 'admin.loyola',
  'roles': ['tenant_admin'],
  'permissions': [
    'students.read',
    'students.write',
    'appointments.read',
    'appointments.write',
    'audit.read',
  ],
  'modules': ['students', 'appointments', 'audit'],
  'requires_password_change': true,
};

class MemoryTokenStore implements MultitenantTokenStore {
  final values = <String, String>{};

  @override
  Future<void> delete({required String key}) async {
    values.remove(key);
  }

  @override
  Future<String?> read({required String key}) async => values[key];

  @override
  Future<void> write({required String key, required String value}) async {
    values[key] = value;
  }
}

class RecordingClient extends http.BaseClient {
  RecordingClient(this.handler);

  final FutureOr<http.Response> Function(http.Request request) handler;
  final requests = <http.Request>[];
  final bodies = <String>[];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final http.Request captured = request as http.Request;
    requests.add(captured);
    bodies.add(captured.body);
    final response = await handler(captured);
    return http.StreamedResponse(
      Stream.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
      reasonPhrase: response.reasonPhrase,
      request: request,
    );
  }
}

class FailingClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    throw http.ClientException('connection failed', request.url);
  }
}

class FakeLoginApi extends MultitenantApiService {
  FakeLoginApi(this.session)
      : super(apiBaseUrl: 'https://staging.example.invalid');

  final MultitenantSession session;

  @override
  Future<InstitutionBranding> resolveInstitution(String institutionCode) async {
    return const InstitutionBranding(
      institutionId: 'loyola-demo',
      displayName: 'LOYOLA',
      status: 'trial',
      branding: {},
      enabledModules: ['students', 'appointments', 'audit'],
      demo: true,
    );
  }

  @override
  Future<MultitenantSession> login({
    required String institutionCode,
    required String username,
    required String password,
  }) async {
    return session;
  }
}

void main() {
  group('Multitenant login API', () {
    test('accepts temporary password response and stores token', () async {
      final store = MemoryTokenStore();
      final client = RecordingClient((_) async {
        return http.Response(jsonEncode(_loginResponse), 200);
      });
      final api = MultitenantApiService(
        client: client,
        tokenStore: store,
        apiBaseUrl: 'https://staging.example.invalid',
      );

      final session = await api.login(
        institutionCode: ' LOYOLA-DEMO-2026 ',
        username: ' admin.loyola ',
        password: r'Temp !@# 123$%^',
      );

      expect(session.requiresPasswordChange, isTrue);
      expect(session.accessToken, 'test-token');
      expect(session.refreshToken, 'test-refresh');
      expect(session.roles, ['tenant_admin']);
      expect(session.permissions, contains('students.read'));
      expect(session.modules, ['students', 'appointments', 'audit']);
      expect(
        store.values[MultitenantApiService.accessTokenKey],
        'test-token',
      );
    });

    test('sends exact login JSON and does not transform password symbols',
        () async {
      final client = RecordingClient((_) async {
        return http.Response(jsonEncode(_loginResponse), 200);
      });
      final api = MultitenantApiService(
        client: client,
        tokenStore: MemoryTokenStore(),
        apiBaseUrl: 'https://staging.example.invalid',
      );
      const password = r'  Abc!@# $%^  ';

      await api.login(
        institutionCode: ' LOYOLA-DEMO-2026 ',
        username: ' admin.loyola ',
        password: password,
      );

      final body = jsonDecode(client.bodies.single) as Map<String, dynamic>;
      expect(body.keys.toSet(), {'institution_code', 'username', 'password'});
      expect(body['institution_code'], 'LOYOLA-DEMO-2026');
      expect(body['username'], 'admin.loyola');
      expect(body['password'], password);
    });

    test('maps HTTP 401 to invalid credentials', () async {
      final api = MultitenantApiService(
        client: RecordingClient((_) async => http.Response('{}', 401)),
        tokenStore: MemoryTokenStore(),
        apiBaseUrl: 'https://staging.example.invalid',
      );

      expect(
        () => api.login(
          institutionCode: 'LOYOLA-DEMO-2026',
          username: 'admin.loyola',
          password: 'bad-password',
        ),
        throwsA(
          isA<MultitenantAuthException>().having(
            (error) => error.type,
            'type',
            MultitenantAuthFailureType.invalidCredentials,
          ),
        ),
      );
    });

    test('maps connection failure to server unavailable', () async {
      final api = MultitenantApiService(
        client: FailingClient(),
        tokenStore: MemoryTokenStore(),
        apiBaseUrl: 'https://staging.example.invalid',
      );

      expect(
        () => api.login(
          institutionCode: 'LOYOLA-DEMO-2026',
          username: 'admin.loyola',
          password: 'not-real',
        ),
        throwsA(
          isA<MultitenantAuthException>().having(
            (error) => error.type,
            'type',
            MultitenantAuthFailureType.serverUnavailable,
          ),
        ),
      );
    });
  });

  testWidgets('temporary password login navigates to password change',
      (tester) async {
    final db = AppDatabase();
    addTearDown(db.close);
    final api = FakeLoginApi(
      MultitenantSession.fromJson(Map<String, dynamic>.from(_loginResponse)),
    );

    await tester.pumpWidget(
      MaterialApp(home: MultitenantEntryScreen(db: db, api: api)),
    );
    await tester.tap(find.text('Continuar'));
    await tester.pump();
    await tester.enterText(find.byType(TextField).at(1), 'admin.loyola');
    await tester.enterText(find.byType(TextField).at(2), 'Temp123!');
    await tester.tap(find.text('Iniciar sesion'));
    await tester.pumpAndSettle();

    expect(find.byType(TemporaryPasswordChangeScreen), findsOneWidget);
    expect(find.text('Cambiar contrasena temporal'), findsOneWidget);
  });
}
