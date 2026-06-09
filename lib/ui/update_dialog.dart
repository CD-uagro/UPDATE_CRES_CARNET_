import 'package:flutter/material.dart';
import '../services/update_service.dart';
import '../ui/uagro_theme.dart';

/// Diálogo para notificar actualizaciones disponibles
class UpdateDialog extends StatelessWidget {
  final VersionInfo versionInfo;
  final String currentVersion;
  final VoidCallback onUpdate;
  final VoidCallback? onLater;

  const UpdateDialog({
    Key? key,
    required this.versionInfo,
    required this.currentVersion,
    required this.onUpdate,
    this.onLater,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isMandatory = versionInfo.isMandatory;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(
            isMandatory ? Icons.system_update : Icons.update,
            color: isMandatory ? Colors.orange : UAGroColors.azulMarino,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMandatory
                      ? 'Actualización Requerida'
                      : 'Actualización Disponible',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Versión ${versionInfo.version}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info de versiones
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _buildInfoRow(
                    'Versión actual:',
                    currentVersion,
                    Colors.grey[700]!,
                  ),
                  const SizedBox(height: 6),
                  _buildInfoRow(
                    'Nueva versión:',
                    '${versionInfo.version} (Build ${versionInfo.buildNumber})',
                    UAGroColors.azulMarino,
                  ),
                  const SizedBox(height: 6),
                  _buildInfoRow(
                    'Fecha de lanzamiento:',
                    versionInfo.releaseDate,
                    Colors.grey[700]!,
                  ),
                  if (versionInfo.fileSize != null) ...[
                    const SizedBox(height: 6),
                    _buildInfoRow(
                      'Tamaño:',
                      _formatFileSize(versionInfo.fileSize!),
                      Colors.grey[700]!,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Changelog
            if (versionInfo.changelog.isNotEmpty) ...[
              const Text(
                '¿Qué hay de nuevo?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: versionInfo.changelog.map((change) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '• ',
                            style: TextStyle(
                              color: UAGroColors.azulMarino,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              change,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],

            // Mensaje de actualización obligatoria
            if (isMandatory) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  border: Border.all(color: Colors.orange),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Esta actualización es obligatoria para continuar usando la aplicación.',
                        style: TextStyle(
                          color: Colors.orange[900],
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        // Botón "Más tarde" (solo si no es obligatoria)
        if (!isMandatory && onLater != null)
          TextButton(
            onPressed: onLater,
            child: Text(
              'Más tarde',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),

        // Botón "Actualizar"
        ElevatedButton.icon(
          onPressed: onUpdate,
          icon: const Icon(Icons.download),
          label: Text(isMandatory ? 'Actualizar ahora' : 'Actualizar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: UAGroColors.azulMarino,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, Color valueColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Muestra el diálogo de actualización
  static Future<bool?> show(
    BuildContext context, {
    required VersionInfo versionInfo,
    required String currentVersion,
    required VoidCallback onUpdate,
    VoidCallback? onLater,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: !versionInfo.isMandatory,
      builder: (context) => UpdateDialog(
        versionInfo: versionInfo,
        currentVersion: currentVersion,
        onUpdate: () {
          Navigator.of(context).pop(true);
          onUpdate();
        },
        onLater: versionInfo.isMandatory
            ? null
            : () {
                Navigator.of(context).pop(false);
                onLater?.call();
              },
      ),
    );
  }
}

/// Diálogo de progreso de descarga
class DownloadProgressDialog extends StatelessWidget {
  final double progress;
  final String? status;

  const DownloadProgressDialog({
    Key? key,
    required this.progress,
    this.status,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final percentage = (progress * 100).toStringAsFixed(0);

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(
            Icons.download,
            color: UAGroColors.azulMarino,
          ),
          const SizedBox(width: 12),
          const Text('Descargando actualización'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(UAGroColors.azulMarino),
            minHeight: 8,
          ),
          const SizedBox(height: 16),
          Text(
            '$percentage%',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (status != null) ...[
            const SizedBox(height: 8),
            Text(
              status!,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  /// Muestra el diálogo de progreso
  static void show(
    BuildContext context, {
    required double progress,
    String? status,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DownloadProgressDialog(
        progress: progress,
        status: status,
      ),
    );
  }
}
