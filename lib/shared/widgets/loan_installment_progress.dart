import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

class LoanInstallmentProgress extends StatelessWidget {
  const LoanInstallmentProgress({
    super.key,
    required this.paid,
    required this.total,
    this.label,
  });

  final int paid;
  final int total;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? paid / total : 0.0;
    final paidStr = paid.toString().padLeft(2, '0');
    final totalStr = total.toString().padLeft(2, '0');
    final text = label ?? '$paidStr/$totalStr parcelas pagas';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              text,
              style: Theme.of(context).textTheme.labelMedium,
            ),
            Text(
              '${(progress * 100).round()}%',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: AppColors.accent.withValues(alpha: 0.15),
            color: AppColors.accent,
          ),
        ),
      ],
    );
  }
}
