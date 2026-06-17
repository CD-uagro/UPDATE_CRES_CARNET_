import 'package:flutter/material.dart';

import '../data/api_service.dart';
import '../data/auth_service.dart';
import '../models/referral_admin_model.dart';
import '../ui/uagro_theme.dart';

class NewReferralScreen extends StatefulWidget {
  const NewReferralScreen({super.key});

  @override
  State<NewReferralScreen> createState() => _NewReferralScreenState();
}

class _NewReferralScreenState extends State<NewReferralScreen> {
  static const _areas = {
    'medico': 'Medico',
    'psicologia': 'Psicologia',
    'nutricion': 'Nutricion',
    'odontologia': 'Odontologia',
    'atencion_estudiantil': 'Atencion estudiantil',
  };

  static const _priorities = {
    'baja': 'Baja',
    'media': 'Media',
    'alta': 'Alta',
    'urgente': 'Urgente',
  };

  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  final _reasonController = TextEditingController();
  final _observationsController = TextEditingController();

  String _originArea = 'medico';
  String _destinationArea = '';
  String _priority = 'media';
  bool _loadingUser = true;
  bool _searching = false;
  bool _saving = false;
  String? _studentError;
  String? _formError;
  ReferralStudentModel? _selectedStudent;
  List<ReferralStudentModel> _studentResults = [];

  @override
  void initState() {
    super.initState();
    _loadCurrentUserArea();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _reasonController.dispose();
    _observationsController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUserArea() async {
    final user = await AuthService.getCurrentUser();
    if (!mounted) return;
    setState(() {
      _originArea = _areaForRole(user?.rol) ?? _originArea;
      _loadingUser = false;
    });
  }

  Future<void> _searchStudent() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _studentError = 'Escribe matricula o nombre del estudiante.';
        _studentResults = [];
        _selectedStudent = null;
      });
      return;
    }

    setState(() {
      _searching = true;
      _studentError = null;
      _formError = null;
      _studentResults = [];
    });

    try {
      final results = <ReferralStudentModel>[];
      final isMatricula = RegExp(r'^\d+$').hasMatch(query);
      if (isMatricula) {
        final record = await ApiService.getExpedienteByMatricula(query);
        if (record != null) results.add(_studentFromRecord(record));
      } else {
        final records = await ApiService.searchExpedientesByName(query);
        results.addAll(records.map(_studentFromRecord));
      }

      if (!mounted) return;
      setState(() {
        _studentResults = _dedupeStudents(results);
        _selectedStudent =
            _studentResults.length == 1 ? _studentResults.first : null;
        _studentError = _studentResults.isEmpty
            ? 'No se encontro estudiante con ese criterio.'
            : null;
        _searching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _studentError = 'No se pudo buscar el estudiante: $e';
        _searching = false;
      });
    }
  }

  Future<void> _submit() async {
    setState(() => _formError = null);

    if (_selectedStudent == null) {
      setState(() => _formError = 'Selecciona un estudiante.');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      await ApiService.createReferral(
        ReferralCreateRequest(
          student: _selectedStudent!,
          originArea: _originArea,
          destinationArea: _destinationArea,
          priority: _priority,
          reason: _reasonController.text.trim(),
          observations: _observationsController.text.trim(),
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Referencia creada correctamente.')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _formError = e.toString();
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UAGroColors.grisClaro,
      appBar: AppBar(
        title: const Text('Nueva Referencia'),
        backgroundColor: UAGroColors.azulMarino,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: _loadingUser
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Form(
                      key: _formKey,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildStudentPanel()),
                          const SizedBox(width: 16),
                          Expanded(child: _buildReferralForm()),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildStudentPanel() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Estudiante',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const Text(
            'Busca por matricula o nombre para reutilizar el expediente actual.',
            style: TextStyle(color: Color(0xFF4B5563)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  enabled: !_searching && !_saving,
                  decoration: const InputDecoration(
                    labelText: 'Matricula o nombre',
                    prefixIcon: Icon(Icons.person_search_outlined),
                  ),
                  onSubmitted: (_) => _searchStudent(),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                onPressed: _searching || _saving ? null : _searchStudent,
                icon: _searching
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search),
                label: const Text('Buscar'),
              ),
            ],
          ),
          if (_studentError != null) ...[
            const SizedBox(height: 12),
            Text(
              _studentError!,
              style: const TextStyle(
                color: UAGroColors.rojoEscudo,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (_selectedStudent != null)
            _SelectedStudentCard(student: _selectedStudent!)
          else if (_studentResults.isNotEmpty)
            ..._studentResults.map(
              (student) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _StudentResultCard(
                  student: student,
                  onTap: () => setState(() => _selectedStudent = student),
                ),
              ),
            )
          else
            const _EmptyStudentHint(),
        ],
      ),
    );
  }

  Widget _buildReferralForm() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Datos de la referencia',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _originArea,
            decoration: const InputDecoration(
              labelText: 'Area origen',
              prefixIcon: Icon(Icons.outbound_outlined),
            ),
            items: _areas.entries
                .map((entry) => DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    ))
                .toList(),
            onChanged: _saving
                ? null
                : (value) => setState(() => _originArea = value!),
            validator: (value) => value == null || value.isEmpty
                ? 'Selecciona area origen.'
                : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _destinationArea.isEmpty ? null : _destinationArea,
            decoration: const InputDecoration(
              labelText: 'Area destino',
              prefixIcon: Icon(Icons.move_down_outlined),
            ),
            items: _areas.entries
                .map((entry) => DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    ))
                .toList(),
            onChanged: _saving
                ? null
                : (value) => setState(() => _destinationArea = value ?? ''),
            validator: (value) => value == null || value.isEmpty
                ? 'Selecciona area destino.'
                : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _priority,
            decoration: const InputDecoration(
              labelText: 'Prioridad',
              prefixIcon: Icon(Icons.flag_outlined),
            ),
            items: _priorities.entries
                .map((entry) => DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    ))
                .toList(),
            onChanged:
                _saving ? null : (value) => setState(() => _priority = value!),
            validator: (value) =>
                value == null || value.isEmpty ? 'Selecciona prioridad.' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _reasonController,
            enabled: !_saving,
            minLines: 4,
            maxLines: 7,
            decoration: const InputDecoration(
              labelText: 'Motivo',
              alignLabelWithHint: true,
              prefixIcon: Icon(Icons.assignment_outlined),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Escribe el motivo de la referencia.';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _observationsController,
            enabled: !_saving,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Observaciones',
              alignLabelWithHint: true,
              prefixIcon: Icon(Icons.notes_outlined),
            ),
          ),
          if (_formError != null) ...[
            const SizedBox(height: 12),
            Text(
              _formError!,
              style: const TextStyle(
                color: UAGroColors.rojoEscudo,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _saving ? null : () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                onPressed: _saving ? null : _submit,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_outlined),
                label: const Text('Crear referencia'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  BoxDecoration _panelDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFFE5E7EB)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  static String? _areaForRole(String? role) {
    return switch (role) {
      'medico' => 'medico',
      'psicologia' => 'psicologia',
      'nutricion' => 'nutricion',
      'odontologia' => 'odontologia',
      'servicios_estudiantiles' => 'atencion_estudiantil',
      _ => null,
    };
  }

  static List<ReferralStudentModel> _dedupeStudents(
    List<ReferralStudentModel> students,
  ) {
    final seen = <String>{};
    final result = <ReferralStudentModel>[];
    for (final student in students) {
      final key = student.matricula.isNotEmpty
          ? student.matricula
          : '${student.nombre}-${student.correo}';
      if (seen.add(key)) result.add(student);
    }
    return result;
  }

  static ReferralStudentModel _studentFromRecord(Map<String, dynamic> record) {
    String read(List<String> keys) {
      for (final key in keys) {
        final value = record[key];
        if (value != null && value.toString().trim().isNotEmpty) {
          return value.toString().trim();
        }
      }
      return '';
    }

    return ReferralStudentModel(
      matricula: read(const [
        'matricula',
        'matricula_alumno',
        'numeroCuenta',
        'studentId',
        'student_id',
      ]),
      nombre: read(const [
        'nombreCompleto',
        'nombre',
        'fullName',
        'full_name',
        'studentName',
      ]),
      correo: read(const [
        'correo',
        'email',
        'correoInstitucional',
        'correo_institucional',
      ]),
      programa: read(const ['programa', 'carrera']),
      campus: read(const ['campus']),
      unidadAcademica: read(const [
        'unidadAcademica',
        'unidad_academica',
        'escuelaUnidadAcademica',
        'escuela_unidad_academica',
        'preparatoria',
      ]),
    );
  }
}

class _SelectedStudentCard extends StatelessWidget {
  final ReferralStudentModel student;

  const _SelectedStudentCard({required this.student});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: UAGroColors.azulMarino.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border:
            Border.all(color: UAGroColors.azulMarino.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Estudiante seleccionado',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          _InfoRow(label: 'Nombre', value: student.nombre),
          _InfoRow(label: 'Matricula', value: student.matricula),
          if (student.unidadAcademica.isNotEmpty)
            _InfoRow(label: 'Unidad', value: student.unidadAcademica),
          if (student.campus.isNotEmpty)
            _InfoRow(label: 'Campus', value: student.campus),
          if (student.correo.isNotEmpty)
            _InfoRow(label: 'Correo', value: student.correo),
        ],
      ),
    );
  }
}

class _StudentResultCard extends StatelessWidget {
  final ReferralStudentModel student;
  final VoidCallback onTap;

  const _StudentResultCard({
    required this.student,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Ink(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            const Icon(Icons.person_outline, color: UAGroColors.azulMarino),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.nombre.isEmpty ? 'Sin nombre' : student.nombre,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    student.matricula.isEmpty
                        ? 'Sin matricula'
                        : student.matricula,
                    style: const TextStyle(color: Color(0xFF4B5563)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class _EmptyStudentHint extends StatelessWidget {
  const _EmptyStudentHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: const Column(
        children: [
          Icon(Icons.search_outlined, size: 42, color: Color(0xFF64748B)),
          SizedBox(height: 8),
          Text(
            'Busca y selecciona un estudiante para iniciar la referencia.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 82,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'No registrado' : value,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
