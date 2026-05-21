import 'package:flutter/material.dart';

/// Paleta PRD — identidade Claude (warm neutrals + terracotta accent).
abstract final class AppColors {
  static const accent = Color(0xFFD97757);
  static const accentLightSecondary = Color(0xFFE9C46A);
  static const accentDarkSecondary = Color(0xFFF2CC8F);

  static const lightBackground = Color(0xFFF7F3ED);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightTextPrimary = Color(0xFF2B2B27);
  static const lightTextSecondary = Color(0xFF6B665E);
  static const lightBorder = Color(0xFFE6DED3);

  static const darkBackground = Color(0xFF232320);
  static const darkSurface = Color(0xFF2B2B27);
  static const darkTextPrimary = Color(0xFFF4F1EA);
  static const darkTextSecondary = Color(0xFFB7B2A8);
  static const darkBorder = Color(0xFF3A3A35);

  static const error = Color(0xFFC45C4A);
  static const errorContainer = Color(0xFFFCEEEA);
  static const onError = Color(0xFFFFFFFF);
}

@immutable
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  const AppThemeExtension({
    required this.border,
    required this.textSecondary,
    required this.accentSecondary,
    required this.cardShadow,
  });

  final Color border;
  final Color textSecondary;
  final Color accentSecondary;
  final List<BoxShadow> cardShadow;

  static const light = AppThemeExtension(
    border: AppColors.lightBorder,
    textSecondary: AppColors.lightTextSecondary,
    accentSecondary: AppColors.accentLightSecondary,
    cardShadow: [
      BoxShadow(
        color: Color(0x0D2B2B27),
        blurRadius: 24,
        offset: Offset(0, 8),
      ),
    ],
  );

  static const dark = AppThemeExtension(
    border: AppColors.darkBorder,
    textSecondary: AppColors.darkTextSecondary,
    accentSecondary: AppColors.accentDarkSecondary,
    cardShadow: [
      BoxShadow(
        color: Color(0x33000000),
        blurRadius: 20,
        offset: Offset(0, 6),
      ),
    ],
  );

  @override
  AppThemeExtension copyWith({
    Color? border,
    Color? textSecondary,
    Color? accentSecondary,
    List<BoxShadow>? cardShadow,
  }) {
    return AppThemeExtension(
      border: border ?? this.border,
      textSecondary: textSecondary ?? this.textSecondary,
      accentSecondary: accentSecondary ?? this.accentSecondary,
      cardShadow: cardShadow ?? this.cardShadow,
    );
  }

  @override
  AppThemeExtension lerp(ThemeExtension<AppThemeExtension>? other, double t) {
    if (other is! AppThemeExtension) return this;
    return AppThemeExtension(
      border: Color.lerp(border, other.border, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      accentSecondary: Color.lerp(accentSecondary, other.accentSecondary, t)!,
      cardShadow: cardShadow,
    );
  }
}

extension AppThemeContext on BuildContext {
  AppThemeExtension get appTheme =>
      Theme.of(this).extension<AppThemeExtension>()!;
}
