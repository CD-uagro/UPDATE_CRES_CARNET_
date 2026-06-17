import 'package:flutter/material.dart';

import '../data/api_service.dart';
import '../models/referral_admin_model.dart';
import '../ui/uagro_theme.dart';

class CounterReferralScreen extends StatefulWidget {
  final ReferralAdminModel referral;

  const CounterReferralScreen({
    super.key,
    required this.referral,
  });

  @override
  State<CounterReferralScreen> createState() => _CounterReferralScreenState();
}

class _CounterReferralScreenState extends State<CounterReferralScreen> {
  final _formKey = GlobalKey<FormState>();
  final _summaryController = TextEditingController();
  final _recommendationsController = TextEditingController();

  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final counterReferral = widget.referral.counterReferral;
    if (counterReferral != null) {
      _summaryController.text = counterReferral.summary;
      _recommendationsController.text = counterReferral.recommendations;
    }
  }

  @override
  void dispose() {
    _summaryController.dispose();
    _recommendationsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      await ApiService.addCounterReferral(
        referralId: widget.referral.id,
        request: CounterReferralCreateRequest(
          summary: _summaryController.text.trim(),
          recommendations: _recommendationsController.text.trim(),
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UAGroColors.grisClaro,
      appBar: AppBar(
        title: const Text('Contrarreferencia'),
        backgroundColor: UAGroColors.azulMarino,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Form(
                key: _formKey,
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: _panelDecoration(),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 18),
                        TextFormField(
                          controller: _summaryController,
                          enabled: !_saving,
                          minLines: 5,
                          maxLines: 8,
                          decoration: const InputDecoration(
                            labelText: 'Resumen de atencion',
                            alignLabelWithHint: true,
                            prefixIcon: Icon(Icons.description_outlined),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Escribe el resumen de atencion.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _recommendationsController,
                          enabled: !_saving,
                          minLines: 5,
                          maxLines: 8,
                          decoration: const InputDecoration(
                            labelText: 'Recomendaciones',
                            alignLabelWithHint: true,
                            prefixIcon: Icon(Icons.fact_check_outlined),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Escribe las recomendaciones.';
                            }
                            return null;
                          },
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _error!,
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
                              onPressed:
                                  _saving ? null : () => Navigator.pop(context),
                              child: const Text('Cancelar'),
                            ),
                            const SizedBox(width: 10),
                            FilledButton.icon(
                              onPressed: _saving ? null : _submit,
                              icon: _saving
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.save_outlined),
                              label: const Text('Guardar contrarreferencia'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final student = widget.referral.student;
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: UAGroColors.azulMarino.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.assignment_return_outlined,
            color: UAGroColors.azulMarino,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Registrar contrarreferencia',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                '${student.nombre.isEmpty ? "Sin nombre" : student.nombre} - ${student.matricula}',
                style: const TextStyle(color: Color(0xFF4B5563)),
              ),
            ],
          ),
        ),
      ],
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
}
