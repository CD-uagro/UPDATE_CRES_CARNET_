import 'db.dart' as DB;
import 'api_service.dart';
import '../utils/clinical_datetime.dart';

/// Sube todas las notas locales a FastAPI.
/// Usa un ID idempotente 'nota_local_<rowId>' para evitar duplicados.
Future<void> syncToCloudant(DB.AppDatabase db) async {
  final notes = await (db.select(db.notes)).get();

  for (final n in notes) {
    final clientId = n.clientId?.trim() ?? '';
    final String id = clientId.isNotEmpty ? clientId : 'nota_local_${n.id}';
    try {
      final ok = await ApiService.pushSingleNote(
        matricula: n.matricula,
        departamento: n.departamento,
        cuerpo: n.cuerpo,
        tratante: n.tratante ?? '',
        idOverride: id,
        createdAt: ClinicalDateTime.utcForStoredClinicalNote(
          n.createdAt,
          clientId: n.clientId,
        ),
      );
      if (ok) {
        // ignore: avoid_print
        print('[SYNC] OK -> $id (${n.matricula} / ${n.departamento})');
      } else {
        // ignore: avoid_print
        print('[SYNC] FAIL (no OK) -> $id');
      }
    } catch (e) {
      // ignore: avoid_print
      print('[SYNC] FAIL -> $id : $e');
    }
  }
}
