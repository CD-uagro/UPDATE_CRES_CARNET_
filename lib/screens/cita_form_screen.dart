// lib/screens/cita_form_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/api_service.dart';
import 'dashboard_screen.dart';

class CitaFormScreen extends StatefulWidget {
  final String matricula;
  final dynamic db;

  const CitaFormScreen({super.key, required this.matricula, this.db});

  @override
  State<CitaFormScreen> createState() => _CitaFormScreenState();
}

class _CitaFormScreenState extends State<CitaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _motivoController = TextEditingController();
  final _departamentoController = TextEditingController();

  DateTime _inicioDate = DateTime.now().add(Duration(days: 1));
  TimeOfDay _inicioTime = TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _finTime = TimeOfDay(hour: 9, minute: 30);

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Agendar Cita'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          // Botón de inicio sutil
          IconButton(
            icon: const Icon(Icons.home_outlined,
                color: Colors.white70, size: 22),
            tooltip: 'Ir al inicio',
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                    builder: (context) => DashboardScreen(db: widget.db)),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Motivo
              TextFormField(
                controller: _motivoController,
                decoration: InputDecoration(
                  labelText: 'Motivo de la cita *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El motivo es obligatorio';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Departamento
              TextFormField(
                controller: _departamentoController,
                decoration: InputDecoration(
                  labelText: 'Departamento (opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),

              // Fecha
              Card(
                child: ListTile(
                  leading: Icon(Icons.calendar_today),
                  title: Text('Fecha'),
                  subtitle: Text(DateFormat('dd/MM/yyyy').format(_inicioDate)),
                  trailing: Icon(Icons.edit),
                  onTap: _selectDate,
                ),
              ),
              SizedBox(height: 8),

              // Hora inicio
              Card(
                child: ListTile(
                  leading: Icon(Icons.access_time),
                  title: Text('Hora inicio'),
                  subtitle: Text(_inicioTime.format(context)),
                  trailing: Icon(Icons.edit),
                  onTap: _selectInicioTime,
                ),
              ),
              SizedBox(height: 8),

              // Hora fin
              Card(
                child: ListTile(
                  leading: Icon(Icons.access_time_filled),
                  title: Text('Hora fin'),
                  subtitle: Text(_finTime.format(context)),
                  trailing: Icon(Icons.edit),
                  onTap: _selectFinTime,
                ),
              ),

              Spacer(),

              // Botones de acción
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text('Cancelar'),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveCita,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text('Guardar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _inicioDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _inicioDate = picked;
      });
    }
  }

  Future<void> _selectInicioTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _inicioTime,
    );
    if (picked != null) {
      setState(() {
        _inicioTime = picked;
        // Ajustar fin automáticamente (+30 min)
        final inicioMinutes = picked.hour * 60 + picked.minute;
        final finMinutes = inicioMinutes + 30;
        _finTime = TimeOfDay(
          hour: (finMinutes ~/ 60) % 24,
          minute: finMinutes % 60,
        );
      });
    }
  }

  Future<void> _selectFinTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _finTime,
    );
    if (picked != null) {
      setState(() {
        _finTime = picked;
      });
    }
  }

  Future<void> _saveCita() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Construir DateTimes
      final inicio = DateTime(
        _inicioDate.year,
        _inicioDate.month,
        _inicioDate.day,
        _inicioTime.hour,
        _inicioTime.minute,
      );
      final fin = DateTime(
        _inicioDate.year,
        _inicioDate.month,
        _inicioDate.day,
        _finTime.hour,
        _finTime.minute,
      );

      // Construir payload con mínimas claves requeridas
      final payload = {
        "matricula": widget.matricula,
        "inicio": inicio.toUtc().toIso8601String(), // ISO 8601 UTC
        "fin": fin.toUtc().toIso8601String(),
        "motivo": _motivoController.text.trim().isEmpty
            ? "SEGUIMIENTO"
            : _motivoController.text.trim(),
        "departamento": _departamentoController.text.trim(),
        "estado": "programada"
      };

      // Llamar ApiService.createCita
      final result = await ApiService.createCita(payload);

      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cita creada y lista actualizada'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Indicar éxito para refrescar lista
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al crear la cita'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al agendar cita: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _motivoController.dispose();
    _departamentoController.dispose();
    super.dispose();
  }
}
