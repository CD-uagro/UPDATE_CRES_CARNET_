import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cres_carnets_ibmcloud/screens/form_screen.dart';
import 'package:cres_carnets_ibmcloud/screens/nueva_nota_screen.dart';
import 'package:cres_carnets_ibmcloud/screens/vaccination_screen.dart';
import 'package:cres_carnets_ibmcloud/screens/promocion_salud_screen.dart';
import 'package:cres_carnets_ibmcloud/screens/tickets_screen.dart';
import 'package:cres_carnets_ibmcloud/screens/appointments_screen.dart';
import 'package:cres_carnets_ibmcloud/screens/auth/login_screen.dart';
import 'package:cres_carnets_ibmcloud/screens/about_screen.dart';
import 'package:cres_carnets_ibmcloud/screens/database_cleaner_screen.dart';
import 'package:cres_carnets_ibmcloud/screens/pending_sync_screen.dart';
import 'package:cres_carnets_ibmcloud/ui/uagro_theme.dart';
import 'package:cres_carnets_ibmcloud/ui/connection_indicator.dart';
import 'package:cres_carnets_ibmcloud/ui/widgets/recent_activity_panel.dart';
import 'package:cres_carnets_ibmcloud/ui/mobile_adaptive.dart'; // Para detectar móvil
import 'package:cres_carnets_ibmcloud/data/db.dart' as app_db;
import 'package:cres_carnets_ibmcloud/data/api_service.dart';
import 'package:cres_carnets_ibmcloud/data/auth_service.dart';
import 'package:cres_carnets_ibmcloud/data/sync_service.dart';
import 'package:cres_carnets_ibmcloud/models/appointment_admin_model.dart';
import 'package:cres_carnets_ibmcloud/services/version_service.dart';
import 'package:cres_carnets_ibmcloud/services/update_manager.dart';
import 'package:cres_carnets_ibmcloud/widgets/appointment_toast.dart';
import 'package:cres_carnets_ibmcloud/widgets/pending_appointments_reminder_toast.dart';
import 'package:url_launcher/url_launcher.dart';

/// Dashboard principal después del login
/// Muestra las 4 opciones principales del sistema
class DashboardScreen extends StatefulWidget {
  final app_db.AppDatabase db;
  const DashboardScreen({super.key, required this.db});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const String _observatoryUrl = String.fromEnvironment(
    'SASU_OBSERVATORIO_URL',
    defaultValue: '',
  );
  static const Duration _pendingAppointmentsReminderInterval =
      Duration(hours: 1);

  AuthUser? _currentUser;
  bool _loadingUser = true;

  // Permisos del usuario actual
  bool _canCreateCarnet = false;
  bool _canManageExpedientes = false;
  bool _canViewPromocion = false;
  bool _canViewVacunacion = false;
  bool _canViewTickets = false;
  bool _canViewAppointments = false;
  int _pendingAppointmentRequests = 0;
  bool _pollingAppointments = false;
  Timer? _appointmentPollingTimer;
  final Set<String> _notifiedAppointmentIds = <String>{};
  final List<AppointmentAdminModel> _appointmentToasts = [];
  final Map<String, Timer> _appointmentToastTimers = {};
  DateTime? _lastPendingReminderAt;
  Timer? _pendingReminderTimer;
  bool _pendingReminderVisible = false;
  int _pendingReminderCount = 0;
  bool _appointmentsScreenOpen = false;

  // Manejador de actualizaciones
  UpdateManager? _updateManager;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadPermissions();
    _initUpdateManager();
  }

  /// Inicializar el sistema de actualizaciones
  Future<void> _initUpdateManager() async {
    try {
      // Obtener versión del servicio singleton
      final versionService = VersionService();
      if (!versionService.isLoaded) {
        await versionService.loadVersion();
      }

      final versionInfo = versionService.versionInfo;
      if (versionInfo == null) {
        debugPrint('⚠️ No se pudo cargar información de versión');
        return;
      }

      _updateManager = UpdateManager(
        currentVersion: versionInfo.version,
        currentBuild: versionInfo.buildNumber,
      );

      // Verificar actualizaciones automáticamente después de cargar el dashboard
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _updateManager != null) {
          _updateManager!.checkForUpdatesAutomatic(context);
        }
      });
    } catch (e) {
      debugPrint('⚠️ Error al inicializar UpdateManager: $e');
    }
  }

  @override
  void dispose() {
    _appointmentPollingTimer?.cancel();
    for (final timer in _appointmentToastTimers.values) {
      timer.cancel();
    }
    _pendingReminderTimer?.cancel();
    _updateManager?.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    final user = await AuthService.getCurrentUser();
    if (mounted) {
      setState(() {
        _currentUser = user;
        _loadingUser = false;
      });
    }
  }

  /// Cargar permisos del usuario actual
  Future<void> _loadPermissions() async {
    final canCarnet = await AuthService.hasPermission('carnets:write');
    final canExpedientes = await AuthService.hasPermission('notas:write');
    final canPromocion = await AuthService.hasPermission('promociones:read');
    final canVacunacion = await AuthService.hasPermission('vacunacion:read');
    final canTickets = await AuthService.hasPermission('tickets:read');
    final canAppointments = await AuthService.hasPermission('citas:read');

    if (mounted) {
      setState(() {
        _canCreateCarnet = canCarnet;
        _canManageExpedientes = canExpedientes;
        _canViewPromocion = canPromocion;
        _canViewVacunacion = canVacunacion;
        _canViewTickets = canTickets;
        _canViewAppointments = canAppointments;
      });
    }
    if (canAppointments) {
      _startAppointmentPolling();
    } else {
      _stopAppointmentPolling();
    }
  }

  Future<void> _loadPendingAppointmentRequests() async {
    await _pollAppointmentRequests(showToasts: false);
  }

  void _startAppointmentPolling() {
    _appointmentPollingTimer?.cancel();
    _pollAppointmentRequests();
    _appointmentPollingTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      _pollAppointmentRequests();
    });
  }

  void _stopAppointmentPolling() {
    _appointmentPollingTimer?.cancel();
    _appointmentPollingTimer = null;
  }

  Future<void> _pollAppointmentRequests({bool showToasts = true}) async {
    if (_pollingAppointments) return;
    _pollingAppointments = true;
    try {
      final appointments =
          await ApiService.getAppointments(status: 'requested');
      if (!mounted) return;
      setState(() {
        _pendingAppointmentRequests = appointments.length;
      });
      if (showToasts) {
        _showNewAppointmentToasts(appointments);
        _showPendingAppointmentsReminder(appointments.length);
      }
    } catch (e) {
      debugPrint('No se pudo cargar contador de citas pendientes: $e');
    } finally {
      _pollingAppointments = false;
    }
  }

  void _showNewAppointmentToasts(List<AppointmentAdminModel> appointments) {
    final requested = appointments
        .where(
          (appointment) =>
              appointment.status == 'requested' &&
              !_notifiedAppointmentIds.contains(appointment.id),
        )
        .toList()
      ..sort((a, b) {
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });

    for (final appointment in requested) {
      if (_appointmentToasts.length >= 3) break;
      if (_appointmentToasts.any((item) => item.id == appointment.id)) {
        continue;
      }
      _notifiedAppointmentIds.add(appointment.id);
      setState(() {
        _appointmentToasts.add(appointment);
      });
      _appointmentToastTimers[appointment.id] =
          Timer(const Duration(seconds: 10), () {
        _dismissAppointmentToast(appointment.id);
      });
    }
  }

  void _dismissAppointmentToast(String appointmentId) {
    _appointmentToastTimers.remove(appointmentId)?.cancel();
    if (!mounted) return;
    setState(() {
      _appointmentToasts.removeWhere((item) => item.id == appointmentId);
    });
  }

  void _showPendingAppointmentsReminder(int pendingCount) {
    if (!_shouldShowPendingReminder(pendingCount)) return;
    _lastPendingReminderAt = DateTime.now();
    _pendingReminderTimer?.cancel();
    setState(() {
      _pendingReminderCount = pendingCount;
      _pendingReminderVisible = true;
    });
    _pendingReminderTimer = Timer(const Duration(seconds: 10), () {
      _dismissPendingReminder();
    });
  }

  bool _shouldShowPendingReminder(int pendingCount) {
    if (pendingCount <= 0) return false;
    if (_pendingReminderVisible || _appointmentsScreenOpen) return false;
    final lastReminder = _lastPendingReminderAt;
    if (lastReminder == null) return true;
    return DateTime.now().difference(lastReminder) >=
        _pendingAppointmentsReminderInterval;
  }

  void _dismissPendingReminder() {
    _pendingReminderTimer?.cancel();
    _pendingReminderTimer = null;
    if (!mounted || !_pendingReminderVisible) return;
    setState(() {
      _pendingReminderVisible = false;
    });
  }

  Future<void> _openPendingAppointmentsReminder() async {
    _dismissPendingReminder();
    await _openAppointmentsScreen(initialStatus: 'requested');
  }

  Future<void> _openAppointmentFromToast(
    AppointmentAdminModel appointment,
  ) async {
    _dismissAppointmentToast(appointment.id);
    await _openAppointmentsScreen(
      initialStatus: 'requested',
      initialAppointmentId: appointment.id,
    );
  }

  Future<void> _openAppointmentsScreen({
    String? initialStatus,
    String? initialAppointmentId,
  }) async {
    _appointmentsScreenOpen = true;
    try {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AppointmentsScreen(
            initialStatus: initialStatus,
            initialAppointmentId: initialAppointmentId,
          ),
        ),
      );
    } finally {
      _appointmentsScreenOpen = false;
    }
    if (mounted) {
      _loadPendingAppointmentRequests();
    }
  }

  /// Obtener string de versión actual
  Future<String> _getVersionString() async {
    try {
      final versionService = VersionService();
      if (!versionService.isLoaded) {
        await versionService.loadVersion();
      }
      final info = versionService.versionInfo;
      if (info != null) {
        return '${info.version} (${info.buildNumber})';
      }
    } catch (e) {
      debugPrint('Error al obtener versión: $e');
    }
    return 'Versión no disponible';
  }

  /// Verificar permiso antes de navegar
  Future<bool> _checkPermission(String permission, String feature) async {
    final hasPermission = await AuthService.hasPermission(permission);

    if (!hasPermission && mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.block, color: UAGroColors.rojoEscudo),
              const SizedBox(width: 8),
              const Text('Acceso Denegado'),
            ],
          ),
          content: Text(
            'No tienes permiso para acceder a "$feature".\n\n'
            'Contacta al administrador si necesitas este acceso.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
    }

    return hasPermission;
  }

  Future<void> _handleSyncPendingData() async {
    // Mostrar indicador de progreso
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Sincronizando datos pendientes...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final syncService = SyncService(widget.db);
      final result = await syncService.syncAll();

      // Cerrar indicador de progreso
      if (mounted) Navigator.pop(context);

      // Mostrar resultado
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  result.hasErrors ? Icons.warning : Icons.check_circle,
                  color: result.hasErrors ? Colors.orange : Colors.green,
                ),
                const SizedBox(width: 8),
                const Text('Sincronización Completada'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (result.totalPending == 0)
                    const Text('✅ No había datos pendientes para sincronizar')
                  else ...[
                    Text('📊 Total items procesados: ${result.totalPending}'),
                    const SizedBox(height: 8),
                    Text('✅ Sincronizados: ${result.totalSynced}',
                        style: const TextStyle(color: Colors.green)),
                    if (result.totalErrors > 0)
                      Text('❌ Con errores: ${result.totalErrors}',
                          style: const TextStyle(color: Colors.red)),
                    const Divider(),
                    if (result.recordsSynced > 0 || result.recordsErrors > 0)
                      Text(
                          'Expedientes: ${result.recordsSynced}✓ ${result.recordsErrors}✗'),
                    if (result.notesSynced > 0 || result.notesErrors > 0)
                      Text(
                          'Notas: ${result.notesSynced}✓ ${result.notesErrors}✗'),
                    if (result.citasSynced > 0 || result.citasErrors > 0)
                      Text(
                          'Citas: ${result.citasSynced}✓ ${result.citasErrors}✗'),
                    if (result.vacunacionesSynced > 0 ||
                        result.vacunacionesErrors > 0)
                      Text(
                          'Vacunaciones: ${result.vacunacionesSynced}✓ ${result.vacunacionesErrors}✗'),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Cerrar indicador de progreso
      if (mounted) Navigator.pop(context);

      // Mostrar error
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.error, color: Colors.red),
                SizedBox(width: 8),
                Text('Error'),
              ],
            ),
            content: Text('Error al sincronizar datos:\n$e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro que deseas salir?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: UAGroColors.rojoEscudo,
              foregroundColor: Colors.white,
            ),
            child: const Text('Salir'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await AuthService.logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LoginScreen(db: widget.db)),
          (route) => false,
        );
      }
    }
  }

  Future<void> _openObservatory() async {
    if (_observatoryUrl.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Observatorio pendiente de configurar'),
        ),
      );
      return;
    }

    final uri = Uri.tryParse(_observatoryUrl);
    if (uri == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('URL del Observatorio no valida'),
        ),
      );
      return;
    }

    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No fue posible abrir el Observatorio'),
        ),
      );
    }
  }

  /// Acciones compactas para móvil (solo iconos esenciales + menú)
  List<Widget> _buildMobileActions(BuildContext context) {
    return [
      const ConnectionBadge(),
      // Solo sync rápido y menú desplegable en móvil
      IconButton(
        icon: const Icon(Icons.sync),
        tooltip: 'Sincronizar',
        iconSize: 20, // Icono más pequeño
        onPressed: _handleSyncPendingData,
      ),
      PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, size: 20),
        onSelected: (value) {
          switch (value) {
            case 'pending':
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PendingSyncScreen(db: widget.db),
                ),
              );
              break;
            case 'clean':
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DatabaseCleanerScreen(db: widget.db),
                ),
              );
              break;
            case 'update':
              if (_updateManager != null) {
                _updateManager!.checkForUpdatesManual(context);
              }
              break;
            case 'about':
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AboutScreen(db: widget.db),
                ),
              );
              break;
            case 'logout':
              _handleLogout();
              break;
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'pending',
            child: Row(
              children: [
                Icon(Icons.cloud_sync, size: 18),
                SizedBox(width: 8),
                Text('Datos pendientes', style: TextStyle(fontSize: 13)),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'clean',
            child: Row(
              children: [
                Icon(Icons.cleaning_services, size: 18),
                SizedBox(width: 8),
                Text('Gestión datos', style: TextStyle(fontSize: 13)),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'update',
            child: Row(
              children: [
                Icon(Icons.system_update, size: 18),
                SizedBox(width: 8),
                Text('Actualizaciones', style: TextStyle(fontSize: 13)),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'about',
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 18),
                SizedBox(width: 8),
                Text('Acerca de', style: TextStyle(fontSize: 13)),
              ],
            ),
          ),
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: 'logout',
            child: Row(
              children: [
                Icon(Icons.logout, size: 18, color: Colors.red),
                SizedBox(width: 8),
                Text('Cerrar sesión',
                    style: TextStyle(fontSize: 13, color: Colors.red)),
              ],
            ),
          ),
        ],
      ),
    ];
  }

  /// Acciones completas para desktop (todos los iconos visibles)
  List<Widget> _buildDesktopActions(BuildContext context) {
    return [
      const ConnectionBadge(),
      if (_currentUser != null)
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Center(
            child: Text(
              _currentUser!.nombreCompleto,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ),
      IconButton(
        icon: const Icon(Icons.cloud_sync),
        tooltip: 'Ver y sincronizar datos pendientes',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PendingSyncScreen(db: widget.db),
            ),
          );
        },
      ),
      IconButton(
        icon: const Icon(Icons.sync),
        tooltip: 'Sincronizar datos pendientes (rápido)',
        onPressed: _handleSyncPendingData,
      ),
      IconButton(
        icon: const Icon(Icons.cleaning_services),
        tooltip: 'Gestión de datos locales',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DatabaseCleanerScreen(db: widget.db),
            ),
          );
        },
      ),
      IconButton(
        icon: const Icon(Icons.system_update),
        tooltip: 'Buscar actualizaciones',
        onPressed: () {
          if (_updateManager != null) {
            _updateManager!.checkForUpdatesManual(context);
          }
        },
      ),
      IconButton(
        icon: const Icon(Icons.info_outline),
        tooltip: 'Acerca de',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AboutScreen(db: widget.db),
            ),
          );
        },
      ),
      IconButton(
        icon: const Icon(Icons.logout),
        tooltip: 'Cerrar Sesión',
        onPressed: _handleLogout,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    // Detectar si es móvil para AppBar compacto
    final isMobile =
        MobileAdaptive.isMobilePlatform && MobileAdaptive.isPhone(context);
    final userName = _currentUser?.nombreCompleto ?? 'Cargando usuario';
    final campusName = _currentUser != null
        ? AuthService.formatCampusName(_currentUser!.campus)
        : 'Campus pendiente';

    return Stack(
      children: [
        Scaffold(
          backgroundColor: UAGroColors.grisClaro,
          appBar: AppBar(
            title: _loadingUser
                ? Text(isMobile ? 'CRES' : 'CRES Carnets - UAGro')
                : isMobile
                    ? const Text('CRES') // Solo nombre corto en móvil
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'CRES Carnets - UAGro',
                            style: TextStyle(fontSize: 16),
                          ),
                          if (_currentUser != null)
                            Text(
                              '${AuthService.formatRoleName(_currentUser!.rol)} - ${AuthService.formatCampusName(_currentUser!.campus)}',
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.normal),
                            ),
                        ],
                      ),
            backgroundColor: UAGroColors.azulMarino,
            elevation: 0,
            centerTitle: false,
            actions: isMobile
                ? _buildMobileActions(context) // Acciones compactas para móvil
                : _buildDesktopActions(
                    context), // Todas las acciones para desktop
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _InstitutionalHeader(
                        userName: userName,
                        campusName: campusName,
                        versionFuture: _getVersionString(),
                      ),
                      const SizedBox(height: 16),
                      _StatusStrip(
                        onSync: _handleSyncPendingData,
                        onUpdates: () {
                          if (_updateManager != null) {
                            _updateManager!.checkForUpdatesManual(context);
                          }
                        },
                      ),
                      if (_currentUser != null) ...[
                        const SizedBox(height: 18),
                        RecentActivityPanel(
                          user: _currentUser!,
                          onOpenPatient: (matricula) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => NuevaNotaScreen(
                                  db: widget.db,
                                  matriculaInicial: matricula,
                                ),
                              ),
                            );
                          },
                          onOpenNote: (matricula) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => NuevaNotaScreen(
                                  db: widget.db,
                                  matriculaInicial: matricula,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                      const SizedBox(height: 18),
                      _SectionHeader(
                        title: 'Centro de Servicios Universitarios',
                        subtitle: 'SASU 2.5 - Universidad Autónoma de Guerrero',
                      ),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final visibleOptions = <Widget>[];
                          final maxWidth = constraints.maxWidth;
                          final columns = maxWidth >= 980
                              ? 4
                              : maxWidth >= 640
                                  ? 2
                                  : 1;
                          final spacing = 14.0;
                          final cardWidth =
                              (maxWidth - (spacing * (columns - 1))) / columns;

                          if (_canCreateCarnet) {
                            visibleOptions.add(
                              _DashboardCard(
                                icon: Icons.badge_outlined,
                                title: 'Crear Carnet',
                                description: 'Registro estudiantil',
                                color: UAGroColors.azulMarino,
                                onTap: () async {
                                  final allowed = await _checkPermission(
                                    'carnets:write',
                                    'Crear Carnet',
                                  );
                                  if (!allowed || !context.mounted) return;
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => FormScreen(db: widget.db),
                                    ),
                                  );
                                },
                                width: cardWidth,
                              ),
                            );
                          }

                          if (_canManageExpedientes) {
                            visibleOptions.add(
                              _DashboardCard(
                                icon: Icons.folder_open,
                                title: 'Administrar Expedientes',
                                description: 'Notas y expedientes médicos',
                                color: UAGroColors.rojoEscudo,
                                onTap: () async {
                                  final allowed = await _checkPermission(
                                    'notas:write',
                                    'Administrar Expedientes',
                                  );
                                  if (!allowed || !context.mounted) return;
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          NuevaNotaScreen(db: widget.db),
                                    ),
                                  );
                                },
                                width: cardWidth,
                              ),
                            );
                          }

                          if (_canViewPromocion) {
                            visibleOptions.add(
                              _DashboardCard(
                                icon: Icons.campaign,
                                title: 'Promoción de Salud',
                                description: 'Campañas universitarias',
                                color: Colors.green[700]!,
                                onTap: () async {
                                  final allowed = await _checkPermission(
                                    'promociones:read',
                                    'Promoción de Salud',
                                  );
                                  if (!allowed || !context.mounted) return;
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          PromocionSaludScreen(db: widget.db),
                                    ),
                                  );
                                },
                                width: cardWidth,
                              ),
                            );
                          }

                          if (_canViewVacunacion) {
                            visibleOptions.add(
                              _DashboardCard(
                                icon: Icons.vaccines,
                                title: 'Vacunación',
                                description: 'Registro y campañas',
                                color: Colors.purple[700]!,
                                onTap: () async {
                                  final allowed = await _checkPermission(
                                    'vacunacion:read',
                                    'Vacunación',
                                  );
                                  if (!allowed || !context.mounted) return;
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const VaccinationScreen(),
                                    ),
                                  );
                                },
                                width: cardWidth,
                                badge: 'NUEVO',
                              ),
                            );
                          }

                          if (_canViewTickets) {
                            visibleOptions.add(
                              _DashboardCard(
                                icon: Icons.support_agent_outlined,
                                title: 'Centro de Atencion',
                                description: 'Bandeja y seguimiento de tickets',
                                color: Colors.teal[700]!,
                                onTap: () async {
                                  final allowed = await _checkPermission(
                                    'tickets:read',
                                    'Centro de Atencion',
                                  );
                                  if (!allowed || !context.mounted) return;
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const TicketsScreen(),
                                    ),
                                  );
                                },
                                width: cardWidth,
                                badge: '2.6',
                              ),
                            );
                          }

                          if (_canViewAppointments) {
                            visibleOptions.add(
                              _DashboardCard(
                                icon: Icons.event_available_outlined,
                                title: 'Agenda Integrada',
                                description: 'Solicitudes de cita del alumnado',
                                color: Colors.blue[700]!,
                                onTap: () async {
                                  final allowed = await _checkPermission(
                                    'citas:read',
                                    'Agenda Integrada',
                                  );
                                  if (!allowed || !context.mounted) return;
                                  await _openAppointmentsScreen();
                                },
                                width: cardWidth,
                                badge: _pendingAppointmentRequests > 0
                                    ? '$_pendingAppointmentRequests nuevas'
                                    : 'MVP',
                              ),
                            );
                          }

                          if (visibleOptions.isEmpty) {
                            return const _EmptyPermissionsPanel();
                          }

                          return Wrap(
                            spacing: spacing,
                            runSpacing: spacing,
                            children: visibleOptions,
                          );
                        },
                      ),
                      const SizedBox(height: 18),
                      _ObservatoryCard(onTap: _openObservatory),
                      const SizedBox(height: 18),
                      Text(
                        'Dirección de Innovación en la Gestión de la Salud Universitaria',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: UAGroColors.azulMarino.withValues(alpha: 0.68),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        _buildAppointmentToastStack(),
      ],
    );
  }

  Widget _buildAppointmentToastStack() {
    if (_appointmentToasts.isEmpty && !_pendingReminderVisible) {
      return const SizedBox.shrink();
    }
    return Positioned(
      right: 22,
      bottom: 22,
      child: SafeArea(
        child: IgnorePointer(
          ignoring: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (_pendingReminderVisible)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: PendingAppointmentsReminderToast(
                    pendingCount: _pendingReminderCount,
                    onClose: _dismissPendingReminder,
                    onView: _openPendingAppointmentsReminder,
                  ),
                ),
              ..._appointmentToasts.reversed.map((appointment) {
                return Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: AppointmentToast(
                    appointment: appointment,
                    onClose: () => _dismissAppointmentToast(appointment.id),
                    onView: () => _openAppointmentFromToast(appointment),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget de tarjeta para cada opción del dashboard
class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;
  final double width;
  final String? badge;

  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
    required this.width,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 158,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        elevation: 1.5,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: color.withValues(alpha: 0.18)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(icon, size: 24, color: color),
                        ),
                        const Spacer(),
                        Icon(Icons.arrow_forward, size: 18, color: color),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: UAGroColors.azulMarino,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
                if (badge != null)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badge!,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InstitutionalHeader extends StatelessWidget {
  final String userName;
  final String campusName;
  final Future<String> versionFuture;

  const _InstitutionalHeader({
    required this.userName,
    required this.campusName,
    required this.versionFuture,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: UAGroColors.azulMarino,
        borderRadius: BorderRadius.circular(8),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 760;
          final identity = Column(
            crossAxisAlignment:
                wide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: [
              Text(
                'Universidad Autónoma de Guerrero',
                textAlign: wide ? TextAlign.start : TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'SASU',
                textAlign: wide ? TextAlign.start : TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Sistema de Atención en Salud Universitaria',
                textAlign: wide ? TextAlign.start : TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.86),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Dirección de Innovación en la Gestión de la Salud Universitaria',
                textAlign: wide ? TextAlign.start : TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: 12,
                ),
              ),
            ],
          );

          final details = Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: wide ? WrapAlignment.end : WrapAlignment.center,
            children: [
              _InfoChip(icon: Icons.person_outline, label: userName),
              _InfoChip(icon: Icons.location_city, label: campusName),
              const _InfoChip(icon: Icons.sync, label: 'Sincronización activa'),
              FutureBuilder<String>(
                future: versionFuture,
                builder: (context, snapshot) {
                  final version = snapshot.data ?? 'Cargando versión';
                  return _InfoChip(
                    icon: Icons.verified_outlined,
                    label: 'v$version',
                  );
                },
              ),
            ],
          );

          if (!wide) {
            return Column(
              children: [
                identity,
                const SizedBox(height: 16),
                details,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(flex: 5, child: identity),
              const SizedBox(width: 18),
              Expanded(flex: 4, child: details),
            ],
          );
        },
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusStrip extends StatelessWidget {
  final VoidCallback onSync;
  final VoidCallback onUpdates;

  const _StatusStrip({
    required this.onSync,
    required this.onUpdates,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border:
            Border.all(color: UAGroColors.azulMarino.withValues(alpha: 0.08)),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          const ConnectionIndicator(),
          _CompactAction(
            icon: Icons.sync,
            label: 'Sincronizar',
            onPressed: onSync,
          ),
          _CompactAction(
            icon: Icons.system_update,
            label: 'Actualizaciones',
            onPressed: onUpdates,
          ),
        ],
      ),
    );
  }
}

class _CompactAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _CompactAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 38),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        side: BorderSide(color: UAGroColors.azulMarino.withValues(alpha: 0.22)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: UAGroColors.azulMarino,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ObservatoryCard extends StatelessWidget {
  final VoidCallback onTap;

  const _ObservatoryCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: UAGroColors.azulMarino.withValues(alpha: 0.12),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: UAGroColors.azulMarino.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.analytics_outlined,
                  color: UAGroColors.azulMarino,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Observatorio SASU',
                      style: TextStyle(
                        color: UAGroColors.azulMarino,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Indicadores y seguimiento institucional',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.open_in_new,
                  size: 20, color: UAGroColors.azulMarino),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyPermissionsPanel extends StatelessWidget {
  const _EmptyPermissionsPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[300]!),
      ),
      child: Column(
        children: [
          Icon(Icons.info_outline, size: 42, color: Colors.orange[700]),
          const SizedBox(height: 12),
          Text(
            'Sin Permisos Asignados',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.orange[900],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tu cuenta no tiene permisos para acceder a ninguna funcionalidad.\n'
            'Contacta al administrador del sistema.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}
