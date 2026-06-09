import 'package:flutter/material.dart';
import 'brand.dart';

/// Tema de aplicación UAGro con tipografía jerárquica y estilos institucionales
class AppTheme {
  // Constructor privado
  AppTheme._();

  /// Tema claro principal
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: UAGroColorScheme.light,

        // Tipografía jerárquica institucional
        textTheme: _textTheme,

        // Configuración de input fields
        inputDecorationTheme: _inputDecorationTheme,

        // Configuración de cards
        cardTheme: _cardTheme,

        // Configuración de elevated buttons
        elevatedButtonTheme: _elevatedButtonTheme,

        // Configuración de outlined buttons
        outlinedButtonTheme: _outlinedButtonTheme,

        // Configuración de filled buttons
        filledButtonTheme: _filledButtonTheme,

        // App bar theme
        appBarTheme: _appBarTheme,

        // Scaffold background
        scaffoldBackgroundColor: UAGroColors.background,
      );

  /// Tipografía jerárquica UAGro
  static const TextTheme _textTheme = TextTheme(
    // Títulos principales
    headlineLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.25,
      color: UAGroColors.blue,
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
      color: UAGroColors.blue,
    ),
    headlineSmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
      color: UAGroColors.blue,
    ),

    // Títulos de sección
    titleLarge: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
      color: UAGroColors.blue,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.15,
      color: UAGroColors.blue,
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
      color: UAGroColors.onSurfaceVariant,
    ),

    // Contenido de texto
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.5,
      color: UAGroColors.onSurfaceVariant,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
      color: UAGroColors.onSurfaceVariant,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.4,
      color: UAGroColors.onSurfaceVariant,
    ),

    // Etiquetas
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      color: UAGroColors.blue,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      color: UAGroColors.blue,
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      color: UAGroColors.onSurfaceVariant,
    ),
  );

  /// Decoración de input fields consistente
  static InputDecorationTheme get _inputDecorationTheme => InputDecorationTheme(
        filled: true,
        fillColor: UAGroColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),

        // Bordes con radio de 12px
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: UAGroColors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: UAGroColors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: UAGroColors.blue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: UAGroColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: UAGroColors.error, width: 2),
        ),

        // Estilo de labels
        labelStyle: const TextStyle(
          color: UAGroColors.onSurfaceVariant,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        floatingLabelStyle: const TextStyle(
          color: UAGroColors.blue,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      );

  /// Tema de cards con estilo institucional
  static CardThemeData get _cardTheme => CardThemeData(
        color: Colors.white,
        elevation: 2,
        shadowColor: UAGroColors.blue.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: UAGroColors.outlineVariant, width: 1),
        ),
        margin: const EdgeInsets.all(0), // Se controla desde el widget padre
      );

  /// Tema de elevated buttons
  static ElevatedButtonThemeData get _elevatedButtonTheme =>
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: UAGroColors.blue,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      );

  /// Tema de outlined buttons
  static OutlinedButtonThemeData get _outlinedButtonTheme =>
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: UAGroColors.blue,
          side: const BorderSide(color: UAGroColors.blue, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      );

  /// Tema de filled buttons (acento dorado)
  static FilledButtonThemeData get _filledButtonTheme => FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: UAGroColors.gold,
          foregroundColor: UAGroColors.blue,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      );

  /// Tema de AppBar institucional
  static AppBarTheme get _appBarTheme => const AppBarTheme(
        backgroundColor: UAGroColors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
          color: Colors.white,
        ),
      );

  /// Padding generoso estándar para contenido
  static const EdgeInsets contentPadding = EdgeInsets.all(24);
  static const EdgeInsets sectionPadding = EdgeInsets.all(16);
  static const EdgeInsets cardPadding = EdgeInsets.all(16);

  /// Espaciado vertical estándar
  static const double spacing = 16;
  static const double spacingSmall = 8;
  static const double spacingLarge = 24;
  static const double spacingXLarge = 32;
}
