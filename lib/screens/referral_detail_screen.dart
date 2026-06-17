import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/api_service.dart';
import '../models/referral_admin_model.dart';
import '../screens/counter_referral_screen.dart';
import '../ui/uagro_theme.dart';

class ReferralDetailScreen extends StatefulWidget {
  final String referralId;

  const ReferralDetailScreen({
    super.key,
    required this.referralId,
  });

  @override
  State<ReferralDetailScreen> createState() => _ReferralDetailScreenState();
}

class _ReferralDetailScreenState extends State<ReferralDetailScreen> {
  bool _loading = true;
  bool _savingStatus = false;
  String? _error;
  ReferralAdminModel? _referral;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final detail = await ApiService.getReferralDetail(widget.referralId);
      if (!mounted) return;
      setState(() {
        _referral = detail;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _changeStatus(String nextStatus) async {
    final referral = _referral;
    if (referral == null || _savingStatus) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambiar estado'),
        content: Text('¿Cambiar estado a ${_statusLabel(nextStatus)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cambiar estado'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _savingStatus = true);
    try {
      final updated = await ApiService.updateReferralStatus(
        referralId: referral.id,
        status: nextStatus,
      );
      if (!mounted) return;
      setState(() {
        _referral = updated;
        _savingStatus = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Referencia actualizada a ${_statusLabel(nextStatus)}.'),
        ),
      );
      await _loadDetail();
    } catch (e) {
      if (!mounted) return;
      setState(() => _savingStatus = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: UAGroColors.rojoEscudo,
        ),
      );
    }
  }

  Future<void> _openCounterReferral(ReferralAdminModel referral) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CounterReferralScreen(referral: referral),
      ),
    );
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contrarreferencia guardada.')),
      );
      await _loadDetail();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UAGroColors.grisClaro,
      appBar: AppBar(
        title: const Text('Detalle de Referencia'),
        backgroundColor: UAGroColors.azulMarino,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Actualizar detalle',
            onPressed: _loading ? null : _loadDetail,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildError()
                : _referral == null
                    ? _buildEmpty()
                    : _buildDetail(_referral!),
      ),
    );
  }

  Widget _buildDetail(ReferralAdminModel referral) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(referral),
                const SizedBox(height: 14),
                _buildActions(referral),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildStudentPanel(referral)),
                    const SizedBox(width: 14),
                    Expanded(child: _buildReferralPanel(referral)),
                  ],
                ),
                const SizedBox(height: 14),
                _buildCounterReferralPanel(referral),
                const SizedBox(height: 14),
                _buildTimeline(referral.statusHistory),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActions(ReferralAdminModel referral) {
    final actions = _availableActions(referral.status);
    final isFinal =
        referral.status == 'closed' || referral.status == 'cancelled';
    final title = isFinal
        ? 'La referencia se encuentra ${_statusLabel(referral.status).toLowerCase()}.'
        : actions.isEmpty
            ? 'No hay acciones disponibles para este estado.'
            : 'Acciones disponibles';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 320,
            child: Row(
              children: [
                Icon(
                  isFinal ? Icons.lock_outline : Icons.task_alt_outlined,
                  color: isFinal
                      ? const Color(0xFF64748B)
                      : UAGroColors.azulMarino,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
          ...actions.map((action) => _StatusActionButton(
                action: action,
                saving: _savingStatus,
                onPressed: () => _changeStatus(action.status),
              )),
          if (referral.status == 'attended')
            OutlinedButton.icon(
              onPressed:
                  _savingStatus ? null : () => _openCounterReferral(referral),
              icon: const Icon(Icons.assignment_return_outlined),
              label: Text(
                referral.counterReferral == null
                    ? 'Crear contrarreferencia'
                    : 'Actualizar contrarreferencia',
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(ReferralAdminModel referral) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _panelDecoration(),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: UAGroColors.azulMarino.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.swap_horiz_outlined,
              color: UAGroColors.azulMarino,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  referral.id.isEmpty ? 'Referencia' : referral.id,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Creada: ${_formatDate(referral.createdAt)}',
                  style: const TextStyle(color: Color(0xFF4B5563)),
                ),
              ],
            ),
          ),
          _Chip(
            label: _statusLabel(referral.status),
            color: _statusColor(referral.status),
          ),
          const SizedBox(width: 8),
          _Chip(
            label: _priorityLabel(referral.priority),
            color: _priorityColor(referral.priority),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentPanel(ReferralAdminModel referral) {
    final student = referral.student;
    return _InfoPanel(
      title: 'Estudiante',
      icon: Icons.school_outlined,
      children: [
        _InfoRow(label: 'Nombre', value: student.nombre),
        _InfoRow(label: 'Matricula', value: student.matricula),
        _InfoRow(label: 'Programa', value: student.programa),
        _InfoRow(label: 'Campus', value: student.campus),
        _InfoRow(label: 'Unidad', value: student.unidadAcademica),
      ],
    );
  }

  Widget _buildReferralPanel(ReferralAdminModel referral) {
    return _InfoPanel(
      title: 'Referencia',
      icon: Icons.assignment_outlined,
      children: [
        _InfoRow(label: 'Area origen', value: _areaLabel(referral.origin.area)),
        _InfoRow(
          label: 'Area destino',
          value: _areaLabel(referral.destination.area),
        ),
        _TextBlock(label: 'Motivo', value: referral.reason),
        _TextBlock(
          label: 'Notas clinicas o administrativas',
          value: referral.observations,
        ),
      ],
    );
  }

  Widget _buildCounterReferralPanel(ReferralAdminModel referral) {
    final counterReferral = referral.counterReferral;
    if (counterReferral == null) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: _panelDecoration(),
        child: const Row(
          children: [
            Icon(
              Icons.assignment_return_outlined,
              color: Color(0xFF64748B),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Aun no hay contrarreferencia registrada.',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return _InfoPanel(
      title: 'Contrarreferencia',
      icon: Icons.assignment_return_outlined,
      children: [
        _InfoRow(
          label: 'Area',
          value: _areaLabel(counterReferral.responseArea),
        ),
        _InfoRow(
          label: 'Responsable',
          value: counterReferral.responseUserName.isEmpty
              ? counterReferral.responseUserId
              : counterReferral.responseUserName,
        ),
        _InfoRow(
          label: 'Fecha',
          value: _formatDate(counterReferral.createdAt),
        ),
        _TextBlock(
          label: 'Resumen de atencion',
          value: counterReferral.summary,
        ),
        _TextBlock(
          label: 'Recomendaciones',
          value: counterReferral.recommendations,
        ),
      ],
    );
  }

  Widget _buildTimeline(List<ReferralStatusHistoryEntry> history) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.timeline_outlined, color: UAGroColors.azulMarino),
              SizedBox(width: 8),
              Text(
                'Timeline',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (history.isEmpty)
            const _EmptyTimeline()
          else
            ...history.map((entry) => _TimelineEntry(entry: entry)),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Container(
        width: 520,
        padding: const EdgeInsets.all(22),
        decoration: _panelDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 46,
              color: UAGroColors.rojoEscudo,
            ),
            const SizedBox(height: 12),
            const Text(
              'No se pudo cargar la referencia',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(_error ?? '', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadDetail,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Container(
        width: 520,
        padding: const EdgeInsets.all(22),
        decoration: _panelDecoration(),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 46, color: Color(0xFF64748B)),
            SizedBox(height: 12),
            Text(
              'Referencia no disponible',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _panelDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFFE5E7EB)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }
}

List<_ReferralStatusAction> _availableActions(String status) {
  switch (status) {
    case 'sent':
      return const [
        _ReferralStatusAction(
          status: 'received',
          label: 'Recibir referencia',
          icon: Icons.mark_email_read_outlined,
          primary: true,
        ),
        _ReferralStatusAction(
          status: 'cancelled',
          label: 'Rechazar referencia',
          icon: Icons.cancel_outlined,
        ),
      ];
    case 'received':
      return const [
        _ReferralStatusAction(
          status: 'accepted',
          label: 'Aceptar referencia',
          icon: Icons.check_circle_outline,
          primary: true,
        ),
        _ReferralStatusAction(
          status: 'cancelled',
          label: 'Rechazar referencia',
          icon: Icons.cancel_outlined,
        ),
      ];
    case 'accepted':
      return const [
        _ReferralStatusAction(
          status: 'scheduled',
          label: 'Marcar agendada',
          icon: Icons.event_available_outlined,
          primary: true,
        ),
        _ReferralStatusAction(
          status: 'attended',
          label: 'Marcar atendida',
          icon: Icons.medical_services_outlined,
        ),
        _ReferralStatusAction(
          status: 'cancelled',
          label: 'Rechazar referencia',
          icon: Icons.cancel_outlined,
        ),
      ];
    case 'scheduled':
      return const [
        _ReferralStatusAction(
          status: 'attended',
          label: 'Marcar atendida',
          icon: Icons.medical_services_outlined,
          primary: true,
        ),
        _ReferralStatusAction(
          status: 'cancelled',
          label: 'Rechazar referencia',
          icon: Icons.cancel_outlined,
        ),
      ];
    case 'attended':
      return const [
        _ReferralStatusAction(
          status: 'closed',
          label: 'Cerrar referencia',
          icon: Icons.task_alt_outlined,
          primary: true,
        ),
      ];
    default:
      return const [];
  }
}

class _ReferralStatusAction {
  final String status;
  final String label;
  final IconData icon;
  final bool primary;

  const _ReferralStatusAction({
    required this.status,
    required this.label,
    required this.icon,
    this.primary = false,
  });
}

class _StatusActionButton extends StatelessWidget {
  final _ReferralStatusAction action;
  final bool saving;
  final VoidCallback onPressed;

  const _StatusActionButton({
    required this.action,
    required this.saving,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final icon = saving
        ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Icon(action.icon);
    if (action.primary) {
      return FilledButton.icon(
        onPressed: saving ? null : onPressed,
        icon: icon,
        label: Text(action.label),
      );
    }
    return OutlinedButton.icon(
      onPressed: saving ? null : onPressed,
      icon: icon,
      label: Text(action.label),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _InfoPanel({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: UAGroColors.azulMarino),
              const SizedBox(width: 8),
              Text(
                title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'No registrado' : value,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _TextBlock extends StatelessWidget {
  final String label;
  final String value;

  const _TextBlock({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Text(value.isEmpty ? 'Sin informacion registrada.' : value),
          ),
        ],
      ),
    );
  }
}

class _TimelineEntry extends StatelessWidget {
  final ReferralStatusHistoryEntry entry;

  const _TimelineEntry({required this.entry});

  @override
  Widget build(BuildContext context) {
    final actor = entry.byUserName.isNotEmpty
        ? entry.byUserName
        : entry.byUserId.isNotEmpty
            ? entry.byUserId
            : 'Usuario SASU';
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: _statusColor(entry.status),
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 2,
                height: 52,
                color: const Color(0xFFE5E7EB),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _statusLabel(entry.status),
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      Text(
                        _formatDate(entry.at),
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$actor - ${entry.byRole.isEmpty ? "rol no registrado" : entry.byRole}',
                    style: const TextStyle(color: Color(0xFF4B5563)),
                  ),
                  if (entry.area.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      _areaLabel(entry.area),
                      style: const TextStyle(color: Color(0xFF4B5563)),
                    ),
                  ],
                  if (entry.note.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(entry.note),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyTimeline extends StatelessWidget {
  const _EmptyTimeline();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: const Text(
        'Aun no hay movimientos registrados para esta referencia.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Color(0xFF64748B)),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;

  const _Chip({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

String _formatDate(DateTime? date) {
  if (date == null) return 'Sin fecha';
  return DateFormat('dd/MM/yyyy HH:mm').format(date.toLocal());
}

String _areaLabel(String value) {
  const labels = {
    'medico': 'Medico',
    'psicologia': 'Psicologia',
    'nutricion': 'Nutricion',
    'odontologia': 'Odontologia',
    'atencion_estudiantil': 'Atencion estudiantil',
  };
  return labels[value] ?? value.replaceAll('_', ' ');
}

String _statusLabel(String value) {
  const labels = {
    'draft': 'Borrador',
    'sent': 'Enviada',
    'received': 'Recibida',
    'accepted': 'Aceptada',
    'scheduled': 'Agendada',
    'attended': 'Atendida',
    'closed': 'Cerrada',
    'cancelled': 'Rechazada',
  };
  return labels[value] ?? value.replaceAll('_', ' ');
}

String _priorityLabel(String value) {
  const labels = {
    'baja': 'Baja',
    'media': 'Media',
    'alta': 'Alta',
    'urgente': 'Urgente',
  };
  return labels[value] ?? value.replaceAll('_', ' ');
}

Color _statusColor(String value) {
  switch (value) {
    case 'draft':
      return Colors.grey;
    case 'sent':
      return Colors.blue;
    case 'received':
    case 'accepted':
      return Colors.orange;
    case 'scheduled':
      return Colors.indigo;
    case 'attended':
    case 'closed':
      return Colors.green;
    case 'cancelled':
      return UAGroColors.rojoEscudo;
    default:
      return UAGroColors.azulMarino;
  }
}

Color _priorityColor(String value) {
  switch (value) {
    case 'baja':
      return Colors.green;
    case 'media':
      return Colors.blueGrey;
    case 'alta':
      return Colors.orange;
    case 'urgente':
      return UAGroColors.rojoEscudo;
    default:
      return UAGroColors.azulMarino;
  }
}
