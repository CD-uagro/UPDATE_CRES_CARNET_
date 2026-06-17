import 'package:flutter/material.dart';

import '../models/referral_admin_model.dart';
import '../ui/uagro_theme.dart';

class ReferralToast extends StatelessWidget {
  final ReferralAdminModel referral;
  final VoidCallback onClose;
  final VoidCallback onView;

  const ReferralToast({
    super.key,
    required this.referral,
    required this.onClose,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    final studentName = referral.student.nombre.isEmpty
        ? 'Alumno UAGro'
        : referral.student.nombre;
    final area = _formatArea(referral.origin.area);

    return Material(
      color: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
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
                color: Colors.indigo,
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
                        color: Colors.indigo.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.swap_horiz_outlined,
                        color: Colors.indigo,
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
                                  'Nueva referencia recibida',
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
                            studentName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Desde: $area',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: FilledButton.icon(
                              onPressed: onView,
                              icon: const Icon(Icons.open_in_new, size: 16),
                              label: const Text('Ver referencia'),
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

  String _formatArea(String value) {
    switch (value) {
      case 'medico':
        return 'Medico';
      case 'psicologia':
        return 'Psicologia';
      case 'nutricion':
        return 'Nutricion';
      case 'odontologia':
        return 'Odontologia';
      case 'atencion_estudiantil':
        return 'Atencion estudiantil';
      default:
        return value.isEmpty ? 'Area SASU' : value.replaceAll('_', ' ');
    }
  }
}
