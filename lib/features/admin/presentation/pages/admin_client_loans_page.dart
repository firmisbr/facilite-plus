import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../loans/domain/entities/loan.dart';
import '../../../loans/domain/loan_installment_status.dart';
import '../../../loans/domain/loan_schedule_builder.dart';
import '../../../loans/domain/loan_simulator.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../admin_routes.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_app_bar_actions.dart';
import '../widgets/admin_metric_card.dart';

class AdminClientLoansPage extends ConsumerWidget {
  const AdminClientLoansPage({
    super.key,
    required this.userId,
    required this.clientId,
  });

  final String userId;
  final String clientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync =
        ref.watch(adminClientSummaryProvider((userId, clientId)));
    final loansAsync = ref.watch(adminClientLoansProvider((userId, clientId)));
    final paymentsAsync = ref.watch(adminPaymentsProvider(userId));
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      appBar: AppBar(
        title: summaryAsync.when(
          data: (s) => Text(s?.client.name ?? 'Empréstimos'),
          loading: () => const Text('Empréstimos'),
          error: (_, _) => const Text('Empréstimos'),
        ),
        actions: const [AdminAppBarActions()],
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppDecorations.screenBackground(brightness),
        ),
        child: SafeArea(
          child: loansAsync.when(
            data: (loans) {
              final payments = paymentsAsync.valueOrNull ?? [];

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(adminClientLoansProvider((userId, clientId)));
                  ref.invalidate(adminClientSummaryProvider((userId, clientId)));
                  await ref.read(
                    adminClientLoansProvider((userId, clientId)).future,
                  );
                },
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    if (summaryAsync.valueOrNull != null)
                      SliverToBoxAdapter(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: AppSpacing.maxContentWidth,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.lg,
                                AppSpacing.md,
                                AppSpacing.lg,
                                AppSpacing.md,
                              ),
                              child: _ClientSummaryCard(
                                summary: summaryAsync.value!,
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (loans.isEmpty)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: AppEmptyState(
                            icon: LucideIcons.hand_coins,
                            title: 'Sem empréstimos',
                            subtitle: 'Este cliente não tem contratos na nuvem.',
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          0,
                          AppSpacing.lg,
                          AppSpacing.xl,
                        ),
                        sliver: SliverList.separated(
                          itemCount: loans.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (context, index) {
                            final loan = loans[index];
                            final loanPayments = payments
                                .where((p) => p.loanId == loan.id)
                                .toList();
                            final detail = LoanScheduleBuilder.build(
                              loan: loan,
                              payments: loanPayments,
                            );
                            final summary = detail == null
                                ? null
                                : LoanScheduleBuilder.cardSummary(
                                    loan: loan,
                                    payments: loanPayments,
                                  );

                            return Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: AppSpacing.maxContentWidth,
                                ),
                                child: _LoanTile(
                                  loan: loan,
                                  detail: detail,
                                  cardSummary: summary,
                                  onTap: () => context.push(
                                    AdminRoutes.loanDetail(userId, loan.id),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
          ),
        ),
      ),
    );
  }
}

class _ClientSummaryCard extends StatelessWidget {
  const _ClientSummaryCard({required this.summary});

  final AdminClientSummary summary;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: AdminMoneyMetric(
                label: 'Emprestado (ativo)',
                amount: summary.totalLent,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AdminMoneyMetric(
                label: 'Saldo em aberto',
                amount: summary.totalRemaining,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        AdminMetricCard(
          label: 'Empréstimos ativos',
          value: '${summary.activeLoans}',
          subtitle: summary.overdueInstallments > 0
              ? '${summary.overdueInstallments} parcela(s) em atraso'
              : null,
          warning: summary.overdueInstallments > 0,
        ),
      ],
    );
  }
}

class _LoanTile extends StatelessWidget {
  const _LoanTile({
    required this.loan,
    required this.detail,
    required this.cardSummary,
    required this.onTap,
  });

  final Loan loan;
  final LoanDetailData? detail;
  final LoanCardSummary? cardSummary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final principal = LoanSimulator.parseAmount(loan.amount) ?? 0;
    final paid = cardSummary?.paidInstallments ?? 0;
    final total = cardSummary?.totalInstallments ?? loan.installments ?? 0;
    final isQuitado = total > 0 && paid >= total;
    final isOverdue = (cardSummary?.overdueInstallments ?? 0) > 0;
    final statusLabel = isQuitado
        ? 'Quitado'
        : isOverdue
            ? 'Em atraso'
            : (loan.status ?? 'Ativo');
    final remaining = detail?.overview.remainingAmount ?? 0;
    final overdue = detail?.overview.overdueInstallments ?? 0;

    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      LoanSimulator.formatMoney(principal),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  _StatusChip(label: statusLabel, overdue: overdue > 0),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${loan.installments ?? '?'} parcelas · '
                'juros ${loan.interest ?? '0'}%',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (detail != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Recebido: ${LoanSimulator.formatMoney(detail!.overview.paidAmount)} · '
                  'Aberto: ${LoanSimulator.formatMoney(remaining)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  'Lucro contrato: ${LoanSimulator.formatMoney(detail!.manager.totalProfit)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.accent,
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
  const _StatusChip({required this.label, required this.overdue});

  final String label;
  final bool overdue;

  @override
  Widget build(BuildContext context) {
    final color = overdue ? AppColors.error : AppColors.accent;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
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
