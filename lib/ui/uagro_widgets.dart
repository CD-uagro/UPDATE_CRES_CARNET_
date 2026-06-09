import 'package:flutter/material.dart';
import 'package:cres_carnets_ibmcloud/ui/uagro_theme.dart';
import 'package:cres_carnets_ibmcloud/screens/dashboard_screen.dart';

/// AppBar con gradiente UAGro y botón de inicio sutil
PreferredSizeWidget uagroAppBar(String title,
    [String? subtitle,
    List<Widget>? actions,
    BuildContext? context,
    dynamic db]) {
  List<Widget> allActions = [];

  // Agregar botón de inicio sutil si tenemos contexto y db
  if (context != null && db != null) {
    allActions.add(
      IconButton(
        icon: const Icon(Icons.home_outlined, color: Colors.white70, size: 22),
        tooltip: 'Ir al inicio',
        onPressed: () {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => DashboardScreen(db: db)),
            (route) => false,
          );
        },
      ),
    );
  }

  // Agregar acciones adicionales si las hay
  if (actions != null) {
    allActions.addAll(actions);
  }

  return AppBar(
    flexibleSpace: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [UAGroColors.azulMarino, UAGroColors.rojoEscudo],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
    ),
    title: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w800)),
        if (subtitle != null) const SizedBox(height: 2),
        if (subtitle != null)
          const Text('Expediente de salud universitario',
              style:
                  TextStyle(color: Colors.white70, fontSize: 12, height: 1.1)),
      ],
    ),
    backgroundColor: Colors.transparent,
    actions: allActions.isNotEmpty ? allActions : null,
  );
}

/// Encabezado “portada” dentro del contenido
class BrandHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const BrandHeader({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(18)),
        gradient: LinearGradient(
          colors: [UAGroColors.azulMarino, UAGroColors.rojoEscudo],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      child: Row(
        children: [
          const Icon(Icons.local_hospital, color: Colors.white, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('CRES Carnets',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16)),
                  SizedBox(height: 2),
                  Text('Expediente de salud universitario',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                ]),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta de sección con icono y título
class SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  const SectionCard(
      {super.key,
      required this.icon,
      required this.title,
      required this.child,
      this.padding});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: padding ?? const EdgeInsets.fromLTRB(14, 14, 14, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: cs.primary),
              const SizedBox(width: 8),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
            ]),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
