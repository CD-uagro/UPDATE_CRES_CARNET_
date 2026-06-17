import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/api_service.dart';
import '../models/appointment_admin_model.dart';
import '../ui/uagro_theme.dart';
import '../widgets/appointment_schedule_dialog.dart';

class AppointmentsScreen extends StatefulWidget {
  final String? initialStatus;
  final String? initialAppointmentId;

  const AppointmentsScreen({
    super.key,
    this.initialStatus,
    this.initialAppointmentId,
  });

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  static const _statuses = {
    '': 'Todos',
    'requested': 'Solicitada',
    'confirmed': 'Confirmada',
    'rescheduled': 'Reprogramada',
    'cancelled_by_student': 'Cancelada por alumno',
    'cancelled_by_staff': 'Cancelada por SASU',
    'attended': 'Atendida',
    'no_show': 'No asistio',
    'rejected': 'Rechazada',
  };

  static const _areas = {
    '': 'Todas',
    'medicina': 'Medicina',
    'psicologia': 'Psicologia',
    'nutricion': 'Nutricion',
    'odontologia': 'Odontologia',
    'atencion_estudiantil': 'Atencion estudiantil',
  };

  final _matriculaController = TextEditingController();
  final _campusController = TextEditingController();

  String _status = '';
  String _area = '';
  bool _loading = true;
  String? _error;
  List<AppointmentAdminModel> _appointments = [];
  Timer? _refreshTimer;
  int _lastNotifiedPending = -1;
  bool _openedInitialAppointment = false;

  @override
  void initState() {
    super.initState();
    _status = widget.initialStatus ?? '';
    _loadAppointments();
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (!_loading && mounted) {
        _loadAppointments(showLoading: false);
      }
    });
  }

  @override
  void dispose() {
    _matriculaController.dispose();
    _campusController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadAppointments({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final appointments = await ApiService.getAppointments(
        status: _status,
        area: _area,
        campus: _campusController.text,
        matricula: _matriculaController.text,
      );
      _sortAppointments(appointments);
      if (!mounted) return;
      setState(() {
        _appointments = appointments;
        _loading = false;
      });
      _notifyPendingRequests(appointments);
      _openInitialAppointmentIfNeeded(appointments);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _appointments = [];
        _loading = false;
      });
    }
  }

  void _sortAppointments(List<AppointmentAdminModel> appointments) {
    appointments.sort((a, b) {
      if (a.status == 'requested' && b.status != 'requested') return -1;
      if (a.status != 'requested' && b.status == 'requested') return 1;
      final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });
  }

  void _notifyPendingRequests(List<AppointmentAdminModel> appointments) {
    final pending =
        appointments.where((item) => item.status == 'requested').length;
    if (pending <= 0 || pending == _lastNotifiedPending || !mounted) return;
    _lastNotifiedPending = pending;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tienes $pending solicitudes de cita pendientes.'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _openInitialAppointmentIfNeeded(
    List<AppointmentAdminModel> appointments,
  ) {
    if (_openedInitialAppointment || widget.initialAppointmentId == null) {
      return;
    }
    final appointmentId = widget.initialAppointmentId!;
    AppointmentAdminModel? appointment;
    for (final item in appointments) {
      if (item.id == appointmentId) {
        appointment = item;
        break;
      }
    }
    if (appointment == null) return;

    _openedInitialAppointment = true;
    final appointmentToOpen = appointment;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _openDetail(appointmentToOpen);
      }
    });
  }

  void _clearFilters() {
    _matriculaController.clear();
    _campusController.clear();
    setState(() {
      _status = '';
      _area = '';
    });
    _loadAppointments();
  }

  void _showNewRequests() {
    setState(() {
      _status = 'requested';
    });
    _loadAppointments();
  }

  Future<void> _openDetail(AppointmentAdminModel appointment) async {
    final detail = await ApiService.getAppointmentDetail(appointment.id);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => _AppointmentDetailDialog(
        appointment: detail,
        onAction: _handleAction,
      ),
    );
    if (mounted) _loadAppointments();
  }

  Future<void> _handleAction(
    AppointmentAdminModel appointment,
    String action,
  ) async {
    final payload = await _payloadForAction(appointment, action);
    if (payload == null) return;

    try {
      await ApiService.updateAppointmentAction(
        appointmentId: appointment.id,
        action: action,
        payload: payload,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cita actualizada correctamente')),
      );
      Navigator.of(context, rootNavigator: true).pop();
      _loadAppointments();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  Future<Map<String, dynamic>?> _payloadForAction(
    AppointmentAdminModel appointment,
    String action,
  ) async {
    if (action == 'attended' || action == 'no-show') {
      return const {};
    }
    if (action == 'cancel') {
      final reason = await _askText(
        title: 'Cancelar cita',
        label: 'Motivo de cancelacion',
      );
      if (reason == null) return null;
      return {'cancellation_reason': reason};
    }

    final schedule = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => AppointmentScheduleDialog(
        appointment: appointment,
        action: action,
      ),
    );
    if (schedule == null) return null;
    return schedule;
  }

  Future<String?> _askText({
    required String title,
    required String label,
  }) async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          minLines: 2,
          maxLines: 4,
          decoration: InputDecoration(labelText: label),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    controller.dispose();
    return value;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UAGroColors.grisClaro,
      appBar: AppBar(
        title: const Text('Agenda Integrada'),
        backgroundColor: UAGroColors.azulMarino,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Actualizar solicitudes',
            onPressed: _loading ? null : () => _loadAppointments(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 14),
              _buildFilters(),
              const SizedBox(height: 14),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? _buildError()
                        : _appointments.isEmpty
                            ? _buildEmpty()
                            : _buildTable(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final pending =
        _appointments.where((item) => item.status == 'requested').length;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: UAGroColors.azulMarino.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.event_available,
                color: UAGroColors.azulMarino),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bandeja de Agenda',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 3),
                Text(
                  'Solicitudes de cita enviadas desde Carnet Digital',
                  style: TextStyle(color: Color(0xFF4B5563)),
                ),
              ],
            ),
          ),
          _Metric(label: 'Total', value: _appointments.length.toString()),
          const SizedBox(width: 10),
          _Metric(label: 'Nuevas', value: pending.toString()),
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: _loading ? null : _showNewRequests,
            icon: const Icon(Icons.notifications_active_outlined, size: 18),
            label: const Text('Nuevas solicitudes'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _panelDecoration(),
      child: Row(
        children: [
          Expanded(
            child: _DropdownFilter(
              label: 'Estado',
              value: _status,
              items: _statuses,
              onChanged: (value) => setState(() => _status = value ?? ''),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _DropdownFilter(
              label: 'Area',
              value: _area,
              items: _areas,
              onChanged: (value) => setState(() => _area = value ?? ''),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _campusController,
              decoration: const InputDecoration(
                labelText: 'Campus',
                prefixIcon: Icon(Icons.location_city_outlined),
              ),
              onSubmitted: (_) => _loadAppointments(),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _matriculaController,
              decoration: const InputDecoration(
                labelText: 'Matricula',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              onSubmitted: (_) => _loadAppointments(),
            ),
          ),
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: _loading ? null : () => _loadAppointments(),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Actualizar solicitudes'),
          ),
          const SizedBox(width: 8),
          IconButton.outlined(
            tooltip: 'Limpiar filtros',
            onPressed: _loading ? null : _clearFilters,
            icon: const Icon(Icons.filter_alt_off_outlined),
          ),
        ],
      ),
    );
  }

  Widget _buildTable() {
    return Container(
      decoration: _panelDecoration(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SingleChildScrollView(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStatePropertyAll(
                UAGroColors.azulMarino.withValues(alpha: 0.08),
              ),
              columns: const [
                DataColumn(label: Text('ID')),
                DataColumn(label: Text('Fecha')),
                DataColumn(label: Text('Alumno')),
                DataColumn(label: Text('Matricula')),
                DataColumn(label: Text('Area')),
                DataColumn(label: Text('Preferencia')),
                DataColumn(label: Text('Estado')),
                DataColumn(label: Text('Campus')),
                DataColumn(label: Text('')),
              ],
              rows: _appointments.map((appointment) {
                return DataRow(
                  cells: [
                    DataCell(Text(_shortId(appointment.id))),
                    DataCell(Text(_formatDate(appointment.createdAt))),
                    DataCell(SizedBox(
                      width: 180,
                      child: Text(
                        appointment.student.nombre.isEmpty
                            ? 'Sin nombre'
                            : appointment.student.nombre,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )),
                    DataCell(Text(appointment.student.matricula)),
                    DataCell(Text(_areaLabel(appointment.area))),
                    DataCell(Text(
                      '${appointment.preferredDate} / ${_timeBlockLabel(appointment.preferredTimeBlock)}',
                    )),
                    DataCell(_Chip(
                      label: _statusLabel(appointment.status),
                      color: _statusColor(appointment.status),
                    )),
                    DataCell(Text(
                      appointment.student.campus.isEmpty
                          ? 'Sin campus'
                          : appointment.student.campus,
                    )),
                    DataCell(
                      IconButton(
                        tooltip: 'Ver detalle',
                        onPressed: () => _openDetail(appointment),
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _panelDecoration(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline,
              size: 46, color: UAGroColors.rojoEscudo),
          const SizedBox(height: 12),
          const Text(
            'No se pudo cargar la agenda',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(_error ?? '', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _loadAppointments,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _panelDecoration(),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy_outlined, size: 54, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            'No hay solicitudes de cita',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 6),
          Text('Ajusta los filtros o actualiza la bandeja.'),
        ],
      ),
    );
  }

  BoxDecoration _panelDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: UAGroColors.azulMarino.withValues(alpha: 0.08)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  static String _shortId(String id) =>
      id.length <= 18 ? id : id.substring(0, 18);

  static String _formatDate(DateTime? date) {
    if (date == null) return 'Sin fecha';
    return DateFormat('dd/MM/yyyy HH:mm').format(date.toLocal());
  }

  static String _formatSchedule(String? startValue, String? endValue) {
    final start = _parseDate(startValue);
    if (start == null) return 'Pendiente';
    final end = _parseDate(endValue);
    final date = '${start.day} de ${_monthName(start.month)} de ${start.year}';
    final startTime = DateFormat('HH:mm').format(start);
    if (end == null) return '$date, $startTime';
    final endTime = DateFormat('HH:mm').format(end);
    return '$date, $startTime a $endTime';
  }

  static String _monthName(int month) {
    const names = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    if (month < 1 || month > names.length) return '';
    return names[month - 1];
  }

  static DateTime? _parseDate(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return DateTime.tryParse(value)?.toLocal();
  }

  static String _areaLabel(String value) =>
      _areas[value] ?? value.replaceAll('_', ' ');
  static String _statusLabel(String value) =>
      _statuses[value] ?? value.replaceAll('_', ' ');

  static String _timeBlockLabel(String value) {
    switch (value) {
      case 'morning':
        return 'Manana';
      case 'afternoon':
        return 'Tarde';
      default:
        return value;
    }
  }

  static Color _statusColor(String value) {
    switch (value) {
      case 'requested':
        return Colors.orange.shade800;
      case 'confirmed':
      case 'rescheduled':
        return UAGroColors.azulMarino;
      case 'attended':
        return Colors.green.shade700;
      case 'cancelled_by_student':
      case 'cancelled_by_staff':
      case 'rejected':
      case 'no_show':
        return Colors.grey.shade700;
      default:
        return UAGroColors.azulMarino;
    }
  }
}

class _AppointmentDetailDialog extends StatelessWidget {
  final AppointmentAdminModel appointment;
  final Future<void> Function(AppointmentAdminModel appointment, String action)
      onAction;

  const _AppointmentDetailDialog({
    required this.appointment,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(appointment.student.nombre.isEmpty
          ? 'Detalle de cita'
          : appointment.student.nombre),
      content: SizedBox(
        width: 620,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _InfoRow(
                  label: 'Matricula', value: appointment.student.matricula),
              _InfoRow(
                  label: 'Correo',
                  value: appointment.student.correoInstitucional),
              _InfoRow(
                  label: 'Area',
                  value: _AppointmentsScreenState._areaLabel(appointment.area)),
              _InfoRow(label: 'Motivo', value: appointment.reasonCategory),
              _InfoRow(label: 'Comentario', value: appointment.reasonText),
              _InfoRow(
                  label: 'Preferencia',
                  value:
                      '${appointment.preferredDate} / ${appointment.preferredTimeBlock}'),
              _InfoRow(
                  label: 'Programada',
                  value: _AppointmentsScreenState._formatSchedule(
                    appointment.scheduledStart,
                    appointment.scheduledEnd,
                  )),
              const SizedBox(height: 12),
              const Text('Historial',
                  style: TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              if (appointment.history.isEmpty)
                const Text('Sin historial registrado')
              else
                ...appointment.history.map(
                  (item) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.history, size: 18),
                    title: Text(
                        '${item.fromStatus.isEmpty ? "inicio" : item.fromStatus} -> ${item.toStatus}'),
                    subtitle: Text('${item.actor} - ${item.message}'),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
        if (appointment.canChangeStatus) ...[
          OutlinedButton(
            onPressed: () => onAction(appointment, 'cancel'),
            child: const Text('Cancelar'),
          ),
          OutlinedButton(
            onPressed: () => onAction(appointment, 'no-show'),
            child: const Text('No asistio'),
          ),
          OutlinedButton(
            onPressed: () => onAction(appointment, 'attended'),
            child: const Text('Atendida'),
          ),
          FilledButton(
            onPressed: () => onAction(appointment, 'confirm'),
            child: const Text('Confirmar'),
          ),
          FilledButton(
            onPressed: () => onAction(appointment, 'reschedule'),
            child: const Text('Reprogramar'),
          ),
        ],
      ],
    );
  }
}

class _DropdownFilter extends StatelessWidget {
  final String label;
  final String value;
  final Map<String, String> items;
  final ValueChanged<String?> onChanged;

  const _DropdownFilter({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: items.entries
          .map((entry) => DropdownMenuItem(
                value: entry.key,
                child: Text(entry.value),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;

  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;

  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: UAGroColors.azulMarino.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          Expanded(child: Text(value.isEmpty ? 'No especificado' : value)),
        ],
      ),
    );
  }
}
