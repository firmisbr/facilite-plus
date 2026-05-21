import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

/// Formas, gradientes e superfícies — só com a paleta existente.
abstract final class AppDecorations {
  static LinearGradient screenBackground(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    if (isLight) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.lightBackground,
          Color(0xFFF3EFE8),
          Color(0xFFE8EFE6),
        ],
        stops: [0.0, 0.55, 1.0],
      );
    }
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        AppColors.darkBackground,
        Color(0xFF181917),
        Color(0xFF1A221E),
      ],
      stops: [0.0, 0.6, 1.0],
    );
  }

  static LinearGradient drawerHeader(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isLight
          ? [
              AppColors.accent.withValues(alpha: 0.14),
              AppColors.accentSecondary.withValues(alpha: 0.35),
            ]
          : [
              AppColors.accent.withValues(alpha: 0.28),
              AppColors.darkSurface,
            ],
    );
  }

  static BoxDecoration iconBadge({
    required Color color,
    double radius = AppSpacing.radiusMd,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          color.withValues(alpha: 0.22),
          color.withValues(alpha: 0.06),
        ],
      ),
      border: Border.all(color: color.withValues(alpha: 0.2)),
    );
  }

  static BoxDecoration accentStripe(Color color) {
    return BoxDecoration(
      borderRadius: const BorderRadius.horizontal(
        left: Radius.circular(AppSpacing.radiusSm),
      ),
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.9),
          color.withValues(alpha: 0.45),
        ],
      ),
    );
  }
}
