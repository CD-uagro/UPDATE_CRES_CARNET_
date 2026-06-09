import 'package:flutter/material.dart';

/// Colores institucionales Universidad Autónoma de Guerrero (UAGro)
/// TODO: ajustar a códigos oficiales UAGro una vez confirmados
class UAGroColors {
  // Colores principales institucionales
  static const Color blue = Color(0xFF0E2A66); // Azul institucional aprox.
  static const Color gold = Color(0xFFF2B705); // Dorado/acento aprox.
  static const Color red = Color(0xFFB00020); // Rojo institucional aprox.

  // Colores de superficie y fondos
  static const Color surface = Color(0xFFF6F7FB);
  static const Color surfaceVariant = Color(0xFFE8EAF0);
  static const Color background = Color(0xFFFAFBFF);

  // Grises institucionales
  static const Color onSurfaceVariant = Color(0xFF44474F);
  static const Color outline = Color(0xFF74777F);
  static const Color outlineVariant = Color(0xFFC4C7C5);

  // Estados con tinte institucional
  static const Color success = Color(0xFF146C2E); // Verde con tinte UAGro
  static const Color warning = Color(0xFFB3261E); // Naranja con tinte UAGro
  static const Color error = Color(0xFFB00020); // Rojo institucional

  // Constructor privado para evitar instanciación
  UAGroColors._();
}

/// Función para obtener el logo institucional UAGro
/// Si existe el asset, lo retorna; si no, retorna un placeholder
Widget maybeUAGroLogo({double size = 48}) {
  // TODO: verificar si existe assets/images/uagro_logo.png
  // Por ahora usamos un placeholder institucional
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: UAGroColors.gold,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Icon(
      Icons.school_outlined,
      color: UAGroColors.blue,
      size: size * 0.6,
    ),
  );
}

/// Extensión para obtener variantes de colores institucionales
extension UAGroColorScheme on ColorScheme {
  /// Obtiene un ColorScheme basado en los colores institucionales UAGro
  static ColorScheme get light => ColorScheme.fromSeed(
        seedColor: UAGroColors.blue,
        brightness: Brightness.light,
        surface: UAGroColors.surface,
        background: UAGroColors.background,
        error: UAGroColors.error,
      );

  static ColorScheme get dark => ColorScheme.fromSeed(
        seedColor: UAGroColors.blue,
        brightness: Brightness.dark,
      );
}
