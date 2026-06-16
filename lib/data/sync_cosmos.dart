import 'db.dart' as DB;
import 'cloudant_query.dart';
import '../utils/clinical_datetime.dart';

/// Sube todas las notas locales a Cosmos en contenedor carnets_id (PK /id).
/// Usa ID idempotente 'nota_local_<rowId>' para evitar duplicados.
Future<void> syncToCosmos(DB.AppDatabase db) async {
  final api = CloudantQueries();
  final notes = await (db.select(db.notes)).get();

  for (final n in notes) {
    final clientId = n.clientId?.trim() ?? '';
    final String id = clientId.isNotEmpty ? clientId : 'nota_local_${n.id}';
    try {
      await api.pushSingleNote(
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
      // ignore: avoid_print
      print('[SYNC] OK -> $id (${n.matricula} / ${n.departamento})');
    } catch (e) {
      // ignore: avoid_print
      print('[SYNC] FAIL -> $id : $e');
    }
  }
}
