import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/auth_service.dart';
import '../../data/recent_activity_service.dart';
import '../uagro_theme.dart';

class RecentActivityPanel extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return FutureBuilder<_RecentActivityData>(
      future: _loadData(),
      builder: (context, snapshot) {
        final data = snapshot.data ?? const _RecentActivityData();
        final loading = snapshot.connectionState == ConnectionState.waiting;

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
                      onOpen: onOpenPatient,
                    ),
                  );
                  final notes = _ActivityBlock(
                    title: 'Últimas notas realizadas',
                    emptyText: 'Aún no has registrado notas recientemente.',
                    child: _NotesList(
                      items: data.notes,
                      onOpen: onOpenNote,
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
    final patients = await RecentActivityService.getRecentPatients(user);
    final notes = await RecentActivityService.getRecentNotes(user);
    return _RecentActivityData(patients: patients, notes: notes);
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

  const _PatientsList({
    required this.items,
    required this.onOpen,
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
          ),
      ],
    );
  }
}

class _NotesList extends StatelessWidget {
  final List<RecentNoteActivity> items;
  final ValueChanged<String> onOpen;

  const _NotesList({
    required this.items,
    required this.onOpen,
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

  const _ActivityTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.meta,
    required this.trailing,
    required this.onTap,
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
                Icon(trailing, size: 18, color: Colors.grey[600]),
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
