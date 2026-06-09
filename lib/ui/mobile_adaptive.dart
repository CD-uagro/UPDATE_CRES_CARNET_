import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io' show Platform;

/// Configuración adaptable para optimizar la UI en dispositivos móviles
/// Este archivo permite ajustar automáticamente tamaños sin modificar código base
class MobileAdaptive {
  MobileAdaptive._();

  /// Detecta si la app está corriendo en móvil
  static bool get isMobilePlatform {
    if (kIsWeb) return false;
    try {
      return Platform.isAndroid || Platform.isIOS;
    } catch (e) {
      return false;
    }
  }

  /// Detecta si es tablet (pantalla > 600dp pero en móvil)
  static bool isTablet(BuildContext context) {
    if (!isMobilePlatform) return false;
    final width = MediaQuery.of(context).size.width;
    return width >= 600;
  }

  /// Detecta si es teléfono (pantalla < 600dp)
  static bool isPhone(BuildContext context) {
    if (!isMobilePlatform) return false;
    final width = MediaQuery.of(context).size.width;
    return width < 600;
  }

  /// Factor de escala para fuentes según plataforma
  static double fontScale(BuildContext context) {
    if (!isMobilePlatform) return 1.0; // Desktop mantiene tamaños originales

    final width = MediaQuery.of(context).size.width;

    // Teléfonos pequeños (< 360dp): REDUCCIÓN EXTREMA
    if (width < 360) return 0.55;

    // Teléfonos normales (360-600dp): REDUCCIÓN FUERTE
    if (width < 600) return 0.65;

    // Tablets (>= 600dp): reducir poco (dejar como estaba)
    return 0.95;
  }

  /// Padding adaptable para contenedores
  static EdgeInsets containerPadding(BuildContext context) {
    if (!isMobilePlatform) {
      return const EdgeInsets.all(24.0); // Desktop: padding generoso
    }

    final width = MediaQuery.of(context).size.width;

    if (width < 360) {
      return const EdgeInsets.all(4.0); // Teléfonos pequeños: MÍNIMO
    } else if (width < 600) {
      return const EdgeInsets.all(8.0); // Teléfonos normales: muy compacto
    } else {
      return const EdgeInsets.all(20.0); // Tablets
    }
  }

  /// Espaciado vertical adaptable
  static double verticalSpacing(BuildContext context, {double base = 16.0}) {
    if (!isMobilePlatform) return base;

    final width = MediaQuery.of(context).size.width;

    if (width < 360) {
      return base * 0.4; // Reducir 60% en pantallas pequeñas
    } else if (width < 600) {
      return base * 0.5; // Reducir 50% en teléfonos
    } else {
      return base * 0.9; // Reducir 10% en tablets
    }
  }

  /// Espaciado horizontal adaptable
  static double horizontalSpacing(BuildContext context, {double base = 16.0}) {
    return verticalSpacing(context, base: base);
  }

  /// Altura de botones adaptable
  static double buttonHeight(BuildContext context) {
    if (!isMobilePlatform) return 48.0; // Desktop: botones estándar

    final width = MediaQuery.of(context).size.width;

    if (width < 360) {
      return 40.0; // Teléfonos pequeños: compacto
    } else if (width < 600) {
      return 42.0; // Teléfonos: compacto
    } else {
      return 48.0; // Tablets: tamaño completo
    }
  }

  /// Tamaño de íconos adaptable
  static double iconSize(BuildContext context, {double base = 24.0}) {
    if (!isMobilePlatform) return base;

    final width = MediaQuery.of(context).size.width;

    if (width < 360) {
      return base * 0.85;
    } else if (width < 600) {
      return base * 0.9;
    } else {
      return base;
    }
  }

  /// Ancho máximo para contenido en tablets
  static double maxContentWidth(BuildContext context) {
    if (!isMobilePlatform) return double.infinity;

    final width = MediaQuery.of(context).size.width;

    // En tablets, limitar ancho de contenido para mejor legibilidad
    if (width >= 600) {
      return 600.0;
    }

    return double.infinity;
  }

  /// Radio de bordes adaptable
  static double borderRadius(BuildContext context, {double base = 12.0}) {
    if (!isMobilePlatform) return base;

    final width = MediaQuery.of(context).size.width;

    if (width < 360) {
      return base * 0.75;
    } else if (width < 600) {
      return base * 0.85;
    } else {
      return base;
    }
  }

  /// Tamaño de AppBar adaptable
  static double appBarHeight(BuildContext context) {
    if (!isMobilePlatform) return kToolbarHeight; // 56.0

    final width = MediaQuery.of(context).size.width;

    if (width < 360) {
      return 48.0; // MÁS compacto en pantallas pequeñas
    } else if (width < 600) {
      return 50.0; // Compacto en teléfonos normales
    } else {
      return kToolbarHeight;
    }
  }

  /// Padding para inputs/forms
  static EdgeInsets inputPadding(BuildContext context) {
    if (!isMobilePlatform) {
      return const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
    }

    final width = MediaQuery.of(context).size.width;

    if (width < 360) {
      return const EdgeInsets.symmetric(horizontal: 12, vertical: 10);
    } else if (width < 600) {
      return const EdgeInsets.symmetric(horizontal: 14, vertical: 11);
    } else {
      return const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
    }
  }

  /// Número de columnas para grids
  static int gridColumns(BuildContext context) {
    if (!isMobilePlatform) return 2; // Desktop: 2 columnas

    final width = MediaQuery.of(context).size.width;

    if (width < 360) {
      return 1; // Teléfonos pequeños: 1 columna
    } else if (width < 600) {
      return 1; // Teléfonos: 1 columna para mejor visualización
    } else {
      return 2; // Tablets: 2 columnas
    }
  }

  /// Espaciado entre elementos de grid
  static double gridSpacing(BuildContext context) {
    if (!isMobilePlatform) return 16.0;

    final width = MediaQuery.of(context).size.width;

    if (width < 360) {
      return 10.0;
    } else if (width < 600) {
      return 12.0;
    } else {
      return 16.0;
    }
  }

  /// Ancho de tarjetas en dashboard
  static double dashboardCardWidth(BuildContext context) {
    if (!isMobilePlatform) return 280.0;

    final width = MediaQuery.of(context).size.width;

    // En móvil, usar casi todo el ancho disponible
    if (width < 600) {
      return width - containerPadding(context).horizontal - 16;
    } else {
      return 280.0;
    }
  }

  /// Padding para diálogos
  static EdgeInsets dialogPadding(BuildContext context) {
    if (!isMobilePlatform) {
      return const EdgeInsets.all(24.0);
    }

    final width = MediaQuery.of(context).size.width;

    if (width < 360) {
      return const EdgeInsets.all(16.0);
    } else if (width < 600) {
      return const EdgeInsets.all(20.0);
    } else {
      return const EdgeInsets.all(24.0);
    }
  }

  /// Método helper para obtener TextStyle escalado
  static TextStyle? scaleTextStyle(BuildContext context, TextStyle? style) {
    if (style == null || !isMobilePlatform) return style;

    final scale = fontScale(context);
    return style.copyWith(fontSize: (style.fontSize ?? 14.0) * scale);
  }

  /// Altura de elementos de lista
  static double listTileHeight(BuildContext context) {
    if (!isMobilePlatform) return 72.0;

    final width = MediaQuery.of(context).size.width;

    if (width < 360) {
      return 64.0;
    } else if (width < 600) {
      return 68.0;
    } else {
      return 72.0;
    }
  }

  /// Determinar si usar scroll horizontal o vertical en tabs
  static bool useHorizontalTabs(BuildContext context) {
    // En móvil, tabs siempre scrolleables horizontalmente
    return isMobilePlatform;
  }

  /// Tamaño de logo/imagen adaptable
  static double logoSize(BuildContext context, {double base = 60.0}) {
    if (!isMobilePlatform) return base;

    final width = MediaQuery.of(context).size.width;

    if (width < 360) {
      return base * 0.7;
    } else if (width < 600) {
      return base * 0.85;
    } else {
      return base;
    }
  }
}

/// Extension para aplicar escalado a TextTheme completo
extension AdaptiveTextTheme on TextTheme {
  TextTheme scaleForMobile(BuildContext context) {
    if (!MobileAdaptive.isMobilePlatform) return this;

    final scale = MobileAdaptive.fontScale(context);

    return TextTheme(
      displayLarge: displayLarge?.copyWith(
          fontSize: (displayLarge?.fontSize ?? 57) * scale),
      displayMedium: displayMedium?.copyWith(
          fontSize: (displayMedium?.fontSize ?? 45) * scale),
      displaySmall: displaySmall?.copyWith(
          fontSize: (displaySmall?.fontSize ?? 36) * scale),
      headlineLarge: headlineLarge?.copyWith(
          fontSize: (headlineLarge?.fontSize ?? 32) * scale),
      headlineMedium: headlineMedium?.copyWith(
          fontSize: (headlineMedium?.fontSize ?? 28) * scale),
      headlineSmall: headlineSmall?.copyWith(
          fontSize: (headlineSmall?.fontSize ?? 24) * scale),
      titleLarge:
          titleLarge?.copyWith(fontSize: (titleLarge?.fontSize ?? 22) * scale),
      titleMedium: titleMedium?.copyWith(
          fontSize: (titleMedium?.fontSize ?? 16) * scale),
      titleSmall:
          titleSmall?.copyWith(fontSize: (titleSmall?.fontSize ?? 14) * scale),
      bodyLarge:
          bodyLarge?.copyWith(fontSize: (bodyLarge?.fontSize ?? 16) * scale),
      bodyMedium:
          bodyMedium?.copyWith(fontSize: (bodyMedium?.fontSize ?? 14) * scale),
      bodySmall:
          bodySmall?.copyWith(fontSize: (bodySmall?.fontSize ?? 12) * scale),
      labelLarge:
          labelLarge?.copyWith(fontSize: (labelLarge?.fontSize ?? 14) * scale),
      labelMedium: labelMedium?.copyWith(
          fontSize: (labelMedium?.fontSize ?? 12) * scale),
      labelSmall:
          labelSmall?.copyWith(fontSize: (labelSmall?.fontSize ?? 11) * scale),
    );
  }
}
