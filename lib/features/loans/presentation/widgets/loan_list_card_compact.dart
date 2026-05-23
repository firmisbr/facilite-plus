import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/attention_lucide_icon.dart';
import '../../domain/entities/loan_with_client.dart';
import '../../domain/loan_simulator.dart';
import '../providers/loan_detail_providers.dart';

/// Card enxuto para listas longas de empréstimos.
class LoanListCardCompact extends ConsumerWidget {
  const LoanListCardCompact({
    required this.item,
    super.key,
    this.selecting = false,
    this.selected = false,
    this.onTap,
    this.onLongPress,
  });

  final LoanWithClient item;
  final bool selecting;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loan = item.loan;
    final summary = ref.watch(loanCardSummaryProvider(loan.id));

    final principalText = LoanSimulator.formatMoney(
      LoanSimulator.parseAmount(loan.amount) ?? 0,
    );

    final nextDue = summary?.nextDueDate;
    final nextDueText = nextDue != null
        ? LoanSimulator.formatDate(nextDue)
        : '—';

    final isOverdue = summary?.isNextDueOverdue ?? false;
    final paid = summary?.paidInstallments ?? 0;
    final total = summary?.totalInstallments ?? loan.installments ?? 0;
    final progress = total > 0 ? paid / total : 0.0;
    final isQuitado = total > 0 && paid >= total;

    final accent = isOverdue
        ? AppColors.error
        : isQuitado
            ? AppColors.success
            : AppColors.accent;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap ?? () => context.push(AppRoutes.loanDetail(loan.id)),
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Ink(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: selected
                  ? AppColors.accent.withValues(alpha: 0.65)
                  : isOverdue
                      ? AppColors.error.withValues(alpha: 0.4)
                      : context.appTheme.border,
              width: selected ? 2 : 1,
            ),
            boxShadow: context.appTheme.cardShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm + 2,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: isOverdue
                          ? const AttentionLucideIcon(
                              icon: LucideIcons.triangle_alert,
                              size: 16,
                              color: AppColors.error,
                            )
                          : Icon(
                              isQuitado
                                  ? LucideIcons.circle_check
                                  : LucideIcons.banknote,
                              size: 16,
                              color: accent,
                            ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.clientName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$principalText · $paid/$total · $nextDueText',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: isOverdue
                                          ? AppColors.error
                                          : context.appTheme.textSecondary,
                                    ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Icon(
                      LucideIcons.chevron_right,
                      size: 16,
                      color: context.appTheme.textSecondary,
                    ),
                  ],
                ),
              ),
              if (total > 0)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(AppSpacing.radiusLg),
                  ),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 3,
                    backgroundColor: accent.withValues(alpha: 0.1),
                    color: accent,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
