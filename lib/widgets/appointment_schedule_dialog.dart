import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/appointment_admin_model.dart';
import '../ui/uagro_theme.dart';

class AppointmentScheduleDialog extends StatefulWidget {
  final AppointmentAdminModel appointment;
  final String action;

  const AppointmentScheduleDialog({
    super.key,
    required this.appointment,
    required this.action,
  });

  @override
  State<AppointmentScheduleDialog> createState() =>
      _AppointmentScheduleDialogState();
}

class _AppointmentScheduleDialogState extends State<AppointmentScheduleDialog> {
  static const _quickHours = [
    TimeOfDay(hour: 8, minute: 0),
    TimeOfDay(hour: 8, minute: 30),
    TimeOfDay(hour: 9, minute: 0),
    TimeOfDay(hour: 9, minute: 30),
    TimeOfDay(hour: 10, minute: 0),
    TimeOfDay(hour: 10, minute: 30),
    TimeOfDay(hour: 11, minute: 0),
    TimeOfDay(hour: 11, minute: 30),
    TimeOfDay(hour: 12, minute: 0),
    TimeOfDay(hour: 13, minute: 0),
    TimeOfDay(hour: 13, minute: 30),
    TimeOfDay(hour: 14, minute: 0),
  ];

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  int _durationMinutes = 30;
  final _assignedController = TextEditingController();
  final _messageController = TextEditingController();
  String? _error;

  bool get _isReschedule => widget.action == 'reschedule';

  @override
  void dispose() {
    _assignedController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isReschedule ? 'Reprogramar cita' : 'Confirmar cita'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _AppointmentSummary(
                appointment: widget.appointment,
                isReschedule: _isReschedule,
              ),
              const SizedBox(height: 16),
              _QuickDateButtons(onSelected: _setDate),
              const SizedBox(height: 12),
              _DateSelector(
                selectedDate: _selectedDate,
                onTap: _pickDate,
              ),
              const SizedBox(height: 12),
              _TimeSelector(
                selectedTime: _selectedTime,
                onTap: _pickTime,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _quickHours.map((time) {
                  final selected = _selectedTime == time;
                  return ChoiceChip(
                    label: Text(_formatTime(time)),
                    selected: selected,
                    onSelected: (_) => setState(() => _selectedTime = time),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 30, label: Text('30 min')),
                  ButtonSegment(value: 45, label: Text('45 min')),
                  ButtonSegment(value: 60, label: Text('60 min')),
                ],
                selected: {_durationMinutes},
                onSelectionChanged: (value) {
                  setState(() => _durationMinutes = value.first);
                },
              ),
              const SizedBox(height: 12),
              if (!_isReschedule) ...[
                TextField(
                  controller: _assignedController,
                  decoration: const InputDecoration(
                    labelText: 'Asignado a',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: _messageController,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: _isReschedule
                      ? 'Motivo de reprogramacion'
                      : 'Mensaje opcional',
                  prefixIcon: const Icon(Icons.notes_outlined),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(
                    color: UAGroColors.rojoEscudo,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _submit,
          child:
              Text(_isReschedule ? 'Enviar nueva propuesta' : 'Confirmar cita'),
        ),
      ],
    );
  }

  void _setDate(DateTime date) {
    setState(() {
      _selectedDate = DateUtils.dateOnly(date);
      _error = null;
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateUtils.dateOnly(now),
      lastDate: DateTime(now.year + 2, 12, 31),
      initialDate: _selectedDate ?? DateUtils.dateOnly(now),
    );
    if (picked != null) _setDate(picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _error = null;
      });
    }
  }

  void _submit() {
    final start = _selectedDateTime();
    if (_selectedDate == null) {
      _setError('Selecciona una fecha valida.');
      return;
    }
    if (_selectedTime == null) {
      _setError('Selecciona una hora de atencion.');
      return;
    }
    if (_durationMinutes <= 0) {
      _setError('Selecciona una duracion valida.');
      return;
    }
    if (start == null || !start.isAfter(DateTime.now())) {
      _setError('La cita no puede programarse en una fecha pasada.');
      return;
    }

    final end = start.add(Duration(minutes: _durationMinutes));
    final message = _messageController.text.trim();
    final assignedTo = _assignedController.text.trim();

    Navigator.pop(context, {
      'scheduled_start': start.toUtc().toIso8601String(),
      'scheduled_end': end.toUtc().toIso8601String(),
      if (!_isReschedule && assignedTo.isNotEmpty) 'assigned_to': assignedTo,
      if (message.isNotEmpty) 'message': message,
      if (_isReschedule && message.isNotEmpty) 'reschedule_reason': message,
    });
  }

  DateTime? _selectedDateTime() {
    final date = _selectedDate;
    final time = _selectedTime;
    if (date == null || time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  void _setError(String message) {
    setState(() => _error = message);
  }

  static String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _AppointmentSummary extends StatelessWidget {
  final AppointmentAdminModel appointment;
  final bool isReschedule;

  const _AppointmentSummary({
    required this.appointment,
    required this.isReschedule,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: UAGroColors.azulMarino.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: UAGroColors.azulMarino.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            appointment.student.nombre.isEmpty
                ? 'Estudiante UAGro'
                : appointment.student.nombre,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text('Area: ${_areaLabel(appointment.area)}'),
          if (isReschedule) ...[
            const SizedBox(height: 6),
            Text(
              'Fecha propuesta por estudiante: '
              '${appointment.preferredDate} / ${_timeBlockLabel(appointment.preferredTimeBlock)}',
            ),
          ],
        ],
      ),
    );
  }

  static String _areaLabel(String value) {
    switch (value) {
      case 'medicina':
        return 'Medicina';
      case 'psicologia':
        return 'Psicologia';
      case 'nutricion':
        return 'Nutricion';
      case 'odontologia':
        return 'Odontologia';
      case 'atencion_estudiantil':
        return 'Atencion estudiantil';
      default:
        return value.isEmpty ? 'Atencion universitaria' : value;
    }
  }

  static String _timeBlockLabel(String value) {
    switch (value) {
      case 'morning':
        return 'Manana';
      case 'afternoon':
        return 'Tarde';
      default:
        return value.isEmpty ? 'Sin preferencia' : value;
    }
  }
}

class _QuickDateButtons extends StatelessWidget {
  final ValueChanged<DateTime> onSelected;

  const _QuickDateButtons({required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final today = DateUtils.dateOnly(DateTime.now());
    final tomorrow = today.add(const Duration(days: 1));
    final nextMonday = _nextMonday(today);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ActionChip(
          avatar: const Icon(Icons.today, size: 18),
          label: const Text('Hoy'),
          onPressed: () => onSelected(today),
        ),
        ActionChip(
          avatar: const Icon(Icons.event, size: 18),
          label: const Text('Manana'),
          onPressed: () => onSelected(tomorrow),
        ),
        ActionChip(
          avatar: const Icon(Icons.next_week_outlined, size: 18),
          label: const Text('Proximo lunes'),
          onPressed: () => onSelected(nextMonday),
        ),
      ],
    );
  }

  static DateTime _nextMonday(DateTime from) {
    final daysUntilMonday = (DateTime.monday - from.weekday) % 7;
    final offset = daysUntilMonday == 0 ? 7 : daysUntilMonday;
    return from.add(Duration(days: offset));
  }
}

class _DateSelector extends StatelessWidget {
  final DateTime? selectedDate;
  final VoidCallback onTap;

  const _DateSelector({
    required this.selectedDate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Fecha',
          prefixIcon: Icon(Icons.calendar_month_outlined),
        ),
        child: Text(
          selectedDate == null
              ? 'Selecciona una fecha'
              : DateFormat('dd/MM/yyyy').format(selectedDate!),
        ),
      ),
    );
  }
}

class _TimeSelector extends StatelessWidget {
  final TimeOfDay? selectedTime;
  final VoidCallback onTap;

  const _TimeSelector({
    required this.selectedTime,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Hora',
          prefixIcon: Icon(Icons.schedule_outlined),
        ),
        child: Text(
          selectedTime == null ? 'Selecciona una hora' : _format(selectedTime!),
        ),
      ),
    );
  }

  static String _format(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
