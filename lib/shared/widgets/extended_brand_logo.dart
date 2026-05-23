import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

/// Logomarca horizontal com fundo transparente.
///
/// `logo_extended_black` → tema escuro (texto claro).
/// `logo_extended_white` → tema claro (texto escuro).
class ExtendedBrandLogo extends StatelessWidget {
  const ExtendedBrandLogo({
    super.key,
    this.height = 72,
    this.maxWidth = AppSpacing.maxContentWidth,
  });

  final double height;
  final double maxWidth;

  static const _darkThemeAsset = 'assets/images/logo_extended_black.png';
  static const _lightThemeAsset = 'assets/images/logo_extended_white.png';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final asset = isDark ? _darkThemeAsset : _lightThemeAsset;

    return Semantics(
      label: 'Facilite Plus, gerenciamento de finanças',
      image: true,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Image.asset(
            asset,
            height: height,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            errorBuilder: (context, error, stackTrace) {
              debugPrint('ExtendedBrandLogo: $error');
              return Icon(
                Icons.image_not_supported_outlined,
                size: height * 0.45,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.35),
              );
            },
          ),
        ),
      ),
    );
  }
}
