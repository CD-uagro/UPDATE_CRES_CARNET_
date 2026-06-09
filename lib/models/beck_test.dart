import '../models/psychological_test.dart';
import 'package:uuid/uuid.dart';

/// Inventario de Ansiedad de Beck (BAI)
/// Test estandarizado para medir la severidad de la ansiedad
class BeckAnxietyInventory extends PsychologicalTest {
  static const _uuid = Uuid();

  @override
  TestType get testType => TestType.bai;

  @override
  String get name => "Inventario de Ansiedad de Beck (BAI)";

  @override
  String get description =>
      "Cuestionario de autoevaluación que mide la intensidad de síntomas de ansiedad. "
      "Consta de 21 preguntas sobre síntomas comunes de ansiedad.";

  @override
  String get instructions =>
      "A continuación encontrará una lista de síntomas comunes de la ansiedad. "
      "Lea cada uno de los ítems atentamente e indique cuánto le ha afectado "
      "en la ÚLTIMA SEMANA INCLUYENDO HOY.";

  @override
  Duration get estimatedDuration => const Duration(minutes: 8);

  @override
  List<TestQuestion> get questions => [
        TestQuestion(
          id: "bai1",
          text: "Torpe o entumecido",
          responseType: ResponseType.likert,
          options: [
            "0 - En absoluto",
            "1 - Levemente (no me molesta mucho)",
            "2 - Moderadamente (fue muy desagradable pero pude soportarlo)",
            "3 - Gravemente (casi no pude soportarlo)"
          ],
          scoreMapping: {"0": 0, "1": 1, "2": 2, "3": 3},
        ),
        TestQuestion(
          id: "bai2",
          text: "Acalorado",
          responseType: ResponseType.likert,
          options: [
            "0 - En absoluto",
            "1 - Levemente (no me molesta mucho)",
            "2 - Moderadamente (fue muy desagradable pero pude soportarlo)",
            "3 - Gravemente (casi no pude soportarlo)"
          ],
          scoreMapping: {"0": 0, "1": 1, "2": 2, "3": 3},
        ),
        TestQuestion(
          id: "bai3",
          text: "Con temblor en las piernas",
          responseType: ResponseType.likert,
          options: [
            "0 - En absoluto",
            "1 - Levemente (no me molesta mucho)",
            "2 - Moderadamente (fue muy desagradable pero pude soportarlo)",
            "3 - Gravemente (casi no pude soportarlo)"
          ],
          scoreMapping: {"0": 0, "1": 1, "2": 2, "3": 3},
        ),
        TestQuestion(
          id: "bai4",
          text: "Incapaz de relajarse",
          responseType: ResponseType.likert,
          options: [
            "0 - En absoluto",
            "1 - Levemente (no me molesta mucho)",
            "2 - Moderadamente (fue muy desagradable pero pude soportarlo)",
            "3 - Gravemente (casi no pude soportarlo)"
          ],
          scoreMapping: {"0": 0, "1": 1, "2": 2, "3": 3},
        ),
        TestQuestion(
          id: "bai5",
          text: "Con temor a que ocurra lo peor",
          responseType: ResponseType.likert,
          options: [
            "0 - En absoluto",
            "1 - Levemente (no me molesta mucho)",
            "2 - Moderadamente (fue muy desagradable pero pude soportarlo)",
            "3 - Gravemente (casi no pude soportarlo)"
          ],
          scoreMapping: {"0": 0, "1": 1, "2": 2, "3": 3},
        ),
        TestQuestion(
          id: "bai6",
          text: "Mareado, o que se le va la cabeza",
          responseType: ResponseType.likert,
          options: [
            "0 - En absoluto",
            "1 - Levemente (no me molesta mucho)",
            "2 - Moderadamente (fue muy desagradable pero pude soportarlo)",
            "3 - Gravemente (casi no pude soportarlo)"
          ],
          scoreMapping: {"0": 0, "1": 1, "2": 2, "3": 3},
        ),
        TestQuestion(
          id: "bai7",
          text: "Con latidos del corazón fuertes y acelerados",
          responseType: ResponseType.likert,
          options: [
            "0 - En absoluto",
            "1 - Levemente (no me molesta mucho)",
            "2 - Moderadamente (fue muy desagradable pero pude soportarlo)",
            "3 - Gravemente (casi no pude soportarlo)"
          ],
          scoreMapping: {"0": 0, "1": 1, "2": 2, "3": 3},
        ),
        TestQuestion(
          id: "bai8",
          text: "Inestable",
          responseType: ResponseType.likert,
          options: [
            "0 - En absoluto",
            "1 - Levemente (no me molesta mucho)",
            "2 - Moderadamente (fue muy desagradable pero pude soportarlo)",
            "3 - Gravemente (casi no pude soportarlo)"
          ],
          scoreMapping: {"0": 0, "1": 1, "2": 2, "3": 3},
        ),
        TestQuestion(
          id: "bai9",
          text: "Atemorizado o asustado",
          responseType: ResponseType.likert,
          options: [
            "0 - En absoluto",
            "1 - Levemente (no me molesta mucho)",
            "2 - Moderadamente (fue muy desagradable pero pude soportarlo)",
            "3 - Gravemente (casi no pude soportarlo)"
          ],
          scoreMapping: {"0": 0, "1": 1, "2": 2, "3": 3},
        ),
        TestQuestion(
          id: "bai10",
          text: "Nervioso",
          responseType: ResponseType.likert,
          options: [
            "0 - En absoluto",
            "1 - Levemente (no me molesta mucho)",
            "2 - Moderadamente (fue muy desagradable pero pude soportarlo)",
            "3 - Gravemente (casi no pude soportarlo)"
          ],
          scoreMapping: {"0": 0, "1": 1, "2": 2, "3": 3},
        ),
        TestQuestion(
          id: "bai11",
          text: "Con sensación de bloqueo",
          responseType: ResponseType.likert,
          options: [
            "0 - En absoluto",
            "1 - Levemente (no me molesta mucho)",
            "2 - Moderadamente (fue muy desagradable pero pude soportarlo)",
            "3 - Gravemente (casi no pude soportarlo)"
          ],
          scoreMapping: {"0": 0, "1": 1, "2": 2, "3": 3},
        ),
        TestQuestion(
          id: "bai12",
          text: "Con temblores en las manos",
          responseType: ResponseType.likert,
          options: [
            "0 - En absoluto",
            "1 - Levemente (no me molesta mucho)",
            "2 - Moderadamente (fue muy desagradable pero pude soportarlo)",
            "3 - Gravemente (casi no pude soportarlo)"
          ],
          scoreMapping: {"0": 0, "1": 1, "2": 2, "3": 3},
        ),
        TestQuestion(
          id: "bai13",
          text: "Inquieto, inseguro",
          responseType: ResponseType.likert,
          options: [
            "0 - En absoluto",
            "1 - Levemente (no me molesta mucho)",
            "2 - Moderadamente (fue muy desagradable pero pude soportarlo)",
            "3 - Gravemente (casi no pude soportarlo)"
          ],
          scoreMapping: {"0": 0, "1": 1, "2": 2, "3": 3},
        ),
        TestQuestion(
          id: "bai14",
          text: "Con miedo a perder el control",
          responseType: ResponseType.likert,
          options: [
            "0 - En absoluto",
            "1 - Levemente (no me molesta mucho)",
            "2 - Moderadamente (fue muy desagradable pero pude soportarlo)",
            "3 - Gravemente (casi no pude soportarlo)"
          ],
          scoreMapping: {"0": 0, "1": 1, "2": 2, "3": 3},
        ),
        TestQuestion(
          id: "bai15",
          text: "Con sensación de ahogo",
          responseType: ResponseType.likert,
          options: [
            "0 - En absoluto",
            "1 - Levemente (no me molesta mucho)",
            "2 - Moderadamente (fue muy desagradable pero pude soportarlo)",
            "3 - Gravemente (casi no pude soportarlo)"
          ],
          scoreMapping: {"0": 0, "1": 1, "2": 2, "3": 3},
        ),
        TestQuestion(
          id: "bai16",
          text: "Con temor a morir",
          responseType: ResponseType.likert,
          options: [
            "0 - En absoluto",
            "1 - Levemente (no me molesta mucho)",
            "2 - Moderadamente (fue muy desagradable pero pude soportarlo)",
            "3 - Gravemente (casi no pude soportarlo)"
          ],
          scoreMapping: {"0": 0, "1": 1, "2": 2, "3": 3},
        ),
        TestQuestion(
          id: "bai17",
          text: "Con miedo",
          responseType: ResponseType.likert,
          options: [
            "0 - En absoluto",
            "1 - Levemente (no me molesta mucho)",
            "2 - Moderadamente (fue muy desagradable pero pude soportarlo)",
            "3 - Gravemente (casi no pude soportarlo)"
          ],
          scoreMapping: {"0": 0, "1": 1, "2": 2, "3": 3},
        ),
        TestQuestion(
          id: "bai18",
          text: "Con problemas digestivos",
          responseType: ResponseType.likert,
          options: [
            "0 - En absoluto",
            "1 - Levemente (no me molesta mucho)",
            "2 - Moderadamente (fue muy desagradable pero pude soportarlo)",
            "3 - Gravemente (casi no pude soportarlo)"
          ],
          scoreMapping: {"0": 0, "1": 1, "2": 2, "3": 3},
        ),
        TestQuestion(
          id: "bai19",
          text: "Con desvanecimientos",
          responseType: ResponseType.likert,
          options: [
            "0 - En absoluto",
            "1 - Levemente (no me molesta mucho)",
            "2 - Moderadamente (fue muy desagradable pero pude soportarlo)",
            "3 - Gravemente (casi no pude soportarlo)"
          ],
          scoreMapping: {"0": 0, "1": 1, "2": 2, "3": 3},
        ),
        TestQuestion(
          id: "bai20",
          text: "Con rubor facial",
          responseType: ResponseType.likert,
          options: [
            "0 - En absoluto",
            "1 - Levemente (no me molesta mucho)",
            "2 - Moderadamente (fue muy desagradable pero pude soportarlo)",
            "3 - Gravemente (casi no pude soportarlo)"
          ],
          scoreMapping: {"0": 0, "1": 1, "2": 2, "3": 3},
        ),
        TestQuestion(
          id: "bai21",
          text: "Con sudores, fríos o calientes",
          responseType: ResponseType.likert,
          options: [
            "0 - En absoluto",
            "1 - Levemente (no me molesta mucho)",
            "2 - Moderadamente (fue muy desagradable pero pude soportarlo)",
            "3 - Gravemente (casi no pude soportarlo)"
          ],
          scoreMapping: {"0": 0, "1": 1, "2": 2, "3": 3},
        ),
      ];

  @override
  TestResult calculateResult({
    required List<TestResponse> responses,
    required String matricula,
    required String nombrePaciente,
    required String psicologo,
  }) {
    int totalScore = 0;
    for (var response in responses) {
      totalScore += response.score;
    }

    // Clasificación según puntuación total (0-63)
    String severity;
    String interpretation;
    bool alertaCritica = false;

    if (totalScore <= 7) {
      severity = "Ansiedad Mínima";
      interpretation = "El nivel de ansiedad es mínimo o ausente. "
          "No se detectan síntomas significativos de ansiedad.";
    } else if (totalScore <= 15) {
      severity = "Ansiedad Leve";
      interpretation = "Se detectan síntomas leves de ansiedad. "
          "Los síntomas pueden ser molestos pero generalmente no interfieren "
          "significativamente con el funcionamiento diario.";
    } else if (totalScore <= 25) {
      severity = "Ansiedad Moderada";
      interpretation = "Presencia de síntomas moderados de ansiedad. "
          "Los síntomas pueden causar malestar considerable y comenzar a "
          "interferir con las actividades cotidianas. Se recomienda atención profesional.";
    } else if (totalScore <= 63) {
      severity = "Ansiedad Severa";
      interpretation =
          "Síntomas severos de ansiedad que probablemente interfieren "
          "de manera significativa con el funcionamiento diario. "
          "Se requiere intervención profesional inmediata.";
      alertaCritica = true;
    } else {
      severity = "Error de cálculo";
      interpretation = "Puntuación fuera de rango";
    }

    final recommendations = _generateRecommendations(totalScore);

    return TestResult(
      id: _uuid.v4(),
      testType: testType,
      matricula: matricula,
      nombrePaciente: nombrePaciente,
      psicologo: psicologo,
      fechaAplicacion: DateTime.now(),
      responses: responses,
      puntuacionTotal: totalScore,
      interpretacion: "$severity\n\n$interpretation",
      recomendaciones: recommendations.join('\n• '),
      alertaCritica: alertaCritica,
    );
  }

  @override
  String interpretScore(int score) {
    if (score <= 7) return "Ansiedad Mínima";
    if (score <= 15) return "Ansiedad Leve";
    if (score <= 25) return "Ansiedad Moderada";
    return "Ansiedad Severa";
  }

  @override
  String generateRecommendations(int score) {
    return _generateRecommendations(score).join('\n• ');
  }

  @override
  bool hasCriticalAlert(int score) {
    return score > 25;
  }

  List<String> _generateRecommendations(int score) {
    List<String> recommendations = [];

    if (score <= 7) {
      recommendations.addAll([
        "Mantener hábitos saludables de vida",
        "Continuar con actividades recreativas y sociales",
        "Mantener rutina de sueño adecuada",
      ]);
    } else if (score <= 15) {
      recommendations.addAll([
        "Técnicas de relajación y respiración",
        "Ejercicio físico regular",
        "Higiene del sueño",
        "Considerar consulta con profesional si los síntomas persisten",
      ]);
    } else if (score <= 25) {
      recommendations.addAll([
        "Evaluación psicológica más detallada",
        "Terapia cognitivo-conductual",
        "Técnicas de manejo de estrés y ansiedad",
        "Evaluación médica para descartar causas orgánicas",
        "Establecer red de apoyo social",
      ]);
    } else {
      recommendations.addAll([
        "ATENCIÓN PSICOLÓGICA URGENTE",
        "Evaluación psiquiátrica completa",
        "Considerar tratamiento farmacológico",
        "Psicoterapia intensiva (TCC, terapia de exposición)",
        "Seguimiento cercano y frecuente",
        "Evaluar necesidad de intervención en crisis",
        "Informar a familiares o red de apoyo",
      ]);
    }

    return recommendations;
  }

  Map<String, dynamic> toJson() {
    return {
      'testType': testType.toString(),
      'name': name,
      'description': description,
      'version': '1.0',
    };
  }
}
