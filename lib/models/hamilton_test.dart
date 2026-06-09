import '../models/psychological_test.dart';
import 'package:uuid/uuid.dart';

/// Escala de Depresión de Hamilton (HAM-D 17 ítems)
/// Test clínico estándar para evaluar la severidad de la depresión
class HamiltonDepressionTest extends PsychologicalTest {
  static const _uuid = Uuid();

  @override
  TestType get testType => TestType.hamilton;

  @override
  String get name => "Escala de Depresión de Hamilton (HAM-D)";

  @override
  String get description =>
      "Evaluación clínica de la severidad de síntomas depresivos. "
      "Instrumento estándar utilizado en la práctica clínica y en investigación.";

  @override
  String get instructions =>
      "Las siguientes preguntas se refieren a cómo se ha sentido durante la ÚLTIMA SEMANA. "
      "Para cada pregunta, seleccione la respuesta que mejor describe su situación.";

  @override
  Duration get estimatedDuration => const Duration(minutes: 10);

  @override
  List<TestQuestion> get questions => [
        TestQuestion(
          id: "ham1",
          text:
              "Estado de ánimo deprimido (sentimientos de tristeza, desesperanza, desamparo, sentimiento de inutilidad)",
          responseType: ResponseType.likert,
          options: [
            "0 - Ausente",
            "1 - Estas sensaciones las expresa solamente si le preguntan",
            "2 - Estas sensaciones las relata espontáneamente",
            "3 - Sensaciones no comunicadas verbalmente (expresión facial, postura, voz, tendencia al llanto)",
            "4 - Manifiesta estas sensaciones en su expresión facial, postura, voz, tendencia al llanto"
          ],
          scoreMapping: {"0": 0, "1": 1, "2": 2, "3": 3, "4": 4},
        ),
        TestQuestion(
          id: "ham2",
          text: "Sentimientos de culpa",
          responseType: ResponseType.likert,
          options: [
            "0 - Ausente",
            "1 - Se culpa a sí mismo, cree haber decepcionado a la gente",
            "2 - Ideas de culpa o meditación sobre errores pasados o malas acciones",
            "3 - Siente que la enfermedad actual es un castigo",
            "4 - Oye voces acusatorias o de denuncia y/o experimenta alucinaciones visuales amenazadoras"
          ],
          scoreMapping: {"0": 0, "1": 1, "2": 2, "3": 3, "4": 4},
        ),
        TestQuestion(
          id: "ham3",
          text: "Suicidio",
          responseType: ResponseType.likert,
          options: [
            "0 - Ausente",
            "1 - Le parece que la vida no vale la pena ser vivida",
            "2 - Desearía estar muerto o tiene pensamientos sobre la posibilidad de morirse",
            "3 - Ideas de suicidio o amenazas",
            "4 - Intentos de suicidio (cualquier intento serio se califica 4)"
          ],
          scoreMapping: {"0": 0, "1": 1, "2": 2, "3": 3, "4": 4},
        ),
        TestQuestion(
          id: "ham4",
          text: "Insomnio precoz",
          responseType: ResponseType.likert,
          options: [
            "0 - No tiene dificultad para conciliar el sueño",
            "1 - Quejas ocasionales de dificultad para conciliar el sueño (más de media hora)",
            "2 - Quejas constantes de dificultad para conciliar el sueño"
          ],
          scoreMapping: {"0": 0, "1": 1, "2": 2},
        ),
        TestQuestion(
          id: "ham5",
          text: "Insomnio intermedio",
          responseType: ResponseType.likert,
          options: [
            "0 - No hay dificultad",
            "1 - Quejas de estar inquieto durante la noche",
            "2 - Está despierto durante la noche (se levanta de la cama se califica 2)"
          ],
          scoreMapping: {"0": 0, "1": 1, "2": 2},
        ),
        TestQuestion(
          id: "ham6",
          text: "Insomnio tardío",
          responseType: ResponseType.likert,
          options: [
            "0 - No hay dificultad",
            "1 - Se despierta a primeras horas de la madrugada, pero se vuelve a dormir",
            "2 - No puede volver a dormirse si se levanta de la cama"
          ],
          scoreMapping: {"0": 0, "1": 1, "2": 2},
        ),
        TestQuestion(
          id: "ham7",
          text: "Trabajo y actividades",
          responseType: ResponseType.likert,
          options: [
            "0 - No hay dificultad",
            "1 - Pensamientos y sentimientos de incapacidad, fatiga o debilidad (trabajos, pasatiempos)",
            "2 - Pérdida de interés en su actividad (trabajos o pasatiempos) ya sea directamente o indirectamente",
            "3 - Disminución del tiempo actual dedicado a actividades o disminución de la productividad",
            "4 - Dejó de trabajar por la presente enfermedad"
          ],
          scoreMapping: {"0": 0, "1": 1, "2": 2, "3": 3, "4": 4},
        ),
        TestQuestion(
          id: "ham8",
          text:
              "Inhibición (lentitud de pensamiento y lenguaje; empeoramiento de la concentración; actividad motora disminuida)",
          responseType: ResponseType.likert,
          options: [
            "0 - Palabra y pensamiento normales",
            "1 - Ligero retraso en el diálogo",
            "2 - Evidente retraso en el diálogo",
            "3 - Diálogo difícil",
            "4 - Torpeza completa"
          ],
          scoreMapping: {"0": 0, "1": 1, "2": 2, "3": 3, "4": 4},
        ),
        TestQuestion(
          id: "ham9",
          text: "Agitación",
          responseType: ResponseType.likert,
          options: [
            "0 - Ninguna",
            "1 - Juguetea con sus manos, cabellos, etc.",
            "2 - Se retuerce las manos, se muerde las uñas, se tira de los cabellos, se muerde los labios"
          ],
          scoreMapping: {"0": 0, "1": 1, "2": 2},
        ),
        TestQuestion(
          id: "ham10",
          text: "Ansiedad (psíquica)",
          responseType: ResponseType.likert,
          options: [
            "0 - No hay dificultad",
            "1 - Tensión e irritabilidad subjetivas",
            "2 - Preocupación por pequeñas cosas",
            "3 - Actitud aprensiva en la expresión o en el habla",
            "4 - Expresa sus temores sin que le pregunten"
          ],
          scoreMapping: {"0": 0, "1": 1, "2": 2, "3": 3, "4": 4},
        ),
        TestQuestion(
          id: "ham11",
          text:
              "Ansiedad (somática): síntomas fisiológicos de ansiedad (sequedad de boca, flatulencia, diarrea, eructos, calambres, etc.)",
          responseType: ResponseType.likert,
          options: [
            "0 - Ausente",
            "1 - Ligera",
            "2 - Moderada",
            "3 - Severa",
            "4 - Incapacitante"
          ],
          scoreMapping: {"0": 0, "1": 1, "2": 2, "3": 3, "4": 4},
        ),
        TestQuestion(
          id: "ham12",
          text: "Síntomas somáticos (gastrointestinales)",
          responseType: ResponseType.likert,
          options: [
            "0 - Ninguno",
            "1 - Pérdida del apetito, pero come sin necesidad de que lo estimulen",
            "2 - Dificultad en comer si no se le insiste"
          ],
          scoreMapping: {"0": 0, "1": 1, "2": 2},
        ),
        TestQuestion(
          id: "ham13",
          text: "Síntomas somáticos generales",
          responseType: ResponseType.likert,
          options: [
            "0 - Ninguno",
            "1 - Pesadez en las extremidades, espalda o cabeza; dolores de espalda, cefalea, dolores musculares",
            "2 - Cualquier síntoma bien definido se califica 2"
          ],
          scoreMapping: {"0": 0, "1": 1, "2": 2},
        ),
        TestQuestion(
          id: "ham14",
          text:
              "Síntomas genitales (pérdida de la libido, trastornos menstruales)",
          responseType: ResponseType.likert,
          options: ["0 - Ausente", "1 - Ligero", "2 - Severo"],
          scoreMapping: {"0": 0, "1": 1, "2": 2},
        ),
        TestQuestion(
          id: "ham15",
          text: "Hipocondría",
          responseType: ResponseType.likert,
          options: [
            "0 - No la hay",
            "1 - Preocupado de sí mismo (corporalmente)",
            "2 - Preocupado por su salud",
            "3 - Se lamenta constantemente, solicita ayuda",
            "4 - Ideas delirantes hipocondríacas"
          ],
          scoreMapping: {"0": 0, "1": 1, "2": 2, "3": 3, "4": 4},
        ),
        TestQuestion(
          id: "ham16",
          text: "Pérdida de peso",
          responseType: ResponseType.likert,
          options: [
            "0 - No hay pérdida de peso",
            "1 - Probable pérdida de peso asociada con la enfermedad actual",
            "2 - Pérdida de peso definida (según el paciente)"
          ],
          scoreMapping: {"0": 0, "1": 1, "2": 2},
        ),
        TestQuestion(
          id: "ham17",
          text: "Introspección",
          responseType: ResponseType.likert,
          options: [
            "0 - Se da cuenta que está deprimido y enfermo",
            "1 - Se da cuenta de su enfermedad pero atribuye la causa a la mala alimentación, clima, exceso de trabajo, virus, necesidad de descanso, etc.",
            "2 - Niega que esté enfermo"
          ],
          scoreMapping: {"0": 0, "1": 1, "2": 2},
        ),
      ];

  @override
  TestResult calculateResult({
    required String matricula,
    required String nombrePaciente,
    required String psicologo,
    required List<TestResponse> responses,
  }) {
    final totalScore =
        responses.fold<int>(0, (sum, response) => sum + response.score);

    return TestResult(
      id: _uuid.v4(),
      testType: testType,
      matricula: matricula,
      nombrePaciente: nombrePaciente,
      psicologo: psicologo,
      fechaAplicacion: DateTime.now(),
      responses: responses,
      puntuacionTotal: totalScore,
      interpretacion: interpretScore(totalScore),
      recomendaciones: generateRecommendations(totalScore),
      alertaCritica: hasCriticalAlert(totalScore),
    );
  }

  @override
  String interpretScore(int score) {
    if (score <= 7) {
      return "NORMAL: Sin síntomas depresivos significativos. "
          "La puntuación está dentro del rango normal. "
          "No se evidencian signos clínicos de depresión.";
    } else if (score <= 13) {
      return "DEPRESIÓN LEVE: Síntomas depresivos leves presentes. "
          "Se recomienda monitoreo y evaluación de factores estresantes. "
          "Considerar intervenciones psicoterapéuticas de apoyo.";
    } else if (score <= 18) {
      return "DEPRESIÓN MODERADA: Síntomas depresivos moderados que requieren atención clínica. "
          "Se recomienda intervención psicoterapéutica y seguimiento regular. "
          "Evaluar necesidad de derivación a psiquiatría.";
    } else if (score <= 22) {
      return "DEPRESIÓN SEVERA: Síntomas depresivos severos que requieren intervención inmediata. "
          "Se recomienda tratamiento psicoterapéutico intensivo y evaluación psiquiátrica urgente. "
          "Monitoreo estrecho del riesgo suicida.";
    } else {
      return "DEPRESIÓN MUY SEVERA: Síntomas depresivos muy severos que requieren atención urgente. "
          "DERIVACIÓN INMEDIATA a psiquiatría. Consideración de hospitalización. "
          "Protocolo de riesgo suicida activado.";
    }
  }

  @override
  String generateRecommendations(int score) {
    if (score <= 7) {
      return "• Mantener hábitos saludables de sueño y ejercicio\n"
          "• Continuar con actividades sociales y recreativas\n"
          "• Seguimiento en 6 meses o ante cambios significativos";
    } else if (score <= 13) {
      return "• Psicoterapia de apoyo o terapia cognitivo-conductual\n"
          "• Técnicas de manejo del estrés y relajación\n"
          "• Evaluación de factores estresantes actuales\n"
          "• Seguimiento en 4-6 semanas";
    } else if (score <= 18) {
      return "• Psicoterapia especializada (TCC, TIP, o similar)\n"
          "• Evaluación psiquiátrica para considerar farmacoterapia\n"
          "• Monitoreo semanal de síntomas\n"
          "• Evaluación de red de apoyo social\n"
          "• Seguimiento en 2-3 semanas";
    } else if (score <= 22) {
      return "• DERIVACIÓN URGENTE a psiquiatría\n"
          "• Psicoterapia intensiva (2+ sesiones por semana)\n"
          "• Evaluación diaria de riesgo suicida\n"
          "• Activación de red de apoyo familiar\n"
          "• Considerar tratamiento farmacológico\n"
          "• Seguimiento semanal obligatorio";
    } else {
      return "• DERIVACIÓN INMEDIATA a servicio de urgencias psiquiátricas\n"
          "• Evaluación de riesgo suicida cada 24-48 horas\n"
          "• Considerar hospitalización psiquiátrica\n"
          "• Tratamiento farmacológico urgente\n"
          "• Supervisión familiar constante\n"
          "• Protocolo de crisis activado";
    }
  }

  @override
  bool hasCriticalAlert(int score) {
    // Alerta crítica si hay depresión severa o muy severa
    return score >= 19;
  }
}
