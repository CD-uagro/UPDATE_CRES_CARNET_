import 'package:flutter/material.dart';
import '../brand.dart';
import '../app_theme.dart';

/// Card de sección consistente con diseño institucional UAGro
/// Bordes suaves, fondo blanco y encabezado con icono
class SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  final Color? iconColor;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const SectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.iconColor,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveIconColor = iconColor ?? UAGroColors.blue;
    final effectivePadding = padding ?? AppTheme.cardPadding;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: effectivePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado con icono y título
              Row(
                children: [
                  Icon(
                    icon,
                    size: 20,
                    color: effectiveIconColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: UAGroColors.blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppTheme.spacing),

              // Contenido de la sección
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// Variante de SectionCard con diseño compacto
class CompactSectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  final Color? iconColor;
  final VoidCallback? onTap;

  const CompactSectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveIconColor = iconColor ?? UAGroColors.blue;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: effectiveIconColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: UAGroColors.blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// Card de estado con colores específicos para diferentes estados
class StatusSectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  final StatusCardType type;
  final VoidCallback? onTap;

  const StatusSectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    required this.type,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = _getStatusColors(type);

    return Card(
      color: colors.backgroundColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colors.borderColor,
              width: 1,
            ),
          ),
          child: Padding(
            padding: AppTheme.cardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      icon,
                      size: 20,
                      color: colors.iconColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colors.textColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacing),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }

  _StatusColors _getStatusColors(StatusCardType type) {
    switch (type) {
      case StatusCardType.success:
        return _StatusColors(
          backgroundColor: UAGroColors.success.withOpacity(0.1),
          borderColor: UAGroColors.success.withOpacity(0.3),
          iconColor: UAGroColors.success,
          textColor: UAGroColors.success,
        );
      case StatusCardType.warning:
        return _StatusColors(
          backgroundColor: UAGroColors.warning.withOpacity(0.1),
          borderColor: UAGroColors.warning.withOpacity(0.3),
          iconColor: UAGroColors.warning,
          textColor: UAGroColors.warning,
        );
      case StatusCardType.error:
        return _StatusColors(
          backgroundColor: UAGroColors.error.withOpacity(0.1),
          borderColor: UAGroColors.error.withOpacity(0.3),
          iconColor: UAGroColors.error,
          textColor: UAGroColors.error,
        );
      case StatusCardType.info:
        return _StatusColors(
          backgroundColor: UAGroColors.blue.withOpacity(0.1),
          borderColor: UAGroColors.blue.withOpacity(0.3),
          iconColor: UAGroColors.blue,
          textColor: UAGroColors.blue,
        );
    }
  }
}

/// Tipos de estados para StatusSectionCard
enum StatusCardType {
  success,
  warning,
  error,
  info,
}

/// Colores para diferentes estados
class _StatusColors {
  final Color backgroundColor;
  final Color borderColor;
  final Color iconColor;
  final Color textColor;

  const _StatusColors({
    required this.backgroundColor,
    required this.borderColor,
    required this.iconColor,
    required this.textColor,
  });
}
