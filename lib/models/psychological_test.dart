/// Modelos para Tests Psicológicos
/// Sistema de evaluación psicológica integrado con CRES

enum TestType {
  hamilton, // Escala de Depresión de Hamilton
  bai, // Inventario de Ansiedad de Beck
  narcisismo, // Cuestionario de Rasgos Narcisistas
  plutchik, // Escala de Riesgo Suicida de Plutchik
  mbi, // Maslach Burnout Inventory
}

enum ResponseType {
  likert, // Escala Likert (0-4, 1-5, etc.)
  binary, // Sí/No, Verdadero/Falso
  multiple, // Selección múltiple
  numeric, // Valor numérico
}

/// Representa una pregunta individual del test
class TestQuestion {
  final String id;
  final String text;
  final ResponseType responseType;
  final List<String> options;
  final int? maxValue;
  final int? minValue;
  final Map<String, int>? scoreMapping; // Para mapear respuestas a puntuaciones

  TestQuestion({
    required this.id,
    required this.text,
    required this.responseType,
    required this.options,
    this.maxValue,
    this.minValue,
    this.scoreMapping,
  });
}

/// Respuesta del paciente a una pregunta
class TestResponse {
  final String questionId;
  final dynamic response; // String, int, bool según el tipo
  final int score; // Puntuación calculada
  final DateTime timestamp;

  TestResponse({
    required this.questionId,
    required this.response,
    required this.score,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'questionId': questionId,
        'response': response,
        'score': score,
        'timestamp': timestamp.toIso8601String(),
      };

  factory TestResponse.fromJson(Map<String, dynamic> json) => TestResponse(
        questionId: json['questionId'],
        response: json['response'],
        score: json['score'],
        timestamp: DateTime.parse(json['timestamp']),
      );
}

/// Resultado completo del test
class TestResult {
  final String id;
  final TestType testType;
  final String matricula;
  final String nombrePaciente;
  final String psicologo;
  final DateTime fechaAplicacion;
  final List<TestResponse> responses;
  final int puntuacionTotal;
  final String interpretacion;
  final String recomendaciones;
  final bool alertaCritica;
  final Map<String, dynamic>? datosAdicionales;

  TestResult({
    required this.id,
    required this.testType,
    required this.matricula,
    required this.nombrePaciente,
    required this.psicologo,
    required this.fechaAplicacion,
    required this.responses,
    required this.puntuacionTotal,
    required this.interpretacion,
    required this.recomendaciones,
    this.alertaCritica = false,
    this.datosAdicionales,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'testType': testType.toString(),
        'matricula': matricula,
        'nombrePaciente': nombrePaciente,
        'psicologo': psicologo,
        'fechaAplicacion': fechaAplicacion.toIso8601String(),
        'responses': responses.map((r) => r.toJson()).toList(),
        'puntuacionTotal': puntuacionTotal,
        'interpretacion': interpretacion,
        'recomendaciones': recomendaciones,
        'alertaCritica': alertaCritica,
        'datosAdicionales': datosAdicionales,
      };

  factory TestResult.fromJson(Map<String, dynamic> json) => TestResult(
        id: json['id'],
        testType:
            TestType.values.firstWhere((t) => t.toString() == json['testType']),
        matricula: json['matricula'],
        nombrePaciente: json['nombrePaciente'],
        psicologo: json['psicologo'],
        fechaAplicacion: DateTime.parse(json['fechaAplicacion']),
        responses: (json['responses'] as List)
            .map((r) => TestResponse.fromJson(r))
            .toList(),
        puntuacionTotal: json['puntuacionTotal'],
        interpretacion: json['interpretacion'],
        recomendaciones: json['recomendaciones'],
        alertaCritica: json['alertaCritica'] ?? false,
        datosAdicionales: json['datosAdicionales'],
      );
}

/// Test psicológico base
abstract class PsychologicalTest {
  TestType get testType;
  String get name;
  String get description;
  String get instructions;
  List<TestQuestion> get questions;
  Duration get estimatedDuration;

  /// Calcula la puntuación del test
  TestResult calculateResult({
    required String matricula,
    required String nombrePaciente,
    required String psicologo,
    required List<TestResponse> responses,
  });

  /// Interpreta la puntuación según criterios clínicos
  String interpretScore(int score);

  /// Genera recomendaciones basadas en el resultado
  String generateRecommendations(int score);

  /// Determina si hay alerta crítica
  bool hasCriticalAlert(int score);
}
