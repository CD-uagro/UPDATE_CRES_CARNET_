import '../models/psychological_test.dart';
import 'package:uuid/uuid.dart';

/// Maslach Burnout Inventory (MBI)
/// Inventario de evaluación del síndrome de burnout laboral
class MaslachBurnoutInventory extends PsychologicalTest {
  static const _uuid = Uuid();

  @override
  TestType get testType => TestType.mbi;

  @override
  String get name => "Inventario de Burnout de Maslach (MBI)";

  @override
  String get description =>
      "Evaluación del síndrome de burnout o 'desgaste profesional'. "
      "Mide tres dimensiones: Agotamiento Emocional, Despersonalización y Realización Personal.";

  @override
  String get instructions =>
      "A continuación encontrará una serie de enunciados acerca de su trabajo y sus sentimientos. "
      "Indique la frecuencia con que experimenta cada situación usando la siguiente escala:\n"
      "0 = Nunca\n1 = Pocas veces al año\n2 = Una vez al mes o menos\n"
      "3 = Unas pocas veces al mes\n4 = Una vez a la semana\n"
      "5 = Pocas veces a la semana\n6 = Todos los días";

  @override
  Duration get estimatedDuration => const Duration(minutes: 12);

  @override
  List<TestQuestion> get questions => [
        // AGOTAMIENTO EMOCIONAL (9 ítems: 1, 2, 3, 6, 8, 13, 14, 16, 20)
        TestQuestion(
          id: "mbi1",
          text: "Me siento emocionalmente agotado/a por mi trabajo",
          responseType: ResponseType.likert,
          options: [
            "0 - Nunca",
            "1 - Pocas veces al año",
            "2 - Una vez al mes o menos",
            "3 - Unas pocas veces al mes",
            "4 - Una vez a la semana",
            "5 - Pocas veces a la semana",
            "6 - Todos los días"
          ],
          scoreMapping: {
            "0": 0,
            "1": 1,
            "2": 2,
            "3": 3,
            "4": 4,
            "5": 5,
            "6": 6
          },
        ),

        TestQuestion(
          id: "mbi2",
          text: "Me siento cansado/a al final de la jornada de trabajo",
          responseType: ResponseType.likert,
          options: [
            "0 - Nunca",
            "1 - Pocas veces al año",
            "2 - Una vez al mes o menos",
            "3 - Unas pocas veces al mes",
            "4 - Una vez a la semana",
            "5 - Pocas veces a la semana",
            "6 - Todos los días"
          ],
          scoreMapping: {
            "0": 0,
            "1": 1,
            "2": 2,
            "3": 3,
            "4": 4,
            "5": 5,
            "6": 6
          },
        ),

        TestQuestion(
          id: "mbi3",
          text:
              "Me siento fatigado/a cuando me levanto por la mañana y tengo que ir a trabajar",
          responseType: ResponseType.likert,
          options: [
            "0 - Nunca",
            "1 - Pocas veces al año",
            "2 - Una vez al mes o menos",
            "3 - Unas pocas veces al mes",
            "4 - Una vez a la semana",
            "5 - Pocas veces a la semana",
            "6 - Todos los días"
          ],
          scoreMapping: {
            "0": 0,
            "1": 1,
            "2": 2,
            "3": 3,
            "4": 4,
            "5": 5,
            "6": 6
          },
        ),

        // DESPERSONALIZACIÓN (5 ítems: 5, 10, 11, 15, 22)
        TestQuestion(
          id: "mbi4",
          text: "Comprendo fácilmente cómo se sienten las personas",
          responseType: ResponseType.likert,
          options: [
            "0 - Nunca",
            "1 - Pocas veces al año",
            "2 - Una vez al mes o menos",
            "3 - Unas pocas veces al mes",
            "4 - Una vez a la semana",
            "5 - Pocas veces a la semana",
            "6 - Todos los días"
          ],
          scoreMapping: {
            "0": 0,
            "1": 1,
            "2": 2,
            "3": 3,
            "4": 4,
            "5": 5,
            "6": 6
          },
        ),

        TestQuestion(
          id: "mbi5",
          text:
              "Creo que trato a algunas personas como si fueran objetos impersonales",
          responseType: ResponseType.likert,
          options: [
            "0 - Nunca",
            "1 - Pocas veces al año",
            "2 - Una vez al mes o menos",
            "3 - Unas pocas veces al mes",
            "4 - Una vez a la semana",
            "5 - Pocas veces a la semana",
            "6 - Todos los días"
          ],
          scoreMapping: {
            "0": 0,
            "1": 1,
            "2": 2,
            "3": 3,
            "4": 4,
            "5": 5,
            "6": 6
          },
        ),

        TestQuestion(
          id: "mbi6",
          text: "Trabajar todo el día con personas es un esfuerzo",
          responseType: ResponseType.likert,
          options: [
            "0 - Nunca",
            "1 - Pocas veces al año",
            "2 - Una vez al mes o menos",
            "3 - Unas pocas veces al mes",
            "4 - Una vez a la semana",
            "5 - Pocas veces a la semana",
            "6 - Todos los días"
          ],
          scoreMapping: {
            "0": 0,
            "1": 1,
            "2": 2,
            "3": 3,
            "4": 4,
            "5": 5,
            "6": 6
          },
        ),

        // REALIZACIÓN PERSONAL (8 ítems: 4, 7, 9, 12, 17, 18, 19, 21)
        TestQuestion(
          id: "mbi7",
          text: "Trato muy eficazmente los problemas de las personas",
          responseType: ResponseType.likert,
          options: [
            "0 - Nunca",
            "1 - Pocas veces al año",
            "2 - Una vez al mes o menos",
            "3 - Unas pocas veces al mes",
            "4 - Una vez a la semana",
            "5 - Pocas veces a la semana",
            "6 - Todos los días"
          ],
          scoreMapping: {
            "0": 0,
            "1": 1,
            "2": 2,
            "3": 3,
            "4": 4,
            "5": 5,
            "6": 6
          },
        ),

        TestQuestion(
          id: "mbi8",
          text: "Me siento 'quemado/a' por mi trabajo",
          responseType: ResponseType.likert,
          options: [
            "0 - Nunca",
            "1 - Pocas veces al año",
            "2 - Una vez al mes o menos",
            "3 - Unas pocas veces al mes",
            "4 - Una vez a la semana",
            "5 - Pocas veces a la semana",
            "6 - Todos los días"
          ],
          scoreMapping: {
            "0": 0,
            "1": 1,
            "2": 2,
            "3": 3,
            "4": 4,
            "5": 5,
            "6": 6
          },
        ),

        TestQuestion(
          id: "mbi9",
          text:
              "Creo que influyo positivamente con mi trabajo en la vida de las personas",
          responseType: ResponseType.likert,
          options: [
            "0 - Nunca",
            "1 - Pocas veces al año",
            "2 - Una vez al mes o menos",
            "3 - Unas pocas veces al mes",
            "4 - Una vez a la semana",
            "5 - Pocas veces a la semana",
            "6 - Todos los días"
          ],
          scoreMapping: {
            "0": 0,
            "1": 1,
            "2": 2,
            "3": 3,
            "4": 4,
            "5": 5,
            "6": 6
          },
        ),

        TestQuestion(
          id: "mbi10",
          text:
              "Me he vuelto más insensible con la gente desde que ejerzo esta profesión",
          responseType: ResponseType.likert,
          options: [
            "0 - Nunca",
            "1 - Pocas veces al año",
            "2 - Una vez al mes o menos",
            "3 - Unas pocas veces al mes",
            "4 - Una vez a la semana",
            "5 - Pocas veces a la semana",
            "6 - Todos los días"
          ],
          scoreMapping: {
            "0": 0,
            "1": 1,
            "2": 2,
            "3": 3,
            "4": 4,
            "5": 5,
            "6": 6
          },
        ),

        TestQuestion(
          id: "mbi11",
          text: "Pienso que este trabajo me está endureciendo emocionalmente",
          responseType: ResponseType.likert,
          options: [
            "0 - Nunca",
            "1 - Pocas veces al año",
            "2 - Una vez al mes o menos",
            "3 - Unas pocas veces al mes",
            "4 - Una vez a la semana",
            "5 - Pocas veces a la semana",
            "6 - Todos los días"
          ],
          scoreMapping: {
            "0": 0,
            "1": 1,
            "2": 2,
            "3": 3,
            "4": 4,
            "5": 5,
            "6": 6
          },
        ),

        TestQuestion(
          id: "mbi12",
          text: "Me siento muy activo/a",
          responseType: ResponseType.likert,
          options: [
            "0 - Nunca",
            "1 - Pocas veces al año",
            "2 - Una vez al mes o menos",
            "3 - Unas pocas veces al mes",
            "4 - Una vez a la semana",
            "5 - Pocas veces a la semana",
            "6 - Todos los días"
          ],
          scoreMapping: {
            "0": 0,
            "1": 1,
            "2": 2,
            "3": 3,
            "4": 4,
            "5": 5,
            "6": 6
          },
        ),

        TestQuestion(
          id: "mbi13",
          text: "Me siento frustrado/a en mi trabajo",
          responseType: ResponseType.likert,
          options: [
            "0 - Nunca",
            "1 - Pocas veces al año",
            "2 - Una vez al mes o menos",
            "3 - Unas pocas veces al mes",
            "4 - Una vez a la semana",
            "5 - Pocas veces a la semana",
            "6 - Todos los días"
          ],
          scoreMapping: {
            "0": 0,
            "1": 1,
            "2": 2,
            "3": 3,
            "4": 4,
            "5": 5,
            "6": 6
          },
        ),

        TestQuestion(
          id: "mbi14",
          text: "Creo que estoy trabajando demasiado",
          responseType: ResponseType.likert,
          options: [
            "0 - Nunca",
            "1 - Pocas veces al año",
            "2 - Una vez al mes o menos",
            "3 - Unas pocas veces al mes",
            "4 - Una vez a la semana",
            "5 - Pocas veces a la semana",
            "6 - Todos los días"
          ],
          scoreMapping: {
            "0": 0,
            "1": 1,
            "2": 2,
            "3": 3,
            "4": 4,
            "5": 5,
            "6": 6
          },
        ),

        TestQuestion(
          id: "mbi15",
          text:
              "No me preocupa realmente lo que le ocurre a algunas personas a las que doy servicio",
          responseType: ResponseType.likert,
          options: [
            "0 - Nunca",
            "1 - Pocas veces al año",
            "2 - Una vez al mes o menos",
            "3 - Unas pocas veces al mes",
            "4 - Una vez a la semana",
            "5 - Pocas veces a la semana",
            "6 - Todos los días"
          ],
          scoreMapping: {
            "0": 0,
            "1": 1,
            "2": 2,
            "3": 3,
            "4": 4,
            "5": 5,
            "6": 6
          },
        ),

        TestQuestion(
          id: "mbi16",
          text: "Trabajar directamente con personas me produce estrés",
          responseType: ResponseType.likert,
          options: [
            "0 - Nunca",
            "1 - Pocas veces al año",
            "2 - Una vez al mes o menos",
            "3 - Unas pocas veces al mes",
            "4 - Una vez a la semana",
            "5 - Pocas veces a la semana",
            "6 - Todos los días"
          ],
          scoreMapping: {
            "0": 0,
            "1": 1,
            "2": 2,
            "3": 3,
            "4": 4,
            "5": 5,
            "6": 6
          },
        ),

        TestQuestion(
          id: "mbi17",
          text:
              "Puedo crear fácilmente una atmósfera relajada con las personas a las que doy servicio",
          responseType: ResponseType.likert,
          options: [
            "0 - Nunca",
            "1 - Pocas veces al año",
            "2 - Una vez al mes o menos",
            "3 - Unas pocas veces al mes",
            "4 - Una vez a la semana",
            "5 - Pocas veces a la semana",
            "6 - Todos los días"
          ],
          scoreMapping: {
            "0": 0,
            "1": 1,
            "2": 2,
            "3": 3,
            "4": 4,
            "5": 5,
            "6": 6
          },
        ),

        TestQuestion(
          id: "mbi18",
          text: "Me siento estimulado/a después de trabajar con personas",
          responseType: ResponseType.likert,
          options: [
            "0 - Nunca",
            "1 - Pocas veces al año",
            "2 - Una vez al mes o menos",
            "3 - Unas pocas veces al mes",
            "4 - Una vez a la semana",
            "5 - Pocas veces a la semana",
            "6 - Todos los días"
          ],
          scoreMapping: {
            "0": 0,
            "1": 1,
            "2": 2,
            "3": 3,
            "4": 4,
            "5": 5,
            "6": 6
          },
        ),

        TestQuestion(
          id: "mbi19",
          text: "He conseguido muchas cosas útiles en mi profesión",
          responseType: ResponseType.likert,
          options: [
            "0 - Nunca",
            "1 - Pocas veces al año",
            "2 - Una vez al mes o menos",
            "3 - Unas pocas veces al mes",
            "4 - Una vez a la semana",
            "5 - Pocas veces a la semana",
            "6 - Todos los días"
          ],
          scoreMapping: {
            "0": 0,
            "1": 1,
            "2": 2,
            "3": 3,
            "4": 4,
            "5": 5,
            "6": 6
          },
        ),

        TestQuestion(
          id: "mbi20",
          text: "Me siento acabado/a",
          responseType: ResponseType.likert,
          options: [
            "0 - Nunca",
            "1 - Pocas veces al año",
            "2 - Una vez al mes o menos",
            "3 - Unas pocas veces al mes",
            "4 - Una vez a la semana",
            "5 - Pocas veces a la semana",
            "6 - Todos los días"
          ],
          scoreMapping: {
            "0": 0,
            "1": 1,
            "2": 2,
            "3": 3,
            "4": 4,
            "5": 5,
            "6": 6
          },
        ),

        TestQuestion(
          id: "mbi21",
          text: "En mi trabajo trato los problemas emocionales con mucha calma",
          responseType: ResponseType.likert,
          options: [
            "0 - Nunca",
            "1 - Pocas veces al año",
            "2 - Una vez al mes o menos",
            "3 - Unas pocas veces al mes",
            "4 - Una vez a la semana",
            "5 - Pocas veces a la semana",
            "6 - Todos los días"
          ],
          scoreMapping: {
            "0": 0,
            "1": 1,
            "2": 2,
            "3": 3,
            "4": 4,
            "5": 5,
            "6": 6
          },
        ),

        TestQuestion(
          id: "mbi22",
          text:
              "Siento que las personas que trato me culpan de algunos de sus problemas",
          responseType: ResponseType.likert,
          options: [
            "0 - Nunca",
            "1 - Pocas veces al año",
            "2 - Una vez al mes o menos",
            "3 - Unas pocas veces al mes",
            "4 - Una vez a la semana",
            "5 - Pocas veces a la semana",
            "6 - Todos los días"
          ],
          scoreMapping: {
            "0": 0,
            "1": 1,
            "2": 2,
            "3": 3,
            "4": 4,
            "5": 5,
            "6": 6
          },
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
    // Agotamiento Emocional: ítems 1, 2, 3, 6, 8, 13, 14, 16, 20
    final agotamientoItems = [
      'mbi1',
      'mbi2',
      'mbi3',
      'mbi6',
      'mbi8',
      'mbi13',
      'mbi14',
      'mbi16',
      'mbi20'
    ];
    // Despersonalización: ítems 5, 10, 11, 15, 22
    final despersonalizacionItems = [
      'mbi5',
      'mbi10',
      'mbi11',
      'mbi15',
      'mbi22'
    ];
    // Realización Personal: ítems 4, 7, 9, 12, 17, 18, 19, 21 (puntuación inversa)
    final realizacionItems = [
      'mbi4',
      'mbi7',
      'mbi9',
      'mbi12',
      'mbi17',
      'mbi18',
      'mbi19',
      'mbi21'
    ];

    int agotamiento = 0;
    int despersonalizacion = 0;
    int realizacion = 0;

    for (var response in responses) {
      if (agotamientoItems.contains(response.questionId)) {
        agotamiento += response.score;
      } else if (despersonalizacionItems.contains(response.questionId)) {
        despersonalizacion += response.score;
      } else if (realizacionItems.contains(response.questionId)) {
        realizacion += response.score;
      }
    }

    // Clasificar cada dimensión
    final agotClass = _classifyAgotamiento(agotamiento);
    final despClass = _classifyDespersonalizacion(despersonalizacion);
    final realClass = _classifyRealizacion(realizacion);

    // Determinar si hay burnout
    bool hasBurnout = (agotamiento >= 27) ||
        (despersonalizacion >= 10) ||
        (realizacion <= 33);
    bool alertaCritica = (agotamiento >= 27) && (despersonalizacion >= 10);

    int totalScore = agotamiento +
        despersonalizacion +
        (48 - realizacion); // Invertir realización

    String severity =
        "Agotamiento: $agotClass | Despersonalización: $despClass | Realización: $realClass";

    String interpretation = "MBI - Resultados por dimensión:\n\n"
        "AGOTAMIENTO EMOCIONAL ($agotamiento): $agotClass\n"
        "${_interpretAgotamiento(agotamiento)}\n\n"
        "DESPERSONALIZACIÓN ($despersonalizacion): $despClass\n"
        "${_interpretDespersonalizacion(despersonalizacion)}\n\n"
        "REALIZACIÓN PERSONAL ($realizacion): $realClass\n"
        "${_interpretRealizacion(realizacion)}\n\n"
        "${hasBurnout ? '⚠️ Se detectan indicadores de SÍNDROME DE BURNOUT.' : 'No se detecta síndrome de burnout en este momento.'}";

    final recommendations =
        _generateRecommendations(agotamiento, despersonalizacion, realizacion);

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
          'Agotamiento Emocional': agotamiento,
          'Despersonalización': despersonalizacion,
          'Realización Personal': realizacion,
        },
        'hasBurnout': hasBurnout,
      },
    );
  }

  String _classifyAgotamiento(int score) {
    if (score <= 18) return "Bajo";
    if (score <= 26) return "Medio";
    return "Alto";
  }

  String _classifyDespersonalizacion(int score) {
    if (score <= 5) return "Bajo";
    if (score <= 9) return "Medio";
    return "Alto";
  }

  String _classifyRealizacion(int score) {
    if (score >= 40) return "Alto";
    if (score >= 34) return "Medio";
    return "Bajo";
  }

  String _interpretAgotamiento(int score) {
    if (score <= 18)
      return "Nivel bajo de cansancio emocional. Energía adecuada para el trabajo.";
    if (score <= 26)
      return "Nivel moderado de agotamiento. Se recomienda atención a signos de desgaste.";
    return "Nivel alto de agotamiento emocional. Sensación de estar exhausto y sin recursos. REQUIERE INTERVENCIÓN.";
  }

  String _interpretDespersonalizacion(int score) {
    if (score <= 5)
      return "Actitud positiva hacia las personas. No hay distanciamiento emocional problemático.";
    if (score <= 9)
      return "Despersonalización moderada. Inicio de actitudes cínicas o distantes.";
    return "Despersonalización alta. Actitudes negativas, cínicas o insensibles hacia las personas. REQUIERE ATENCIÓN.";
  }

  String _interpretRealizacion(int score) {
    if (score >= 40)
      return "Alto sentido de logro y competencia profesional. Satisfacción con el trabajo.";
    if (score >= 34)
      return "Realización personal moderada. Cuestionamiento ocasional de la eficacia.";
    return "Baja realización personal. Sentimientos de incompetencia e ineficacia. REQUIERE INTERVENCIÓN.";
  }

  List<String> _generateRecommendations(
      int agotamiento, int despersonalizacion, int realizacion) {
    List<String> recommendations = [];

    // Recomendaciones por agotamiento
    if (agotamiento >= 27) {
      recommendations.addAll([
        "AGOTAMIENTO ALTO - Necesario tomar medidas inmediatas",
        "Evaluar carga laboral y redistribuir tareas",
        "Establecer límites claros entre trabajo y vida personal",
        "Técnicas de manejo del estrés (mindfulness, relajación)",
        "Considerar período de descanso o vacaciones",
      ]);
    } else if (agotamiento >= 19) {
      recommendations.addAll([
        "Monitorear signos de agotamiento",
        "Implementar pausas regulares durante jornada",
        "Actividad física regular",
      ]);
    }

    // Recomendaciones por despersonalización
    if (despersonalizacion >= 10) {
      recommendations.addAll([
        "DESPERSONALIZACIÓN ALTA - Supervisión y apoyo necesarios",
        "Terapia grupal o individual",
        "Rehumanizar la relación con beneficiarios del servicio",
        "Grupos de apoyo con colegas",
      ]);
    }

    // Recomendaciones por baja realización
    if (realizacion <= 33) {
      recommendations.addAll([
        "BAJA REALIZACIÓN - Trabajar autoestima profesional",
        "Reconocimiento de logros y fortalezas",
        "Capacitación y desarrollo profesional",
        "Mentoría o supervisión clínica",
        "Replantear metas profesionales realistas",
      ]);
    }

    // Recomendaciones generales
    if (recommendations.isEmpty) {
      recommendations.addAll([
        "Mantener balance vida-trabajo",
        "Continuar con autocuidado",
        "Actividades recreativas fuera del trabajo",
        "Mantener red de apoyo social",
      ]);
    } else {
      recommendations.addAll([
        "Evaluación ocupacional completa",
        "Considerar intervención organizacional",
        "Reevaluación en 2-3 meses",
      ]);
    }

    return recommendations;
  }

  @override
  String interpretScore(int score) {
    return "Ver interpretación por dimensiones (Agotamiento, Despersonalización, Realización)";
  }

  @override
  String generateRecommendations(int score) {
    return "Ver recomendaciones específicas según dimensiones afectadas";
  }

  @override
  bool hasCriticalAlert(int score) {
    return score > 80; // Aproximación basada en puntajes altos combinados
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
