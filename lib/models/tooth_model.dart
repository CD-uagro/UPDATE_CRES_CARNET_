import 'package:flutter/material.dart';

/// Tipo de dentición
enum DentitionType {
  deciduous, // Dentición decidua/temporal (infantil) - 20 dientes
  permanent, // Dentición permanente (adulto) - 32 dientes
}

/// Numeración FDI (Fédération Dentaire Internationale)
/// Adulto (Permanente): 11-18, 21-28, 31-38, 41-48
/// Infantil (Decidua): 51-55, 61-65, 71-75, 81-85
/// Cuadrantes: 1/5=Superior Derecho, 2/6=Superior Izquierdo, 3/7=Inferior Izquierdo, 4/8=Inferior Derecho

enum ToothSurface {
  oclusal, // Superficie de masticación
  vestibular, // Superficie hacia los labios/mejillas
  lingual, // Superficie hacia la lengua
  mesial, // Superficie hacia el centro
  distal, // Superficie hacia atrás
}

enum ToothCondition {
  healthy, // Sano
  caries, // Caries
  restoration, // Restauración/Obturación
  extraction, // Extracción/Ausente
  endodontics, // Endodoncia (tratamiento de conducto)
  crown, // Corona
  bridge, // Puente
  implant, // Implante
  fracture, // Fractura
  abscess, // Absceso
  calculus, // Cálculo/Sarro
  gingivitis, // Gingivitis
  mobility, // Movilidad
  toExtract, // Por extraer
}

class ToothSurfaceState {
  final ToothSurface surface;
  ToothCondition condition;
  String notes;

  ToothSurfaceState({
    required this.surface,
    this.condition = ToothCondition.healthy,
    this.notes = '',
  });

  Map<String, dynamic> toJson() => {
        'surface': surface.name,
        'condition': condition.name,
        'notes': notes,
      };

  factory ToothSurfaceState.fromJson(Map<String, dynamic> json) =>
      ToothSurfaceState(
        surface:
            ToothSurface.values.firstWhere((e) => e.name == json['surface']),
        condition: ToothCondition.values
            .firstWhere((e) => e.name == json['condition']),
        notes: json['notes'] ?? '',
      );

  ToothSurfaceState copyWith({
    ToothSurface? surface,
    ToothCondition? condition,
    String? notes,
  }) =>
      ToothSurfaceState(
        surface: surface ?? this.surface,
        condition: condition ?? this.condition,
        notes: notes ?? this.notes,
      );
}

class Tooth {
  final int fdiNumber; // Número FDI (11-48)
  final String name; // Nombre del diente
  final Map<ToothSurface, ToothSurfaceState> surfaces;
  ToothCondition generalCondition;
  String observations;
  bool isPresent; // Si el diente está presente o no

  Tooth({
    required this.fdiNumber,
    required this.name,
    Map<ToothSurface, ToothSurfaceState>? surfaces,
    this.generalCondition = ToothCondition.healthy,
    this.observations = '',
    this.isPresent = true,
  }) : surfaces = surfaces ??
            {
              ToothSurface.oclusal:
                  ToothSurfaceState(surface: ToothSurface.oclusal),
              ToothSurface.vestibular:
                  ToothSurfaceState(surface: ToothSurface.vestibular),
              ToothSurface.lingual:
                  ToothSurfaceState(surface: ToothSurface.lingual),
              ToothSurface.mesial:
                  ToothSurfaceState(surface: ToothSurface.mesial),
              ToothSurface.distal:
                  ToothSurfaceState(surface: ToothSurface.distal),
            };

  Map<String, dynamic> toJson() => {
        'fdiNumber': fdiNumber,
        'name': name,
        'surfaces':
            surfaces.map((key, value) => MapEntry(key.name, value.toJson())),
        'generalCondition': generalCondition.name,
        'observations': observations,
        'isPresent': isPresent,
      };

  factory Tooth.fromJson(Map<String, dynamic> json) {
    final surfacesMap = (json['surfaces'] as Map<String, dynamic>).map(
      (key, value) => MapEntry(
        ToothSurface.values.firstWhere((e) => e.name == key),
        ToothSurfaceState.fromJson(value),
      ),
    );

    return Tooth(
      fdiNumber: json['fdiNumber'],
      name: json['name'],
      surfaces: surfacesMap,
      generalCondition: ToothCondition.values
          .firstWhere((e) => e.name == json['generalCondition']),
      observations: json['observations'] ?? '',
      isPresent: json['isPresent'] ?? true,
    );
  }

  Tooth copyWith({
    int? fdiNumber,
    String? name,
    Map<ToothSurface, ToothSurfaceState>? surfaces,
    ToothCondition? generalCondition,
    String? observations,
    bool? isPresent,
  }) =>
      Tooth(
        fdiNumber: fdiNumber ?? this.fdiNumber,
        name: name ?? this.name,
        surfaces: surfaces ?? Map.from(this.surfaces),
        generalCondition: generalCondition ?? this.generalCondition,
        observations: observations ?? this.observations,
        isPresent: isPresent ?? this.isPresent,
      );
}

/// Colores para cada condición dental
class ToothConditionColors {
  static const Map<ToothCondition, Color> colors = {
    ToothCondition.healthy: Color(0xFFFFFFFF), // Blanco
    ToothCondition.caries: Color(0xFF000000), // Negro
    ToothCondition.restoration: Color(0xFF2196F3), // Azul
    ToothCondition.extraction: Color(0xFFFF0000), // Rojo - X
    ToothCondition.endodontics: Color(0xFFFF9800), // Naranja
    ToothCondition.crown: Color(0xFFFFEB3B), // Amarillo
    ToothCondition.bridge: Color(0xFF9C27B0), // Morado
    ToothCondition.implant: Color(0xFF00BCD4), // Cian
    ToothCondition.fracture: Color(0xFFE91E63), // Rosa
    ToothCondition.abscess: Color(0xFFFF5722), // Rojo-naranja
    ToothCondition.calculus: Color(0xFF795548), // Café
    ToothCondition.gingivitis: Color(0xFFF44336), // Rojo claro
    ToothCondition.mobility: Color(0xFF9E9E9E), // Gris
    ToothCondition.toExtract: Color(0xFFFF0000), // Rojo con círculo
  };

  static Color getColor(ToothCondition condition) {
    return colors[condition] ?? Colors.white;
  }

  static String getLabel(ToothCondition condition) {
    switch (condition) {
      case ToothCondition.healthy:
        return 'Sano';
      case ToothCondition.caries:
        return 'Caries';
      case ToothCondition.restoration:
        return 'Restauración';
      case ToothCondition.extraction:
        return 'Extracción';
      case ToothCondition.endodontics:
        return 'Endodoncia';
      case ToothCondition.crown:
        return 'Corona';
      case ToothCondition.bridge:
        return 'Puente';
      case ToothCondition.implant:
        return 'Implante';
      case ToothCondition.fracture:
        return 'Fractura';
      case ToothCondition.abscess:
        return 'Absceso';
      case ToothCondition.calculus:
        return 'Cálculo';
      case ToothCondition.gingivitis:
        return 'Gingivitis';
      case ToothCondition.mobility:
        return 'Movilidad';
      case ToothCondition.toExtract:
        return 'Por Extraer';
    }
  }

  static String getSymbol(ToothCondition condition) {
    switch (condition) {
      case ToothCondition.extraction:
        return 'X';
      case ToothCondition.toExtract:
        return '⊗';
      case ToothCondition.implant:
        return 'I';
      case ToothCondition.mobility:
        return 'M';
      case ToothCondition.bridge:
        return '═';
      default:
        return '';
    }
  }
}

/// Nombres de los dientes según FDI
class ToothNames {
  // Dentición Permanente (Adulto) - 32 dientes
  static const Map<int, String> permanentNames = {
    // Cuadrante 1: Superior Derecho
    18: 'Tercer Molar',
    17: 'Segundo Molar',
    16: 'Primer Molar',
    15: 'Segundo Premolar',
    14: 'Primer Premolar',
    13: 'Canino',
    12: 'Incisivo Lateral',
    11: 'Incisivo Central',

    // Cuadrante 2: Superior Izquierdo
    21: 'Incisivo Central',
    22: 'Incisivo Lateral',
    23: 'Canino',
    24: 'Primer Premolar',
    25: 'Segundo Premolar',
    26: 'Primer Molar',
    27: 'Segundo Molar',
    28: 'Tercer Molar',

    // Cuadrante 3: Inferior Izquierdo
    38: 'Tercer Molar',
    37: 'Segundo Molar',
    36: 'Primer Molar',
    35: 'Segundo Premolar',
    34: 'Primer Premolar',
    33: 'Canino',
    32: 'Incisivo Lateral',
    31: 'Incisivo Central',

    // Cuadrante 4: Inferior Derecho
    41: 'Incisivo Central',
    42: 'Incisivo Lateral',
    43: 'Canino',
    44: 'Primer Premolar',
    45: 'Segundo Premolar',
    46: 'Primer Molar',
    47: 'Segundo Molar',
    48: 'Tercer Molar',
  };

  // Dentición Decidua/Temporal (Infantil) - 20 dientes
  static const Map<int, String> deciduousNames = {
    // Cuadrante 5: Superior Derecho
    55: 'Segundo Molar Deciduo',
    54: 'Primer Molar Deciduo',
    53: 'Canino Deciduo',
    52: 'Incisivo Lateral Deciduo',
    51: 'Incisivo Central Deciduo',

    // Cuadrante 6: Superior Izquierdo
    61: 'Incisivo Central Deciduo',
    62: 'Incisivo Lateral Deciduo',
    63: 'Canino Deciduo',
    64: 'Primer Molar Deciduo',
    65: 'Segundo Molar Deciduo',

    // Cuadrante 7: Inferior Izquierdo
    75: 'Segundo Molar Deciduo',
    74: 'Primer Molar Deciduo',
    73: 'Canino Deciduo',
    72: 'Incisivo Lateral Deciduo',
    71: 'Incisivo Central Deciduo',

    // Cuadrante 8: Inferior Derecho
    81: 'Incisivo Central Deciduo',
    82: 'Incisivo Lateral Deciduo',
    83: 'Canino Deciduo',
    84: 'Primer Molar Deciduo',
    85: 'Segundo Molar Deciduo',
  };

  // Método helper para obtener el nombre según el tipo de dentición
  static String getName(int fdiNumber, DentitionType type) {
    if (type == DentitionType.deciduous) {
      return deciduousNames[fdiNumber] ?? 'Diente $fdiNumber';
    } else {
      return permanentNames[fdiNumber] ?? 'Diente $fdiNumber';
    }
  }

  // Retrocompatibilidad - método sobrecargado
  static const Map<int, String> names = permanentNames;
}
