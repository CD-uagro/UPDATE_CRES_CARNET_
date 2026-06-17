import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/api_service.dart';
import '../models/referral_admin_model.dart';
import '../screens/referral_detail_screen.dart';
import '../screens/new_referral_screen.dart';
import '../ui/uagro_theme.dart';

class ReferralsScreen extends StatefulWidget {
  const ReferralsScreen({super.key});

  @override
  State<ReferralsScreen> createState() => _ReferralsScreenState();
}

class _ReferralsScreenState extends State<ReferralsScreen> {
  static const _statuses = {
    '': 'Todos',
    'draft': 'Borrador',
    'sent': 'Enviada',
    'received': 'Recibida',
    'accepted': 'Aceptada',
    'scheduled': 'Agendada',
    'attended': 'Atendida',
    'closed': 'Cerrada',
    'cancelled': 'Cancelada',
  };

  static const _areas = {
    '': 'Todas',
    'medico': 'Medico',
    'psicologia': 'Psicologia',
    'nutricion': 'Nutricion',
    'odontologia': 'Odontologia',
    'atencion_estudiantil': 'Atencion estudiantil',
  };

  final _matriculaController = TextEditingController();
  final _nombreController = TextEditingController();

  String _status = '';
  String _destinationArea = '';
  bool _loading = true;
  String? _error;
  List<ReferralAdminModel> _referrals = [];

  @override
  void initState() {
    super.initState();
    _loadReferrals();
  }

  @override
  void dispose() {
    _matriculaController.dispose();
    _nombreController.dispose();
    super.dispose();
  }

  Future<void> _loadReferrals() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final referrals = await ApiService.getReferrals(
        status: _status,
        destinationArea: _destinationArea,
        matricula: _matriculaController.text,
        studentName: _nombreController.text,
      );
      referrals.sort((a, b) {
        final aDate = a.updatedAt ?? a.createdAt;
        final bDate = b.updatedAt ?? b.createdAt;
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return bDate.compareTo(aDate);
      });
      if (!mounted) return;
      setState(() {
        _referrals = referrals;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _referrals = [];
        _loading = false;
      });
    }
  }

  void _clearFilters() {
    _matriculaController.clear();
    _nombreController.clear();
    setState(() {
      _status = '';
      _destinationArea = '';
    });
    _loadReferrals();
  }

  Future<void> _openNewReferral() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const NewReferralScreen()),
    );
    if (created == true && mounted) {
      _loadReferrals();
    }
  }

  Future<void> _openDetail(ReferralAdminModel referral) async {
    if (referral.id.isEmpty) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ReferralDetailScreen(referralId: referral.id),
      ),
    );
    if (mounted) {
      _loadReferrals();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UAGroColors.grisClaro,
      appBar: AppBar(
        title: const Text('Referencias'),
        backgroundColor: UAGroColors.azulMarino,
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: FilledButton.icon(
              onPressed: _loading ? null : _openNewReferral,
              icon: const Icon(Icons.add),
              label: const Text('Nueva Referencia'),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Actualizar referencias',
            onPressed: _loading ? null : _loadReferrals,
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
                        : _referrals.isEmpty
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
    final pending = _referrals
        .where((item) =>
            item.status == 'sent' ||
            item.status == 'received' ||
            item.status == 'accepted')
        .length;
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
            child: const Icon(
              Icons.swap_horiz_outlined,
              color: UAGroColors.azulMarino,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bandeja de Referencias',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 3),
                Text(
                  'Seguimiento institucional entre areas SASU',
                  style: TextStyle(color: Color(0xFF4B5563)),
                ),
              ],
            ),
          ),
          _Metric(label: 'Total', value: _referrals.length.toString()),
          const SizedBox(width: 10),
          _Metric(label: 'Pendientes', value: pending.toString()),
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
              label: 'Area destino',
              value: _destinationArea,
              items: _areas,
              onChanged: (value) =>
                  setState(() => _destinationArea = value ?? ''),
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
              onSubmitted: (_) => _loadReferrals(),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                prefixIcon: Icon(Icons.person_search_outlined),
              ),
              onSubmitted: (_) => _loadReferrals(),
            ),
          ),
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: _loading ? null : _loadReferrals,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Actualizar'),
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
                DataColumn(label: Text('Fecha')),
                DataColumn(label: Text('Estudiante')),
                DataColumn(label: Text('Matricula')),
                DataColumn(label: Text('Area origen')),
                DataColumn(label: Text('Area destino')),
                DataColumn(label: Text('Prioridad')),
                DataColumn(label: Text('Estado')),
                DataColumn(label: Text('Acciones')),
              ],
              rows: _referrals.map((referral) {
                return DataRow(
                  onSelectChanged:
                      referral.id.isEmpty ? null : (_) => _openDetail(referral),
                  cells: [
                    DataCell(Text(_formatDate(referral.createdAt))),
                    DataCell(
                      SizedBox(
                        width: 190,
                        child: Text(
                          referral.student.nombre.isEmpty
                              ? 'Sin nombre'
                              : referral.student.nombre,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(Text(referral.student.matricula)),
                    DataCell(Text(_areaLabel(referral.origin.area))),
                    DataCell(Text(_areaLabel(referral.destination.area))),
                    DataCell(
                      _Chip(
                        label: _priorityLabel(referral.priority),
                        color: _priorityColor(referral.priority),
                      ),
                    ),
                    DataCell(
                      _Chip(
                        label: _statusLabel(referral.status),
                        color: _statusColor(referral.status),
                      ),
                    ),
                    DataCell(
                      TextButton.icon(
                        onPressed: referral.id.isEmpty
                            ? null
                            : () => _openDetail(referral),
                        icon: const Icon(Icons.visibility_outlined, size: 18),
                        label: const Text('Ver'),
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
          const Icon(
            Icons.error_outline,
            size: 46,
            color: UAGroColors.rojoEscudo,
          ),
          const SizedBox(height: 12),
          const Text(
            'No se pudieron cargar las referencias',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(_error ?? '', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _loadReferrals,
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
          Icon(
            Icons.inbox_outlined,
            size: 48,
            color: Color(0xFF64748B),
          ),
          SizedBox(height: 12),
          Text(
            'No hay referencias para mostrar',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 6),
          Text(
            'Ajusta los filtros o actualiza la bandeja.',
            style: TextStyle(color: Color(0xFF64748B)),
          ),
        ],
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

  static String _formatDate(DateTime? date) {
    if (date == null) return 'Sin fecha';
    return DateFormat('dd/MM/yyyy HH:mm').format(date.toLocal());
  }

  static String _areaLabel(String value) =>
      _areas[value] ?? value.replaceAll('_', ' ');

  static String _statusLabel(String value) =>
      _statuses[value] ?? value.replaceAll('_', ' ');

  static String _priorityLabel(String value) {
    const labels = {
      'baja': 'Baja',
      'media': 'Media',
      'alta': 'Alta',
      'urgente': 'Urgente',
    };
    return labels[value] ?? value.replaceAll('_', ' ');
  }

  static Color _statusColor(String value) {
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

  static Color _priorityColor(String value) {
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

class _Metric extends StatelessWidget {
  final String label;
  final String value;

  const _Metric({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: UAGroColors.azulMarino.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF4B5563)),
          ),
        ],
      ),
    );
  }
}
