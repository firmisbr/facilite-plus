import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/loan_installment_progress.dart';
import '../../domain/entities/loan_with_client.dart';
import '../../domain/loan_simulator.dart';
import '../providers/loan_detail_providers.dart';

class LoanListCard extends ConsumerWidget {
  const LoanListCard({
    super.key,
    required this.item,
  });

  final LoanWithClient item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loan = item.loan;
    final summary = ref.watch(loanCardSummaryProvider(loan.id));

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

    final dueLabel = isOverdue
        ? 'Pagamento venceu em $nextDueText'
        : 'Próximo pagamento: $nextDueText';

    final paid = summary?.paidInstallments ?? 0;
    final total = summary?.totalInstallments ?? loan.installments ?? 0;

    return AppCard(
      onTap: () => context.push(AppRoutes.loanDetail(loan.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.clientName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'R\$ ${loan.amount}',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.accent,
              ),
            ],
          ),
          if (overdueCount > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            _OverdueBadge(count: overdueCount),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Icon(
                isOverdue
                    ? Icons.warning_amber_rounded
                    : Icons.event_outlined,
                size: 16,
                color: isOverdue
                    ? AppColors.error
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  dueLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isOverdue ? AppColors.error : null,
                        fontWeight:
                            isOverdue ? FontWeight.w600 : FontWeight.normal,
                      ),
                ),
              ),
            ],
          ),
          if (total > 0) ...[
            const SizedBox(height: AppSpacing.md),
            LoanInstallmentProgress(
              paid: paid,
              total: total,
            ),
          ],
        ],
      ),
    );
  }
}

class _OverdueBadge extends StatelessWidget {
  const _OverdueBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        count == 1
            ? '1 parcela em atraso'
            : '$count parcelas em atraso',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
