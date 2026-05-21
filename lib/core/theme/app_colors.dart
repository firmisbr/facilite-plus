import 'package:flutter/material.dart';

/// Paleta Facilite Plus — verde premium, neutros quentes e detalhes dourados (PRD).
abstract final class AppColors {
  /// Accent principal (verde premium).
  static const accent = Color(0xFF4C6B5A);

  /// Accent secundário (verde suave).
  static const accentSecondary = Color(0xFFA7C3A1);

  /// Destaque / detalhes premium (dourado suave).
  static const premium = Color(0xFFE3C88D);

  // —— Tema claro ——
  static const lightBackground = Color(0xFFF7F5F1);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightTextPrimary = Color(0xFF232320);
  static const lightTextSecondary = Color(0xFF6F6A62);
  static const lightBorder = Color(0xFFE7E0D6);

  // —— Tema escuro ——
  static const darkBackground = Color(0xFF141513);
  static const darkSurface = Color(0xFF1F1F1D);
  static const darkTextPrimary = Color(0xFFF4F1EA);
  static const darkTextSecondary = Color(0xFFA7A398);
  static const darkBorder = Color(0xFF2E2E2B);

  // —— Cores auxiliares (UI) ——
  static const success = Color(0xFF5FA36A);
  static const warning = Color(0xFFD6A85F);
  static const error = Color(0xFFC46A6A);
  static const info = Color(0xFF6B8FA3);

  static const errorContainer = Color(0xFFF8EBEB);
  static const onError = Color(0xFFFFFFFF);

  /// Compatibilidade com código legado.
  @Deprecated('Use accentSecondary')
  static const accentLightSecondary = accentSecondary;

  @Deprecated('Use premium')
  static const accentDarkSecondary = premium;
}

@immutable
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  const AppThemeExtension({
    required this.border,
    required this.textSecondary,
    required this.accentSecondary,
    required this.premium,
    required this.cardShadow,
  });

  final Color border;
  final Color textSecondary;
  final Color accentSecondary;
  final Color premium;
  final List<BoxShadow> cardShadow;

  static const light = AppThemeExtension(
    border: AppColors.lightBorder,
    textSecondary: AppColors.lightTextSecondary,
    accentSecondary: AppColors.accentSecondary,
    premium: AppColors.premium,
    cardShadow: [
      BoxShadow(
        color: Color(0x0D232320),
        blurRadius: 24,
        offset: Offset(0, 8),
      ),
    ],
  );

  static const dark = AppThemeExtension(
    border: AppColors.darkBorder,
    textSecondary: AppColors.darkTextSecondary,
    accentSecondary: AppColors.accentSecondary,
    premium: AppColors.premium,
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
    Color? premium,
    List<BoxShadow>? cardShadow,
  }) {
    return AppThemeExtension(
      border: border ?? this.border,
      textSecondary: textSecondary ?? this.textSecondary,
      accentSecondary: accentSecondary ?? this.accentSecondary,
      premium: premium ?? this.premium,
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
      premium: Color.lerp(premium, other.premium, t)!,
      cardShadow: cardShadow,
    );
  }
}

extension AppThemeContext on BuildContext {
  AppThemeExtension get appTheme =>
      Theme.of(this).extension<AppThemeExtension>()!;
}
