import 'api_service.dart';

/// Clase de compatibilidad para mantener nombres históricos en el código.
/// Ahora toda la lógica apunta a FastAPI usando ApiService.
/// Puedes eliminar este archivo si cambias todas las referencias por ApiService directamente.
class CloudantQueries {
  /// Busca el carnet por ID (normalmente el QR).
  Future<Map<String, dynamic>?> getExpedienteById(String id) {
    return ApiService.getExpedienteById(id);
  }

  /// Busca el carnet por MATRÍCULA.
  Future<Map<String, dynamic>?> getExpedienteByMatricula(String matricula) {
    return ApiService.getExpedienteByMatricula(matricula);
  }

  /// Trae todas las notas por matrícula.
  Future<List<Map<String, dynamic>>> getNotasForMatricula(String matricula) {
    return ApiService.getNotasForMatricula(matricula);
  }

  /// Inserta 1 nota en la nube.
  Future<void> pushSingleNote({
    required String matricula,
    required String departamento,
    required String cuerpo,
    required String tratante,
    String? idOverride,
    DateTime? createdAt,
  }) async {
    await ApiService.pushSingleNote(
      matricula: matricula,
      departamento: departamento,
      cuerpo: cuerpo,
      tratante: tratante,
      idOverride: idOverride,
      createdAt: createdAt,
    );
  }
}
