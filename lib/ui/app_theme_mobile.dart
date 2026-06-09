import 'package:flutter/material.dart';
import 'mobile_adaptive.dart';
import 'uagro_theme.dart'; // Para UAGroColors completo

/// Tema optimizado para Android que adapta automáticamente
/// los tamaños según el dispositivo móvil
///
/// Este tema NO modifica el comportamiento en Windows/Desktop
class AppThemeMobile {
  AppThemeMobile._();

  /// Crear tema adaptable basado en el contexto
  static ThemeData adaptiveTheme(BuildContext context,
      {required ThemeData baseTheme}) {
    // Si no es móvil, retornar el tema base sin cambios
    if (!MobileAdaptive.isMobilePlatform) {
      return baseTheme;
    }

    // Escalar textTheme para móvil
    final scaledTextTheme = baseTheme.textTheme.scaleForMobile(context);

    // Ajustar InputDecorationTheme para móvil
    final mobileInputTheme = _buildMobileInputTheme(context);

    // Ajustar CardTheme para móvil
    final mobileCardTheme = _buildMobileCardTheme(context);

    // Ajustar ElevatedButtonTheme para móvil
    final mobileButtonTheme = _buildMobileButtonTheme(context);

    // Ajustar AppBarTheme para móvil
    final mobileAppBarTheme = _buildMobileAppBarTheme(context);

    return baseTheme.copyWith(
      textTheme: scaledTextTheme,
      inputDecorationTheme: mobileInputTheme,
      cardTheme: CardThemeData(
        color: mobileCardTheme.color,
        elevation: mobileCardTheme.elevation,
        shape: mobileCardTheme.shape,
        margin: mobileCardTheme.margin,
      ),
      elevatedButtonTheme: mobileButtonTheme,
      outlinedButtonTheme: _buildMobileOutlinedButtonTheme(context),
      filledButtonTheme: _buildMobileFilledButtonTheme(context),
      appBarTheme: mobileAppBarTheme,
    );
  }

  /// InputDecorationTheme adaptado para móvil
  static InputDecorationTheme _buildMobileInputTheme(BuildContext context) {
    final padding = MobileAdaptive.inputPadding(context);
    final borderRadius = MobileAdaptive.borderRadius(context);

    return InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: padding,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: BorderSide(color: UAGroColors.azulMarino.withOpacity(0.25)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: BorderSide(color: UAGroColors.azulMarino.withOpacity(0.25)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: const BorderSide(color: UAGroColors.azulMarino, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }

  /// CardTheme adaptado para móvil
  static CardTheme _buildMobileCardTheme(BuildContext context) {
    final borderRadius = MobileAdaptive.borderRadius(context, base: 16.0);
    final margin = MobileAdaptive.containerPadding(context) * 0.5;

    return CardTheme(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      margin: EdgeInsets.all(margin.top),
    );
  }

  /// ElevatedButtonTheme adaptado para móvil
  static ElevatedButtonThemeData _buildMobileButtonTheme(BuildContext context) {
    final height = MobileAdaptive.buttonHeight(context);
    final padding = MobileAdaptive.inputPadding(context);
    final borderRadius = MobileAdaptive.borderRadius(context);

    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: UAGroColors.azulMarino,
        foregroundColor: Colors.white,
        minimumSize: Size(double.infinity, height),
        padding: padding,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        elevation: 2,
        textStyle: MobileAdaptive.scaleTextStyle(
          context,
          const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  /// OutlinedButtonTheme adaptado para móvil
  static OutlinedButtonThemeData _buildMobileOutlinedButtonTheme(
      BuildContext context) {
    final height = MobileAdaptive.buttonHeight(context);
    final padding = MobileAdaptive.inputPadding(context);
    final borderRadius = MobileAdaptive.borderRadius(context);

    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: UAGroColors.azulMarino,
        minimumSize: Size(double.infinity, height),
        padding: padding,
        side: const BorderSide(color: UAGroColors.azulMarino, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        textStyle: MobileAdaptive.scaleTextStyle(
          context,
          const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  /// FilledButtonTheme adaptado para móvil
  static FilledButtonThemeData _buildMobileFilledButtonTheme(
      BuildContext context) {
    final height = MobileAdaptive.buttonHeight(context);
    final padding = MobileAdaptive.inputPadding(context);
    final borderRadius = MobileAdaptive.borderRadius(context);

    return FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: UAGroColors.azulMarino,
        foregroundColor: Colors.white,
        minimumSize: Size(double.infinity, height),
        padding: padding,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        elevation: 0,
        textStyle: MobileAdaptive.scaleTextStyle(
          context,
          const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  /// AppBarTheme adaptado para móvil
  static AppBarTheme _buildMobileAppBarTheme(BuildContext context) {
    final titleStyle = MobileAdaptive.scaleTextStyle(
      context,
      const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    );

    final iconSize = MobileAdaptive.iconSize(context);

    return AppBarTheme(
      backgroundColor: UAGroColors.azulMarino,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: titleStyle,
      toolbarHeight: MobileAdaptive.appBarHeight(context),
      iconTheme: IconThemeData(size: iconSize, color: Colors.white),
      actionsIconTheme: IconThemeData(size: iconSize, color: Colors.white),
    );
  }
}

/// Widget wrapper que aplica adaptación móvil automática
class MobileAdaptiveScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? drawer;
  final Widget? bottomNavigationBar;
  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;

  const MobileAdaptiveScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.drawer,
    this.bottomNavigationBar,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
  });

  @override
  Widget build(BuildContext context) {
    // Envolver body en SafeArea + ScrollConfiguration optimizado para móvil
    Widget adaptiveBody = body;

    if (MobileAdaptive.isMobilePlatform) {
      // En móvil, asegurar SafeArea y mejor comportamiento de scroll
      adaptiveBody = SafeArea(
        child: GestureDetector(
          // Cerrar teclado al tocar fuera de un input
          onTap: () {
            final currentFocus = FocusScope.of(context);
            if (!currentFocus.hasPrimaryFocus &&
                currentFocus.focusedChild != null) {
              FocusManager.instance.primaryFocus?.unfocus();
            }
          },
          child: body,
        ),
      );
    }

    return Scaffold(
      appBar: appBar,
      body: adaptiveBody,
      floatingActionButton: floatingActionButton,
      drawer: drawer,
      bottomNavigationBar: bottomNavigationBar,
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
    );
  }
}

/// Padding adaptable como widget
class AdaptivePadding extends StatelessWidget {
  final Widget child;
  final EdgeInsets? customPadding;

  const AdaptivePadding({
    super.key,
    required this.child,
    this.customPadding,
  });

  @override
  Widget build(BuildContext context) {
    final padding = customPadding ?? MobileAdaptive.containerPadding(context);
    return Padding(
      padding: padding,
      child: child,
    );
  }
}

/// SizedBox vertical adaptable
class AdaptiveVSpace extends StatelessWidget {
  final double base;

  const AdaptiveVSpace(this.base, {super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        height: MobileAdaptive.verticalSpacing(context, base: base));
  }
}

/// SizedBox horizontal adaptable
class AdaptiveHSpace extends StatelessWidget {
  final double base;

  const AdaptiveHSpace(this.base, {super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: MobileAdaptive.horizontalSpacing(context, base: base));
  }
}

/// Container con ancho máximo para tablets
class MaxWidthContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;

  const MaxWidthContainer({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final maxWidth = MobileAdaptive.maxContentWidth(context);

    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        padding: padding,
        child: child,
      ),
    );
  }
}
