import 'package:flutter/material.dart';
import '../../models/tooth_model.dart';
import '../../models/odontogram_model.dart';
import '../../ui/uagro_theme.dart' as theme;
import '../../data/auth_service.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

class OdontogramScreen extends StatefulWidget {
  final String matricula;
  final String nombrePaciente;

  const OdontogramScreen({
    super.key,
    required this.matricula,
    required this.nombrePaciente,
  });

  @override
  State<OdontogramScreen> createState() => _OdontogramScreenState();
}

class _OdontogramScreenState extends State<OdontogramScreen> {
  Odontogram? _odontogram;
  int? _selectedToothNumber;
  ToothSurface? _selectedSurface;
  ToothCondition _selectedCondition = ToothCondition.caries;
  DentitionType _dentitionType = DentitionType.permanent;
  bool _isGeneratingPdf = false;
  bool _isLoading = true;

  final TextEditingController _observacionesController =
      TextEditingController();
  final TextEditingController _diagnosticoController = TextEditingController();
  final TextEditingController _planTratamientoController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _showDentitionTypeDialog();
  }

  Future<void> _showDentitionTypeDialog() async {
    final result = await showDialog<DentitionType>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Tipo de Odontograma'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Seleccione el tipo de dentición:'),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.child_care, color: Colors.blue),
              title: const Text('Dentición Decidua'),
              subtitle: const Text('Infantil - 20 dientes (FDI 51-85)'),
              onTap: () => Navigator.pop(context, DentitionType.deciduous),
            ),
            ListTile(
              leading: const Icon(Icons.person, color: Colors.green),
              title: const Text('Dentición Permanente'),
              subtitle: const Text('Adulto - 32 dientes (FDI 11-48)'),
              onTap: () => Navigator.pop(context, DentitionType.permanent),
            ),
          ],
        ),
      ),
    );

    setState(() {
      _dentitionType = result ?? DentitionType.permanent;
    });

    await _initializeOdontogram();
  }

  Future<void> _initializeOdontogram() async {
    final user = await AuthService.getCurrentUser();
    final dentista = user?.nombreCompleto ?? 'Dr. Sin Nombre';
    setState(() {
      _odontogram = Odontogram(
        matricula: widget.matricula,
        nombrePaciente: widget.nombrePaciente,
        dentista: dentista,
        dentitionType: _dentitionType,
      );
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _observacionesController.dispose();
    _diagnosticoController.dispose();
    _planTratamientoController.dispose();
    super.dispose();
  }

  void _applyConditionToSurface() {
    if (_selectedToothNumber == null || _odontogram == null) return;

    setState(() {
      final tooth = _odontogram!.teeth[_selectedToothNumber!]!;

      if (_selectedSurface != null) {
        // Aplicar a superficie específica
        tooth.surfaces[_selectedSurface!]!.condition = _selectedCondition;
      } else {
        // Aplicar a todo el diente
        if (_selectedCondition == ToothCondition.extraction) {
          tooth.isPresent = false;
        } else {
          tooth.isPresent = true;
          for (var surface in tooth.surfaces.values) {
            surface.condition = _selectedCondition;
          }
        }
      }
    });
  }

  void _clearTooth() {
    if (_selectedToothNumber == null || _odontogram == null) return;

    setState(() {
      final tooth = _odontogram!.teeth[_selectedToothNumber!]!;
      tooth.isPresent = true;
      for (var surface in tooth.surfaces.values) {
        surface.condition = ToothCondition.healthy;
      }
      // Forzar rebuild inmediato
      _selectedSurface = null;
    });

    // Feedback visual
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✓ Diente $_selectedToothNumber limpiado'),
        duration: const Duration(milliseconds: 800),
        behavior: SnackBarBehavior.floating,
        width: 200,
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _odontogram == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Odontograma Profesional',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: theme.UAGroColors.azulMarino,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Odontograma Profesional',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.UAGroColors.azulMarino,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Botón para cambiar tipo de dentición
          PopupMenuButton<DentitionType>(
            icon: Icon(
              _dentitionType == DentitionType.deciduous
                  ? Icons.child_care
                  : Icons.person,
              color: Colors.white,
            ),
            tooltip: 'Cambiar tipo de dentición',
            onSelected: (type) async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('¿Cambiar tipo de dentición?'),
                  content: Text(
                    type == DentitionType.deciduous
                        ? 'Esto cambiará a dentición decidua (infantil, 20 dientes).\n\nSe perderán los datos actuales del odontograma.'
                        : 'Esto cambiará a dentición permanente (adulto, 32 dientes).\n\nSe perderán los datos actuales del odontograma.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.UAGroColors.azulMarino,
                      ),
                      child: const Text('Cambiar'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                setState(() {
                  _dentitionType = type;
                  _selectedToothNumber = null;
                  _selectedSurface = null;
                });
                await _initializeOdontogram();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: DentitionType.deciduous,
                enabled: _dentitionType != DentitionType.deciduous,
                child: const Row(
                  children: [
                    Icon(Icons.child_care, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Dentición Decidua (20 dientes)'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: DentitionType.permanent,
                enabled: _dentitionType != DentitionType.permanent,
                child: const Row(
                  children: [
                    Icon(Icons.person, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Dentición Permanente (32 dientes)'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: _isGeneratingPdf ? null : _generatePdf,
            icon: _isGeneratingPdf
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.picture_as_pdf),
            tooltip: 'Generar PDF',
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).pop(_odontogram);
            },
            icon: const Icon(Icons.check),
            tooltip: 'Guardar y Salir',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.UAGroColors.azulMarino.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: Row(
          children: [
            // Panel izquierdo: Herramientas
            Container(
              width: 260,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(2, 0),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildToolsPanel(),
                  const Divider(height: 1),
                  Expanded(child: _buildLegend()),
                ],
              ),
            ),

            // Centro: Odontograma
            Expanded(
              flex: 4,
              child: Column(
                children: [
                  _buildPatientInfo(),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: _buildOdontogram(),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Panel derecho: Detalles y observaciones
            Container(
              width: 300,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(-2, 0),
                  ),
                ],
              ),
              child: _buildDetailsPanel(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.UAGroColors.azulMarino.withOpacity(0.05),
        border: Border(
          bottom:
              BorderSide(color: theme.UAGroColors.azulMarino.withOpacity(0.2)),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.person, color: theme.UAGroColors.azulMarino),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.nombrePaciente,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.UAGroColors.azulMarino,
                  ),
                ),
                Text(
                  'Matrícula: ${widget.matricula} • ${DateFormat('dd/MM/yyyy').format(_odontogram!.fecha)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            DateFormat('HH:mm').format(_odontogram!.fecha),
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildToolsPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Herramientas',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.UAGroColors.azulMarino,
            ),
          ),
          const SizedBox(height: 16),

          // Selector de condición - Grid organizado
          Text(
            'Seleccionar tratamiento:',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),

          // Grid de tratamientos más ordenado
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.2,
            children: ToothCondition.values
                .where((c) => c != ToothCondition.healthy)
                .map((condition) {
              final isSelected = _selectedCondition == condition;
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedCondition = condition;
                  });
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? ToothConditionColors.getColor(condition)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected
                          ? theme.UAGroColors.azulMarino
                          : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (ToothConditionColors.getSymbol(condition).isNotEmpty)
                        Text(
                          ToothConditionColors.getSymbol(condition),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _getContrastColor(isSelected
                                ? ToothConditionColors.getColor(condition)
                                : Colors.grey[100]!),
                          ),
                        ),
                      const SizedBox(height: 2),
                      Text(
                        ToothConditionColors.getLabel(condition),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color: _getContrastColor(isSelected
                              ? ToothConditionColors.getColor(condition)
                              : Colors.grey[100]!),
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Botones de acción
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _selectedToothNumber != null
                  ? _applyConditionToSurface
                  : null,
              icon: const Icon(Icons.brush),
              label: const Text('Aplicar al Diente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.UAGroColors.azulMarino,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _selectedToothNumber != null ? _clearTooth : null,
              icon: const Icon(Icons.cleaning_services),
              label: const Text('Limpiar Diente'),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.UAGroColors.azulMarino,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          if (_selectedToothNumber != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.UAGroColors.azulMarino.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Diente Seleccionado:',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'FDI $_selectedToothNumber',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.UAGroColors.azulMarino,
                    ),
                  ),
                  Text(
                    ToothNames.getName(_selectedToothNumber!, _dentitionType),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOdontogram() {
    // Determinar números de dientes según tipo de dentición
    List<int> upperRight, upperLeft, lowerLeft, lowerRight;

    if (_dentitionType == DentitionType.deciduous) {
      // Dentición decidua: 51-55, 61-65, 71-75, 81-85
      upperRight = [55, 54, 53, 52, 51];
      upperLeft = [61, 62, 63, 64, 65];
      lowerRight = [85, 84, 83, 82, 81];
      lowerLeft = [71, 72, 73, 74, 75];
    } else {
      // Dentición permanente: 11-18, 21-28, 31-38, 41-48
      upperRight = [18, 17, 16, 15, 14, 13, 12, 11];
      upperLeft = [21, 22, 23, 24, 25, 26, 27, 28];
      lowerRight = [48, 47, 46, 45, 44, 43, 42, 41];
      lowerLeft = [31, 32, 33, 34, 35, 36, 37, 38];
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Indicador de tipo de dentición
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _dentitionType == DentitionType.deciduous
                  ? Colors.blue.withOpacity(0.1)
                  : Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _dentitionType == DentitionType.deciduous
                    ? Colors.blue
                    : Colors.green,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _dentitionType == DentitionType.deciduous
                      ? Icons.child_care
                      : Icons.person,
                  size: 16,
                  color: _dentitionType == DentitionType.deciduous
                      ? Colors.blue
                      : Colors.green,
                ),
                const SizedBox(width: 6),
                Text(
                  _dentitionType == DentitionType.deciduous
                      ? 'DENTICIÓN DECIDUA (20 dientes)'
                      : 'DENTICIÓN PERMANENTE (32 dientes)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _dentitionType == DentitionType.deciduous
                        ? Colors.blue
                        : Colors.green,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Arcada superior
          Text(
            'ARCADA SUPERIOR',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),

          // Cuadrantes superiores
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Cuadrante superior derecho
              ...upperRight.map((fdiNumber) {
                return _buildToothWidget(fdiNumber, isUpper: true);
              }),

              const SizedBox(width: 24),

              // Cuadrante superior izquierdo
              ...upperLeft.map((fdiNumber) {
                return _buildToothWidget(fdiNumber, isUpper: true);
              }),
            ],
          ),

          const SizedBox(height: 48),

          // Línea media
          Container(
            height: 2,
            width: _dentitionType == DentitionType.deciduous ? 400 : 600,
            color: Colors.grey[300],
          ),

          const SizedBox(height: 48),

          // Cuadrantes inferiores
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Cuadrante inferior derecho (invertido)
              ...lowerRight.reversed.map((fdiNumber) {
                return _buildToothWidget(fdiNumber, isUpper: false);
              }),

              const SizedBox(width: 24),

              // Cuadrante inferior izquierdo (invertido)
              ...lowerLeft.reversed.map((fdiNumber) {
                return _buildToothWidget(fdiNumber, isUpper: false);
              }),
            ],
          ),

          const SizedBox(height: 16),
          Text(
            'ARCADA INFERIOR',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToothWidget(int fdiNumber, {required bool isUpper}) {
    final tooth = _odontogram!.teeth[fdiNumber]!;
    final isSelected = _selectedToothNumber == fdiNumber;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        children: [
          // Número FDI arriba
          if (isUpper)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                fdiNumber.toString(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? theme.UAGroColors.azulMarino
                      : Colors.grey[600],
                ),
              ),
            ),

          // Diente visual - ahora con detección por superficie
          GestureDetector(
            onTapDown: (details) {
              final localPosition = details.localPosition;
              final toothSize = const Size(60, 80);

              // Detectar en qué superficie se hizo clic
              final surface =
                  _detectSurfaceFromPosition(localPosition, toothSize);

              setState(() {
                _selectedToothNumber = fdiNumber;
                _selectedSurface = surface;

                // Aplicar inmediatamente el color a la superficie clickeada
                if (surface != null) {
                  tooth.surfaces[surface]!.condition = _selectedCondition;
                }
              });
            },
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: CustomPaint(
                size: const Size(60, 80),
                painter: ToothPainter(
                  tooth: tooth,
                  isSelected: isSelected,
                  selectedSurface: _selectedSurface,
                  selectedCondition: _selectedCondition,
                ),
              ),
            ),
          ),

          // Número FDI abajo
          if (!isUpper)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                fdiNumber.toString(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? theme.UAGroColors.azulMarino
                      : Colors.grey[600],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Detectar en qué superficie del diente se hizo clic
  ToothSurface? _detectSurfaceFromPosition(Offset position, Size toothSize) {
    final centerX = toothSize.width / 2;
    final centerY = toothSize.height / 2;
    final relX = position.dx - centerX;
    final relY = position.dy - centerY;

    // Área central = Oclusal
    if (relX.abs() < toothSize.width * 0.15 &&
        relY.abs() < toothSize.height * 0.15) {
      return ToothSurface.oclusal;
    }

    // Determinar superficie según posición
    if (relY < -toothSize.height * 0.15) {
      return ToothSurface.vestibular; // Arriba
    } else if (relY > toothSize.height * 0.15) {
      return ToothSurface.lingual; // Abajo
    } else if (relX < -toothSize.width * 0.15) {
      return ToothSurface.mesial; // Izquierda
    } else if (relX > toothSize.width * 0.15) {
      return ToothSurface.distal; // Derecha
    }

    return ToothSurface.oclusal; // Por defecto
  }

  Widget _buildDetailsPanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Observaciones Clínicas',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.UAGroColors.azulMarino,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _diagnosticoController,
            decoration: InputDecoration(
              labelText: 'Diagnóstico',
              hintText: 'Diagnóstico general del paciente...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon:
                  Icon(Icons.assignment, color: theme.UAGroColors.azulMarino),
            ),
            maxLines: 3,
            onChanged: (value) {
              _odontogram!.diagnostico = value;
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _planTratamientoController,
            decoration: InputDecoration(
              labelText: 'Plan de Tratamiento',
              hintText: 'Descripción del plan de tratamiento...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: Icon(Icons.medical_services,
                  color: theme.UAGroColors.azulMarino),
            ),
            maxLines: 4,
            onChanged: (value) {
              _odontogram!.planTratamiento = value;
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _observacionesController,
            decoration: InputDecoration(
              labelText: 'Observaciones Generales',
              hintText: 'Notas adicionales...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: Icon(Icons.note, color: theme.UAGroColors.azulMarino),
            ),
            maxLines: 5,
            onChanged: (value) {
              _odontogram!.observacionesGenerales = value;
            },
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          Text(
            'Estadísticas',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.UAGroColors.azulMarino,
            ),
          ),
          const SizedBox(height: 12),
          _buildStatistics(),
        ],
      ),
    );
  }

  Widget _buildStatistics() {
    final stats = _odontogram!.getStatistics();
    final relevantStats = stats.entries.where((e) => e.value > 0).toList();

    if (relevantStats.isEmpty) {
      return Text(
        'Sin hallazgos registrados',
        style: TextStyle(color: Colors.grey[600], fontSize: 14),
      );
    }

    return Column(
      children: relevantStats.map((entry) {
        final condition =
            ToothCondition.values.firstWhere((c) => c.name == entry.key);
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: ToothConditionColors.getColor(condition),
                  border: Border.all(color: Colors.grey[400]!),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    ToothConditionColors.getSymbol(condition),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _getContrastColor(
                          ToothConditionColors.getColor(condition)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ToothConditionColors.getLabel(condition),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.UAGroColors.azulMarino.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${entry.value}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: theme.UAGroColors.azulMarino,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLegend() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Leyenda',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.UAGroColors.azulMarino,
            ),
          ),
          const SizedBox(height: 12),
          ...ToothCondition.values.map((condition) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: ToothConditionColors.getColor(condition),
                      border: Border.all(color: Colors.grey[400]!),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Text(
                        ToothConditionColors.getSymbol(condition),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _getContrastColor(
                              ToothConditionColors.getColor(condition)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      ToothConditionColors.getLabel(condition),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _getContrastColor(Color background) {
    final luminance = background.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  Future<void> _generatePdf() async {
    setState(() {
      _isGeneratingPdf = true;
    });

    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape, // A4 horizontal: 842 x 595 pt
          margin: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          build: (pw.Context context) {
            return [
              // Header compacto
              pw.Container(
                padding: const pw.EdgeInsets.only(bottom: 12),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(width: 2, color: PdfColors.blue900),
                  ),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'UNIVERSIDAD AUTÓNOMA DE GUERRERO',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                        ),
                        pw.Text(
                          'Centro Regional de Educación Superior',
                          style: const pw.TextStyle(
                              fontSize: 11, color: PdfColors.grey700),
                        ),
                        pw.Text(
                          'Departamento de Odontología',
                          style: const pw.TextStyle(
                              fontSize: 11, color: PdfColors.grey700),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'ODONTOGRAMA',
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                        ),
                        pw.Text(
                          DateFormat('dd/MM/yyyy HH:mm')
                              .format(_odontogram!.fecha),
                          style: const pw.TextStyle(
                              fontSize: 10, color: PdfColors.grey600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 10),

              // Información del paciente compacta
              pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(5)),
                  color: PdfColors.grey50,
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Paciente: ${_odontogram!.nombrePaciente}',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    pw.Text('Matrícula: ${_odontogram!.matricula}',
                        style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('Dentista: ${_odontogram!.dentista}',
                        style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ),

              pw.SizedBox(height: 12),

              // ODONTOGRAMA VISUAL
              pw.Text(
                'ODONTOGRAMA VISUAL',
                style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900),
              ),
              pw.SizedBox(height: 15),

              // Tipo de dentición
              pw.Center(
                child: pw.Text(
                  _dentitionType == DentitionType.deciduous
                      ? 'DENTICIÓN DECIDUA (20 dientes - FDI 51-85)'
                      : 'DENTICIÓN PERMANENTE (32 dientes - FDI 11-48)',
                  style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue),
                ),
              ),
              pw.SizedBox(height: 10),

              // Arcada Superior
              pw.Center(
                child: pw.Text('ARCADA SUPERIOR',
                    style: const pw.TextStyle(
                        fontSize: 10, color: PdfColors.grey600)),
              ),
              pw.SizedBox(height: 10),

              // Contenedor del odontograma optimizado para A4 horizontal (842pt ancho)
              pw.Container(
                width: double.infinity,
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.blue900, width: 1.5),
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(8)),
                  color: PdfColors.grey50,
                ),
                child: pw.Column(
                  children: [
                    // Cuadrantes superiores
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: _dentitionType == DentitionType.deciduous
                          ? [
                              // Cuadrante 5 (55-51)
                              ...[55, 54, 53, 52, 51]
                                  .map((fdi) => _buildPdfTooth(fdi)),
                              pw.SizedBox(width: 30),
                              // Cuadrante 6 (61-65)
                              ...[61, 62, 63, 64, 65]
                                  .map((fdi) => _buildPdfTooth(fdi)),
                            ]
                          : [
                              // Cuadrante 1 (18-11)
                              ...[18, 17, 16, 15, 14, 13, 12, 11]
                                  .map((fdi) => _buildPdfTooth(fdi)),
                              pw.SizedBox(width: 30),
                              // Cuadrante 2 (21-28)
                              ...[21, 22, 23, 24, 25, 26, 27, 28]
                                  .map((fdi) => _buildPdfTooth(fdi)),
                            ],
                    ),

                    pw.SizedBox(height: 14),

                    // Línea media más definida y centrada
                    pw.Container(
                      height: 3,
                      width:
                          _dentitionType == DentitionType.deciduous ? 420 : 640,
                      decoration: pw.BoxDecoration(
                        color: PdfColors.blue900,
                        borderRadius:
                            const pw.BorderRadius.all(pw.Radius.circular(2)),
                      ),
                    ),

                    pw.SizedBox(height: 14),

                    // Cuadrantes inferiores
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: _dentitionType == DentitionType.deciduous
                          ? [
                              // Cuadrante 8 (85-81)
                              ...[85, 84, 83, 82, 81]
                                  .reversed
                                  .map((fdi) => _buildPdfTooth(fdi)),
                              pw.SizedBox(width: 30),
                              // Cuadrante 7 (71-75)
                              ...[71, 72, 73, 74, 75]
                                  .reversed
                                  .map((fdi) => _buildPdfTooth(fdi)),
                            ]
                          : [
                              // Cuadrante 4 (48-41)
                              ...[48, 47, 46, 45, 44, 43, 42, 41]
                                  .reversed
                                  .map((fdi) => _buildPdfTooth(fdi)),
                              pw.SizedBox(width: 30),
                              // Cuadrante 3 (31-38)
                              ...[31, 32, 33, 34, 35, 36, 37, 38]
                                  .reversed
                                  .map((fdi) => _buildPdfTooth(fdi)),
                            ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Text('ARCADA INFERIOR',
                    style: const pw.TextStyle(
                        fontSize: 10, color: PdfColors.grey600)),
              ),

              pw.SizedBox(height: 10),

              // Leyenda compacta en 2 filas para aprovechar ancho horizontal
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.blue900, width: 1),
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(6)),
                  color: PdfColors.blue50,
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'LEYENDA DE CONDICIONES:',
                      style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900),
                    ),
                    pw.SizedBox(height: 6),
                    // Primera fila
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                      children: [
                        _buildLegendItem('Sano', PdfColors.white),
                        _buildLegendItem('Caries', PdfColors.black),
                        _buildLegendItem(
                            'Restauración', const PdfColor(0.2, 0.4, 0.8)),
                        _buildLegendItem(
                            'Extracción', const PdfColor(0.9, 0.1, 0.1)),
                        _buildLegendItem(
                            'Endodoncia', const PdfColor(1.0, 0.5, 0.0)),
                        _buildLegendItem(
                            'Corona', const PdfColor(1.0, 0.85, 0.0)),
                        _buildLegendItem(
                            'Puente', const PdfColor(0.6, 0.2, 0.8)),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                    // Segunda fila
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                      children: [
                        _buildLegendItem(
                            'Implante', const PdfColor(0.0, 0.8, 0.8)),
                        _buildLegendItem(
                            'Fractura', const PdfColor(1.0, 0.4, 0.7)),
                        _buildLegendItem(
                            'Absceso', const PdfColor(0.9, 0.3, 0.0)),
                        _buildLegendItem(
                            'Cálculo', const PdfColor(0.5, 0.35, 0.2)),
                        _buildLegendItem(
                            'Gingivitis', const PdfColor(0.9, 0.5, 0.5)),
                        _buildLegendItem(
                            'Movilidad', const PdfColor(0.6, 0.6, 0.6)),
                        _buildLegendItem(
                            'Por Extraer', const PdfColor(0.85, 0.0, 0.0)),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 10),

              // Hallazgos detallados
              pw.Text(
                'Hallazgos Clínicos Detallados:',
                style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900),
              ),
              pw.SizedBox(height: 6),

              ...(_odontogram!.getProblematicTeeth().map((tooth) {
                final conditions = <String>[];
                for (var surface in tooth.surfaces.entries) {
                  if (surface.value.condition != ToothCondition.healthy) {
                    conditions.add(
                        '${_getSurfaceLabel(surface.key)}: ${ToothConditionColors.getLabel(surface.value.condition)}');
                  }
                }
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Text(
                      '• Diente ${tooth.fdiNumber} (${tooth.name}): ${conditions.join(', ')}',
                      style: const pw.TextStyle(fontSize: 10)),
                );
              })),

              pw.SizedBox(height: 20),

              if (_odontogram!.diagnostico.isNotEmpty) ...[
                pw.Text('Diagnóstico:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 5),
                pw.Text(_odontogram!.diagnostico),
                pw.SizedBox(height: 15),
              ],

              if (_odontogram!.planTratamiento.isNotEmpty) ...[
                pw.Text('Plan de Tratamiento:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 5),
                pw.Text(_odontogram!.planTratamiento),
                pw.SizedBox(height: 15),
              ],

              if (_odontogram!.observacionesGenerales.isNotEmpty) ...[
                pw.Text('Observaciones:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 5),
                pw.Text(_odontogram!.observacionesGenerales),
              ],
            ];
          },
        ),
      );

      final pdfBytes = await pdf.save();
      final fileName =
          'Odontograma_${_odontogram!.matricula}_${DateFormat('yyyyMMdd_HHmmss').format(_odontogram!.fecha)}.pdf';

      // Guardar localmente
      final baseDir = await getApplicationSupportDirectory();
      final pdfDir = Directory(
          path.join(baseDir.path, 'odontogramas', _odontogram!.matricula));
      if (!await pdfDir.exists()) {
        await pdfDir.create(recursive: true);
      }

      final pdfFile = File(path.join(pdfDir.path, fileName));
      await pdfFile.writeAsBytes(pdfBytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '✓ PDF guardado en: odontogramas/${_odontogram!.matricula}/'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Mostrar el PDF FORZANDO orientación horizontal
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async {
            // Retornar el PDF con el formato landscape original
            return pdfBytes;
          },
          name: fileName,
          format: PdfPageFormat.a4.landscape, // FORZAR horizontal al visualizar
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
          _isGeneratingPdf = false;
        });
      }
    }
  }

  // Construir diente para PDF optimizado para A4 horizontal
  pw.Widget _buildPdfTooth(int fdiNumber) {
    final tooth = _odontogram!.teeth[fdiNumber]!;

    // Tamaño optimizado: A4 horizontal tiene 842pt de ancho
    // Con márgenes de 40pt quedan 802pt
    // Para 16 dientes + espacios: ~45pt por diente
    final toothWidth = _dentitionType == DentitionType.deciduous ? 36.0 : 32.0;
    final toothHeight = _dentitionType == DentitionType.deciduous ? 48.0 : 44.0;

    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 1.5),
      child: pw.Column(
        children: [
          // Número FDI más legible
          pw.Text(
            fdiNumber.toString(),
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.black,
            ),
          ),
          pw.SizedBox(height: 2),

          // Diente visual más grande para A4 horizontal
          pw.Container(
            width: toothWidth,
            height: toothHeight,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
            ),
            child: pw.CustomPaint(
              painter: (PdfGraphics canvas, PdfPoint size) {
                _drawPdfTooth(canvas, size, tooth);
              },
            ),
          ),
        ],
      ),
    );
  }

  // Dibujar diente en PDF con mayor precisión y claridad
  void _drawPdfTooth(PdfGraphics canvas, PdfPoint size, Tooth tooth) {
    if (!tooth.isPresent) {
      // Dibujar X para diente ausente con mayor grosor
      canvas
        ..setStrokeColor(PdfColors.red)
        ..setLineWidth(2.5)
        ..drawLine(3, 3, size.x - 3, size.y - 3)
        ..drawLine(size.x - 3, 3, 3, size.y - 3)
        ..strokePath();
      return;
    }

    // Usar coordenadas más precisas con margen interno
    final margin = 2.0;
    final centerX = size.x / 2;
    final centerY = size.y / 2;
    final w = (size.x - margin * 2) * 0.8;
    final h = (size.y - margin * 2) * 0.75;

    // SUPERFICIE OCLUSAL (centro) - círculo más grande y definido
    final oclusalColor =
        _getPdfColor(tooth.surfaces[ToothSurface.oclusal]!.condition);
    final oclusalRadiusX = w * 0.22;
    final oclusalRadiusY = h * 0.22;
    canvas
      ..setFillColor(oclusalColor)
      ..drawEllipse(centerX - oclusalRadiusX, centerY - oclusalRadiusY,
          oclusalRadiusX * 2, oclusalRadiusY * 2)
      ..fillPath();

    // SUPERFICIE VESTIBULAR (arriba) - trapecio bien definido
    final vestibularColor =
        _getPdfColor(tooth.surfaces[ToothSurface.vestibular]!.condition);
    canvas
      ..setFillColor(vestibularColor)
      ..moveTo(centerX - w * 0.28, centerY - h * 0.12)
      ..lineTo(centerX + w * 0.28, centerY - h * 0.12)
      ..lineTo(centerX + w * 0.35, centerY - h * 0.5)
      ..lineTo(centerX - w * 0.35, centerY - h * 0.5)
      ..closePath()
      ..fillPath();

    // SUPERFICIE LINGUAL (abajo) - trapecio simétrico al vestibular
    final lingualColor =
        _getPdfColor(tooth.surfaces[ToothSurface.lingual]!.condition);
    canvas
      ..setFillColor(lingualColor)
      ..moveTo(centerX - w * 0.28, centerY + h * 0.12)
      ..lineTo(centerX + w * 0.28, centerY + h * 0.12)
      ..lineTo(centerX + w * 0.35, centerY + h * 0.5)
      ..lineTo(centerX - w * 0.35, centerY + h * 0.5)
      ..closePath()
      ..fillPath();

    // SUPERFICIE MESIAL (izquierda) - más ancha y visible
    final mesialColor =
        _getPdfColor(tooth.surfaces[ToothSurface.mesial]!.condition);
    canvas
      ..setFillColor(mesialColor)
      ..moveTo(centerX - w * 0.28, centerY - h * 0.12)
      ..lineTo(centerX - w * 0.28, centerY + h * 0.12)
      ..lineTo(centerX - w * 0.48, centerY + h * 0.2)
      ..lineTo(centerX - w * 0.48, centerY - h * 0.2)
      ..closePath()
      ..fillPath();

    // SUPERFICIE DISTAL (derecha) - simétrica a mesial
    final distalColor =
        _getPdfColor(tooth.surfaces[ToothSurface.distal]!.condition);
    canvas
      ..setFillColor(distalColor)
      ..moveTo(centerX + w * 0.28, centerY - h * 0.12)
      ..lineTo(centerX + w * 0.28, centerY + h * 0.12)
      ..lineTo(centerX + w * 0.48, centerY + h * 0.2)
      ..lineTo(centerX + w * 0.48, centerY - h * 0.2)
      ..closePath()
      ..fillPath();

    // BORDES más gruesos y visibles
    canvas
      ..setStrokeColor(PdfColors.black)
      ..setLineWidth(1.2);

    // Borde oclusal (centro)
    canvas
      ..drawEllipse(centerX - oclusalRadiusX, centerY - oclusalRadiusY,
          oclusalRadiusX * 2, oclusalRadiusY * 2)
      ..strokePath();

    // Borde vestibular (arriba)
    canvas
      ..moveTo(centerX - w * 0.28, centerY - h * 0.12)
      ..lineTo(centerX + w * 0.28, centerY - h * 0.12)
      ..lineTo(centerX + w * 0.35, centerY - h * 0.5)
      ..lineTo(centerX - w * 0.35, centerY - h * 0.5)
      ..closePath()
      ..strokePath();

    // Borde lingual (abajo)
    canvas
      ..moveTo(centerX - w * 0.28, centerY + h * 0.12)
      ..lineTo(centerX + w * 0.28, centerY + h * 0.12)
      ..lineTo(centerX + w * 0.35, centerY + h * 0.5)
      ..lineTo(centerX - w * 0.35, centerY + h * 0.5)
      ..closePath()
      ..strokePath();

    // Borde mesial (izquierda)
    canvas
      ..moveTo(centerX - w * 0.28, centerY - h * 0.12)
      ..lineTo(centerX - w * 0.28, centerY + h * 0.12)
      ..lineTo(centerX - w * 0.48, centerY + h * 0.2)
      ..lineTo(centerX - w * 0.48, centerY - h * 0.2)
      ..closePath()
      ..strokePath();

    // Borde distal (derecha)
    canvas
      ..moveTo(centerX + w * 0.28, centerY - h * 0.12)
      ..lineTo(centerX + w * 0.28, centerY + h * 0.12)
      ..lineTo(centerX + w * 0.48, centerY + h * 0.2)
      ..lineTo(centerX + w * 0.48, centerY - h * 0.2)
      ..closePath()
      ..strokePath();
  }

  // Convertir ToothCondition a PdfColor con colores más vibrantes y fieles
  PdfColor _getPdfColor(ToothCondition condition) {
    switch (condition) {
      case ToothCondition.healthy:
        return PdfColors.white;
      case ToothCondition.caries:
        return PdfColors.black; // Negro sólido para caries
      case ToothCondition.restoration:
        return const PdfColor(0.2, 0.4, 0.8); // Azul más vibrante
      case ToothCondition.extraction:
        return const PdfColor(0.9, 0.1, 0.1); // Rojo intenso
      case ToothCondition.endodontics:
        return const PdfColor(1.0, 0.5, 0.0); // Naranja vibrante
      case ToothCondition.crown:
        return const PdfColor(1.0, 0.85, 0.0); // Amarillo dorado
      case ToothCondition.bridge:
        return const PdfColor(0.6, 0.2, 0.8); // Púrpura intenso
      case ToothCondition.implant:
        return const PdfColor(0.0, 0.8, 0.8); // Cian brillante
      case ToothCondition.fracture:
        return const PdfColor(1.0, 0.4, 0.7); // Rosa intenso
      case ToothCondition.abscess:
        return const PdfColor(0.9, 0.3, 0.0); // Naranja rojizo
      case ToothCondition.calculus:
        return const PdfColor(0.5, 0.35, 0.2); // Marrón definido
      case ToothCondition.gingivitis:
        return const PdfColor(0.9, 0.5, 0.5); // Rojo claro
      case ToothCondition.mobility:
        return const PdfColor(0.6, 0.6, 0.6); // Gris medio
      case ToothCondition.toExtract:
        return const PdfColor(0.85, 0.0, 0.0); // Rojo oscuro
    }
  }

  // Construir item de leyenda compacto
  pw.Widget _buildLegendItem(String label, PdfColor color) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Container(
          width: 14,
          height: 14,
          decoration: pw.BoxDecoration(
            color: color,
            border: pw.Border.all(color: PdfColors.black, width: 0.8),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
          ),
        ),
        pw.SizedBox(width: 4),
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 8,
            fontWeight: pw.FontWeight.normal,
            color: PdfColors.black,
          ),
        ),
      ],
    );
  }

  // Obtener etiqueta de superficie
  String _getSurfaceLabel(ToothSurface surface) {
    switch (surface) {
      case ToothSurface.oclusal:
        return 'Oclusal';
      case ToothSurface.vestibular:
        return 'Vestibular';
      case ToothSurface.lingual:
        return 'Lingual';
      case ToothSurface.mesial:
        return 'Mesial';
      case ToothSurface.distal:
        return 'Distal';
    }
  }
}

/// CustomPainter para dibujar cada diente con sus superficies
class ToothPainter extends CustomPainter {
  final Tooth tooth;
  final bool isSelected;
  final ToothSurface? selectedSurface;
  final ToothCondition? selectedCondition;

  ToothPainter({
    required this.tooth,
    required this.isSelected,
    this.selectedSurface,
    this.selectedCondition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 2;

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final toothWidth = size.width * 0.8;
    final toothHeight = size.height * 0.7;

    // Si el diente no está presente, dibujar X
    if (!tooth.isPresent) {
      paint.color = Colors.red;
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 3;

      canvas.drawLine(
        Offset(centerX - 20, centerY - 20),
        Offset(centerX + 20, centerY + 20),
        paint,
      );
      canvas.drawLine(
        Offset(centerX + 20, centerY - 20),
        Offset(centerX - 20, centerY + 20),
        paint,
      );
      return;
    }

    // Dibujar superficies del diente
    final surfaces = [
      // Oclusal (centro)
      _ToothSurfacePath(
        surface: ToothSurface.oclusal,
        path: Path()
          ..addOval(Rect.fromCenter(
            center: Offset(centerX, centerY),
            width: toothWidth * 0.4,
            height: toothHeight * 0.4,
          )),
      ),

      // Vestibular (arriba)
      _ToothSurfacePath(
        surface: ToothSurface.vestibular,
        path: Path()
          ..moveTo(centerX - toothWidth * 0.3, centerY - toothHeight * 0.15)
          ..lineTo(centerX + toothWidth * 0.3, centerY - toothHeight * 0.15)
          ..lineTo(centerX + toothWidth * 0.35, centerY - toothHeight * 0.45)
          ..lineTo(centerX - toothWidth * 0.35, centerY - toothHeight * 0.45)
          ..close(),
      ),

      // Lingual (abajo)
      _ToothSurfacePath(
        surface: ToothSurface.lingual,
        path: Path()
          ..moveTo(centerX - toothWidth * 0.3, centerY + toothHeight * 0.15)
          ..lineTo(centerX + toothWidth * 0.3, centerY + toothHeight * 0.15)
          ..lineTo(centerX + toothWidth * 0.35, centerY + toothHeight * 0.45)
          ..lineTo(centerX - toothWidth * 0.35, centerY + toothHeight * 0.45)
          ..close(),
      ),

      // Mesial (izquierda)
      _ToothSurfacePath(
        surface: ToothSurface.mesial,
        path: Path()
          ..moveTo(centerX - toothWidth * 0.3, centerY - toothHeight * 0.15)
          ..lineTo(centerX - toothWidth * 0.3, centerY + toothHeight * 0.15)
          ..lineTo(centerX - toothWidth * 0.45, centerY + toothHeight * 0.20)
          ..lineTo(centerX - toothWidth * 0.45, centerY - toothHeight * 0.20)
          ..close(),
      ),

      // Distal (derecha)
      _ToothSurfacePath(
        surface: ToothSurface.distal,
        path: Path()
          ..moveTo(centerX + toothWidth * 0.3, centerY - toothHeight * 0.15)
          ..lineTo(centerX + toothWidth * 0.3, centerY + toothHeight * 0.15)
          ..lineTo(centerX + toothWidth * 0.45, centerY + toothHeight * 0.20)
          ..lineTo(centerX + toothWidth * 0.45, centerY - toothHeight * 0.20)
          ..close(),
      ),
    ];

    // Dibujar cada superficie
    for (var surfacePath in surfaces) {
      final surfaceState = tooth.surfaces[surfacePath.surface]!;
      final isSurfaceSelected = selectedSurface == surfacePath.surface;

      // Color de la superficie
      paint.color = ToothConditionColors.getColor(surfaceState.condition);
      paint.style = PaintingStyle.fill;
      canvas.drawPath(surfacePath.path, paint);

      // Si esta superficie está seleccionada, mostrar preview del color que se aplicará
      if (isSurfaceSelected && selectedCondition != null && isSelected) {
        paint.color =
            ToothConditionColors.getColor(selectedCondition!).withOpacity(0.5);
        canvas.drawPath(surfacePath.path, paint);
      }

      // Borde de cada superficie
      paint.color = isSurfaceSelected && isSelected
          ? Color(0xFF003366)
              .withOpacity(0.8) // Azul marino si está seleccionada
          : Colors.grey[800]!;
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = isSurfaceSelected && isSelected ? 2.5 : 1;
      canvas.drawPath(surfacePath.path, paint);
    }

    // Borde de selección del diente completo
    if (isSelected) {
      paint.color = Color(0xFF003366); // UAGro azul marino
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 2;
      final rect = Rect.fromCenter(
        center: Offset(centerX, centerY),
        width: size.width - 4,
        height: size.height - 4,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(ToothPainter oldDelegate) {
    return tooth != oldDelegate.tooth ||
        isSelected != oldDelegate.isSelected ||
        selectedSurface != oldDelegate.selectedSurface ||
        selectedCondition != oldDelegate.selectedCondition;
  }
}

class _ToothSurfacePath {
  final ToothSurface surface;
  final Path path;

  _ToothSurfacePath({
    required this.surface,
    required this.path,
  });
}
