import 'package:cres_carnets_ibmcloud/config/app_config.dart';
import 'package:cres_carnets_ibmcloud/config/app_environment.dart';
import 'package:cres_carnets_ibmcloud/data/db.dart';
import 'package:cres_carnets_ibmcloud/main.dart' as app;
import 'package:cres_carnets_ibmcloud/screens/auth/multitenant_entry_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'APP_VARIANT=MULTITENANT starts at MultitenantEntryScreen',
    (tester) async {
      final db = AppDatabase();
      addTearDown(db.close);

      await tester.pumpWidget(
        MaterialApp(
          home: app.unauthenticatedHomeForVariant(
            AppVariant.multitenant,
            db,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(MultitenantEntryScreen), findsOneWidget);
      expect(find.text('Codigo institucional'), findsOneWidget);
      expect(find.text('Continuar'), findsOneWidget);
      expect(find.textContaining('UNIVERSIDAD AUTONOMA DE GUERRERO'),
          findsNothing);
      expect(find.textContaining('SASU'), findsNothing);
      expect(find.textContaining('CRES Llano Largo'), findsNothing);
      expect(find.textContaining('Campus'), findsNothing);
    },
    skip: !AppConfig.isMultitenant,
  );
}
