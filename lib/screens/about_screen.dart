// lib/screens/about_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/version_service.dart';
import '../ui/uagro_theme.dart';
import 'dashboard_screen.dart';

/// Pantalla "Acerca de" que muestra información de la aplicación y changelog
class AboutScreen extends StatelessWidget {
  final dynamic db;
  const AboutScreen({super.key, this.db});

  @override
  Widget build(BuildContext context) {
    final versionService = VersionService();
    final versionInfo = versionService.versionInfo;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Acerca de'),
        backgroundColor: UAGroColors.azulMarino,
        actions: [
          // Botón de inicio sutil
          IconButton(
            icon: const Icon(Icons.home_outlined,
                color: Colors.white70, size: 22),
            tooltip: 'Ir al inicio',
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                    builder: (context) => DashboardScreen(db: db)),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: versionInfo == null
          ? const Center(
              child: Text(
                'Información de versión no disponible',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Header con logo y versión
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          UAGroColors.azulMarino,
                          UAGroColors.azulMarino.withOpacity(0.8),
                        ],
                      ),
                    ),
                    child: Column(
                      children: [
                        // Icono de la app
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.badge,
                            size: 80,
                            color: UAGroColors.azulMarino,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Nombre de la app
                        const Text(
                          'CRES Carnets UAGro',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Versión
                        Text(
                          'Versión ${versionInfo.fullVersion}',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Fecha y canal
                        Text(
                          '${versionInfo.releaseDate} • Canal: ${versionInfo.channel}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white60,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Información de la institución
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoCard(
                          icon: Icons.school,
                          title: 'Universidad Autónoma de Guerrero',
                          subtitle: 'Centro Regional de Educación Superior',
                          color: UAGroColors.azulMarino,
                        ),
                        const SizedBox(height: 16),

                        _buildInfoCard(
                          icon: Icons.info_outline,
                          title: 'Sistema de Gestión de Carnets',
                          subtitle:
                              'Control de expedientes estudiantiles con sincronización en la nube',
                          color: UAGroColors.rojoEscudo,
                        ),
                        const SizedBox(height: 16),

                        _buildInfoCard(
                          icon: Icons.cloud_queue,
                          title: 'Modo Híbrido',
                          subtitle:
                              'Funciona online y offline • Sincronización automática',
                          color: Colors.blue,
                        ),

                        const SizedBox(height: 32),

                        // Changelog
                        Row(
                          children: [
                            Icon(Icons.history, color: UAGroColors.azulMarino),
                            const SizedBox(width: 8),
                            const Text(
                              'Historial de Versiones',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        ...versionInfo.changelog.take(3).map((entry) {
                          final isCurrent =
                              entry.version == versionInfo.version;
                          return _buildChangelogCard(entry, isCurrent);
                        }),

                        const SizedBox(height: 24),

                        // Botón para copiar información
                        Center(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              final info = '''
CRES Carnets UAGro
Versión: ${versionInfo.fullVersion}
Fecha: ${versionInfo.releaseDate}
Canal: ${versionInfo.channel}
Institución: Universidad Autónoma de Guerrero

${versionService.getChangelogFormatted(maxVersions: 1)}
''';
                              Clipboard.setData(ClipboardData(text: info));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Información copiada al portapapeles'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            icon: const Icon(Icons.copy),
                            label: const Text('Copiar información'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: UAGroColors.azulMarino,
                              side: BorderSide(color: UAGroColors.azulMarino),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Copyright
                        Center(
                          child: Text(
                            '© 2025 Universidad Autónoma de Guerrero',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChangelogCard(ChangelogEntry entry, bool isCurrent) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrent
            ? UAGroColors.azulMarino.withOpacity(0.1)
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCurrent ? UAGroColors.azulMarino : Colors.grey[300]!,
          width: isCurrent ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isCurrent)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: UAGroColors.azulMarino,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'ACTUAL',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              if (isCurrent) const SizedBox(width: 8),
              Text(
                'v${entry.version}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isCurrent ? UAGroColors.azulMarino : Colors.black87,
                ),
              ),
              const Spacer(),
              Text(
                entry.date,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...entry.changes.map((change) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• ',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                    Expanded(
                      child: Text(
                        change,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
