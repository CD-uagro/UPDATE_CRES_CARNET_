import 'package:flutter/material.dart';
import '../../models/psychological_test.dart';
import '../../models/hamilton_test.dart';
import '../../models/beck_test.dart';
import '../../models/dass21_test.dart';
import '../../models/plutchik_test.dart';
import '../../models/mbi_test.dart';
import '../../ui/uagro_theme.dart' as theme;
import '../../data/auth_service.dart';
import 'test_results_screen.dart';

/// Pantalla de aplicación de tests psicológicos
/// Muestra las preguntas del test seleccionado y recoge las respuestas
class TestApplicationScreen extends StatefulWidget {
  final TestType testType;
  final String matricula;
  final String nombrePaciente;

  const TestApplicationScreen({
    super.key,
    required this.testType,
    required this.matricula,
    required this.nombrePaciente,
  });

  @override
  State<TestApplicationScreen> createState() => _TestApplicationScreenState();
}

class _TestApplicationScreenState extends State<TestApplicationScreen> {
  late PsychologicalTest _test;
  late PageController _pageController;
  int _currentQuestionIndex = 0;
  Map<String, dynamic> _responses = {};
  bool _isCompleting = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _initializeTest();
  }

  void _initializeTest() {
    switch (widget.testType) {
      case TestType.hamilton:
        _test = HamiltonDepressionTest();
        break;
      case TestType.bai:
        _test = BeckAnxietyInventory();
        break;
      case TestType.narcisismo:
        _test = DASS21Test(); // DASS-21 como tercer test disponible
        break;
      case TestType.plutchik:
        _test = PlutchikSuicideRiskScale();
        break;
      case TestType.mbi:
        _test = MaslachBurnoutInventory();
        break;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _selectResponse(String questionId, String response, int score) {
    setState(() {
      _responses[questionId] = {
        'response': response,
        'score': score,
      };
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _test.questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeTest();
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeTest() async {
    setState(() {
      _isCompleting = true;
    });

    try {
      // Obtener información del psicólogo actual
      final currentUser = await AuthService.getCurrentUser();
      final psicologo = currentUser?.nombreCompleto ?? 'Psicólogo UAGro';

      // Convertir respuestas al formato requerido
      final testResponses = _test.questions.map((question) {
        final responseData = _responses[question.id];
        return TestResponse(
          questionId: question.id,
          response: responseData['response'],
          score: responseData['score'],
          timestamp: DateTime.now(),
        );
      }).toList();

      // Calcular resultado del test
      final result = _test.calculateResult(
        matricula: widget.matricula,
        nombrePaciente: widget.nombrePaciente,
        psicologo: psicologo,
        responses: testResponses,
      );

      // Navegar a pantalla de resultados
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => TestResultsScreen(
              result: result,
              test: _test,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al procesar el test: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCompleting = false;
        });
      }
    }
  }

  bool _isQuestionAnswered(String questionId) {
    return _responses.containsKey(questionId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _test.name,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: theme.UAGroColors.azulMarino,
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.UAGroColors.azulMarino,
              theme.UAGroColors.azulMarino.withOpacity(0.8),
              Colors.grey[50]!,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header con progreso
              Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Info del paciente
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '${widget.nombrePaciente} • ${widget.matricula}',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Indicador de progreso
                    Row(
                      children: [
                        Text(
                          'Pregunta ${_currentQuestionIndex + 1} de ${_test.questions.length}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${((_currentQuestionIndex + 1) / _test.questions.length * 100).round()}%',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    LinearProgressIndicator(
                      value:
                          (_currentQuestionIndex + 1) / _test.questions.length,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      minHeight: 6,
                    ),
                  ],
                ),
              ),

              // Área de la pregunta
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _test.questions.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentQuestionIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final question = _test.questions[index];
                    return _buildQuestionCard(question);
                  },
                ),
              ),

              // Botones de navegación
              Container(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    // Botón Anterior
                    if (_currentQuestionIndex > 0)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _previousQuestion,
                          icon: Icon(Icons.arrow_back),
                          label: Text('Anterior'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.UAGroColors.azulMarino,
                            side:
                                BorderSide(color: theme.UAGroColors.azulMarino),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),

                    if (_currentQuestionIndex > 0) const SizedBox(width: 16),

                    // Botón Siguiente/Finalizar
                    Expanded(
                      flex: _currentQuestionIndex == 0 ? 1 : 1,
                      child: ElevatedButton.icon(
                        onPressed: _isQuestionAnswered(
                                _test.questions[_currentQuestionIndex].id)
                            ? (_isCompleting
                                ? null
                                : (_currentQuestionIndex ==
                                        _test.questions.length - 1
                                    ? _completeTest
                                    : _nextQuestion))
                            : null,
                        icon: _isCompleting
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : Icon(_currentQuestionIndex ==
                                    _test.questions.length - 1
                                ? Icons.check
                                : Icons.arrow_forward),
                        label: Text(_isCompleting
                            ? 'Procesando...'
                            : (_currentQuestionIndex ==
                                    _test.questions.length - 1
                                ? 'Finalizar Test'
                                : 'Siguiente')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.UAGroColors.azulMarino,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          disabledBackgroundColor: Colors.grey[400],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionCard(TestQuestion question) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Texto de la pregunta
              Text(
                question.text,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.UAGroColors.azulMarino,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 24),

              // Opciones de respuesta
              Expanded(
                child: ListView.builder(
                  itemCount: question.options.length,
                  itemBuilder: (context, index) {
                    final option = question.options[index];
                    final isSelected =
                        _responses[question.id]?['response'] == option;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Material(
                        borderRadius: BorderRadius.circular(12),
                        elevation: isSelected ? 4 : 1,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            final score =
                                question.scoreMapping?[index.toString()] ??
                                    index;
                            _selectResponse(question.id, option, score);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? theme.UAGroColors.azulMarino
                                    : Colors.grey[300]!,
                                width: isSelected ? 2 : 1,
                              ),
                              color: isSelected
                                  ? theme.UAGroColors.azulMarino
                                      .withOpacity(0.1)
                                  : Colors.white,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? theme.UAGroColors.azulMarino
                                          : Colors.grey[400]!,
                                      width: 2,
                                    ),
                                    color: isSelected
                                        ? theme.UAGroColors.azulMarino
                                        : Colors.white,
                                  ),
                                  child: isSelected
                                      ? Icon(
                                          Icons.check,
                                          size: 16,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    option,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: isSelected
                                          ? theme.UAGroColors.azulMarino
                                          : Colors.grey[700],
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
