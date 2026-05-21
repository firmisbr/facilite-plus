import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../services/sync/sync_queue_summary.dart';

class SyncStatusChip extends StatelessWidget {
  const SyncStatusChip({super.key, required this.summary});

  final SyncQueueSummary summary;

  @override
  Widget build(BuildContext context) {
    if (summary.total <= 0) return const SizedBox.shrink();

    if (summary.hasFailures) {
      return _Chip(
        icon: Icons.cloud_off_outlined,
        label: summary.hasPending
            ? '${summary.pending} pendente(s), ${summary.failed} erro(s)'
            : '${summary.failed} erro(s) de sync',
        color: AppColors.error,
        backgroundAlpha: 0.12,
      );
    }

    return _Chip(
      icon: Icons.cloud_upload_outlined,
      label: '${summary.pending} pendente${summary.pending > 1 ? 's' : ''}',
      color: AppColors.accent,
      backgroundAlpha: 0.25,
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.label,
    required this.color,
    required this.backgroundAlpha,
  });

  final IconData icon;
  final String label;
  final Color color;
  final double backgroundAlpha;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: backgroundAlpha),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
