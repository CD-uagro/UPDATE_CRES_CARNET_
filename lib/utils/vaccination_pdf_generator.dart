import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class VaccinationPdfGenerator {
  /// Generar PDF con el reporte de vacunación de una campaña
  static Future<File> generateCampaignReport({
    required String campaignName,
    required String vaccine,
    required List<dynamic> records,
    String? description,
    DateTime? startDate,
  }) async {
    final pdf = pw.Document();

    // Obtener directorio de documentos
    final Directory? dir = await getDownloadsDirectory();
    if (dir == null) {
      throw Exception('No se pudo acceder al directorio de descargas');
    }

    // Crear nombre de archivo con timestamp
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final filename = 'reporte_vacunacion_$timestamp.pdf';
    final file = File('${dir.path}/$filename');

    // Construir el PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Encabezado
          _buildHeader(campaignName, vaccine, description, startDate),

          pw.SizedBox(height: 20),

          // Resumen
          _buildSummary(records),

          pw.SizedBox(height: 20),

          // Tabla de registros
          _buildTable(records),

          pw.SizedBox(height: 30),

          // Pie de página
          _buildFooter(),
        ],
      ),
    );

    // Guardar el archivo
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static pw.Widget _buildHeader(
    String campaignName,
    String vaccine,
    String? description,
    DateTime? startDate,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'SASU',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
                pw.Text(
                  'Sistema de Atención en Salud Universitaria',
                  style: pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.Text(
                  'CRES Llano Largo',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: PdfColors.purple100,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'REPORTE DE VACUNACIÓN',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.purple900,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.purple700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        pw.SizedBox(height: 20),
        pw.Divider(color: PdfColors.purple300, thickness: 2),
        pw.SizedBox(height: 16),

        // Información de la campaña
        pw.Text(
          'Campaña: $campaignName',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'Vacuna: $vaccine',
          style: pw.TextStyle(
            fontSize: 14,
            color: PdfColors.grey800,
          ),
        ),
        if (description != null && description.isNotEmpty) ...[
          pw.SizedBox(height: 4),
          pw.Text(
            'Descripción: $description',
            style: const pw.TextStyle(
              fontSize: 12,
              color: PdfColors.grey700,
            ),
          ),
        ],
        if (startDate != null) ...[
          pw.SizedBox(height: 4),
          pw.Text(
            'Fecha de inicio: ${DateFormat('dd/MM/yyyy').format(startDate)}',
            style: const pw.TextStyle(
              fontSize: 12,
              color: PdfColors.grey700,
            ),
          ),
        ],
      ],
    );
  }

  static pw.Widget _buildSummary(List<dynamic> records) {
    final totalRecords = records.length;
    final uniqueStudents = records.map((r) => r['matricula']).toSet().length;

    // Contar por dosis
    final dosisCount = <int, int>{};
    for (var record in records) {
      final dosis = record['dosis'] ?? 1;
      dosisCount[dosis] = (dosisCount[dosis] ?? 0) + 1;
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('Total de Aplicaciones', totalRecords.toString()),
          _buildSummaryItem('Estudiantes Únicos', uniqueStudents.toString()),
          if (dosisCount.isNotEmpty)
            _buildSummaryItem(
              'Dosis más aplicada',
              'Dosis ${dosisCount.entries.reduce((a, b) => a.value > b.value ? a : b).key}',
            ),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryItem(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.purple900,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          label,
          style: const pw.TextStyle(
            fontSize: 10,
            color: PdfColors.grey700,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildTable(List<dynamic> records) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(2),
        4: const pw.FlexColumnWidth(2),
      },
      children: [
        // Encabezado
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            color: PdfColors.purple700,
          ),
          children: [
            _buildTableCell('Matrícula', isHeader: true),
            _buildTableCell('Estudiante', isHeader: true),
            _buildTableCell('Dosis', isHeader: true),
            _buildTableCell('Fecha', isHeader: true),
            _buildTableCell('Aplicado por', isHeader: true),
          ],
        ),

        // Filas de datos
        ...records.map((record) {
          return pw.TableRow(
            children: [
              _buildTableCell(record['matricula'] ?? ''),
              _buildTableCell(record['nombreEstudiante'] ?? 'N/A'),
              _buildTableCell(record['dosis']?.toString() ?? '1'),
              _buildTableCell(
                record['fechaAplicacion'] != null
                    ? DateFormat('dd/MM/yyyy')
                        .format(DateTime.parse(record['fechaAplicacion']))
                    : 'N/A',
              ),
              _buildTableCell(record['aplicadoPor'] ?? 'N/A'),
            ],
          );
        }).toList(),
      ],
    );
  }

  static pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? PdfColors.white : PdfColors.black,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Divider(color: PdfColors.grey400),
        pw.SizedBox(height: 8),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'SASU - Sistema de Atención en Salud Universitaria',
              style: const pw.TextStyle(
                fontSize: 8,
                color: PdfColors.grey600,
              ),
            ),
            pw.Text(
              'CRES Llano Largo',
              style: const pw.TextStyle(
                fontSize: 8,
                color: PdfColors.grey600,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Este documento fue generado automáticamente. Para verificación, contactar al Centro de Recursos de Salud Estudiantil.',
          style: const pw.TextStyle(
            fontSize: 7,
            color: PdfColors.grey500,
          ),
        ),
      ],
    );
  }
}
