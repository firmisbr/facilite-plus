import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/utils/whatsapp_utils.dart';
import '../../../../shared/widgets/attention_lucide_icon.dart';
import '../../../loans/domain/loan_simulator.dart';
import '../../domain/payments_overview.dart';

class PaymentListCard extends StatelessWidget {
  const PaymentListCard({
    required this.item,
    required this.onWhatsApp,
    super.key,
  });

  final PaymentLoanCardItem item;
  final VoidCallback onWhatsApp;

  @override
  Widget build(BuildContext context) {
    final loan = item.loanItem.loan;
    final accent = item.hasOverdue
        ? AppColors.error
        : item.hasDueSoon
            ? AppColors.info
            : AppColors.accent;

    final canWhatsApp = item.hasOverdue &&
        WhatsAppUtils.normalizeBrazilPhone(item.clientPhone) != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push(
          AppRoutes.loanDetail(
            loan.id,
            highlightInstallment: item.nextInstallmentNumber,
          ),
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        child: Ink(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            border: Border.all(
              color: item.hasOverdue
                  ? AppColors.error.withValues(alpha: 0.45)
                  : context.appTheme.border,
            ),
            boxShadow: context.appTheme.cardShadow,
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: AppDecorations.iconBadge(color: accent),
                    child: item.hasOverdue
                        ? const AttentionLucideIcon(
                            icon: LucideIcons.triangle_alert,
                            size: 20,
                            color: AppColors.error,
                          )
                        : Icon(
                            item.hasDueSoon
                                ? LucideIcons.calendar_clock
                                : LucideIcons.wallet,
                            size: 20,
                            color: accent,
                          ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.clientName,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          LoanSimulator.formatMoney(item.remainingAmount),
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  if (canWhatsApp)
                    Material(
                      color: const Color(0xFF25D366).withValues(alpha: 0.12),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                      child: InkWell(
                        onTap: onWhatsApp,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          child: Icon(
                            LucideIcons.message_circle,
                            size: 22,
                            color: const Color(0xFF25D366),
                          ),
                        ),
                      ),
                    )
                  else if (item.hasOverdue)
                    Icon(
                      LucideIcons.phone_off,
                      size: 20,
                      color: context.appTheme.textSecondary,
                    ),
                  const SizedBox(width: AppSpacing.xs),
                  Icon(
                    LucideIcons.chevron_right,
                    size: 20,
                    color: context.appTheme.textSecondary,
                  ),
                ],
              ),
              if (item.nextDueDate != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.calendar,
                      size: 14,
                      color: context.appTheme.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        'Próximo: ${LoanSimulator.formatDate(item.nextDueDate!)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: context.appTheme.textSecondary,
                            ),
                      ),
                    ),
                    if (item.hasOverdue) ...[
                      const SizedBox(width: AppSpacing.sm),
                      _PaymentStatusChip(
                        label:
                            '${item.overdueInstallments} em atraso · '
                            '${LoanSimulator.formatMoney(item.overdueAmount)}',
                        color: AppColors.error,
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentStatusChip extends StatelessWidget {
  const _PaymentStatusChip({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
