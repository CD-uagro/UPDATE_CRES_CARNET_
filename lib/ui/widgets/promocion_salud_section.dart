import 'package:flutter/material.dart';

import '../../data/api_service.dart';
import '../brand.dart';
import '../feedback.dart';

class PromocionSaludSection extends StatefulWidget {
  const PromocionSaludSection({super.key});

  @override
  State<PromocionSaludSection> createState() => _PromocionSaludSectionState();
}

class _PromocionSaludSectionState extends State<PromocionSaludSection> {
  final _formKey = GlobalKey<FormState>();
  final _linkController = TextEditingController();
  final _departamentoController = TextEditingController();
  final _matriculaController = TextEditingController();
  final _supervisorKeyController = TextEditingController();

  String? _categoria;
  String? _programa;
  String? _destinatario = 'alumno';
  bool _requiereAutorizacion = false;
  bool _autorizado = false;
  bool _enviando = false;
  bool _validandoClave = false;

  final List<String> _categorias = [
    'Prevención',
    'Promoción',
    'Tratamiento',
    'Rehabilitación',
    'Psicología',
    'Nutrición',
    'Medicina General',
    'Especialidades',
  ];

  final List<String> _programas = [
    'Licenciatura',
    'Maestría',
    'Doctorado',
    'Diplomado',
    'Curso',
    'Taller',
    'Conferencia',
    'Todos',
  ];

  final List<String> _destinatarios = [
    'alumno',
    'general',
  ];

  @override
  void dispose() {
    _linkController.dispose();
    _departamentoController.dispose();
    _matriculaController.dispose();
    _supervisorKeyController.dispose();
    super.dispose();
  }

  void _onDestinatarioChanged(String? value) {
    setState(() {
      _destinatario = value;
      _requiereAutorizacion = value == 'general';
      _autorizado = value == 'alumno';
    });
  }

  Future<void> _validarClaveSupervisor() async {
    if (_supervisorKeyController.text.trim().isEmpty) {
      showErr(context, 'Ingrese la clave de supervisor');
      return;
    }

    setState(() => _validandoClave = true);

    try {
      final result = await ApiService.validateSupervisorKey(
        _supervisorKeyController.text.trim(),
      );

      if (result != null && result['valid'] == true) {
        setState(() {
          _autorizado = true;
          _validandoClave = false;
        });
        if (mounted) {
          showOk(context, 'Clave válida - Autorización concedida');
        }
      } else {
        setState(() {
          _autorizado = false;
          _validandoClave = false;
        });
        if (mounted) {
          showErr(context, result?['message'] ?? 'Clave incorrecta');
        }
      }
    } catch (e) {
      setState(() {
        _autorizado = false;
        _validandoClave = false;
      });
      if (mounted) {
        showErr(context, 'Error al validar clave: $e');
      }
    }
  }

  Future<void> _enviarPromocion() async {
    if (!_formKey.currentState!.validate()) return;

    if (_requiereAutorizacion && !_autorizado) {
      showErr(
        context,
        'Requiere autorización de supervisor para envíos generales',
      );
      return;
    }

    setState(() => _enviando = true);

    try {
      final promocionData = {
        'link': _linkController.text.trim(),
        'departamento': _departamentoController.text.trim(),
        'categoria': _categoria!,
        'programa': _programa!,
        'matricula':
            _destinatario == 'alumno' ? _matriculaController.text.trim() : '',
        'destinatario': _destinatario!,
        'autorizado': _autorizado,
      };

      final result = await ApiService.createPromocionSalud(promocionData);

      if (result != null) {
        if (mounted) {
          showOk(context, 'Promoción de salud enviada exitosamente');
          _limpiarFormulario();
        }
      } else {
        if (mounted) {
          showErr(context, 'Error al enviar promoción de salud');
        }
      }
    } catch (e) {
      if (mounted) {
        showErr(context, 'Error: $e');
      }
    } finally {
      setState(() => _enviando = false);
    }
  }

  void _limpiarFormulario() {
    _formKey.currentState?.reset();
    setState(() {
      _linkController.clear();
      _departamentoController.clear();
      _matriculaController.clear();
      _supervisorKeyController.clear();
      _categoria = null;
      _programa = null;
      _destinatario = 'alumno';
      _requiereAutorizacion = false;
      _autorizado = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _cardDecoration(),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _fieldLabel('Link de promoción *'),
            TextFormField(
              controller: _linkController,
              decoration: _inputDecoration(
                hintText: 'https://ejemplo.com/promocion',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El link es obligatorio';
                }
                final uri = Uri.tryParse(value.trim());
                if (uri == null || !uri.hasScheme) {
                  return 'Ingrese un link válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _fieldLabel('Departamento *'),
            TextFormField(
              controller: _departamentoController,
              decoration: _inputDecoration(
                hintText: 'Ej: SASU, Psicología, Nutrición',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El departamento es obligatorio';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 520;
                final category = _categoryField();
                final program = _programField();
                if (compact) {
                  return Column(
                    children: [
                      category,
                      const SizedBox(height: 16),
                      program,
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: category),
                    const SizedBox(width: 16),
                    Expanded(child: program),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            _fieldLabel('Destinatario *'),
            DropdownButtonFormField<String>(
              initialValue: _destinatario,
              decoration: _inputDecoration(),
              items: _destinatarios
                  .map(
                    (dest) => DropdownMenuItem(
                      value: dest,
                      child: Text(
                        dest == 'alumno'
                            ? 'Alumno específico'
                            : 'Envío general',
                      ),
                    ),
                  )
                  .toList(),
              onChanged: _onDestinatarioChanged,
            ),
            const SizedBox(height: 16),
            if (_destinatario == 'alumno') ...[
              _fieldLabel('Matrícula del alumno *'),
              TextFormField(
                controller: _matriculaController,
                decoration: _inputDecoration(
                  hintText: 'Ingresa la matrícula del alumno',
                ),
                validator: (value) {
                  if (_destinatario == 'alumno' &&
                      (value == null || value.trim().isEmpty)) {
                    return 'La matrícula es obligatoria para envíos a alumnos';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
            ],
            if (_requiereAutorizacion) ...[
              _authorizationCard(),
              const SizedBox(height: 18),
            ],
            const Divider(height: 26),
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 520;
                final sendButton = _sendButton();
                final clearButton = _clearButton();
                if (compact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      sendButton,
                      const SizedBox(height: 12),
                      clearButton,
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(flex: 3, child: sendButton),
                    const SizedBox(width: 12),
                    Expanded(child: clearButton),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F7EE),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.add_rounded, color: Color(0xFF147B45)),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Nueva acción de promoción',
            style: TextStyle(
              color: UAGroColors.blue,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFE9EEF8),
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Text(
            'Obligatoria*',
            style: TextStyle(
              color: UAGroColors.blue,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  Widget _categoryField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _fieldLabel('Categoría *'),
        DropdownButtonFormField<String>(
          initialValue: _categoria,
          decoration: _inputDecoration(),
          items: _categorias
              .map(
                (categoria) => DropdownMenuItem(
                  value: categoria,
                  child: Text(categoria),
                ),
              )
              .toList(),
          onChanged: (value) => setState(() => _categoria = value),
          validator: (value) =>
              value == null ? 'Seleccione una categoría' : null,
        ),
      ],
    );
  }

  Widget _programField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _fieldLabel('Programa *'),
        DropdownButtonFormField<String>(
          initialValue: _programa,
          decoration: _inputDecoration(),
          items: _programas
              .map(
                (programa) => DropdownMenuItem(
                  value: programa,
                  child: Text(programa),
                ),
              )
              .toList(),
          onChanged: (value) => setState(() => _programa = value),
          validator: (value) => value == null ? 'Seleccione un programa' : null,
        ),
      ],
    );
  }

  Widget _authorizationCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E8),
        border: Border.all(
          color: const Color(0xFFE6A11C).withValues(alpha: .42),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.security, color: Color(0xFFE66A00), size: 20),
              SizedBox(width: 8),
              Text(
                'Autorización de supervisor requerida',
                style: TextStyle(
                  color: Color(0xFF875800),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _supervisorKeyController,
                  obscureText: true,
                  decoration: _inputDecoration(hintText: 'Ingrese la clave'),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: _validandoClave ? null : _validarClaveSupervisor,
                  style: FilledButton.styleFrom(
                    backgroundColor: _autorizado
                        ? const Color(0xFF147B45)
                        : UAGroColors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _validandoClave
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(_autorizado ? Icons.check : Icons.vpn_key),
                ),
              ),
            ],
          ),
          if (_autorizado) ...[
            const SizedBox(height: 10),
            const Row(
              children: [
                Icon(Icons.check_circle, color: Color(0xFF147B45), size: 18),
                SizedBox(width: 8),
                Text(
                  'Autorización concedida',
                  style: TextStyle(
                    color: Color(0xFF147B45),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _sendButton() {
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _enviando ? null : _enviarPromocion,
        icon: _enviando
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.send_rounded),
        label: Text(_enviando ? 'Enviando...' : 'Enviar Promoción'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF147B45),
          foregroundColor: Colors.white,
          elevation: 0,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _clearButton() {
    return SizedBox(
      height: 52,
      child: OutlinedButton.icon(
        onPressed: _enviando ? null : _limpiarFormulario,
        icon: const Icon(Icons.close_rounded, size: 20),
        label: const Text('Limpiar'),
        style: OutlinedButton.styleFrom(
          foregroundColor: UAGroColors.blue,
          side: const BorderSide(color: UAGroColors.blue),
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF31415F),
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({String? hintText}) {
    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: const Color(0xFFFAFBFF),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: Color(0xFFD7DDEB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: Color(0xFFD7DDEB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: UAGroColors.blue, width: 1.4),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE3E8F2)),
      boxShadow: [
        BoxShadow(
          color: UAGroColors.blue.withValues(alpha: .06),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }
}
