import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/auth_service.dart';
import '../../data/recent_activity_service.dart';
import '../uagro_theme.dart';

class RecentActivityPanel extends StatefulWidget {
  final AuthUser user;
  final ValueChanged<String> onOpenPatient;
  final ValueChanged<String> onOpenNote;

  const RecentActivityPanel({
    super.key,
    required this.user,
    required this.onOpenPatient,
    required this.onOpenNote,
  });

  @override
  State<RecentActivityPanel> createState() => _RecentActivityPanelState();
}

class _RecentActivityPanelState extends State<RecentActivityPanel> {
  late Future<_RecentActivityData> _activityFuture;

  @override
  void initState() {
    super.initState();
    _activityFuture = _loadData();
  }

  @override
  void didUpdateWidget(covariant RecentActivityPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.id != widget.user.id ||
        oldWidget.user.username != widget.user.username ||
        oldWidget.user.campus != widget.user.campus) {
      _activityFuture = _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_RecentActivityData>(
      future: _activityFuture,
      builder: (context, snapshot) {
        final data = snapshot.data ?? const _RecentActivityData();
        final loading = snapshot.connectionState == ConnectionState.waiting;
        final hasActivity = data.patients.isNotEmpty || data.notes.isNotEmpty;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: UAGroColors.azulMarino.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: UAGroColors.azulMarino.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.history_rounded,
                      size: 20,
                      color: UAGroColors.azulMarino,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Actividad reciente',
                      style: TextStyle(
                        color: UAGroColors.azulMarino,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (loading)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  if (!loading && hasActivity)
                    IconButton(
                      tooltip: 'Limpiar actividad reciente',
                      icon: const Icon(Icons.delete_sweep_outlined),
                      color: UAGroColors.azulMarino,
                      onPressed: _confirmClearAll,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 820;
                  final patients = _ActivityBlock(
                    title: 'Últimos pacientes atendidos',
                    emptyText: 'Aún no hay pacientes atendidos recientemente.',
                    child: _PatientsList(
                      items: data.patients,
                      onOpen: widget.onOpenPatient,
                      onRemove: _confirmRemovePatient,
                    ),
                  );
                  final notes = _ActivityBlock(
                    title: 'Últimas notas realizadas',
                    emptyText: 'Aún no has registrado notas recientemente.',
                    child: _NotesList(
                      items: data.notes,
                      onOpen: widget.onOpenNote,
                      onRemove: _confirmRemoveNote,
                    ),
                  );

                  if (!wide) {
                    return Column(
                      children: [
                        patients,
                        const SizedBox(height: 12),
                        notes,
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: patients),
                      const SizedBox(width: 12),
                      Expanded(child: notes),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<_RecentActivityData> _loadData() async {
    final patients = await RecentActivityService.getRecentPatients(widget.user);
    final notes = await RecentActivityService.getRecentNotes(widget.user);
    return _RecentActivityData(patients: patients, notes: notes);
  }

  void _refreshActivity() {
    if (!mounted) return;
    setState(() {
      _activityFuture = _loadData();
    });
  }

  Future<void> _confirmRemovePatient(RecentPatientActivity item) async {
    final confirmed = await _showConfirmDialog(
      title: '¿Quitar esta actividad reciente?',
      message:
          'Esto solo eliminará el acceso rápido de la lista. No borrará información clínica ni registros del paciente.',
      confirmLabel: 'Quitar',
    );
    if (!confirmed) return;

    await RecentActivityService.removePatientActivity(
      user: widget.user,
      matricula: item.matricula,
    );
    _refreshActivity();
  }

  Future<void> _confirmRemoveNote(RecentNoteActivity item) async {
    final confirmed = await _showConfirmDialog(
      title: '¿Quitar esta actividad reciente?',
      message:
          'Esto solo eliminará el acceso rápido de la lista. No borrará información clínica ni registros del paciente.',
      confirmLabel: 'Quitar',
    );
    if (!confirmed) return;

    await RecentActivityService.removeNoteActivity(
      user: widget.user,
      noteId: item.noteId,
    );
    _refreshActivity();
  }

  Future<void> _confirmClearAll() async {
    final confirmed = await _showConfirmDialog(
      title: 'Limpiar actividad reciente',
      message:
          'Esto quitará todos los accesos rápidos recientes. No se eliminarán notas, expedientes ni registros clínicos.',
      confirmLabel: 'Quitar',
    );
    if (!confirmed) return;

    await RecentActivityService.clearRecentActivity(widget.user);
    _refreshActivity();
  }

  Future<bool> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result == true;
  }
}

class _RecentActivityData {
  final List<RecentPatientActivity> patients;
  final List<RecentNoteActivity> notes;

  const _RecentActivityData({
    this.patients = const [],
    this.notes = const [],
  });
}

class _ActivityBlock extends StatelessWidget {
  final String title;
  final String emptyText;
  final Widget child;

  const _ActivityBlock({
    required this.title,
    required this.emptyText,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 210),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFE),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDDE5F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: UAGroColors.azulMarino,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          DefaultTextStyle.merge(
            style: TextStyle(
              color: Colors.grey[800],
              fontSize: 12,
            ),
            child: _EmptyAwareList(emptyText: emptyText, child: child),
          ),
        ],
      ),
    );
  }
}

class _EmptyAwareList extends StatelessWidget {
  final String emptyText;
  final Widget child;

  const _EmptyAwareList({
    required this.emptyText,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (child is _PatientsList && (child as _PatientsList).items.isEmpty) {
      return _EmptyMessage(text: emptyText);
    }
    if (child is _NotesList && (child as _NotesList).items.isEmpty) {
      return _EmptyMessage(text: emptyText);
    }
    return child;
  }
}

class _PatientsList extends StatelessWidget {
  final List<RecentPatientActivity> items;
  final ValueChanged<String> onOpen;
  final ValueChanged<RecentPatientActivity> onRemove;

  const _PatientsList({
    required this.items,
    required this.onOpen,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final item in items)
          _ActivityTile(
            icon: Icons.person_outline,
            title: item.nombreCompleto,
            subtitle: 'Matrícula: ${item.matricula}',
            meta: '${_formatDate(item.occurredAt)} · ${item.areaResponsable}',
            trailing: Icons.chevron_right_rounded,
            onTap: () => onOpen(item.matricula),
            onRemove: () => onRemove(item),
          ),
      ],
    );
  }
}

class _NotesList extends StatelessWidget {
  final List<RecentNoteActivity> items;
  final ValueChanged<String> onOpen;
  final ValueChanged<RecentNoteActivity> onRemove;

  const _NotesList({
    required this.items,
    required this.onOpen,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final item in items)
          _ActivityTile(
            icon: item.synced ? Icons.cloud_done_outlined : Icons.cloud_off,
            title: item.nombreEstudiante,
            subtitle: '${item.departamento} · Matrícula: ${item.matricula}',
            meta: '${_formatDate(item.occurredAt)} · '
                '${item.synced ? 'Sincronizada' : 'Pendiente'}',
            description: item.diagnosticoResumen,
            trailing: Icons.chevron_right_rounded,
            onTap: () => onOpen(item.matricula),
            onRemove: () => onRemove(item),
          ),
      ],
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String meta;
  final String? description;
  final IconData trailing;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _ActivityTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.meta,
    required this.trailing,
    required this.onTap,
    required this.onRemove,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE4E9F2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 20, color: UAGroColors.azulMarino),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title.trim().isEmpty ? 'Sin nombre' : title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: UAGroColors.azulMarino,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (description != null &&
                          description!.trim().isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          description!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 3),
                      Text(
                        meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkResponse(
                      onTap: onRemove,
                      radius: 18,
                      child: Tooltip(
                        message: 'Quitar de actividad reciente',
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Icon(trailing, size: 18, color: Colors.grey[600]),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  final String text;

  const _EmptyMessage({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE4E9F2)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.grey[700],
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

String _formatDate(DateTime date) {
  if (date.millisecondsSinceEpoch == 0) return 'Fecha pendiente';
  return DateFormat('dd/MM HH:mm').format(date);
}
