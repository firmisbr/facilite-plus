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

    final nextDueText = summary?.nextDueDate != null
        ? LoanSimulator.formatDate(summary!.nextDueDate!)
        : (loan.firstDueDate != null
            ? LoanSimulator.formatDate(
                DateTime.tryParse(loan.firstDueDate!) ?? DateTime.now(),
              )
            : '—');

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
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Icon(
                Icons.event_outlined,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Próximo pagamento: $nextDueText',
                style: Theme.of(context).textTheme.bodySmall,
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
