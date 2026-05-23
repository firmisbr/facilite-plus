import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/loan_with_client.dart';
import '../../domain/loan_simulator.dart';
import '../providers/loan_detail_providers.dart';

class LoanListCard extends ConsumerWidget {
  const LoanListCard({required this.item, super.key});

  final LoanWithClient item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loan = item.loan;
    final summary = ref.watch(loanCardSummaryProvider(loan.id));

    final principal =
        LoanSimulator.parseAmount(loan.amount) ?? 0;
    final principalText = LoanSimulator.formatMoney(principal);

    final nextDue = summary?.nextDueDate;
    final nextDueText = nextDue != null
        ? LoanSimulator.formatDate(nextDue)
        : (loan.firstDueDate != null
            ? LoanSimulator.formatDate(
                DateTime.tryParse(loan.firstDueDate!) ?? DateTime.now(),
              )
            : '—');

    final isOverdue = summary?.isNextDueOverdue ?? false;
    final overdueCount = summary?.overdueInstallments ?? 0;
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
        onTap: () => context.push(AppRoutes.loanDetail(loan.id)),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        child: Ink(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            border: Border.all(
              color: isOverdue
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
                    child: Icon(
                      isQuitado
                          ? LucideIcons.circle_check
                          : isOverdue
                              ? LucideIcons.triangle_alert
                              : LucideIcons.banknote,
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
                          principalText,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.accent,
                                height: 1.05,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    LucideIcons.chevron_right,
                    size: 18,
                    color: context.appTheme.textSecondary,
                  ),
                ],
              ),
              if (overdueCount > 0) ...[
                const SizedBox(height: AppSpacing.sm),
                _StatusChip(
                  label: overdueCount == 1
                      ? '1 parcela em atraso'
                      : '$overdueCount parcelas em atraso',
                  color: AppColors.error,
                ),
              ] else if (isQuitado) ...[
                const SizedBox(height: AppSpacing.sm),
                const _StatusChip(
                  label: 'Quitado',
                  color: AppColors.success,
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Parcelas',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: context.appTheme.textSecondary,
                                  ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$paid/$total',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: accent,
                                height: 1,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          isOverdue ? 'Venceu em' : 'Próximo venc.',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: context.appTheme.textSecondary,
                                  ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          nextDueText,
                          textAlign: TextAlign.end,
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: isOverdue ? AppColors.error : null,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (total > 0) ...[
                const SizedBox(height: AppSpacing.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 5,
                    backgroundColor: accent.withValues(alpha: 0.12),
                    color: accent,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 2,
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
      ),
    );
  }
}
