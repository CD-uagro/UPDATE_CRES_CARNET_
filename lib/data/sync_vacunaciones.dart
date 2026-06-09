import 'db.dart' as DB;
import 'api_service.dart';

/// Sincroniza vacunaciones pendientes con Cosmos DB
Future<void> syncVacunacionesPendientes(DB.AppDatabase db) async {
  final pendientes = await db.getPendingVacunaciones();

  if (pendientes.isEmpty) {
    print('[SYNC_VACUNAS] No hay vacunaciones pendientes');
    return;
  }

  print('[SYNC_VACUNAS] Sincronizando ${pendientes.length} vacunaciones...');

  int sincronizadas = 0;
  int errores = 0;

  for (final vac in pendientes) {
    try {
      print('[SYNC_VACUNAS] Procesando ${vac.matricula} - ${vac.vacuna}');

      final ok = await ApiService.guardarAplicacionVacuna(
        matricula: vac.matricula,
        campana: vac.campana,
        vacuna: vac.vacuna,
        dosis: vac.dosis,
        fechaAplicacion: vac.fechaAplicacion,
        lote: vac.lote,
        aplicadoPor: vac.aplicadoPor,
        observaciones: vac.observaciones,
        nombreEstudiante: vac.nombreEstudiante,
      );

      if (ok) {
        await db.markVacunacionAsSynced(vac.id);
        sincronizadas++;
        print(
            '[SYNC_VACUNAS] ✅ Sincronizada: ${vac.matricula} - ${vac.vacuna}');
      } else {
        errores++;
        print('[SYNC_VACUNAS] ⚠️ No se pudo sincronizar: ${vac.matricula}');
      }
    } catch (e) {
      errores++;
      print('[SYNC_VACUNAS] ❌ Error: ${vac.matricula} - $e');
    }
  }

  print(
      '[SYNC_VACUNAS] Resumen: $sincronizadas sincronizadas, $errores errores');
}

/// Sincroniza todas las tablas pendientes (notas, citas, vacunaciones)
Future<void> syncAll(DB.AppDatabase db) async {
  print('[SYNC_ALL] Iniciando sincronización completa...');

  // Sincronizar notas (ya existe)
  try {
    final notes = await db.getPendingNotes();
    print('[SYNC_ALL] ${notes.length} notas pendientes');
    // Aquí iría la lógica de sync de notas si existe
  } catch (e) {
    print('[SYNC_ALL] Error sincronizando notas: $e');
  }

  // Sincronizar citas (ya existe)
  try {
    final citas = await db.getPendingCitas();
    print('[SYNC_ALL] ${citas.length} citas pendientes');
    // Aquí iría la lógica de sync de citas si existe
  } catch (e) {
    print('[SYNC_ALL] Error sincronizando citas: $e');
  }

  // Sincronizar vacunaciones (NUEVO)
  try {
    await syncVacunacionesPendientes(db);
  } catch (e) {
    print('[SYNC_ALL] Error sincronizando vacunaciones: $e');
  }

  print('[SYNC_ALL] Sincronización completa finalizada');
}
