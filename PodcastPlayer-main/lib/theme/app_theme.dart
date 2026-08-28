import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WhistilPalette {
  static const Color background = Color(0xFFF8F5FF);
  static const Color backgroundAccent = Color(0xFFE7DEFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color primary = Color.fromARGB(222, 85, 9, 135);
  static const Color secondary = Color(0xFFB458FF);
  static const Color primarySoft = Color(0xFFD9CCFF);
  static const Color primaryMuted = Color.fromARGB(255, 172, 121, 214);
  static const Color highlight = Color(0xFFFF8ADB);
  static const Color textPrimary = Color(0xFF201137);
  static const Color textSecondary = Color(0xFF6F58A3);
  static const Color outline = Color(0xFFD5CAF2);
  static const Color success = Color(0xFF61CE70);
}

class WhistilGradients {
  static const LinearGradient background = LinearGradient(
    colors: [Color(0xFFFEFBFF), Color(0xFFF0E7FF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient card = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF6EDFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient button = LinearGradient(
    colors: [Color(0xFFE7D6FF), Color(0xFFD2BCFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

ThemeData whistilTheme() {
  final base = ThemeData.light(useMaterial3: true);
  final textTheme = base.textTheme.copyWith(
    displaySmall: base.textTheme.displaySmall?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: -0.4,
    ),
    titleLarge: base.textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
    ),
    bodyMedium: base.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w400),
  ).apply(
    bodyColor: WhistilPalette.textPrimary,
    displayColor: WhistilPalette.textPrimary,
  );

  return base.copyWith(
    scaffoldBackgroundColor: WhistilPalette.background,
    colorScheme: base.colorScheme.copyWith(
      primary: WhistilPalette.primary,
      secondary: WhistilPalette.secondary,
      background: WhistilPalette.background,
      surface: WhistilPalette.surface,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onBackground: WhistilPalette.textPrimary,
      onSurface: WhistilPalette.textPrimary,
      outline: WhistilPalette.outline,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      foregroundColor: WhistilPalette.textPrimary,
      iconTheme: IconThemeData(color: WhistilPalette.textPrimary),
      titleTextStyle: TextStyle(
        color: WhistilPalette.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    ),
    textTheme: textTheme,
    snackBarTheme: SnackBarThemeData(
      backgroundColor: WhistilPalette.surface,
      contentTextStyle: base.textTheme.bodyMedium?.copyWith(
        color: WhistilPalette.textPrimary,
        fontWeight: FontWeight.w500,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      actionTextColor: WhistilPalette.primary,
    ),
    inputDecorationTheme: InputDecorationTheme(
      labelStyle: const TextStyle(color: WhistilPalette.textSecondary),
      hintStyle: const TextStyle(color: WhistilPalette.textSecondary),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: WhistilPalette.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: WhistilPalette.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: WhistilPalette.primary, width: 2),
      ),
      prefixIconColor: WhistilPalette.textSecondary,
      suffixIconColor: WhistilPalette.textSecondary,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: WhistilPalette.primary.withOpacity(0.35)),
        foregroundColor: WhistilPalette.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: WhistilPalette.primary,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
  );
}
