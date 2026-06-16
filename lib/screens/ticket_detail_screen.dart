import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/api_service.dart';
import '../data/auth_service.dart';
import '../models/ticket_admin_model.dart';
import '../ui/uagro_theme.dart';

class TicketDetailScreen extends StatefulWidget {
  final String ticketId;

  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  static const _statusOptions = {
    'abierto': 'Abierto',
    'en_revision': 'En revision',
    'en_proceso': 'En proceso',
    'resuelto': 'Resuelto',
    'cerrado': 'Cerrado',
    'cancelado': 'Cancelado',
  };

  final _followupController = TextEditingController();
  bool _loading = true;
  bool _savingStatus = false;
  bool _savingFollowup = false;
  String? _error;
  String _selectedStatus = 'abierto';
  String _visibility = 'internal';
  TicketDetailModel? _detail;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  @override
  void dispose() {
    _followupController.dispose();
    super.dispose();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final detail = await ApiService.getTicketDetail(widget.ticketId);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _selectedStatus = detail.ticket.estado;
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

  Future<void> _changeStatus() async {
    final current = _detail?.ticket.estado;
    if (current == null || current == _selectedStatus) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambiar estado'),
        content: Text(
          'El ticket cambiara de "${_statusLabel(current)}" a '
          '"${_statusLabel(_selectedStatus)}".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _savingStatus = true);
    try {
      await ApiService.updateTicketStatus(
        ticketId: widget.ticketId,
        status: _selectedStatus,
      );
      await _loadDetail();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Estado actualizado.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _savingStatus = false);
    }
  }

  Future<void> _addFollowup() async {
    final message = _followupController.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe un seguimiento.')),
      );
      return;
    }

    setState(() => _savingFollowup = true);
    try {
      await ApiService.addTicketFollowup(
        ticketId: widget.ticketId,
        message: message,
        visibility: _visibility,
      );
      _followupController.clear();
      await _loadDetail();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seguimiento agregado.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _savingFollowup = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UAGroColors.grisClaro,
      appBar: AppBar(
        title: const Text('Detalle de Ticket'),
        backgroundColor: UAGroColors.azulMarino,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Actualizar',
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
                : _buildContent(_detail!),
      ),
    );
  }

  Widget _buildContent(TicketDetailModel detail) {
    final ticket = detail.ticket;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSummary(ticket),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 7, child: _buildTicketInfo(ticket)),
                  const SizedBox(width: 14),
                  Expanded(flex: 5, child: _buildActions(ticket)),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildStatusHistory(ticket.statusHistory)),
                  const SizedBox(width: 14),
                  Expanded(child: _buildFollowups(detail.followups)),
                ],
              ),
              const SizedBox(height: 14),
              _buildMessages(detail.messages),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummary(TicketAdminModel ticket) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _statusColor(ticket.estado).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.confirmation_number_outlined,
              color: _statusColor(ticket.estado),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ticket.titulo.isEmpty ? 'Ticket sin titulo' : ticket.titulo,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ticket.ticketNumber.isEmpty ? ticket.id : ticket.ticketNumber,
                  style: const TextStyle(color: Color(0xFF4B5563)),
                ),
              ],
            ),
          ),
          _Chip(
              label: _statusLabel(ticket.estado),
              color: _statusColor(ticket.estado)),
          const SizedBox(width: 8),
          _Chip(
            label: _priorityLabel(ticket.prioridad),
            color: _priorityColor(ticket.prioridad),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketInfo(TicketAdminModel ticket) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Informacion del ticket'),
          const SizedBox(height: 12),
          _InfoRow('Alumno', ticket.nombrePaciente),
          _InfoRow('Matricula', ticket.matricula),
          _InfoRow('Categoria', _categoryLabel(ticket.categoria)),
          _InfoRow('Prioridad', _priorityLabel(ticket.prioridad)),
          _InfoRow('Estado', _statusLabel(ticket.estado)),
          _InfoRow('Campus', _campusLabel(ticket.campus)),
          _InfoRow('Unidad academica', _blank(ticket.unidadAcademica)),
          _InfoRow('Preparatoria', _blank(ticket.preparatoria)),
          _InfoRow('Fecha de creacion', _formatDate(ticket.createdAtUtc)),
          _InfoRow('Ultima actualizacion', _formatDate(ticket.updatedAtUtc)),
          const SizedBox(height: 12),
          const Text(
            'Descripcion',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            ticket.descripcionInicial.isEmpty
                ? 'Sin descripcion registrada.'
                : ticket.descripcionInicial,
          ),
        ],
      ),
    );
  }

  Widget _buildActions(TicketAdminModel ticket) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Gestion'),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _statusOptions.containsKey(_selectedStatus)
                ? _selectedStatus
                : 'abierto',
            decoration: const InputDecoration(
              labelText: 'Estado',
              prefixIcon: Icon(Icons.sync_alt),
            ),
            items: _statusOptions.entries
                .map((entry) => DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    ))
                .toList(),
            onChanged: _savingStatus
                ? null
                : (value) =>
                    setState(() => _selectedStatus = value ?? ticket.estado),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: _savingStatus || _selectedStatus == ticket.estado
                ? null
                : _changeStatus,
            icon: _savingStatus
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_circle_outline),
            label: const Text('Actualizar estado'),
          ),
          const Divider(height: 28),
          DropdownButtonFormField<String>(
            initialValue: _visibility,
            decoration: const InputDecoration(
              labelText: 'Visibilidad',
              prefixIcon: Icon(Icons.visibility_outlined),
            ),
            items: const [
              DropdownMenuItem(value: 'internal', child: Text('Interno')),
              DropdownMenuItem(value: 'student', child: Text('Alumno')),
            ],
            onChanged: _savingFollowup
                ? null
                : (value) => setState(() => _visibility = value ?? 'internal'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _followupController,
            minLines: 4,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'Seguimiento',
              alignLabelWithHint: true,
              prefixIcon: Icon(Icons.notes_outlined),
            ),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: _savingFollowup ? null : _addFollowup,
            icon: _savingFollowup
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_comment_outlined),
            label: const Text('Agregar seguimiento'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusHistory(List<TicketStatusHistoryEntry> history) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Historial de estados'),
          const SizedBox(height: 10),
          if (history.isEmpty)
            const Text('Sin cambios de estado registrados.')
          else
            ...history.reversed.map(
              (entry) => _TimelineItem(
                title:
                    '${_statusLabel(entry.previousStatus)} -> ${_statusLabel(entry.newStatus)}',
                subtitle:
                    '${entry.changedBy} - ${entry.changedByRole} - ${_formatDate(entry.changedAtUtc)}',
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFollowups(List<TicketFollowupModel> followups) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Seguimientos'),
          const SizedBox(height: 10),
          if (followups.isEmpty)
            const Text('Sin seguimientos registrados.')
          else
            ...followups.reversed.map(
              (followup) => _TimelineItem(
                title: followup.message,
                subtitle:
                    '${followup.author} - ${followup.role} - ${followup.visibility} - ${_formatDate(followup.createdAt)}',
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessages(List<TicketMessageModel> messages) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Mensajes'),
          const SizedBox(height: 10),
          if (messages.isEmpty)
            const Text('Sin mensajes registrados.')
          else
            ...messages.map(
              (message) => _TimelineItem(
                title: message.message,
                subtitle:
                    '${message.senderName} - ${message.senderRole} - ${_formatDate(message.createdAtUtc)}',
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Container(
        width: 560,
        padding: const EdgeInsets.all(18),
        decoration: _panelDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                size: 46, color: UAGroColors.rojoEscudo),
            const SizedBox(height: 12),
            const Text(
              'No se pudo cargar el ticket',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              textAlign: TextAlign.center,
            ),
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

  static String _blank(String value) =>
      value.isEmpty ? 'No especificada' : value;

  static String _formatDate(DateTime? date) {
    if (date == null) return 'Sin fecha';
    return DateFormat('dd/MM/yyyy HH:mm').format(date.toLocal());
  }

  static String _categoryLabel(String value) {
    return value.isEmpty ? 'Sin categoria' : value.replaceAll('_', ' ');
  }

  static String _priorityLabel(String value) {
    switch (value) {
      case 'baja':
        return 'Baja';
      case 'alta':
        return 'Alta';
      case 'urgente':
        return 'Urgente';
      default:
        return 'Media';
    }
  }

  static String _statusLabel(String value) {
    return _statusOptions[value] ?? value.replaceAll('_', ' ');
  }

  static String _campusLabel(String value) {
    if (value.isEmpty) return 'No especificado';
    return AuthService.formatCampusName(value);
  }

  static Color _priorityColor(String value) {
    switch (value) {
      case 'urgente':
        return UAGroColors.rojoEscudo;
      case 'alta':
        return Colors.orange.shade800;
      case 'baja':
        return Colors.green.shade700;
      default:
        return UAGroColors.azulMarino;
    }
  }

  static Color _statusColor(String value) {
    switch (value) {
      case 'cerrado':
      case 'resuelto':
        return Colors.green.shade700;
      case 'cancelado':
        return Colors.grey.shade700;
      case 'en_proceso':
      case 'en_revision':
        return Colors.orange.shade800;
      default:
        return UAGroColors.azulMarino;
    }
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
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
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

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: UAGroColors.azulMarino,
        fontSize: 16,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final String title;
  final String subtitle;

  const _TimelineItem({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6),
            decoration: const BoxDecoration(
              color: UAGroColors.azulMarino,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style:
                      const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
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
