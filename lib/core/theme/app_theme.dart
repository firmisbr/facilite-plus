import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

abstract final class AppTheme {
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final extras = isLight ? AppThemeExtension.light : AppThemeExtension.dark;

    final background = isLight
        ? AppColors.lightBackground
        : AppColors.darkBackground;
    final surface = isLight ? AppColors.lightSurface : AppColors.darkSurface;
    final onSurface = isLight
        ? AppColors.lightTextPrimary
        : AppColors.darkTextPrimary;
    final onSurfaceVariant = isLight
        ? AppColors.lightTextSecondary
        : AppColors.darkTextSecondary;
    final outline = extras.border;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.accent,
      onPrimary: const Color(0xFFF4F1EA),
      secondary: extras.accentSecondary,
      onSecondary: AppColors.accent,
      tertiary: extras.premium,
      onTertiary: AppColors.lightTextPrimary,
      surface: surface,
      onSurface: onSurface,
      onSurfaceVariant: onSurfaceVariant,
      outline: outline,
      outlineVariant: outline.withValues(alpha: 0.6),
      error: AppColors.error,
      onError: AppColors.onError,
      errorContainer: isLight
          ? AppColors.errorContainer
          : AppColors.error.withValues(alpha: 0.2),
      onErrorContainer: AppColors.error,
    );

    final baseText = GoogleFonts.interTextTheme(
      ThemeData(brightness: brightness).textTheme,
    ).apply(bodyColor: onSurface, displayColor: onSurface);

    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      borderSide: BorderSide(color: outline),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      extensions: [extras],
      textTheme: baseText.copyWith(
        headlineMedium: baseText.headlineMedium?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
          color: onSurface,
        ),
        titleLarge: baseText.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
        titleMedium: baseText.titleMedium?.copyWith(
          fontWeight: FontWeight.w500,
          color: onSurface,
        ),
        bodyLarge: baseText.bodyLarge?.copyWith(height: 1.5, color: onSurface),
        bodyMedium: baseText.bodyMedium?.copyWith(
          height: 1.45,
          color: onSurfaceVariant,
        ),
        labelLarge: baseText.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: background,
        foregroundColor: onSurface,
        systemOverlayStyle: isLight
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          side: BorderSide(color: outline.withValues(alpha: 0.8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        errorBorder: inputBorder.copyWith(
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: inputBorder.copyWith(
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        labelStyle: TextStyle(color: onSurfaceVariant),
        hintStyle: TextStyle(color: onSurfaceVariant.withValues(alpha: 0.7)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        elevation: 3,
        highlightElevation: 6,
        extendedSizeConstraints: const BoxConstraints(minHeight: 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radius2xl),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.accent,
          minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          side: BorderSide(color: outline.withValues(alpha: 0.9)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      navigationDrawerTheme: NavigationDrawerThemeData(
        backgroundColor: surface,
        indicatorColor: AppColors.accent.withValues(alpha: 0.14),
        elevation: 0,
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: surface,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(
            right: Radius.circular(AppSpacing.radius2xl),
          ),
        ),
      ),
      dividerTheme: DividerThemeData(color: outline, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: onSurface,
        contentTextStyle: GoogleFonts.inter(color: background),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accent,
      ),
      iconTheme: IconThemeData(color: onSurfaceVariant),
    );
  }
}
