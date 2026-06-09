// lib/services/auto_sync_service.dart
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../data/offline_manager.dart';
import '../data/auth_service.dart';

/// Servicio global que escucha cambios de conectividad y dispara
/// sincronización automática cuando se recupera internet
class AutoSyncService {
  static AutoSyncService? _instance;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _wasOffline = false;
  bool _isSyncing = false;

  AutoSyncService._();

  /// Singleton
  static AutoSyncService get instance {
    _instance ??= AutoSyncService._();
    return _instance!;
  }

  /// Inicializa el listener de conectividad
  void initialize() {
    print('[AUTO_SYNC] 🚀 Inicializando servicio de sincronización automática');

    // Verificar estado inicial
    _checkInitialState();

    // Escuchar cambios de conectividad
    _connectivitySub =
        OfflineManager.connectivityStream.listen((results) async {
      final hasConnection =
          results.any((result) => result != ConnectivityResult.none);

      if (hasConnection && _wasOffline) {
        print(
            '[AUTO_SYNC] 🌐 Conexión recuperada - disparando sincronización automática');
        await _triggerSync();
      }

      _wasOffline = !hasConnection;
    });
  }

  /// Verifica el estado inicial de conectividad y offline mode
  Future<void> _checkInitialState() async {
    final hasConnection = await OfflineManager.hasInternetConnection();
    final isOfflineMode = await OfflineManager.isOfflineModeEnabled();

    _wasOffline = !hasConnection || isOfflineMode;

    print(
        '[AUTO_SYNC] 📊 Estado inicial: hasConnection=$hasConnection, isOfflineMode=$isOfflineMode');
  }

  /// Dispara sincronización si no está ya en proceso
  Future<void> _triggerSync() async {
    if (_isSyncing) {
      print('[AUTO_SYNC] ⏭️ Sincronización ya en proceso, omitiendo...');
      return;
    }

    try {
      _isSyncing = true;
      print('[AUTO_SYNC] 🔄 Iniciando sincronización automática...');

      final success = await AuthService.forceSyncNow();

      if (success) {
        print(
            '[AUTO_SYNC] ✅ Sincronización automática completada exitosamente');
      } else {
        print(
            '[AUTO_SYNC] ⚠️ Sincronización automática falló (sin conexión o error)');
      }
    } catch (e) {
      print('[AUTO_SYNC] ❌ Error en sincronización automática: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Detiene el listener (llamar al cerrar la app)
  void dispose() {
    print('[AUTO_SYNC] 🛑 Deteniendo servicio de sincronización automática');
    _connectivitySub?.cancel();
  }
}
