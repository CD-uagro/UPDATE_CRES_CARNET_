import 'tooth_model.dart';
import 'package:uuid/uuid.dart';

class Odontogram {
  final String id;
  final String matricula;
  final String nombrePaciente;
  final String dentista;
  final DateTime fecha;
  final DentitionType dentitionType; // Tipo de dentición
  final Map<int, Tooth> teeth; // Key: FDI number
  String observacionesGenerales;
  String diagnostico;
  String planTratamiento;

  Odontogram({
    String? id,
    required this.matricula,
    required this.nombrePaciente,
    required this.dentista,
    DateTime? fecha,
    this.dentitionType = DentitionType.permanent,
    Map<int, Tooth>? teeth,
    this.observacionesGenerales = '',
    this.diagnostico = '',
    this.planTratamiento = '',
  })  : id = id ?? const Uuid().v4(),
        fecha = fecha ?? DateTime.now(),
        teeth = teeth ?? _initializeTeeth(dentitionType);

  static Map<int, Tooth> _initializeTeeth(DentitionType type) {
    final Map<int, Tooth> teethMap = {};

    if (type == DentitionType.deciduous) {
      // Dentición Decidua/Temporal (Infantil) - 20 dientes

      // Cuadrante 5: Superior Derecho (55-51)
      for (int i = 55; i >= 51; i--) {
        teethMap[i] = Tooth(
          fdiNumber: i,
          name: ToothNames.getName(i, type),
        );
      }

      // Cuadrante 6: Superior Izquierdo (61-65)
      for (int i = 61; i <= 65; i++) {
        teethMap[i] = Tooth(
          fdiNumber: i,
          name: ToothNames.getName(i, type),
        );
      }

      // Cuadrante 7: Inferior Izquierdo (75-71)
      for (int i = 75; i >= 71; i--) {
        teethMap[i] = Tooth(
          fdiNumber: i,
          name: ToothNames.getName(i, type),
        );
      }

      // Cuadrante 8: Inferior Derecho (81-85)
      for (int i = 81; i <= 85; i++) {
        teethMap[i] = Tooth(
          fdiNumber: i,
          name: ToothNames.getName(i, type),
        );
      }
    } else {
      // Dentición Permanente (Adulto) - 32 dientes

      // Cuadrante 1: Superior Derecho (18-11)
      for (int i = 18; i >= 11; i--) {
        teethMap[i] = Tooth(
          fdiNumber: i,
          name: ToothNames.getName(i, type),
        );
      }

      // Cuadrante 2: Superior Izquierdo (21-28)
      for (int i = 21; i <= 28; i++) {
        teethMap[i] = Tooth(
          fdiNumber: i,
          name: ToothNames.getName(i, type),
        );
      }

      // Cuadrante 3: Inferior Izquierdo (38-31)
      for (int i = 38; i >= 31; i--) {
        teethMap[i] = Tooth(
          fdiNumber: i,
          name: ToothNames.getName(i, type),
        );
      }

      // Cuadrante 4: Inferior Derecho (41-48)
      for (int i = 41; i <= 48; i++) {
        teethMap[i] = Tooth(
          fdiNumber: i,
          name: ToothNames.getName(i, type),
        );
      }
    }

    return teethMap;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'matricula': matricula,
        'nombrePaciente': nombrePaciente,
        'dentista': dentista,
        'fecha': fecha.toIso8601String(),
        'dentitionType': dentitionType.name,
        'teeth':
            teeth.map((key, value) => MapEntry(key.toString(), value.toJson())),
        'observacionesGenerales': observacionesGenerales,
        'diagnostico': diagnostico,
        'planTratamiento': planTratamiento,
      };

  factory Odontogram.fromJson(Map<String, dynamic> json) {
    final teethMap = (json['teeth'] as Map<String, dynamic>).map(
      (key, value) => MapEntry(int.parse(key), Tooth.fromJson(value)),
    );

    final dentitionTypeStr = json['dentitionType'] as String?;
    final dentitionType = dentitionTypeStr != null
        ? DentitionType.values.firstWhere((e) => e.name == dentitionTypeStr,
            orElse: () => DentitionType.permanent)
        : DentitionType.permanent;

    return Odontogram(
      id: json['id'],
      matricula: json['matricula'],
      nombrePaciente: json['nombrePaciente'],
      dentista: json['dentista'],
      fecha: DateTime.parse(json['fecha']),
      dentitionType: dentitionType,
      teeth: teethMap,
      observacionesGenerales: json['observacionesGenerales'] ?? '',
      diagnostico: json['diagnostico'] ?? '',
      planTratamiento: json['planTratamiento'] ?? '',
    );
  }

  Odontogram copyWith({
    String? id,
    String? matricula,
    String? nombrePaciente,
    String? dentista,
    DateTime? fecha,
    Map<int, Tooth>? teeth,
    String? observacionesGenerales,
    String? diagnostico,
    String? planTratamiento,
  }) =>
      Odontogram(
        id: id ?? this.id,
        matricula: matricula ?? this.matricula,
        nombrePaciente: nombrePaciente ?? this.nombrePaciente,
        dentista: dentista ?? this.dentista,
        fecha: fecha ?? this.fecha,
        teeth: teeth ?? Map.from(this.teeth),
        observacionesGenerales:
            observacionesGenerales ?? this.observacionesGenerales,
        diagnostico: diagnostico ?? this.diagnostico,
        planTratamiento: planTratamiento ?? this.planTratamiento,
      );

  /// Obtiene estadísticas del odontograma
  Map<String, int> getStatistics() {
    final stats = <String, int>{};

    for (final condition in ToothCondition.values) {
      stats[condition.name] = 0;
    }

    for (final tooth in teeth.values) {
      if (!tooth.isPresent) {
        stats[ToothCondition.extraction.name] =
            (stats[ToothCondition.extraction.name] ?? 0) + 1;
      } else {
        // Contar por superficie
        for (final surface in tooth.surfaces.values) {
          if (surface.condition != ToothCondition.healthy) {
            stats[surface.condition.name] =
                (stats[surface.condition.name] ?? 0) + 1;
          }
        }
      }
    }

    return stats;
  }

  /// Obtiene lista de dientes con problemas
  List<Tooth> getProblematicTeeth() {
    return teeth.values.where((tooth) {
      if (!tooth.isPresent) return true;
      return tooth.surfaces.values
          .any((surface) => surface.condition != ToothCondition.healthy);
    }).toList();
  }
}
