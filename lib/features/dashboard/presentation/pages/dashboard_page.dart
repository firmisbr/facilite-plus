import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_bar_actions.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_page_header.dart';
import '../../../../shared/widgets/app_page_scaffold.dart';
import '../../../loans/domain/loan_simulator.dart';
import '../../../loans/presentation/providers/loans_providers.dart';
import '../../../payments/presentation/providers/payments_providers.dart';
import '../providers/dashboard_providers.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);

    return AppPageScaffold(
      title: 'Dashboard',
      actions: const [
        AppBarActions(showSync: true, showLogout: false),
      ],
      body: statsAsync.when(
        data: (stats) {
          if (stats.activeLoansCount == 0) {
            return const AppEmptyState(
              icon: Icons.dashboard_outlined,
              title: 'Comece por aqui',
              subtitle:
                  'Cadastre um cliente e crie o primeiro empréstimo para ver seus números.',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(allLoansProvider);
              ref.invalidate(allPaymentsForUserProvider);
              await Future<void>.delayed(const Duration(milliseconds: 400));
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                const SliverToBoxAdapter(
                  child: AppPageHeader(
                    title: 'Visão geral',
                    subtitle:
                        'Resumo dos empréstimos ativos e cobranças em aberto.',
                  ),
                ),
                if (stats.overdueInstallments > 0)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        0,
                        AppSpacing.lg,
                        AppSpacing.md,
                      ),
                      child: _AlertBanner(
                        icon: Icons.warning_amber_rounded,
                        color: AppColors.error,
                        title:
                            '${stats.overdueInstallments} parcela(s) em atraso',
                        subtitle: LoanSimulator.formatMoney(stats.overdueAmount),
                      ),
                    ),
                  ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: AppSpacing.md,
                      crossAxisSpacing: AppSpacing.md,
                      childAspectRatio: 1.35,
                    ),
                    delegate: SliverChildListDelegate([
                      _MetricCard(
                        icon: Icons.account_balance_wallet_outlined,
                        label: 'Emprestado',
                        value: LoanSimulator.formatMoney(stats.totalLent),
                        subtitle: '${stats.activeLoansCount} ativo(s)',
                      ),
                      _MetricCard(
                        icon: Icons.payments_outlined,
                        label: 'Recebido',
                        value: LoanSimulator.formatMoney(stats.totalReceived),
                        color: AppColors.success,
                      ),
                      _MetricCard(
                        icon: Icons.schedule_outlined,
                        label: 'A receber',
                        value: LoanSimulator.formatMoney(stats.totalRemaining),
                      ),
                      _MetricCard(
                        icon: Icons.trending_up_rounded,
                        label: 'Lucro previsto',
                        value: LoanSimulator.formatMoney(stats.expectedProfit),
                        color: AppColors.premium,
                        subtitle: 'Juros dos ativos',
                      ),
                    ]),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.xl,
                      AppSpacing.lg,
                      AppSpacing.md,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Próximos vencimentos',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '${stats.clientsCount} cliente(s)',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
                if (stats.upcomingDues.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      child: AppCard(
                        child: Text(
                          'Nenhum vencimento nos próximos 14 dias.',
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.xxl,
                    ),
                    sliver: SliverList.separated(
                      itemCount: stats.upcomingDues.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final due = stats.upcomingDues[index];
                        return AppCard(
                          onTap: () =>
                              context.push(AppRoutes.loanDetail(due.loanId)),
                          child: Row(
                            children: [
                              Icon(
                                due.isOverdue
                                    ? Icons.error_outline
                                    : Icons.event_outlined,
                                color: due.isOverdue
                                    ? AppColors.error
                                    : AppColors.accent,
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      due.clientName,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall,
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      'Parcela ${due.installmentNumber} · '
                                      '${LoanSimulator.formatDate(due.dueDate)}',
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                LoanSimulator.formatMoney(due.amount),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ],
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
        error: (e, _) => AppEmptyState(
          icon: Icons.error_outline,
          title: 'Erro ao carregar',
          subtitle: e.toString(),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    this.subtitle,
    this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? subtitle;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? AppColors.accent;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 22),
          const Spacer(),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w700,
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

class _AlertBanner extends StatelessWidget {
  const _AlertBanner({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
