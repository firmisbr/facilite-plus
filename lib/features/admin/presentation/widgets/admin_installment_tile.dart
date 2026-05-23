import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../loans/domain/loan_installment_status.dart';
import '../../../loans/domain/loan_simulator.dart';

class AdminInstallmentTile extends StatelessWidget {
  const AdminInstallmentTile({super.key, required this.item});

  final LoanInstallmentItem item;

  static final _dateFmt = DateFormat('dd/MM/yyyy', 'pt_BR');

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (item.status) {
      LoanInstallmentStatus.paid => AppColors.success,
      LoanInstallmentStatus.overdue => AppColors.error,
      LoanInstallmentStatus.pending => AppColors.accent,
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Text(
              '${item.number}',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _dateFmt.format(item.dueDate),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    Text(
                      item.status.label,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  LoanSimulator.formatMoney(item.amount),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                if (item.paymentTimingLabel != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    item.paymentTimingLabel!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
