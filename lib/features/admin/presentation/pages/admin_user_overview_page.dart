import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../dashboard/domain/dashboard_stats.dart';
import '../../../loans/domain/loan_simulator.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_page_header.dart';
import '../admin_routes.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_app_bar_actions.dart';
import '../widgets/admin_metric_card.dart';

class AdminUserOverviewPage extends ConsumerWidget {
  const AdminUserOverviewPage({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(adminUserProvider(userId));
    final statsAsync = ref.watch(adminDashboardStatsProvider(userId));
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      appBar: AppBar(
        title: userAsync.when(
          data: (user) => Text(user?.displayName ?? 'Usuário'),
          loading: () => const Text('Carregando…'),
          error: (_, _) => const Text('Usuário'),
        ),
        actions: const [AdminAppBarActions()],
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppDecorations.screenBackground(brightness),
        ),
        child: SafeArea(
          child: statsAsync.when(
            data: (stats) => userAsync.when(
              data: (user) {
                if (user == null) {
                  return const Center(
                    child: AppEmptyState(
                      icon: LucideIcons.user_x,
                      title: 'Usuário não encontrado',
                    ),
                  );
                }
                return _OverviewBody(userId: userId, userEmail: user.email, stats: stats);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: AppEmptyState(
                icon: LucideIcons.circle_alert,
                title: 'Erro ao carregar dados',
                subtitle: e.toString(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OverviewBody extends ConsumerWidget {
  const _OverviewBody({
    required this.userId,
    required this.userEmail,
    required this.stats,
  });

  final String userId;
  final String userEmail;
  final DashboardStats stats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(adminDashboardStatsProvider(userId));
        ref.invalidate(adminLoansProvider(userId));
        ref.invalidate(adminPaymentsProvider(userId));
        await ref.read(adminDashboardStatsProvider(userId).future);
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
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
                    AppSpacing.sm,
                  ),
                  child: AppPageHeader(
                    title: 'Visão geral',
                    subtitle: userEmail,
                    centered: true,
                  ),
                ),
              ),
            ),
          ),
          if (!stats.hasAnyLoans)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: AppEmptyState(
                  icon: LucideIcons.layout_dashboard,
                  title: 'Sem empréstimos na nuvem',
                  subtitle:
                      'Este usuário ainda não sincronizou dados ou não cadastrou empréstimos.',
                ),
              ),
            )
          else ...[
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppSpacing.maxContentWidth,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.md,
                    ),
                    child: _StatsGrid(stats: stats),
                  ),
                ),
              ),
            ),
            if (stats.upcomingDues.isNotEmpty)
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppSpacing.maxContentWidth,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        0,
                        AppSpacing.lg,
                        AppSpacing.md,
                      ),
                      child: _UpcomingSection(dues: stats.upcomingDues.take(8).toList()),
                    ),
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppSpacing.maxContentWidth,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.xl,
                    ),
                    child: Column(
                      children: [
                        AdminNavCard(
                          title: 'Clientes',
                          subtitle:
                              '${stats.clientsCount} cliente(s) — ver empréstimos e parcelas',
                          icon: LucideIcons.users,
                          onTap: () =>
                              context.push(AdminRoutes.userClients(userId)),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        AdminNavCard(
                          title: 'Relatórios',
                          subtitle:
                              'Emprestado, lucro, inadimplência e período',
                          icon: LucideIcons.file_chart_column,
                          onTap: () =>
                              context.push(AdminRoutes.userReports(userId)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});

  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: AdminMoneyMetric(
                label: 'Emprestado (ativo)',
                amount: stats.totalLent,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AdminMoneyMetric(
                label: 'A receber',
                amount: stats.totalRemaining,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: AdminMoneyMetric(
                label: 'Recebido',
                amount: stats.totalReceived,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AdminMoneyMetric(
                label: 'Lucro esperado',
                amount: stats.expectedProfit,
                accent: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: AdminMetricCard(
                label: 'Empréstimos ativos',
                value: '${stats.activeLoansCount}',
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AdminMoneyMetric(
                label: 'Em atraso',
                amount: stats.overdueAmount,
                warning: stats.overdueInstallments > 0,
                subtitle: stats.overdueInstallments > 0
                    ? '${stats.overdueInstallments} parcela(s)'
                    : null,
              ),
            ),
          ],
        ),
        if (stats.isHistoricalOnly) ...[
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: Text(
              'Carteira quitada. Lucro realizado: '
              '${LoanSimulator.formatMoney(stats.lifetime.realizedProfit)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ],
    );
  }
}

class _UpcomingSection extends StatelessWidget {
  const _UpcomingSection({required this.dues});

  final List<UpcomingDueItem> dues;

  static final _dateFmt = DateFormat('dd/MM/yyyy', 'pt_BR');

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Próximos vencimentos',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...dues.map((due) {
          final color = due.isOverdue ? AppColors.error : null;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: ListTile(
              tileColor: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              title: Text(due.clientName),
              subtitle: Text(
                'Parcela ${due.installmentNumber} · '
                '${_dateFmt.format(due.dueDate)}',
              ),
              trailing: Text(
                LoanSimulator.formatMoney(due.amount),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
