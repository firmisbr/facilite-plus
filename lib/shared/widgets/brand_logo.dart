import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Marca minimalista — ícone em verde premium + nome.
class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    this.size = BrandLogoSize.medium,
    this.showSubtitle = false,
    this.subtitle,
  });

  final BrandLogoSize size;
  final bool showSubtitle;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final iconSize = switch (size) {
      BrandLogoSize.small => 40.0,
      BrandLogoSize.medium => 56.0,
      BrandLogoSize.large => 72.0,
    };

    final titleStyle = switch (size) {
      BrandLogoSize.small => Theme.of(context).textTheme.titleLarge,
      BrandLogoSize.medium => Theme.of(context).textTheme.headlineMedium,
      BrandLogoSize.large => Theme.of(context).textTheme.headlineLarge,
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.accent.withValues(alpha: 0.35),
            ),
          ),
          child: Icon(
            Icons.account_balance_wallet_outlined,
            color: AppColors.accent,
            size: iconSize * 0.45,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Facilite Plus',
          style: titleStyle?.copyWith(fontWeight: FontWeight.w600),
        ),
        if (showSubtitle && subtitle != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ],
    );
  }
}

enum BrandLogoSize { small, medium, large }
