import 'package:flutter/material.dart';

import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_spacing.dart';
import 'app_card.dart';

/// Card de métrica com ícone em destaque (dashboard, pagamentos, etc.).
class AppMetricCard extends StatelessWidget {
  const AppMetricCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.subtitle,
    this.color,
    this.accent = AppCardAccent.none,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? subtitle;
  final Color? color;
  final AppCardAccent accent;

  @override
  Widget build(BuildContext context) {
    final accentColor = color ?? Theme.of(context).colorScheme.primary;

    return AppCard(
      accent: accent,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm + 2),
            decoration: AppDecorations.iconBadge(color: accentColor),
            child: Icon(icon, color: accentColor, size: 22),
          ),
          const Spacer(),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  letterSpacing: 0.2,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: accentColor,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ],
      ),
    );
  }
}
