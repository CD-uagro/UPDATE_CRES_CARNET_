// lib/main.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/dashboard_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/multitenant_entry_screen.dart';
import 'data/db.dart' as db_data;
import 'data/auth_service.dart';
import 'services/version_service.dart';
import 'services/auto_sync_service.dart';
import 'config/app_config.dart';
import 'config/app_environment.dart';
import 'data/demo/loyola_demo_data.dart';
// Tema institucional UAGro
import 'ui/app_theme.dart';
import 'ui/app_theme_mobile.dart'; // Tema adaptable para móvil
import 'ui/mobile_adaptive.dart'; // Detección de plataforma

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cargar información de versión
  await VersionService().loadVersion();

  // Inicializar servicio de sincronización automática
  AutoSyncService.instance.initialize();

  // Diagnóstico de API_BASE_URL solo en debug
  if (kDebugMode) {
    print('APP_VARIANT=${AppConfig.current.internalId}');
    print(
        'API_BASE_URL=${AppConfig.current.backendBaseUrl.isEmpty ? "(sin backend demo)" : AppConfig.current.backendBaseUrl}');
    print(
        'Platform: ${MobileAdaptive.isMobilePlatform ? "Mobile (Android/iOS)" : "Desktop (Windows/Linux/Mac)"}');
  }

  final db = db_data.AppDatabase(); // Instancia de la base local (Drift)
  if (AppConfig.isLoyolaDemo) {
    await LoyolaDemoData.seedLocalDatabase(db);
  }
  runApp(MyApp(db: db));
}

class MyApp extends StatelessWidget {
  final db_data.AppDatabase db;
  const MyApp({super.key, required this.db});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.current.windowTitle,
      debugShowCheckedModeBanner: false,
      // Aplicamos el tema institucional UAGro
      // En móvil (Android/iOS) se aplicará automáticamente el tema adaptable
      theme: AppTheme.light,

      // Builder para aplicar adaptación móvil al tema
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();

        Widget app = Shortcuts(
          shortcuts: const <ShortcutActivator, Intent>{
            SingleActivator(LogicalKeyboardKey.backspace):
                DeleteCharacterIntent(forward: false),
            SingleActivator(LogicalKeyboardKey.backspace, shift: true):
                DeleteCharacterIntent(forward: false),
            SingleActivator(LogicalKeyboardKey.delete):
                DeleteCharacterIntent(forward: true),
            SingleActivator(LogicalKeyboardKey.delete, shift: true):
                DeleteCharacterIntent(forward: true),
          },
          child: DefaultTextEditingShortcuts(child: child),
        );

        // Si es móvil, aplicar tema adaptado
        if (MobileAdaptive.isMobilePlatform) {
          app = Theme(
            data: AppThemeMobile.adaptiveTheme(
              context,
              baseTheme: AppTheme.light,
            ),
            child: app,
          );
        }

        return app;
      },

      // 🔐 DOBLE AUTENTICACIÓN:
      // 1. Primero verificamos login con backend (LoginScreen o Dashboard)
      // 2. Luego AuthGate aplica PIN local de seguridad
      home: FutureBuilder<bool>(
        future: AuthService.isLoggedIn(),
        builder: (context, snapshot) {
          // Mostrando splash mientras carga
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          // Si tiene sesión activa, ir directamente al Dashboard
          // NOTA: AuthGate (PIN) deshabilitado temporalmente para pruebas de FASE 10
          if (snapshot.data == true) {
            return DashboardScreen(db: db);
            // TODO: Restaurar AuthGate después de pruebas
            // return AuthGate(
            //   autoLock: const Duration(minutes: 10),
            //   child: DashboardScreen(db: db),
            // );
          }

          return unauthenticatedHomeForVariant(AppConfig.variant, db);
        },
      ),
    );
  }
}

Widget unauthenticatedHomeForVariant(
  AppVariant variant,
  db_data.AppDatabase db,
) {
  if (variant == AppVariant.multitenant) {
    return MultitenantEntryScreen(db: db);
  }

  return LoginScreen(db: db);
}
