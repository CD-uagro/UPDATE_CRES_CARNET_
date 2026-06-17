enum ReferralStatus {
  draft('draft'),
  sent('sent'),
  received('received'),
  accepted('accepted'),
  scheduled('scheduled'),
  attended('attended'),
  closed('closed'),
  cancelled('cancelled');

  final String value;

  const ReferralStatus(this.value);

  static ReferralStatus? fromValue(String value) {
    for (final status in ReferralStatus.values) {
      if (status.value == value) return status;
    }
    return null;
  }
}

typedef Referral = ReferralAdminModel;
typedef CounterReferral = ReferralCounterReferralModel;

class ReferralAdminModel {
  final String id;
  final ReferralStudentModel student;
  final ReferralActorModel origin;
  final ReferralDestinationModel destination;
  final String priority;
  final String reason;
  final String observations;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final ReferralCounterReferralModel? counterReferral;
  final List<ReferralStatusHistoryEntry> statusHistory;

  const ReferralAdminModel({
    required this.id,
    required this.student,
    required this.origin,
    required this.destination,
    required this.priority,
    required this.reason,
    required this.observations,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.counterReferral,
    required this.statusHistory,
  });

  factory ReferralAdminModel.fromJson(Map<String, dynamic> json) {
    final studentJson = json['student'] is Map
        ? Map<String, dynamic>.from(json['student'] as Map)
        : <String, dynamic>{};
    final originJson = json['origin'] is Map
        ? Map<String, dynamic>.from(json['origin'] as Map)
        : <String, dynamic>{};
    final destinationJson = json['destination'] is Map
        ? Map<String, dynamic>.from(json['destination'] as Map)
        : <String, dynamic>{};
    final counterReferralJson = json['counterReferral'] is Map
        ? Map<String, dynamic>.from(json['counterReferral'] as Map)
        : null;

    return ReferralAdminModel(
      id: _readString(json, ['id', '_id', 'referralId']),
      student: ReferralStudentModel.fromJson(studentJson),
      origin: ReferralActorModel.fromJson(originJson),
      destination: ReferralDestinationModel.fromJson(destinationJson),
      priority: _readString(json, ['priority', 'prioridad'], fallback: 'media'),
      reason: _readString(json, ['reason', 'motivo']),
      observations: _readString(json, ['observations', 'observaciones']),
      status: _readString(json, ['status', 'estado'], fallback: 'sent'),
      createdAt: _readDate(json, ['createdAt', 'created_at']),
      updatedAt: _readDate(json, ['updatedAt', 'updated_at']),
      counterReferral: counterReferralJson == null
          ? null
          : ReferralCounterReferralModel.fromJson(counterReferralJson),
      statusHistory: _readList(json['statusHistory'])
          .map((item) => ReferralStatusHistoryEntry.fromJson(item))
          .toList(),
    );
  }
}

class ReferralStudentModel {
  final String matricula;
  final String nombre;
  final String correo;
  final String programa;
  final String campus;
  final String unidadAcademica;

  const ReferralStudentModel({
    required this.matricula,
    required this.nombre,
    required this.correo,
    required this.programa,
    required this.campus,
    required this.unidadAcademica,
  });

  factory ReferralStudentModel.fromJson(Map<String, dynamic> json) {
    return ReferralStudentModel(
      matricula: _readString(json, ['matricula']),
      nombre: _readString(json, ['nombre', 'nombreCompleto', 'studentName']),
      correo: _readString(json, ['correo', 'email', 'correoInstitucional']),
      programa: _readString(json, ['programa']),
      campus: _readString(json, ['campus']),
      unidadAcademica: _readString(json, [
        'unidadAcademica',
        'unidad_academica',
        'escuelaUnidadAcademica',
      ]),
    );
  }
}

class ReferralActorModel {
  final String area;
  final String userId;
  final String userName;
  final String role;

  const ReferralActorModel({
    required this.area,
    required this.userId,
    required this.userName,
    required this.role,
  });

  factory ReferralActorModel.fromJson(Map<String, dynamic> json) {
    return ReferralActorModel(
      area: _readString(json, ['area']),
      userId: _readString(json, ['userId', 'user_id']),
      userName: _readString(json, ['userName', 'user_name']),
      role: _readString(json, ['role', 'rol']),
    );
  }
}

class ReferralDestinationModel {
  final String area;
  final String assignedUserId;
  final String assignedUserName;

  const ReferralDestinationModel({
    required this.area,
    required this.assignedUserId,
    required this.assignedUserName,
  });

  factory ReferralDestinationModel.fromJson(Map<String, dynamic> json) {
    return ReferralDestinationModel(
      area: _readString(json, ['area']),
      assignedUserId: _readString(json, ['assignedUserId', 'assigned_user_id']),
      assignedUserName:
          _readString(json, ['assignedUserName', 'assigned_user_name']),
    );
  }
}

class ReferralStatusHistoryEntry {
  final String previousStatus;
  final String status;
  final String byUserId;
  final String byUserName;
  final String byRole;
  final String area;
  final String note;
  final DateTime? at;

  const ReferralStatusHistoryEntry({
    required this.previousStatus,
    required this.status,
    required this.byUserId,
    required this.byUserName,
    required this.byRole,
    required this.area,
    required this.note,
    required this.at,
  });

  factory ReferralStatusHistoryEntry.fromJson(Map<String, dynamic> json) {
    return ReferralStatusHistoryEntry(
      previousStatus:
          _readString(json, ['previousStatus', 'previous_status', 'from']),
      status: _readString(json, ['status', 'to']),
      byUserId: _readString(json, ['byUserId', 'by_user_id', 'actor']),
      byUserName: _readString(json, ['byUserName', 'by_user_name']),
      byRole: _readString(json, ['byRole', 'by_role', 'actor_role']),
      area: _readString(json, ['area']),
      note: _readString(json, ['note', 'message']),
      at: _readDate(json, ['at', 'created_at', 'createdAt']),
    );
  }
}

class ReferralCounterReferralModel {
  final String responseArea;
  final String responseUserId;
  final String responseUserName;
  final String responseRole;
  final String summary;
  final String recommendations;
  final bool followUpRequired;
  final String followUpArea;
  final String nextSuggestedAction;
  final DateTime? createdAt;

  const ReferralCounterReferralModel({
    required this.responseArea,
    required this.responseUserId,
    required this.responseUserName,
    required this.responseRole,
    required this.summary,
    required this.recommendations,
    required this.followUpRequired,
    required this.followUpArea,
    required this.nextSuggestedAction,
    required this.createdAt,
  });

  factory ReferralCounterReferralModel.fromJson(Map<String, dynamic> json) {
    return ReferralCounterReferralModel(
      responseArea: _readString(json, ['responseArea', 'response_area']),
      responseUserId: _readString(json, ['responseUserId', 'response_user_id']),
      responseUserName:
          _readString(json, ['responseUserName', 'response_user_name']),
      responseRole: _readString(json, ['responseRole', 'response_role']),
      summary: _readString(json, ['summary', 'resumen']),
      recommendations:
          _readString(json, ['recommendations', 'recomendaciones']),
      followUpRequired: json['followUpRequired'] == true ||
          json['follow_up_required'] == true,
      followUpArea: _readString(json, ['followUpArea', 'follow_up_area']),
      nextSuggestedAction: _readString(
        json,
        ['nextSuggestedAction', 'next_suggested_action'],
      ),
      createdAt: _readDate(json, ['createdAt', 'created_at']),
    );
  }
}

class ReferralCreateRequest {
  final ReferralStudentModel student;
  final String originArea;
  final String destinationArea;
  final String priority;
  final String reason;
  final String observations;

  const ReferralCreateRequest({
    required this.student,
    required this.originArea,
    required this.destinationArea,
    required this.priority,
    required this.reason,
    required this.observations,
  });

  Map<String, dynamic> toJson() {
    return {
      'student': {
        'matricula': student.matricula,
        'nombre': student.nombre,
        if (student.correo.isNotEmpty) 'correo': student.correo,
        if (student.programa.isNotEmpty) 'programa': student.programa,
        if (student.campus.isNotEmpty) 'campus': student.campus,
        if (student.unidadAcademica.isNotEmpty)
          'unidadAcademica': student.unidadAcademica,
      },
      'originArea': originArea,
      'destinationArea': destinationArea,
      'priority': priority,
      'reason': reason,
      if (observations.isNotEmpty) 'observations': observations,
      'send': true,
    };
  }
}

class CounterReferralCreateRequest {
  final String summary;
  final String recommendations;

  const CounterReferralCreateRequest({
    required this.summary,
    required this.recommendations,
  });

  Map<String, dynamic> toJson() {
    return {
      'summary': summary,
      'recommendations': recommendations,
    };
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
