import '../models/psychological_test.dart';
import 'package:uuid/uuid.dart';

/// DASS-21 (Depression Anxiety Stress Scales)
/// Escala de evaluación de Depresión, Ansiedad y Estrés en 21 ítems
class DASS21Test extends PsychologicalTest {
  static const _uuid = Uuid();

  @override
  TestType get testType => TestType
      .bai; // Usamos bai temporalmente, necesitarías agregar dass21 al enum

  @override
  String get name => "DASS-21 (Depression, Anxiety and Stress Scale)";

  @override
  String get description =>
      "Escala de autoevaluación que mide tres dimensiones: Depresión, Ansiedad y Estrés. "
      "Consta de 21 ítems divididos en 3 subescalas de 7 preguntas cada una.";

  @override
  String get instructions =>
      "Por favor lea cada afirmación y marque el número (0, 1, 2 o 3) que indica "
      "cuánto le ha ocurrido esto durante la ÚLTIMA SEMANA. "
      "No hay respuestas correctas o incorrectas.";

  @override
  Duration get estimatedDuration => const Duration(minutes: 10);

  @override
  List<TestQuestion> get questions => [
        // DEPRESIÓN (ítems 3, 5, 10, 13, 16, 17, 21)
        TestQuestion(
          id: "dass3",
          text: "Me costó mucho relajarme",
          responseType: ResponseType.likert,
          options: [
            "0 - No me aplicó",
            "1 - Me aplicó un poco, o durante parte del tiempo",
            "2 - Me aplicó bastante, o durante una buena parte del tiempo",
            "3 - Me aplicó mucho, o la mayor parte del tiempo"
          ],
          scoreMapping: {"0": 0, "1": 1, "2": 2, "3": 3},
        ),

        TestQuestion(
          id: "dass5",
          text: "Me costó tomar iniciativa para hacer cosas",
          responseType: ResponseType.likert,
          options: [
            "0 - No me aplicó",
            "1 - Me aplicó un poco, o durante parte del tiempo",
            "2 - Me aplicó bastante, o durante una buena parte del tiempo",
            "3 - Me aplicó mucho, o la mayor parte del tiempo"
          ],
          scoreMapping: {"0": 0, "1": 1, "2": 2, "3": 3},
        ),

        TestQuestion(
          id: "dass10",
          text: "Sentí que no tenía nada por lo que ilusionarme",
          responseType: ResponseType.likert,
          options: [
            "0 - No me aplicó",
            "1 - Me aplicó un poco, o durante parte del tiempo",
            "2 - Me aplicó bastante, o durante una buena parte del tiempo",
            "3 - Me aplicó mucho, o la mayor parte del tiempo"
          ],
          scoreMapping: {"0": 0, "1": 1, "2": 2, "3": 3},
        ),

        TestQuestion(
          id: "dass13",
          text: "Me sentí triste y deprimido",
          responseType: ResponseType.likert,
          options: [
            "0 - No me aplicó",
            "1 - Me aplicó un poco, o durante parte del tiempo",
            "2 - Me aplicó bastante, o durante una buena parte del tiempo",
            "3 - Me aplicó mucho, o la mayor parte del tiempo"
          ],
          scoreMapping: {"0": 0, "1": 1, "2": 2, "3": 3},
        ),

        TestQuestion(
          id: "dass16",
          text: "Sentí que no podía entusiasmarme por nada",
          responseType: ResponseType.likert,
          options: [
            "0 - No me aplicó",
            "1 - Me aplicó un poco, o durante parte del tiempo",
            "2 - Me aplicó bastante, o durante una buena parte del tiempo",
            "3 - Me aplicó mucho, o la mayor parte del tiempo"
          ],
          scoreMapping: {"0": 0, "1": 1, "2": 2, "3": 3},
        ),

        TestQuestion(
          id: "dass17",
          text: "Sentí que valía muy poco como persona",
          responseType: ResponseType.likert,
          options: [
            "0 - No me aplicó",
            "1 - Me aplicó un poco, o durante parte del tiempo",
            "2 - Me aplicó bastante, o durante una buena parte del tiempo",
            "3 - Me aplicó mucho, o la mayor parte del tiempo"
          ],
          scoreMapping: {"0": 0, "1": 1, "2": 2, "3": 3},
        ),

        TestQuestion(
          id: "dass21",
          text: "Sentí que la vida no tenía sentido",
          responseType: ResponseType.likert,
          options: [
            "0 - No me aplicó",
            "1 - Me aplicó un poco, o durante parte del tiempo",
            "2 - Me aplicó bastante, o durante una buena parte del tiempo",
            "3 - Me aplicó mucho, o la mayor parte del tiempo"
          ],
          scoreMapping: {"0": 0, "1": 1, "2": 2, "3": 3},
        ),

        // ANSIEDAD (ítems 2, 4, 7, 9, 15, 19, 20)
        TestQuestion(
          id: "dass2",
          text: "Sentí sequedad en mi boca",
          responseType: ResponseType.likert,
          options: [
            "0 - No me aplicó",
            "1 - Me aplicó un poco, o durante parte del tiempo",
            "2 - Me aplicó bastante, o durante una buena parte del tiempo",
            "3 - Me aplicó mucho, o la mayor parte del tiempo"
          ],
          scoreMapping: {"0": 0, "1": 1, "2": 2, "3": 3},
        ),

        TestQuestion(
          id: "dass4",
          text:
              "Experimenté dificultades para respirar (ej: respiración rápida, falta de aire sin haber hecho esfuerzo físico)",
          responseType: ResponseType.likert,
          options: [
            "0 - No me aplicó",
            "1 - Me aplicó un poco, o durante parte del tiempo",
            "2 - Me aplicó bastante, o durante una buena parte del tiempo",
            "3 - Me aplicó mucho, o la mayor parte del tiempo"
          ],
          scoreMapping: {"0": 0, "1": 1, "2": 2, "3": 3},
        ),

        TestQuestion(
          id: "dass7",
          text: "Experimenté temblor (ej: en las manos)",
          responseType: ResponseType.likert,
          options: [
            "0 - No me aplicó",
            "1 - Me aplicó un poco, o durante parte del tiempo",
            "2 - Me aplicó bastante, o durante una buena parte del tiempo",
            "3 - Me aplicó mucho, o la mayor parte del tiempo"
          ],
          scoreMapping: {"0": 0, "1": 1, "2": 2, "3": 3},
        ),

        TestQuestion(
          id: "dass9",
          text:
              "Estuve preocupado por situaciones en las que podría entrar en pánico y hacer el ridículo",
          responseType: ResponseType.likert,
          options: [
            "0 - No me aplicó",
            "1 - Me aplicó un poco, o durante parte del tiempo",
            "2 - Me aplicó bastante, o durante una buena parte del tiempo",
            "3 - Me aplicó mucho, o la mayor parte del tiempo"
          ],
          scoreMapping: {"0": 0, "1": 1, "2": 2, "3": 3},
        ),

        TestQuestion(
          id: "dass15",
          text: "Sentí que estaba al borde del pánico",
          responseType: ResponseType.likert,
          options: [
            "0 - No me aplicó",
            "1 - Me aplicó un poco, o durante parte del tiempo",
            "2 - Me aplicó bastante, o durante una buena parte del tiempo",
            "3 - Me aplicó mucho, o la mayor parte del tiempo"
          ],
          scoreMapping: {"0": 0, "1": 1, "2": 2, "3": 3},
        ),

        TestQuestion(
          id: "dass19",
          text:
              "Fui consciente de los latidos de mi corazón sin haber hecho esfuerzo físico (ej: aumento del ritmo cardíaco o sensación de saltos de latidos)",
          responseType: ResponseType.likert,
          options: [
            "0 - No me aplicó",
            "1 - Me aplicó un poco, o durante parte del tiempo",
            "2 - Me aplicó bastante, o durante una buena parte del tiempo",
            "3 - Me aplicó mucho, o la mayor parte del tiempo"
          ],
          scoreMapping: {"0": 0, "1": 1, "2": 2, "3": 3},
        ),

        TestQuestion(
          id: "dass20",
          text: "Sentí miedo sin ninguna razón",
          responseType: ResponseType.likert,
          options: [
            "0 - No me aplicó",
            "1 - Me aplicó un poco, o durante parte del tiempo",
            "2 - Me aplicó bastante, o durante una buena parte del tiempo",
            "3 - Me aplicó mucho, o la mayor parte del tiempo"
          ],
          scoreMapping: {"0": 0, "1": 1, "2": 2, "3": 3},
        ),

        // ESTRÉS (ítems 1, 6, 8, 11, 12, 14, 18)
        TestQuestion(
          id: "dass1",
          text: "Me molestaron cosas que usualmente no me molestan",
          responseType: ResponseType.likert,
          options: [
            "0 - No me aplicó",
            "1 - Me aplicó un poco, o durante parte del tiempo",
            "2 - Me aplicó bastante, o durante una buena parte del tiempo",
            "3 - Me aplicó mucho, o la mayor parte del tiempo"
          ],
          scoreMapping: {"0": 0, "1": 1, "2": 2, "3": 3},
        ),

        TestQuestion(
          id: "dass6",
          text: "Tendí a reaccionar de manera exagerada en ciertas situaciones",
          responseType: ResponseType.likert,
          options: [
            "0 - No me aplicó",
            "1 - Me aplicó un poco, o durante parte del tiempo",
            "2 - Me aplicó bastante, o durante una buena parte del tiempo",
            "3 - Me aplicó mucho, o la mayor parte del tiempo"
          ],
          scoreMapping: {"0": 0, "1": 1, "2": 2, "3": 3},
        ),

        TestQuestion(
          id: "dass8",
          text: "Sentí que estaba gastando mucha energía nerviosa",
          responseType: ResponseType.likert,
          options: [
            "0 - No me aplicó",
            "1 - Me aplicó un poco, o durante parte del tiempo",
            "2 - Me aplicó bastante, o durante una buena parte del tiempo",
            "3 - Me aplicó mucho, o la mayor parte del tiempo"
          ],
          scoreMapping: {"0": 0, "1": 1, "2": 2, "3": 3},
        ),

        TestQuestion(
          id: "dass11",
          text: "Me costó calmarme",
          responseType: ResponseType.likert,
          options: [
            "0 - No me aplicó",
            "1 - Me aplicó un poco, o durante parte del tiempo",
            "2 - Me aplicó bastante, o durante una buena parte del tiempo",
            "3 - Me aplicó mucho, o la mayor parte del tiempo"
          ],
          scoreMapping: {"0": 0, "1": 1, "2": 2, "3": 3},
        ),

        TestQuestion(
          id: "dass12",
          text: "Me resultó difícil relajarme",
          responseType: ResponseType.likert,
          options: [
            "0 - No me aplicó",
            "1 - Me aplicó un poco, o durante parte del tiempo",
            "2 - Me aplicó bastante, o durante una buena parte del tiempo",
            "3 - Me aplicó mucho, o la mayor parte del tiempo"
          ],
          scoreMapping: {"0": 0, "1": 1, "2": 2, "3": 3},
        ),

        TestQuestion(
          id: "dass14",
          text:
              "Fui intolerante ante cualquier cosa que me impidiera continuar con lo que estaba haciendo",
          responseType: ResponseType.likert,
          options: [
            "0 - No me aplicó",
            "1 - Me aplicó un poco, o durante parte del tiempo",
            "2 - Me aplicó bastante, o durante una buena parte del tiempo",
            "3 - Me aplicó mucho, o la mayor parte del tiempo"
          ],
          scoreMapping: {"0": 0, "1": 1, "2": 2, "3": 3},
        ),

        TestQuestion(
          id: "dass18",
          text: "Sentí que me era fácil agitarme",
          responseType: ResponseType.likert,
          options: [
            "0 - No me aplicó",
            "1 - Me aplicó un poco, o durante parte del tiempo",
            "2 - Me aplicó bastante, o durante una buena parte del tiempo",
            "3 - Me aplicó mucho, o la mayor parte del tiempo"
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
    // Calcular puntuaciones por subescala
    int depressionScore = 0;
    int anxietyScore = 0;
    int stressScore = 0;

    // Ítems de Depresión: 3, 5, 10, 13, 16, 17, 21
    final depressionItems = [
      'dass3',
      'dass5',
      'dass10',
      'dass13',
      'dass16',
      'dass17',
      'dass21'
    ];
    // Ítems de Ansiedad: 2, 4, 7, 9, 15, 19, 20
    final anxietyItems = [
      'dass2',
      'dass4',
      'dass7',
      'dass9',
      'dass15',
      'dass19',
      'dass20'
    ];
    // Ítems de Estrés: 1, 6, 8, 11, 12, 14, 18
    final stressItems = [
      'dass1',
      'dass6',
      'dass8',
      'dass11',
      'dass12',
      'dass14',
      'dass18'
    ];

    for (var response in responses) {
      if (depressionItems.contains(response.questionId)) {
        depressionScore += response.score;
      } else if (anxietyItems.contains(response.questionId)) {
        anxietyScore += response.score;
      } else if (stressItems.contains(response.questionId)) {
        stressScore += response.score;
      }
    }

    // Multiplicar por 2 para comparar con DASS-42
    depressionScore *= 2;
    anxietyScore *= 2;
    stressScore *= 2;

    int totalScore = depressionScore + anxietyScore + stressScore;

    // Clasificación según severidad
    final depSeverity = _classifyDepression(depressionScore);
    final anxSeverity = _classifyAnxiety(anxietyScore);
    final strSeverity = _classifyStress(stressScore);

    bool alertaCritica =
        depressionScore >= 28 || anxietyScore >= 20 || stressScore >= 34;

    String severity =
        "Depresión: $depSeverity | Ansiedad: $anxSeverity | Estrés: $strSeverity";

    String interpretation = "DASS-21 - Resultados por subescala:\n\n"
        "DEPRESIÓN ($depressionScore): $depSeverity\n"
        "${_getDepressionInterpretation(depressionScore)}\n\n"
        "ANSIEDAD ($anxietyScore): $anxSeverity\n"
        "${_getAnxietyInterpretation(anxietyScore)}\n\n"
        "ESTRÉS ($stressScore): $strSeverity\n"
        "${_getStressInterpretation(stressScore)}";

    final recommendations =
        _generateRecommendations(depressionScore, anxietyScore, stressScore);

    return TestResult(
      id: _uuid.v4(),
      testType: testType,
      matricula: matricula,
      nombrePaciente: nombrePaciente,
      psicologo: psicologo,
      fechaAplicacion: DateTime.now(),
      responses: responses,
      puntuacionTotal: totalScore,
      interpretacion: interpretation,
      recomendaciones: recommendations.join('\n• '),
      alertaCritica: alertaCritica,
      datosAdicionales: {
        'severity': severity,
        'subscaleScores': {
          'Depresión': depressionScore,
          'Ansiedad': anxietyScore,
          'Estrés': stressScore,
        },
        'maxScore': 126,
      },
    );
  }

  @override
  String interpretScore(int score) {
    return "Ver interpretación detallada por subescalas";
  }

  @override
  String generateRecommendations(int score) {
    return "Ver recomendaciones específicas basadas en subescalas";
  }

  @override
  bool hasCriticalAlert(int score) {
    return score >=
        50; // Aproximadamente si hay severidad alta en alguna subescala
  }

  String _classifyDepression(int score) {
    if (score <= 9) return "Normal";
    if (score <= 13) return "Leve";
    if (score <= 20) return "Moderada";
    if (score <= 27) return "Severa";
    return "Extremadamente Severa";
  }

  String _classifyAnxiety(int score) {
    if (score <= 7) return "Normal";
    if (score <= 9) return "Leve";
    if (score <= 14) return "Moderada";
    if (score <= 19) return "Severa";
    return "Extremadamente Severa";
  }

  String _classifyStress(int score) {
    if (score <= 14) return "Normal";
    if (score <= 18) return "Leve";
    if (score <= 25) return "Moderado";
    if (score <= 33) return "Severo";
    return "Extremadamente Severo";
  }

  String _getDepressionInterpretation(int score) {
    if (score <= 9) return "No presenta síntomas significativos de depresión.";
    if (score <= 13)
      return "Síntomas leves de depresión. Monitoreo recomendado.";
    if (score <= 20)
      return "Síntomas moderados de depresión. Se recomienda intervención psicológica.";
    if (score <= 27)
      return "Depresión severa. Requiere atención profesional inmediata.";
    return "Depresión extremadamente severa. ATENCIÓN URGENTE REQUERIDA.";
  }

  String _getAnxietyInterpretation(int score) {
    if (score <= 7) return "No presenta síntomas significativos de ansiedad.";
    if (score <= 9) return "Síntomas leves de ansiedad. Monitoreo recomendado.";
    if (score <= 14)
      return "Ansiedad moderada. Se recomienda intervención psicológica.";
    if (score <= 19)
      return "Ansiedad severa. Requiere atención profesional inmediata.";
    return "Ansiedad extremadamente severa. ATENCIÓN URGENTE REQUERIDA.";
  }

  String _getStressInterpretation(int score) {
    if (score <= 14) return "No presenta síntomas significativos de estrés.";
    if (score <= 18) return "Síntomas leves de estrés. Monitoreo recomendado.";
    if (score <= 25)
      return "Estrés moderado. Se recomiendan técnicas de manejo de estrés.";
    if (score <= 33) return "Estrés severo. Requiere atención profesional.";
    return "Estrés extremadamente severo. ATENCIÓN URGENTE REQUERIDA.";
  }

  List<String> _generateRecommendations(
      int depression, int anxiety, int stress) {
    List<String> recommendations = [];

    // Recomendaciones basadas en depresión
    if (depression >= 21) {
      recommendations.add("DEPRESIÓN SEVERA - Evaluación psiquiátrica urgente");
      recommendations
          .add("Considerar tratamiento farmacológico para depresión");
    } else if (depression >= 14) {
      recommendations.add("Terapia cognitivo-conductual para depresión");
      recommendations.add("Evaluación de ideación suicida");
    }

    // Recomendaciones basadas en ansiedad
    if (anxiety >= 15) {
      recommendations
          .add("ANSIEDAD SEVERA - Técnicas de control de ansiedad inmediatas");
      recommendations.add("Considerar tratamiento ansiolítico");
    } else if (anxiety >= 10) {
      recommendations.add("Técnicas de relajación y mindfulness");
      recommendations.add("Terapia de exposición si hay evitación");
    }

    // Recomendaciones basadas en estrés
    if (stress >= 26) {
      recommendations.add("ESTRÉS SEVERO - Intervención en manejo de estrés");
      recommendations.add("Identificar y modificar estresores principales");
    } else if (stress >= 19) {
      recommendations.add("Técnicas de manejo del estrés");
      recommendations.add("Mejorar habilidades de afrontamiento");
    }

    // Recomendaciones generales
    if (recommendations.isEmpty) {
      recommendations.addAll([
        "Mantener hábitos saludables de vida",
        "Ejercicio regular (mínimo 30 min, 3 veces/semana)",
        "Higiene del sueño adecuada",
        "Mantener red de apoyo social",
      ]);
    } else {
      recommendations.addAll([
        "Seguimiento psicológico regular",
        "Establecer red de apoyo",
        "Actividad física regular",
        "Técnicas de autocuidado",
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
