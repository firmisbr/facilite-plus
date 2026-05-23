import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_spacing.dart';

enum AppCardAccent { none, primary, error, warning, info }

/// Card padrão com sombra suave e faixa lateral opcional.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.accent = AppCardAccent.none,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final AppCardAccent accent;

  Color? get _accentColor => switch (accent) {
        AppCardAccent.none => null,
        AppCardAccent.primary => AppColors.accent,
        AppCardAccent.error => AppColors.error,
        AppCardAccent.warning => AppColors.warning,
        AppCardAccent.info => AppColors.info,
      };

  @override
  Widget build(BuildContext context) {
    final extras = context.appTheme;
    final surface = Theme.of(context).colorScheme.surface;
    final accentColor = _accentColor;

    Widget content = Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: extras.border.withValues(
            alpha: accentColor != null ? 0.5 : 0.85,
          ),
        ),
        boxShadow: extras.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: accentColor != null
            ? IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 4,
                      decoration: AppDecorations.accentStripe(accentColor),
                    ),
                    Expanded(
                      child: Padding(padding: padding, child: child),
                    ),
                  ],
                ),
              )
            : Padding(padding: padding, child: child),
      ),
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        splashColor: AppColors.accent.withValues(alpha: 0.08),
        highlightColor: AppColors.accent.withValues(alpha: 0.04),
        child: content,
      ),
    );
  }
}
