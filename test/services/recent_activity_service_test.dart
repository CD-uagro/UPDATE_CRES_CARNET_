import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cres_carnets_ibmcloud/data/auth_service.dart';
import 'package:cres_carnets_ibmcloud/data/recent_activity_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AuthUser user;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    user = AuthUser(
      id: 'user-1',
      username: 'medico',
      email: 'medico@sasu.test',
      nombreCompleto: 'Medico SASU',
      rol: 'medico',
      campus: 'chilpancingo',
      departamento: 'Consultorio medico',
      activo: true,
    );
  });

  test('quita un paciente reciente sin tocar notas recientes', () async {
    await RecentActivityService.recordPatientActivity(
      user: user,
      matricula: 'A001',
      nombreCompleto: 'Paciente Uno',
      areaResponsable: 'Consultorio medico',
      accion: 'attended',
    );
    await RecentActivityService.recordNoteActivity(
      user: user,
      noteId: 'nota:1',
      matricula: 'A001',
      nombreEstudiante: 'Paciente Uno',
      departamento: 'Consultorio medico',
      diagnosticoResumen: 'PRUEBA 6',
      synced: true,
    );

    await RecentActivityService.removePatientActivity(
      user: user,
      matricula: 'A001',
    );

    expect(await RecentActivityService.getRecentPatients(user), isEmpty);
    expect(await RecentActivityService.getRecentNotes(user), hasLength(1));
  });

  test('quita una nota reciente sin tocar pacientes recientes', () async {
    await RecentActivityService.recordPatientActivity(
      user: user,
      matricula: 'A001',
      nombreCompleto: 'Paciente Uno',
      areaResponsable: 'Consultorio medico',
      accion: 'attended',
    );
    await RecentActivityService.recordNoteActivity(
      user: user,
      noteId: 'nota:1',
      matricula: 'A001',
      nombreEstudiante: 'Paciente Uno',
      departamento: 'Consultorio medico',
      diagnosticoResumen: 'PRUEBA 6',
      synced: true,
    );

    await RecentActivityService.removeNoteActivity(
      user: user,
      noteId: 'nota:1',
    );

    expect(await RecentActivityService.getRecentPatients(user), hasLength(1));
    expect(await RecentActivityService.getRecentNotes(user), isEmpty);
  });

  test('limpia toda la actividad reciente y conserva el limite visible',
      () async {
    for (var i = 0; i < 7; i++) {
      await RecentActivityService.recordPatientActivity(
        user: user,
        matricula: 'A00$i',
        nombreCompleto: 'Paciente $i',
        areaResponsable: 'Consultorio medico',
        accion: 'attended',
      );
      await RecentActivityService.recordNoteActivity(
        user: user,
        noteId: 'nota:$i',
        matricula: 'A00$i',
        nombreEstudiante: 'Paciente $i',
        departamento: 'Consultorio medico',
        diagnosticoResumen: 'Nota $i',
        synced: i.isEven,
      );
    }

    expect(await RecentActivityService.getRecentPatients(user), hasLength(5));
    expect(await RecentActivityService.getRecentNotes(user), hasLength(5));

    await RecentActivityService.clearRecentActivity(user);

    expect(await RecentActivityService.getRecentPatients(user), isEmpty);
    expect(await RecentActivityService.getRecentNotes(user), isEmpty);
  });
}
