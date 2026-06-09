// lib/screens/pending_sync_screen.dart
import 'package:flutter/material.dart';
import '../data/db.dart';
import '../data/sync_service.dart';
import '../ui/uagro_theme.dart';
import 'sync_diagnostic_screen.dart';

/// Pantalla dedicada para gestionar y sincronizar registros pendientes
class PendingSyncScreen extends StatefulWidget {
  final AppDatabase db;

  const PendingSyncScreen({Key? key, required this.db}) : super(key: key);

  @override
  State<PendingSyncScreen> createState() => _PendingSyncScreenState();
}

class _PendingSyncScreenState extends State<PendingSyncScreen> {
  bool _loading = true;
  bool _syncing = false;
  List<HealthRecord> _pendingRecords = [];
  List<Note> _pendingNotes = [];
  List<Cita> _pendingCitas = [];
  List<VacunacionesPendiente> _pendingVacunaciones = [];

  @override
  void initState() {
    super.initState();
    _loadPendingData();
  }

  Future<void> _loadPendingData() async {
    setState(() => _loading = true);

    try {
      final records = await widget.db.getPendingRecords();
      final notes = await widget.db.getPendingNotes();
      final citas = await widget.db.getPendingCitas();
      final vacunaciones = await widget.db.getPendingVacunaciones();

      // DEBUG: Imprimir TODOS los carnets para diagnosticar
      print('=== DEBUG CARNETS ===');
      final allRecords = await widget.db.getAllRecordsWithSyncStatus();
      print('Total carnets en DB: ${allRecords.length}');
      for (final record in allRecords) {
        print(
            '  - ${record.matricula} | ${record.nombreCompleto} | synced=${record.synced}');
      }
      print('Carnets pendientes (synced=false): ${records.length}');
      print('=====================');

      if (mounted) {
        setState(() {
          _pendingRecords = records;
          _pendingNotes = notes;
          _pendingCitas = citas;
          _pendingVacunaciones = vacunaciones;
          _loading = false;
        });
      }
    } catch (e) {
      print('Error cargando datos pendientes: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _syncAll() async {
    setState(() => _syncing = true);

    try {
      final syncService = SyncService(widget.db);
      final result = await syncService.syncAll();

      if (mounted) {
        setState(() => _syncing = false);

        // Recargar datos
        await _loadPendingData();

        // Mostrar resultado
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  result.hasErrors ? Icons.warning : Icons.check_circle,
                  color: result.hasErrors ? Colors.orange : Colors.green,
                ),
                const SizedBox(width: 8),
                const Text('Resultado de Sincronización'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (result.totalPending == 0)
                    const Text('✅ No había datos pendientes')
                  else ...[
                    Text('Total procesados: ${result.totalPending}'),
                    const Divider(),
                    _buildResultRow(
                        'Carnets', result.recordsSynced, result.recordsErrors),
                    _buildResultRow(
                        'Notas', result.notesSynced, result.notesErrors),
                    _buildResultRow(
                        'Citas', result.citasSynced, result.citasErrors),
                    _buildResultRow('Vacunaciones', result.vacunacionesSynced,
                        result.vacunacionesErrors),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _syncing = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al sincronizar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showAllRecordsDebug() async {
    final allRecords = await widget.db.getAllRecordsWithSyncStatus();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🐛 Debug: Todos los Carnets en DB'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total en base de datos: ${allRecords.length}'),
              Text(
                'Sincronizados: ${allRecords.where((r) => r.synced).length} | '
                'Pendientes: ${allRecords.where((r) => !r.synced).length}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
              const Divider(),
              ...allRecords.map((r) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(
                          r.synced ? Icons.check_circle : Icons.pending,
                          size: 16,
                          color: r.synced ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r.nombreCompleto,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'ID: ${r.id} | ${r.matricula} | ${r.synced ? "SINCRONIZADO" : "PENDIENTE"}',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                        // Botón para marcar como pendiente si está sincronizado incorrectamente
                        if (r.synced)
                          IconButton(
                            icon: const Icon(Icons.refresh, size: 18),
                            tooltip: 'Marcar como pendiente',
                            onPressed: () async {
                              await widget.db.markRecordAsPending(r.id);
                              Navigator.pop(context);
                              await _loadPendingData();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        '${r.matricula} marcado como pendiente')),
                              );
                            },
                          ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
        actions: [
          // Botón para limpiar carnets sincronizados
          if (allRecords.where((r) => r.synced).isNotEmpty)
            TextButton.icon(
              icon: const Icon(Icons.delete_sweep, color: Colors.red),
              label: const Text('Limpiar Sincronizados',
                  style: TextStyle(color: Colors.red)),
              onPressed: () async {
                final syncedCount = allRecords.where((r) => r.synced).length;

                // Confirmar antes de borrar
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('⚠️ Confirmar eliminación'),
                    content: Text(
                      '¿Eliminar los $syncedCount carnets sincronizados?\n\n'
                      'Los carnets ya están guardados en la nube. '
                      'Esta acción solo los elimina de la base de datos local para limpiar espacio.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style:
                            TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Eliminar'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  // Eliminar carnets sincronizados
                  final db = widget.db;
                  for (final record in allRecords.where((r) => r.synced)) {
                    await (db.delete(db.healthRecords)
                          ..where((tbl) => tbl.id.equals(record.id)))
                        .go();
                  }

                  if (!mounted) return;
                  Navigator.pop(context); // Cerrar diálogo de debug
                  await _loadPendingData(); // Recargar datos

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          '✅ $syncedCount carnets sincronizados eliminados'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, int success, int errors) {
    if (success == 0 && errors == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          if (success > 0)
            Text('$success ✓', style: const TextStyle(color: Colors.green)),
          const SizedBox(width: 8),
          if (errors > 0)
            Text('$errors ✗', style: const TextStyle(color: Colors.red)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalPending = _pendingRecords.length +
        _pendingNotes.length +
        _pendingCitas.length +
        _pendingVacunaciones.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Datos Pendientes de Sincronizar'),
        backgroundColor: UAGroColors.azulMarino,
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            tooltip: 'Ver TODOS los carnets (debug)',
            onPressed: _showAllRecordsDebug,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : totalPending == 0
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 64,
                        color: Colors.green.shade300,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '✅ No hay datos pendientes',
                        style: TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Todos tus datos están sincronizados',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Icon(
                              Icons.cloud_upload,
                              size: 48,
                              color: UAGroColors.azulMarino,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '$totalPending registro(s) pendientes',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _syncing ? null : _syncAll,
                                icon: _syncing
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.sync),
                                label: Text(_syncing
                                    ? 'Sincronizando...'
                                    : 'Sincronizar Ahora'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.all(16),
                                  backgroundColor: Colors.green.shade600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_pendingRecords.isNotEmpty) _buildCarnetsSection(),
                    if (_pendingNotes.isNotEmpty)
                      _buildSection(
                        '📝 Notas Médicas',
                        _pendingNotes.length,
                        _pendingNotes
                            .map((n) => '${n.matricula} - ${n.departamento}')
                            .toList(),
                      ),
                    if (_pendingCitas.isNotEmpty)
                      _buildSection(
                        '📅 Citas',
                        _pendingCitas.length,
                        _pendingCitas
                            .map((c) => '${c.matricula} - ${c.motivo}')
                            .toList(),
                      ),
                    if (_pendingVacunaciones.isNotEmpty)
                      _buildSection(
                        '💉 Vacunaciones',
                        _pendingVacunaciones.length,
                        _pendingVacunaciones
                            .map((v) => '${v.matricula} - ${v.vacuna}')
                            .toList(),
                      ),
                  ],
                ),
    );
  }

  Widget _buildCarnetsSection() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: const Text('📋 Carnets de Salud'),
        subtitle: Text('${_pendingRecords.length} pendiente(s)'),
        children: [
          ..._pendingRecords.take(10).map((record) => ListTile(
                dense: true,
                leading:
                    const Icon(Icons.pending, size: 16, color: Colors.orange),
                title: Text(
                  record.nombreCompleto,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500),
                ),
                subtitle: Text('Matrícula: ${record.matricula}'),
                trailing: IconButton(
                  icon: const Icon(Icons.bug_report, size: 20),
                  tooltip: 'Diagnosticar',
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SyncDiagnosticScreen(
                          db: widget.db,
                          carnet: record,
                        ),
                      ),
                    );

                    // Si el diagnóstico tuvo éxito, recargar y mostrar confirmación
                    if (result == true && mounted) {
                      await _loadPendingData();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ Carnet sincronizado exitosamente'),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
              )),
          if (_pendingRecords.length > 10)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                '... y ${_pendingRecords.length - 10} más',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, int count, List<String> items) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text(title),
        subtitle: Text('$count pendiente(s)'),
        children: [
          ...items.take(5).map((item) => ListTile(
                dense: true,
                leading: const Icon(Icons.pending, size: 16),
                title: Text(
                  item,
                  style: const TextStyle(fontSize: 14),
                ),
              )),
          if (items.length > 5)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                '... y ${items.length - 5} más',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
