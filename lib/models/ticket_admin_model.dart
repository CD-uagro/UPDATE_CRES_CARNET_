class TicketAdminModel {
  final String id;
  final String ticketNumber;
  final String matricula;
  final String nombrePaciente;
  final String categoria;
  final String prioridad;
  final String estado;
  final String titulo;
  final String descripcionInicial;
  final String campus;
  final String unidadAcademica;
  final String preparatoria;
  final DateTime? createdAtUtc;
  final DateTime? updatedAtUtc;
  final List<TicketStatusHistoryEntry> statusHistory;

  const TicketAdminModel({
    required this.id,
    required this.ticketNumber,
    required this.matricula,
    required this.nombrePaciente,
    required this.categoria,
    required this.prioridad,
    required this.estado,
    required this.titulo,
    required this.descripcionInicial,
    required this.campus,
    required this.unidadAcademica,
    required this.preparatoria,
    required this.createdAtUtc,
    required this.updatedAtUtc,
    required this.statusHistory,
  });

  factory TicketAdminModel.fromJson(Map<String, dynamic> json) {
    final history = _readList(json['statusHistory'])
        .map((item) => TicketStatusHistoryEntry.fromJson(item))
        .toList();

    return TicketAdminModel(
      id: _readString(json, ['id', '_id', 'ticketId']),
      ticketNumber: _readString(json, ['ticketNumber', 'ticket_number']),
      matricula: _readString(json, ['matricula', 'student_id', 'studentId']),
      nombrePaciente: _readString(json, [
        'nombrePaciente',
        'nombre_paciente',
        'nombreCompleto',
        'studentName',
      ]),
      categoria: _readString(json, ['categoria', 'category']),
      prioridad:
          _readString(json, ['prioridad', 'priority'], fallback: 'media'),
      estado: _readString(json, ['estado', 'status'], fallback: 'abierto'),
      titulo: _readString(json, ['titulo', 'title', 'asunto']),
      descripcionInicial: _readString(json, [
        'descripcionInicial',
        'descripcion',
        'description',
        'detalle',
      ]),
      campus: _readString(json, ['campus']),
      unidadAcademica: _readString(json, [
        'unidad_academica',
        'unidadAcademica',
        'escuelaUnidadAcademica',
      ]),
      preparatoria: _readString(json, ['preparatoria']),
      createdAtUtc:
          _readDate(json, ['createdAtUtc', 'createdAt', 'created_at']),
      updatedAtUtc:
          _readDate(json, ['updatedAtUtc', 'updatedAt', 'updated_at']),
      statusHistory: history,
    );
  }
}

class TicketDetailModel {
  final TicketAdminModel ticket;
  final List<TicketMessageModel> messages;
  final List<TicketFollowupModel> followups;

  const TicketDetailModel({
    required this.ticket,
    required this.messages,
    required this.followups,
  });

  factory TicketDetailModel.fromJson(Map<String, dynamic> json) {
    final ticketJson = json['ticket'] ?? json;
    return TicketDetailModel(
      ticket: TicketAdminModel.fromJson(
        ticketJson is Map<String, dynamic>
            ? ticketJson
            : Map<String, dynamic>.from(ticketJson as Map),
      ),
      messages: _readList(json['messages'])
          .map((item) => TicketMessageModel.fromJson(item))
          .toList(),
      followups: _readList(json['followups'])
          .map((item) => TicketFollowupModel.fromJson(item))
          .toList(),
    );
  }
}

class TicketStatusHistoryEntry {
  final String previousStatus;
  final String newStatus;
  final String changedBy;
  final String changedByRole;
  final DateTime? changedAtUtc;

  const TicketStatusHistoryEntry({
    required this.previousStatus,
    required this.newStatus,
    required this.changedBy,
    required this.changedByRole,
    required this.changedAtUtc,
  });

  factory TicketStatusHistoryEntry.fromJson(Map<String, dynamic> json) {
    return TicketStatusHistoryEntry(
      previousStatus: _readString(json, ['previousStatus', 'previous_status']),
      newStatus: _readString(json, ['newStatus', 'new_status']),
      changedBy: _readString(json, ['changedBy', 'changed_by']),
      changedByRole: _readString(json, ['changedByRole', 'changed_by_role']),
      changedAtUtc: _readDate(json, ['changedAtUtc', 'changed_at']),
    );
  }
}

class TicketFollowupModel {
  final String id;
  final String ticketId;
  final String author;
  final String role;
  final String message;
  final String visibility;
  final DateTime? createdAt;

  const TicketFollowupModel({
    required this.id,
    required this.ticketId,
    required this.author,
    required this.role,
    required this.message,
    required this.visibility,
    required this.createdAt,
  });

  factory TicketFollowupModel.fromJson(Map<String, dynamic> json) {
    return TicketFollowupModel(
      id: _readString(json, ['id']),
      ticketId: _readString(json, ['ticket_id', 'ticketId']),
      author: _readString(json, ['author', 'senderId']),
      role: _readString(json, ['role', 'senderRole']),
      message: _readString(json, ['message']),
      visibility: _readString(json, ['visibility'], fallback: 'internal'),
      createdAt: _readDate(json, ['created_at', 'createdAtUtc', 'createdAt']),
    );
  }
}

class TicketMessageModel {
  final String id;
  final String senderName;
  final String senderRole;
  final String message;
  final DateTime? createdAtUtc;

  const TicketMessageModel({
    required this.id,
    required this.senderName,
    required this.senderRole,
    required this.message,
    required this.createdAtUtc,
  });

  factory TicketMessageModel.fromJson(Map<String, dynamic> json) {
    return TicketMessageModel(
      id: _readString(json, ['id']),
      senderName: _readString(json, ['senderName', 'sender_name']),
      senderRole: _readString(json, ['senderRole', 'sender_role']),
      message: _readString(json, ['message']),
      createdAtUtc:
          _readDate(json, ['createdAtUtc', 'created_at', 'createdAt']),
    );
  }
}

List<Map<String, dynamic>> _readList(dynamic value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
}

String _readString(
  Map<String, dynamic> json,
  List<String> keys, {
  String fallback = '',
}) {
  for (final key in keys) {
    final value = json[key];
    if (value != null && value.toString().trim().isNotEmpty) {
      return value.toString().trim();
    }
  }
  return fallback;
}

DateTime? _readDate(Map<String, dynamic> json, List<String> keys) {
  final value = _readString(json, keys);
  if (value.isEmpty) return null;
  return DateTime.tryParse(value);
}
