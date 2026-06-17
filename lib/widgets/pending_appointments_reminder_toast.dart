import 'package:flutter/material.dart';

import '../ui/uagro_theme.dart';

class PendingAppointmentsReminderToast extends StatelessWidget {
  final int pendingCount;
  final VoidCallback onClose;
  final VoidCallback onView;

  const PendingAppointmentsReminderToast({
    super.key,
    required this.pendingCount,
    required this.onClose,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 340,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border:
              Border.all(color: UAGroColors.azulMarino.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 4,
                color: UAGroColors.azulMarino,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: UAGroColors.rojoEscudo.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.notifications_active_outlined,
                        color: UAGroColors.rojoEscudo,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Solicitudes de cita pendientes',
                                  style: TextStyle(
                                    color: UAGroColors.azulMarino,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              InkWell(
                                borderRadius: BorderRadius.circular(18),
                                onTap: onClose,
                                child: const Padding(
                                  padding: EdgeInsets.all(4),
                                  child: Icon(Icons.close, size: 18),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tienes $pendingCount solicitudes por confirmar o reprogramar.',
                            style: TextStyle(
                              color: Colors.grey.shade800,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: FilledButton.icon(
                              onPressed: onView,
                              icon: const Icon(Icons.open_in_new, size: 16),
                              label: const Text('Ver solicitudes'),
                              style: FilledButton.styleFrom(
                                backgroundColor: UAGroColors.azulMarino,
                                foregroundColor: Colors.white,
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
