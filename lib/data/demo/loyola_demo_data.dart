import 'package:drift/drift.dart';

import '../auth_service.dart';
import '../db.dart';

class LoyolaDemoData {
  LoyolaDemoData._();

  static const campus = 'loyola-demo-campus';

  static AuthUser user() => AuthUser(
        id: 'loyola-demo-user',
        username: 'demo.loyola',
        email: 'demo.loyola@example.invalid',
        nombreCompleto: 'Usuario Demo LOYOLA',
        rol: 'admin',
        campus: campus,
        departamento: 'Servicios de Salud Escolar',
        activo: true,
        fechaCreacion: '2026-07-14T00:00:00Z',
        ultimoAcceso: DateTime.now().toUtc().toIso8601String(),
      );

  static const students = [
    {
      'matricula': 'LOY-DEMO-001',
      'nombreCompleto': 'Estudiante Demo Uno',
      'correo': 'estudiante.uno@example.invalid',
      'edad': 16,
      'sexo': 'Femenino',
      'programa': 'Bachillerato',
      'escuelaUnidadAcademica': 'LOYOLA',
      'grupo': '2A',
      'alergias': 'Simulada: polen',
      'tipoSangre': 'O+',
      'enfermedadCronica': 'Ninguna registrada',
    },
    {
      'matricula': 'LOY-DEMO-002',
      'nombreCompleto': 'Estudiante Demo Dos',
      'correo': 'estudiante.dos@example.invalid',
      'edad': 17,
      'sexo': 'Masculino',
      'programa': 'Bachillerato',
      'escuelaUnidadAcademica': 'LOYOLA',
      'grupo': '3B',
      'alergias': 'Ninguna registrada',
      'tipoSangre': 'A+',
      'enfermedadCronica': 'Simulada: asma controlada',
    },
  ];

  static const appointments = [
    {
      'id': 'LOY-CITA-001',
      'matricula': 'LOY-DEMO-001',
      'motivo': 'Valoracion preventiva simulada',
      'departamento': 'Enfermeria',
      'estado': 'programada',
    },
    {
      'id': 'LOY-CITA-002',
      'matricula': 'LOY-DEMO-002',
      'motivo': 'Seguimiento nutricional simulado',
      'departamento': 'Nutricion',
      'estado': 'solicitada',
    },
  ];

  static Future<void> seedLocalDatabase(AppDatabase db) async {
    for (final student in students) {
      final matricula = student['matricula']!.toString();
      final existing = await db.getRecordByMatricula(matricula);
      if (existing != null) continue;

      await db.insertRecord(
        HealthRecordsCompanion(
          matricula: Value(matricula),
          nombreCompleto: Value(student['nombreCompleto']!.toString()),
          correo: Value(student['correo']!.toString()),
          edad: Value(student['edad'] as int),
          sexo: Value(student['sexo']!.toString()),
          categoria: const Value('Demo'),
          programa: Value(student['programa']!.toString()),
          escuelaUnidadAcademica:
              Value(student['escuelaUnidadAcademica']!.toString()),
          grupo: Value(student['grupo']!.toString()),
          alergias: Value(student['alergias']!.toString()),
          tipoSangre: Value(student['tipoSangre']!.toString()),
          enfermedadCronica: Value(student['enfermedadCronica']!.toString()),
          unidadMedica: const Value('Servicio medico escolar demo'),
          emergenciaTelefono: const Value('0000000000'),
          emergenciaContacto: const Value('Contacto ficticio'),
          expedienteNotas: const Value(
            'Expediente ficticio creado para demostracion LOYOLA. No usar para atencion clinica real.',
          ),
          synced: const Value(true),
        ),
      );

      await db.insertNote(
        NotesCompanion(
          clientId: Value('loyola_demo_note_$matricula'),
          matricula: Value(matricula),
          departamento: const Value('Servicios de Salud Escolar'),
          tratante: const Value('Profesional Demo'),
          cuerpo: const Value(
            'Nota clinica ficticia. Registro generado para demostracion segura.',
          ),
          createdAt: Value(DateTime.now().toUtc()),
          updatedAt: Value(DateTime.now().toUtc()),
          synced: const Value(true),
        ),
      );
    }
  }
}
