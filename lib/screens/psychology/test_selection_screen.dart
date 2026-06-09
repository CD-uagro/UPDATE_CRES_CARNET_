import 'package:flutter/material.dart';
import '../../models/psychological_test.dart';
import '../../ui/uagro_theme.dart' as theme;
import 'test_application_screen.dart';
import '../dashboard_screen.dart';

/// Pantalla de selección de tests psicológicos
/// Solo accesible para roles de psicología y admin
class TestSelectionScreen extends StatelessWidget {
  final String matricula;
  final String nombrePaciente;
  final dynamic db;

  const TestSelectionScreen({
    super.key,
    required this.matricula,
    required this.nombrePaciente,
    this.db,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Tests Psicológicos',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: theme.UAGroColors.azulMarino,
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          // Botón de inicio sutil
          IconButton(
            icon: const Icon(Icons.home_outlined,
                color: Colors.white70, size: 22),
            tooltip: 'Ir al inicio',
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                    builder: (context) => DashboardScreen(db: db)),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.UAGroColors.azulMarino,
              theme.UAGroColors.azulMarino.withOpacity(0.8),
              Colors.grey[100]!,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con información del paciente
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.UAGroColors.azulMarino.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.person,
                          color: theme.UAGroColors.azulMarino,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nombrePaciente,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: theme.UAGroColors.azulMarino,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Matrícula: $matricula',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Título de selección
                Text(
                  'Selecciona un test para aplicar',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Selecciona el instrumento de evaluación apropiado para el caso clínico',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),

                const SizedBox(height: 24),

                // Lista de tests disponibles
                Expanded(
                  child: ListView(
                    children: [
                      _buildTestCard(
                        context,
                        icon: Icons.mood_bad,
                        title: 'Escala de Depresión de Hamilton',
                        subtitle: 'HAM-D • 17 ítems • 10 min',
                        description:
                            'Evaluación estándar de síntomas depresivos',
                        color: Colors.blue[700]!,
                        testType: TestType.hamilton,
                        isImplemented: true,
                      ),
                      _buildTestCard(
                        context,
                        icon: Icons.psychology,
                        title: 'Inventario de Ansiedad de Beck',
                        subtitle: 'BAI • 21 ítems • 8 min',
                        description:
                            'Evaluación de síntomas físicos de ansiedad',
                        color: Colors.orange[700]!,
                        testType: TestType.bai,
                        isImplemented: true,
                      ),
                      _buildTestCard(
                        context,
                        icon: Icons.assessment,
                        title: 'DASS-21 (Depresión-Ansiedad-Estrés)',
                        subtitle: 'DASS-21 • 21 ítems • 10 min',
                        description:
                            'Evaluación integral de depresión, ansiedad y estrés',
                        color: Colors.purple[700]!,
                        testType: TestType
                            .narcisismo, // Usamos este enum temporalmente para DASS-21
                        isImplemented: true,
                      ),
                      _buildTestCard(
                        context,
                        icon: Icons.warning,
                        title: 'Escala de Riesgo Suicida de Plutchik',
                        subtitle: 'RS • 15 ítems • 5 min',
                        description: 'Evaluación de riesgo suicida (CRÍTICO)',
                        color: Colors.red[700]!,
                        testType: TestType.plutchik,
                        isImplemented: true,
                      ),
                      _buildTestCard(
                        context,
                        icon: Icons.work_off,
                        title: 'Inventario de Burnout de Maslach',
                        subtitle: 'MBI • 22 ítems • 12 min',
                        description:
                            'Evaluación de síndrome de burnout laboral',
                        color: Colors.green[700]!,
                        testType: TestType.mbi,
                        isImplemented: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTestCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String description,
    required Color color,
    required TestType testType,
    required bool isImplemented,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        borderRadius: BorderRadius.circular(16),
        elevation: 4,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isImplemented
              ? () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => TestApplicationScreen(
                        testType: testType,
                        matricula: matricula,
                        nombrePaciente: nombrePaciente,
                      ),
                    ),
                  );
                }
              : null,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
              border: isImplemented
                  ? null
                  : Border.all(
                      color: Colors.grey[300]!,
                      width: 2,
                    ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isImplemented
                        ? color.withOpacity(0.1)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: isImplemented ? color : Colors.grey[400],
                    size: 28,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isImplemented
                                    ? theme.UAGroColors.azulMarino
                                    : Colors.grey[500],
                              ),
                            ),
                          ),
                          if (!isImplemented)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Próximamente',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange[700],
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isImplemented ? color : Colors.grey[400],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          color: isImplemented
                              ? Colors.grey[600]
                              : Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
                if (isImplemented)
                  Icon(
                    Icons.arrow_forward_ios,
                    color: color,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
