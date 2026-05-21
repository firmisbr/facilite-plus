import 'package:flutter/material.dart';

/// Paleta Claude (PRD) — tema completo na fase de UI.
abstract final class AppTheme {
  static const Color lightBackground = Color(0xFFF7F3ED);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color accent = Color(0xFFD97757);
  static const Color darkBackground = Color(0xFF232320);
  static const Color darkSurface = Color(0xFF2B2B27);
  static const Color darkText = Color(0xFFF4F1EA);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.light(
          primary: accent,
          surface: lightSurface,
        ),
        scaffoldBackgroundColor: lightBackground,
        fontFamily: 'Inter',
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: accent,
          surface: darkSurface,
        ),
        scaffoldBackgroundColor: darkBackground,
        fontFamily: 'Inter',
      );
}
