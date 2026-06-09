// lib/ui/connection_indicator.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../data/auth_service.dart';
import '../data/offline_manager.dart';

/// Widget que muestra el estado de conexión y permite sincronización manual
class ConnectionIndicator extends StatefulWidget {
  const ConnectionIndicator({Key? key}) : super(key: key);

  @override
  State<ConnectionIndicator> createState() => _ConnectionIndicatorState();
}

class _ConnectionIndicatorState extends State<ConnectionIndicator> {
  bool _hasInternet = true;
  bool _isOfflineMode = false;
  int _pendingSync = 0;
  bool _isSyncing = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  StreamSubscription<bool>? _offlineModeSub;

  @override
  void initState() {
    super.initState();
    _checkConnection();
    _listenToConnectivity();
    _listenToOfflineMode();
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    _offlineModeSub?.cancel();
    super.dispose();
  }

  Future<void> _checkConnection() async {
    final info = await AuthService.getConnectionInfo();
    if (mounted) {
      setState(() {
        _hasInternet = info['hasInternet'] as bool;
        _isOfflineMode = info['isOfflineMode'] as bool;
        _pendingSync = info['cacheInfo']['pendingSync'] as int;
      });
    }
  }

  void _listenToConnectivity() {
    _connectivitySub =
        OfflineManager.connectivityStream.listen((results) async {
      final hasConnection =
          results.any((result) => result != ConnectivityResult.none);
      if (mounted) {
        setState(() {
          _hasInternet = hasConnection;
        });

        // Si recuperamos conexión, intentar sincronizar automáticamente
        if (hasConnection && _isOfflineMode) {
          await _syncNow();
        }
      }
    });
  }

  void _listenToOfflineMode() {
    _offlineModeSub =
        OfflineManager.offlineModeStream.listen((isOffline) async {
      if (!mounted) return;
      setState(() {
        _isOfflineMode = isOffline;
      });
      if (!isOffline) {
        await _checkConnection();
      }
    });
  }

  Future<void> _syncNow() async {
    if (_isSyncing) return;

    setState(() {
      _isSyncing = true;
    });

    final success = await AuthService.forceSyncNow();

    if (mounted) {
      setState(() {
        _isSyncing = false;
      });

      if (success) {
        await _checkConnection();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Sincronización completada'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Error: Sin conexión a internet'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // No mostrar nada si todo está normal (online y sin datos pendientes)
    if (_hasInternet && !_isOfflineMode && _pendingSync == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _isOfflineMode ? Colors.orange.shade100 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isOfflineMode ? Colors.orange : Colors.blue,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          // Ícono de estado
          Icon(
            _isOfflineMode ? Icons.cloud_off : Icons.cloud_queue,
            color:
                _isOfflineMode ? Colors.orange.shade700 : Colors.blue.shade700,
            size: 28,
          ),
          const SizedBox(width: 12),

          // Información de estado
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _isOfflineMode ? 'Modo Sin Conexión' : 'Datos Pendientes',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: _isOfflineMode
                        ? Colors.orange.shade900
                        : Colors.blue.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isOfflineMode
                      ? 'Los cambios se sincronizarán cuando tengas internet'
                      : _pendingSync > 0
                          ? '$_pendingSync acciones pendientes de sincronización'
                          : 'Conectando...',
                  style: TextStyle(
                    fontSize: 12,
                    color: _isOfflineMode
                        ? Colors.orange.shade700
                        : Colors.blue.shade700,
                  ),
                ),
              ],
            ),
          ),

          // Botón de sincronización
          if (_hasInternet && _pendingSync > 0)
            _isSyncing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton(
                    icon: const Icon(Icons.sync),
                    color: Colors.green,
                    tooltip: 'Sincronizar ahora',
                    onPressed: _syncNow,
                  ),
        ],
      ),
    );
  }
}

/// Versión compacta del indicador para el AppBar
class ConnectionBadge extends StatefulWidget {
  const ConnectionBadge({Key? key}) : super(key: key);

  @override
  State<ConnectionBadge> createState() => _ConnectionBadgeState();
}

class _ConnectionBadgeState extends State<ConnectionBadge> {
  bool _isOfflineMode = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  StreamSubscription<bool>? _offlineModeSub;

  @override
  void initState() {
    super.initState();
    _checkOfflineMode();
    _listenToConnectivity();
    _listenToOfflineMode();
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    _offlineModeSub?.cancel();
    super.dispose();
  }

  Future<void> _checkOfflineMode() async {
    final isOffline = await AuthService.isOfflineMode();
    if (mounted) {
      setState(() {
        _isOfflineMode = isOffline;
      });
    }
  }

  void _listenToConnectivity() {
    _connectivitySub =
        OfflineManager.connectivityStream.listen((results) async {
      if (!mounted) return;
      await _checkOfflineMode();
    });
  }

  void _listenToOfflineMode() {
    _offlineModeSub = OfflineManager.offlineModeStream.listen((isOffline) {
      if (!mounted) return;
      setState(() {
        _isOfflineMode = isOffline;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isOfflineMode) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange.shade700,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(
            Icons.cloud_off,
            size: 16,
            color: Colors.white,
          ),
          SizedBox(width: 4),
          Text(
            'OFFLINE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
