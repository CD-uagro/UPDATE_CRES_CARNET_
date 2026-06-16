import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/api_service.dart';
import '../data/auth_service.dart';
import '../models/ticket_admin_model.dart';
import '../ui/uagro_theme.dart';
import 'ticket_detail_screen.dart';

class TicketsScreen extends StatefulWidget {
  const TicketsScreen({super.key});

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  static const _statuses = {
    '': 'Todos',
    'abierto': 'Abierto',
    'en_revision': 'En revision',
    'en_proceso': 'En proceso',
    'resuelto': 'Resuelto',
    'cerrado': 'Cerrado',
    'cancelado': 'Cancelado',
  };

  static const _categories = {
    '': 'Todas',
    'psicologia': 'Psicologia',
    'medicina': 'Medicina',
    'nutricion': 'Nutricion',
    'vacunacion': 'Vacunacion',
    'promocion_salud': 'Promocion de salud',
    'soporte_carnet': 'Soporte de carnet',
    'administrativo': 'Administrativo',
    'otro': 'Otro',
  };

  static const _priorities = {
    '': 'Todas',
    'baja': 'Baja',
    'media': 'Media',
    'alta': 'Alta',
    'urgente': 'Urgente',
  };

  final _matriculaController = TextEditingController();
  final _nombreController = TextEditingController();
  final _campusController = TextEditingController();

  String _status = '';
  String _category = '';
  String _priority = '';
  bool _loading = true;
  String? _error;
  List<TicketAdminModel> _tickets = [];

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  @override
  void dispose() {
    _matriculaController.dispose();
    _nombreController.dispose();
    _campusController.dispose();
    super.dispose();
  }

  Future<void> _loadTickets() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final tickets = await ApiService.getTickets(
        status: _status,
        category: _category,
        priority: _priority,
        campus: _campusController.text,
        matricula: _matriculaController.text,
      );
      if (!mounted) return;
      setState(() {
        _tickets = tickets;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _tickets = [];
        _loading = false;
      });
    }
  }

  List<TicketAdminModel> get _visibleTickets {
    final nameQuery = _nombreController.text.trim().toLowerCase();
    if (nameQuery.isEmpty) return _tickets;
    return _tickets
        .where(
            (ticket) => ticket.nombrePaciente.toLowerCase().contains(nameQuery))
        .toList();
  }

  void _clearFilters() {
    _matriculaController.clear();
    _nombreController.clear();
    _campusController.clear();
    setState(() {
      _status = '';
      _category = '';
      _priority = '';
    });
    _loadTickets();
  }

  Future<void> _openDetail(TicketAdminModel ticket) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TicketDetailScreen(ticketId: ticket.id),
      ),
    );
    if (mounted) {
      _loadTickets();
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleTickets = _visibleTickets;

    return Scaffold(
      backgroundColor: UAGroColors.grisClaro,
      appBar: AppBar(
        title: const Text('Centro de Atencion'),
        backgroundColor: UAGroColors.azulMarino,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _loading ? null : _loadTickets,
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
                        : visibleTickets.isEmpty
                            ? _buildEmpty()
                            : _buildTable(visibleTickets),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
              Icons.support_agent,
              color: UAGroColors.azulMarino,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bandeja de Tickets',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 3),
                Text(
                  'Gestion operativa de solicitudes del Centro de Atencion Universitaria',
                  style: TextStyle(color: Color(0xFF4B5563)),
                ),
              ],
            ),
          ),
          _Metric(label: 'Tickets', value: _tickets.length.toString()),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _panelDecoration(),
      child: Column(
        children: [
          Row(
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
                  label: 'Categoria',
                  value: _category,
                  items: _categories,
                  onChanged: (value) => setState(() => _category = value ?? ''),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DropdownFilter(
                  label: 'Prioridad',
                  value: _priority,
                  items: _priorities,
                  onChanged: (value) => setState(() => _priority = value ?? ''),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _campusController,
                  decoration: const InputDecoration(
                    labelText: 'Campus',
                    prefixIcon: Icon(Icons.location_city_outlined),
                  ),
                  onSubmitted: (_) => _loadTickets(),
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
                  onSubmitted: (_) => _loadTickets(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre alumno',
                    prefixIcon: Icon(Icons.person_search_outlined),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 118,
                child: FilledButton.icon(
                  onPressed: _loading ? null : _loadTickets,
                  icon: const Icon(Icons.search, size: 18),
                  label: const Text('Buscar'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.outlined(
                tooltip: 'Limpiar filtros',
                onPressed: _loading ? null : _clearFilters,
                icon: const Icon(Icons.filter_alt_off_outlined),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTable(List<TicketAdminModel> tickets) {
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
                DataColumn(label: Text('ID ticket')),
                DataColumn(label: Text('Fecha')),
                DataColumn(label: Text('Alumno')),
                DataColumn(label: Text('Matricula')),
                DataColumn(label: Text('Categoria')),
                DataColumn(label: Text('Prioridad')),
                DataColumn(label: Text('Estado')),
                DataColumn(label: Text('Campus/Unidad')),
                DataColumn(label: Text('')),
              ],
              rows: tickets.map((ticket) {
                return DataRow(
                  cells: [
                    DataCell(Text(_shortTicketId(ticket))),
                    DataCell(Text(_formatDate(ticket.createdAtUtc))),
                    DataCell(SizedBox(
                      width: 190,
                      child: Text(
                        ticket.nombrePaciente.isEmpty
                            ? 'Sin nombre'
                            : ticket.nombrePaciente,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )),
                    DataCell(Text(ticket.matricula)),
                    DataCell(Text(_categoryLabel(ticket.categoria))),
                    DataCell(_Chip(
                      label: _priorityLabel(ticket.prioridad),
                      color: _priorityColor(ticket.prioridad),
                    )),
                    DataCell(_Chip(
                      label: _statusLabel(ticket.estado),
                      color: _statusColor(ticket.estado),
                    )),
                    DataCell(SizedBox(
                      width: 180,
                      child: Text(
                        _campusLabel(ticket),
                        overflow: TextOverflow.ellipsis,
                      ),
                    )),
                    DataCell(
                      IconButton(
                        tooltip: 'Ver detalle',
                        onPressed: () => _openDetail(ticket),
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
            'No se pudo cargar la bandeja',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? '',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF4B5563)),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _loadTickets,
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
          Icon(Icons.inbox_outlined, size: 54, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            'No hay tickets para los filtros seleccionados',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 6),
          Text('Ajusta los filtros o actualiza la bandeja.'),
        ],
      ),
    );
  }

  static String _shortTicketId(TicketAdminModel ticket) {
    if (ticket.ticketNumber.isNotEmpty) return ticket.ticketNumber;
    if (ticket.id.length <= 18) return ticket.id;
    return ticket.id.substring(0, 18);
  }

  static String _formatDate(DateTime? date) {
    if (date == null) return 'Sin fecha';
    return DateFormat('dd/MM/yyyy HH:mm').format(date.toLocal());
  }

  static String _categoryLabel(String value) {
    return _categories[value] ?? value.replaceAll('_', ' ');
  }

  static String _priorityLabel(String value) {
    return _priorities[value] ?? value;
  }

  static String _statusLabel(String value) {
    return _statuses[value] ?? value.replaceAll('_', ' ');
  }

  static String _campusLabel(TicketAdminModel ticket) {
    final unit = ticket.unidadAcademica.isNotEmpty
        ? ticket.unidadAcademica
        : ticket.preparatoria;
    final campus = ticket.campus.isEmpty
        ? 'Sin campus'
        : AuthService.formatCampusName(ticket.campus);
    if (unit.isEmpty) return campus;
    return '$campus / $unit';
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
