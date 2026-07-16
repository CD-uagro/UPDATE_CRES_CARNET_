import 'dart:convert';

import 'package:cres_carnets_ibmcloud/config/app_config.dart';
import 'package:cres_carnets_ibmcloud/data/db.dart';
import 'package:cres_carnets_ibmcloud/data/multitenant_api_service.dart';
import 'package:cres_carnets_ibmcloud/screens/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class MemoryMultitenantStore implements MultitenantTokenStore {
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

const _session = MultitenantSession(
  accessToken: 'test-token',
  refreshToken: 'test-refresh',
  tokenType: 'bearer',
  tenantId: 'loyola-demo',
  userId: 'loyola-demo-admin-loyola',
  username: 'admin.loyola',
  roles: ['tenant_admin'],
  permissions: [
    'students.read',
    'students.write',
    'appointments.read',
    'appointments.write',
    'audit.read',
  ],
  modules: ['students', 'appointments', 'audit'],
  requiresPasswordChange: false,
);

void main() {
  testWidgets(
    'multitenant dashboard shows licensed LOYOLA modules without legacy text',
    (tester) async {
      final db = AppDatabase();
      addTearDown(db.close);
      final store = MemoryMultitenantStore();
      final api = MultitenantApiService(
        tokenStore: store,
        apiBaseUrl: 'https://staging.example.invalid',
      );
      await api.saveSession(_session);
      await store.write(
        key: MultitenantApiService.brandingKey,
        value: jsonEncode({
          'institution_id': 'loyola-demo',
          'display_name': 'LOYOLA',
          'status': 'trial',
          'branding': {'subtitle': 'Demo institucional'},
          'enabled_modules': ['students', 'appointments', 'audit'],
          'demo': true,
        }),
      );

      await tester.pumpWidget(
        MaterialApp(home: DashboardScreen(db: db, multitenantApi: api)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('admin.loyola'), findsWidgets);
      expect(find.text('LOYOLA'), findsOneWidget);
      expect(find.text('Sistema de Atencion en Salud Digital'), findsWidgets);
      expect(find.text('Estudiantes'), findsOneWidget);
      expect(find.text('Citas'), findsOneWidget);
      expect(find.text('Auditoria'), findsOneWidget);
      expect(find.text('Sin Permisos Asignados'), findsNothing);
      expect(find.text('Campus pendiente'), findsNothing);
      expect(find.textContaining('UAGro'), findsNothing);
      expect(find.textContaining('CRES'), findsNothing);
      expect(find.textContaining('SASU'), findsNothing);
      expect(find.textContaining('Observatorio SASU'), findsNothing);

      await tester.tap(find.text('Estudiantes'));
      await tester.pumpAndSettle();
      expect(find.text('Modulo en preparacion'), findsOneWidget);
    },
    skip: !AppConfig.isMultitenant,
  );
}
