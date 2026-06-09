import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../models/psychological_test.dart';
import '../../ui/uagro_theme.dart' as theme;
import '../../data/api_service.dart';

/// Pantalla de resultados del test psicológico
/// Muestra gráficos, interpretación y permite generar PDF
class TestResultsScreen extends StatefulWidget {
  final TestResult result;
  final PsychologicalTest test;

  const TestResultsScreen({
    super.key,
    required this.result,
    required this.test,
  });

  @override
  State<TestResultsScreen> createState() => _TestResultsScreenState();
}

class _TestResultsScreenState extends State<TestResultsScreen> {
  bool _savingToExpediente = false;
  bool _generatingPdf = false;
  bool _autoSaveOffered = false;

  @override
  void initState() {
    super.initState();
    // Ofrecer guardado automático después de un breve delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && !_autoSaveOffered) {
        _offerAutoSave();
      }
    });
  }

  Future<void> _offerAutoSave() async {
    if (!mounted) return;

    setState(() {
      _autoSaveOffered = true;
    });

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.save, color: theme.UAGroColors.azulMarino),
            const SizedBox(width: 12),
            const Text('Guardar Resultados'),
          ],
        ),
        content: Text(
          '¿Desea guardar y descargar el PDF de los resultados de este test?\n\n'
          'El documento incluirá:\n'
          '• Datos del paciente (${widget.result.nombrePaciente})\n'
          '• Resultados completos del test\n'
          '• Interpretación clínica\n'
          '• Recomendaciones',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Ahora No'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Guardar PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.UAGroColors.azulMarino,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (shouldSave == true && mounted) {
      await _generatePdf();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Resultados del Test',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: widget.result.alertaCritica
            ? Colors.red[700]
            : theme.UAGroColors.azulMarino,
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _generatingPdf ? null : _generatePdf,
            icon: _generatingPdf
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(Icons.picture_as_pdf),
            tooltip: 'Generar PDF',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              widget.result.alertaCritica
                  ? Colors.red[700]!
                  : theme.UAGroColors.azulMarino,
              widget.result.alertaCritica
                  ? Colors.red[400]!
                  : theme.UAGroColors.azulMarino.withOpacity(0.8),
              Colors.grey[50]!,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header de alerta crítica (si aplica)
              if (widget.result.alertaCritica)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red[300]!, width: 2),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red[700], size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ALERTA CRÍTICA',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.red[700],
                              ),
                            ),
                            Text(
                              'Este resultado requiere atención inmediata',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.red[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              // Contenido principal
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Información del paciente y test
                      _buildInfoCard(),
                      const SizedBox(height: 16),

                      // Gráfico de resultados
                      _buildResultChart(),
                      const SizedBox(height: 16),

                      // Interpretación clínica
                      _buildInterpretationCard(),
                      const SizedBox(height: 16),

                      // Recomendaciones
                      _buildRecommendationsCard(),
                      const SizedBox(height: 16),

                      // Detalle de respuestas
                      _buildResponsesCard(),
                      const SizedBox(
                          height: 80), // Espacio para botones flotantes
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            onPressed: _savingToExpediente ? null : _saveToExpediente,
            icon: _savingToExpediente
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(Icons.save),
            label: Text(
                _savingToExpediente ? 'Guardando...' : 'Guardar en Expediente'),
            backgroundColor: Colors.green[600],
            foregroundColor: Colors.white,
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Icon(Icons.psychology),
            backgroundColor: theme.UAGroColors.azulMarino,
            foregroundColor: Colors.white,
            tooltip: 'Aplicar Otro Test',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.UAGroColors.azulMarino.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.assessment,
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
                        widget.test.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.UAGroColors.azulMarino,
                        ),
                      ),
                      Text(
                        'Aplicado el ${DateFormat('dd/MM/yyyy HH:mm').format(widget.result.fechaAplicacion)}',
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
            const SizedBox(height: 16),
            Divider(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child:
                      _buildInfoItem('Paciente', widget.result.nombrePaciente),
                ),
                Expanded(
                  child: _buildInfoItem('Matrícula', widget.result.matricula),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem('Psicólogo', widget.result.psicologo),
                ),
                Expanded(
                  child: _buildInfoItem(
                      'Puntuación', '${widget.result.puntuacionTotal} pts'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.UAGroColors.azulMarino,
          ),
        ),
      ],
    );
  }

  Widget _buildResultChart() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Puntuación del Test',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.UAGroColors.azulMarino,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: _buildHamiltonChart(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHamiltonChart() {
    if (widget.test.testType == TestType.hamilton) {
      return BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 25,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  switch (value.toInt()) {
                    case 0:
                      return Text('Normal\n0-7',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 10));
                    case 1:
                      return Text('Leve\n8-13',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 10));
                    case 2:
                      return Text('Moderada\n14-18',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 10));
                    case 3:
                      return Text('Severa\n19-22',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 10));
                    case 4:
                      return Text('Muy Severa\n23+',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 10));
                    default:
                      return Text('');
                  }
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: [
            _buildBarGroup(
                0, 7, Colors.green[400]!, widget.result.puntuacionTotal <= 7),
            _buildBarGroup(
                1,
                13,
                Colors.yellow[600]!,
                widget.result.puntuacionTotal > 7 &&
                    widget.result.puntuacionTotal <= 13),
            _buildBarGroup(
                2,
                18,
                Colors.orange[600]!,
                widget.result.puntuacionTotal > 13 &&
                    widget.result.puntuacionTotal <= 18),
            _buildBarGroup(
                3,
                22,
                Colors.red[400]!,
                widget.result.puntuacionTotal > 18 &&
                    widget.result.puntuacionTotal <= 22),
            _buildBarGroup(
                4, 25, Colors.red[700]!, widget.result.puntuacionTotal > 22),
          ],
        ),
      );
    }
    return Container(); // Para otros tests
  }

  BarChartGroupData _buildBarGroup(
      int x, double height, Color color, bool isUserScore) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: height,
          color: isUserScore ? color : color.withOpacity(0.3),
          width: 30,
          borderRadius: BorderRadius.circular(4),
        ),
        if (isUserScore)
          BarChartRodData(
            toY: widget.result.puntuacionTotal.toDouble(),
            color: theme.UAGroColors.azulMarino,
            width: 8,
            borderRadius: BorderRadius.circular(4),
          ),
      ],
    );
  }

  Widget _buildInterpretationCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.psychology,
                  color: theme.UAGroColors.azulMarino,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Interpretación Clínica',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.UAGroColors.azulMarino,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.result.alertaCritica
                    ? Colors.red[50]
                    : Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.result.alertaCritica
                      ? Colors.red[200]!
                      : Colors.blue[200]!,
                ),
              ),
              child: Text(
                widget.result.interpretacion,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: Colors.grey[800],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb,
                  color: Colors.orange[600],
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Recomendaciones',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.UAGroColors.azulMarino,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Text(
                widget.result.recomendaciones,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: Colors.grey[800],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsesCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.list_alt,
                  color: theme.UAGroColors.azulMarino,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Detalle de Respuestas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.UAGroColors.azulMarino,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...widget.result.responses.asMap().entries.map((entry) {
              final index = entry.key;
              final response = entry.value;
              final question = widget.test.questions.firstWhere(
                (q) => q.id == response.questionId,
              );

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${index + 1}. ${question.text}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            response.response.toString(),
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.UAGroColors.azulMarino,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color:
                                theme.UAGroColors.azulMarino.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${response.score} pts',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: theme.UAGroColors.azulMarino,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Future<void> _saveToExpediente() async {
    setState(() {
      _savingToExpediente = true;
    });

    try {
      // Crear el contenido de la nota con los resultados del test
      final notaContent = '''
═══════════════════════════════════════════════
${widget.test.name.toUpperCase()}
═══════════════════════════════════════════════

📊 RESULTADOS:
• Puntuación Total: ${widget.result.puntuacionTotal} puntos
• Fecha de Aplicación: ${DateFormat('dd/MM/yyyy HH:mm').format(widget.result.fechaAplicacion)}
• Psicólogo: ${widget.result.psicologo}

🔍 INTERPRETACIÓN CLÍNICA:
${widget.result.interpretacion}

💡 RECOMENDACIONES:
${widget.result.recomendaciones}

${widget.result.alertaCritica ? '🚨 ALERTA CRÍTICA: Este caso requiere atención inmediata\n' : ''}
═══════════════════════════════════════════════
DETALLE DE RESPUESTAS:

${widget.result.responses.asMap().entries.map((entry) {
        final index = entry.key;
        final response = entry.value;
        final question = widget.test.questions
            .firstWhere((q) => q.id == response.questionId);
        return '${index + 1}. ${question.text}\n   Respuesta: ${response.response} (${response.score} pts)\n';
      }).join('\n')}
═══════════════════════════════════════════════
      ''';

      // Guardar como nota en el expediente usando la API existente
      final success = await ApiService.pushSingleNote(
        matricula: widget.result.matricula,
        departamento: 'Departamento psicopedagógico',
        cuerpo: notaContent,
        tratante: widget.result.psicologo,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Test guardado en el expediente exitosamente'),
              ],
            ),
            backgroundColor: Colors.green[600],
            duration: const Duration(seconds: 3),
          ),
        );
      } else if (mounted) {
        throw Exception('Error al guardar en el expediente');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _savingToExpediente = false;
        });
      }
    }
  }

  Future<void> _generatePdf() async {
    setState(() {
      _generatingPdf = true;
    });

    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              // Header institucional
              pw.Container(
                padding: const pw.EdgeInsets.only(bottom: 20),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(width: 2, color: PdfColors.blue900),
                  ),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'UNIVERSIDAD AUTÓNOMA DE GUERRERO',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                    pw.Text(
                      'Centro Regional de Educación Superior - Llano Largo',
                      style: const pw.TextStyle(
                          fontSize: 12, color: PdfColors.grey700),
                    ),
                    pw.Text(
                      'Departamento Psicopedagógico',
                      style: const pw.TextStyle(
                          fontSize: 12, color: PdfColors.grey700),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 30),

              // Título del reporte
              pw.Center(
                child: pw.Text(
                  'REPORTE DE EVALUACIÓN PSICOLÓGICA',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
              ),

              pw.SizedBox(height: 30),

              // Información del paciente
              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(5)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'DATOS DEL PACIENTE',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                  'Nombre: ${widget.result.nombrePaciente}'),
                              pw.Text('Matrícula: ${widget.result.matricula}'),
                            ],
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                  'Fecha: ${DateFormat('dd/MM/yyyy').format(widget.result.fechaAplicacion)}'),
                              pw.Text('Psicólogo: ${widget.result.psicologo}'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Información del test
              pw.Text(
                'INSTRUMENTO APLICADO',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text('${widget.test.name}'),
              pw.Text(
                  'Puntuación Total: ${widget.result.puntuacionTotal} puntos'),

              // Mostrar subescalas si existen (para DASS-21)
              if (widget.result.datosAdicionales != null &&
                  widget.result.datosAdicionales!['subscaleScores'] !=
                      null) ...[
                pw.SizedBox(height: 10),
                pw.Text(
                  'Severidad: ${widget.result.datosAdicionales!['severity']}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  'Puntuaciones por Subescala:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                ...(widget.result.datosAdicionales!['subscaleScores']
                        as Map<String, dynamic>)
                    .entries
                    .map(
                      (entry) =>
                          pw.Text('  • ${entry.key}: ${entry.value} puntos'),
                    ),
              ],

              pw.SizedBox(height: 20),

              // Interpretación
              pw.Text(
                'INTERPRETACIÓN CLÍNICA',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(5)),
                ),
                child: pw.Text(
                  widget.result.interpretacion,
                  style: const pw.TextStyle(fontSize: 11),
                  textAlign: pw.TextAlign.justify,
                ),
              ),

              pw.SizedBox(height: 20),

              // Recomendaciones
              pw.Text(
                'RECOMENDACIONES',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.orange50,
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(5)),
                ),
                child: pw.Text(
                  widget.result.recomendaciones,
                  style: const pw.TextStyle(fontSize: 11),
                  textAlign: pw.TextAlign.justify,
                ),
              ),

              if (widget.result.alertaCritica) ...[
                pw.SizedBox(height: 20),
                pw.Container(
                  padding: const pw.EdgeInsets.all(15),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.red100,
                    border: pw.Border.all(color: PdfColors.red300, width: 2),
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(5)),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        '⚠️ ALERTA CRÍTICA',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.red700,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Este resultado requiere atención inmediata y seguimiento especializado',
                        style:
                            pw.TextStyle(fontSize: 12, color: PdfColors.red600),
                        textAlign: pw.TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],

              pw.SizedBox(height: 40),

              // Firma
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    children: [
                      pw.Container(
                        width: 150,
                        height: 1,
                        color: PdfColors.grey600,
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        widget.result.psicologo,
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.Text(
                        'Psicólogo Clínico',
                        style: const pw.TextStyle(
                            fontSize: 9, color: PdfColors.grey600),
                      ),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Text(
                        'Código de verificación:',
                        style: const pw.TextStyle(
                            fontSize: 8, color: PdfColors.grey600),
                      ),
                      pw.Text(
                        widget.result.id.substring(0, 8).toUpperCase(),
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ];
          },
        ),
      );

      // Generar bytes del PDF
      final pdfBytes = await pdf.save();

      // Nombre del archivo
      final fileName =
          'Test_${widget.test.name.replaceAll(' ', '_')}_${widget.result.matricula}_${DateFormat('yyyyMMdd_HHmmss').format(widget.result.fechaAplicacion)}.pdf';

      // Guardar PDF localmente
      final baseDir = await getApplicationSupportDirectory();
      final pdfDir = Directory(path.join(
          baseDir.path, 'tests_psicologicos', widget.result.matricula));
      if (!await pdfDir.exists()) {
        await pdfDir.create(recursive: true);
      }

      final pdfFile = File(path.join(pdfDir.path, fileName));
      await pdfFile.writeAsBytes(pdfBytes);

      if (mounted) {
        // Mostrar mensaje de éxito con ubicación del archivo
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('✓ PDF guardado exitosamente'),
                const SizedBox(height: 4),
                Text(
                  'Ubicación: tests_psicologicos/${widget.result.matricula}/',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Abrir PDF',
              textColor: Colors.white,
              onPressed: () async {
                await Printing.layoutPdf(
                  onLayout: (PdfPageFormat format) async => pdfBytes,
                  name: fileName,
                );
              },
            ),
          ),
        );

        // Mostrar el PDF automáticamente
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdfBytes,
          name: fileName,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _generatingPdf = false;
        });
      }
    }
  }
}
