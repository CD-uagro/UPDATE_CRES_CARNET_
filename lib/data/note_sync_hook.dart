import 'dart:developer' as dev;
import 'api_service.dart';

/// Sube una sola nota a FastAPI de inmediato (best-effort).
/// Crea un id estilo Couch: nota:<matricula>:<ISO8601 UTC>
Future<void> syncNoteToCloud({
  required String matricula,
  required String departamento,
  required String cuerpo,
  required String tratante,
  String? idOverride,
  DateTime? createdAt,
}) async {
  dev.log(
    '[syncNoteToCloud] push -> {matricula:$matricula, dep:$departamento, len:${cuerpo.length}, tratante:$tratante}',
    name: 'cres.carnets',
  );

  await ApiService.pushSingleNote(
    matricula: matricula,
    departamento: departamento,
    cuerpo: cuerpo,
    tratante: tratante,
    idOverride: idOverride,
    createdAt: createdAt,
  );

  dev.log('[syncNoteToCloud] OK (subida completada)', name: 'cres.carnets');
}
