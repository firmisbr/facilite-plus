import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../payments/domain/payment_list_filter.dart';
import '../../../payments/presentation/providers/payments_overview_filter_provider.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/attention_lucide_icon.dart';
import '../../../../shared/widgets/extended_brand_logo.dart';
import '../../../../shared/widgets/floating_notched_nav_bar.dart';
import '../../../loans/domain/loan_simulator.dart';
import '../../../loans/domain/portfolio_lifetime_builder.dart';
import '../../../loans/presentation/providers/loans_providers.dart';
import '../../../payments/presentation/providers/payments_providers.dart';
import '../providers/dashboard_providers.dart';
import '../../domain/dashboard_stats.dart';

/// Índice da aba Cobranças no [StatefulNavigationShell].
const _paymentsShellBranchIndex = 1;

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  /// Entre o tamanho anterior (100) e o reduzido (72).
  static const _logoHeight = 100.0;

  static void _openOverdueCollections(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(paymentsOverviewFilterRequestProvider.notifier);
    notifier.state = null;
    notifier.state = PaymentListFilter.atrasados;
    StatefulNavigationShell.of(context).goBranch(_paymentsShellBranchIndex);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final brightness = Theme.of(context).brightness;
    return Scaffold(
      extendBody: true,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppDecorations.screenBackground(brightness),
        ),
        child: SafeArea(
          top: true,
          bottom: false,
          child: statsAsync.when(
            data: (stats) {
              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(allLoansProvider);
                  ref.invalidate(allPaymentsForUserProvider);
                  await Future<void>.delayed(
                    const Duration(milliseconds: 400),
                  );
                },
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.md,
                          AppSpacing.lg,
                          AppSpacing.md,
                        ),
                        child: const ExtendedBrandLogo(
                          height: _logoHeight,
                        ),
                      ),
                    ),
                    if (!stats.hasAnyLoans)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: AppSpacing.maxContentWidth,
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(AppSpacing.lg),
                              child: AppEmptyState(
                                icon: LucideIcons.layout_dashboard,
                                title: 'Comece por aqui',
                                subtitle:
                                    'Use o botão + na barra inferior para criar seu primeiro empréstimo.',
                              ),
                            ),
                          ),
                        ),
                      )
                    else if (stats.isHistoricalOnly) ...[
                      SliverToBoxAdapter(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: AppSpacing.maxContentWidth,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.lg,
                                AppSpacing.lg,
                                AppSpacing.lg,
                                AppSpacing.sm,
                              ),
                              child: _DashboardHistoricalBanner(
                                quitadosCount: stats.lifetime.quitadosLoans,
                              ),
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
                                AppSpacing.sm,
                                AppSpacing.lg,
                                kBottomNavReservedHeight + AppSpacing.lg,
                              ),
                              child: _DashboardHistoricalHero(
                                lifetime: stats.lifetime,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      if (stats.overdueInstallments > 0)
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
                                  0,
                                ),
                                child: _DashboardAlertCard(
                                  title:
                                      '${stats.overdueInstallments} parcela(s) em atraso',
                                  subtitle: LoanSimulator.formatMoney(
                                    stats.overdueAmount,
                                  ),
                                  onTap: () => _openOverdueCollections(
                                    context,
                                    ref,
                                  ),
                                ),
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
                                AppSpacing.lg,
                                AppSpacing.lg,
                                AppSpacing.sm,
                              ),
                              child: _DashboardSummaryHero(stats: stats),
                            ),
                          ),
                        ),
                      ),
                      if (stats.cashFlowByWeek.isNotEmpty)
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
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    const _DashboardSectionLabel(
                                      title: 'Radar de caixa',
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                    _CashFlowRadarCard(stats: stats),
                                  ],
                                ),
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
                                AppSpacing.lg,
                                AppSpacing.lg,
                                AppSpacing.sm,
                              ),
                              child: const _DashboardSectionLabel(
                                title: 'Próximos vencimentos',
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (stats.upcomingDues.isEmpty)
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
                                  kBottomNavReservedHeight + AppSpacing.lg,
                                ),
                                child: _DashboardSurfaceCard(
                                  child: Text(
                                    'Nenhum empréstimo ativo com parcela em aberto.',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ),
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
                            kBottomNavReservedHeight + AppSpacing.lg,
                          ),
                          sliver: SliverList.separated(
                            itemCount: stats.upcomingDues.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: AppSpacing.sm),
                            itemBuilder: (context, index) {
                              return Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: AppSpacing.maxContentWidth,
                                  ),
                                  child: _UpcomingDueTile(
                                    due: stats.upcomingDues[index],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: AppEmptyState(
                  icon: LucideIcons.circle_alert,
                  title: 'Erro ao carregar',
                  subtitle: e.toString(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardSurfaceCard extends StatelessWidget {
  const _DashboardSurfaceCard({
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: context.appTheme.border),
        boxShadow: context.appTheme.cardShadow,
      ),
      child: child,
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        child: content,
      ),
    );
  }
}

class _DashboardHistoricalBanner extends StatelessWidget {
  const _DashboardHistoricalBanner({required this.quitadosCount});

  final int quitadosCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(
            LucideIcons.circle_check,
            color: AppColors.success,
            size: 22,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              quitadosCount == 1
                  ? 'Seu empréstimo está quitado. Resumo histórico abaixo.'
                  : 'Todos os $quitadosCount empréstimos estão quitados. '
                      'Resumo histórico abaixo.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    height: 1.35,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardHistoricalHero extends StatelessWidget {
  const _DashboardHistoricalHero({required this.lifetime});

  final PortfolioLifetimeStats lifetime;

  @override
  Widget build(BuildContext context) {
    return _DashboardSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Histórico da carteira',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Total emprestado',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: context.appTheme.textSecondary,
                  letterSpacing: 0.3,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            LoanSimulator.formatMoney(lifetime.totalLent),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.accent,
                  height: 1.05,
                ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _HeroStat(
                  label: 'Total recebido',
                  value: LoanSimulator.formatMoney(lifetime.totalReceived),
                  color: AppColors.success,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: context.appTheme.border,
              ),
              Expanded(
                child: _HeroStat(
                  label: 'Lucro realizado',
                  value: LoanSimulator.formatMoney(lifetime.realizedProfit),
                  color: AppColors.premium,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashboardSummaryHero extends StatelessWidget {
  const _DashboardSummaryHero({required this.stats});

  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    return _DashboardSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            stats.lifetime.quitadosLoans > 0
                ? 'Emprestado (carteira ativa)'
                : 'Total emprestado',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: context.appTheme.textSecondary,
                  letterSpacing: 0.3,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            LoanSimulator.formatMoney(stats.totalLent),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.accent,
                  height: 1.05,
                ),
          ),
          if (stats.lifetime.quitadosLoans > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Histórico (todos): ${LoanSimulator.formatMoney(stats.lifetime.totalLent)}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: context.appTheme.textSecondary,
                  ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Total a receber (com juros)',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: context.appTheme.textSecondary,
                  letterSpacing: 0.3,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            LoanSimulator.formatMoney(stats.totalRemaining),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.accentSecondary,
                  height: 1.05,
                ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _HeroStat(
                  label: 'Recebido',
                  value: LoanSimulator.formatMoney(stats.totalReceived),
                  color: AppColors.success,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: context.appTheme.border,
              ),
              Expanded(
                child: _HeroStat(
                  label: 'Lucro a receber',
                  value: LoanSimulator.formatMoney(stats.remainingProfit),
                  color: AppColors.premium,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({
    required this.label,
    required this.value,
    this.color,
  });

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: context.appTheme.textSecondary,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                  height: 1.1,
                ),
          ),
        ],
      ),
    );
  }
}

class _CashFlowRadarCard extends StatefulWidget {
  const _CashFlowRadarCard({required this.stats});

  final DashboardStats stats;

  @override
  State<_CashFlowRadarCard> createState() => _CashFlowRadarCardState();
}

class _CashFlowRadarCardState extends State<_CashFlowRadarCard> {
  CashFlowGranularity _granularity = CashFlowGranularity.week;

  static const _chartHeight = 108.0;
  static const _valueRowHeight = 36.0;

  @override
  Widget build(BuildContext context) {
    final buckets = widget.stats.cashFlowFor(_granularity);
    final insight = DashboardStatsBuilder.insightFor(
      granularity: _granularity,
      buckets: buckets,
      totalRemaining: widget.stats.totalRemaining,
    );
    final maxAmount = buckets
        .map((b) => b.amount)
        .fold<double>(0, (a, b) => a > b ? a : b);

    return _DashboardSurfaceCard(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<CashFlowGranularity>(
            segments: const [
              ButtonSegment(
                value: CashFlowGranularity.day,
                label: Text('Dia'),
                icon: Icon(LucideIcons.calendar_days, size: 16),
              ),
              ButtonSegment(
                value: CashFlowGranularity.week,
                label: Text('Semana'),
                icon: Icon(LucideIcons.calendar_range, size: 16),
              ),
              ButtonSegment(
                value: CashFlowGranularity.month,
                label: Text('Mês'),
                icon: Icon(LucideIcons.calendar, size: 16),
              ),
            ],
            selected: {_granularity},
            onSelectionChanged: (selected) {
              setState(() => _granularity = selected.first);
            },
          ),
          if (insight != null) ...[
            const SizedBox(height: AppSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  LucideIcons.sparkles,
                  size: 16,
                  color: AppColors.premium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  insight,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        height: 1.45,
                        color: context.appTheme.textSecondary,
                      ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: _valueRowHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < buckets.length; i++) ...[
                  if (i > 0) const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: _CashFlowAmountLabel(bucket: buckets[i]),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          SizedBox(
            height: _chartHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < buckets.length; i++) ...[
                  if (i > 0) const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: _CashFlowColumn(
                      bucket: buckets[i],
                      maxAmount: maxAmount,
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

class _CashFlowAmountLabel extends StatelessWidget {
  const _CashFlowAmountLabel({required this.bucket});

  final CashFlowBucket bucket;

  @override
  Widget build(BuildContext context) {
    if (bucket.amount <= 0) return const SizedBox.shrink();

    final color = bucket.isOverdue
        ? AppColors.error
        : bucket.isCurrentPeriod
            ? AppColors.accent
            : AppColors.premium;

    return Align(
      alignment: Alignment.bottomCenter,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          LoanSimulator.formatMoney(bucket.amount),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
                height: 1.1,
              ),
        ),
      ),
    );
  }
}

class _CashFlowColumn extends StatelessWidget {
  const _CashFlowColumn({
    required this.bucket,
    required this.maxAmount,
  });

  final CashFlowBucket bucket;
  final double maxAmount;

  @override
  Widget build(BuildContext context) {
    final color = bucket.isOverdue
        ? AppColors.error
        : bucket.isCurrentPeriod
            ? AppColors.accent
            : AppColors.premium;

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = AppSpacing.sm;
        final footerHeight = bucket.installmentCount > 0 ? 30.0 : 18.0;
        final barMaxHeight =
            (constraints.maxHeight - footerHeight - gap).clamp(4.0, 72.0);
        final barHeight = maxAmount <= 0 || bucket.amount <= 0
            ? 4.0
            : (bucket.amount / maxAmount * barMaxHeight)
                .clamp(4.0, barMaxHeight);

        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              width: 24,
              height: barHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    color.withValues(alpha: 0.35),
                    color.withValues(alpha: 0.9),
                  ],
                ),
              ),
            ),
            const SizedBox(height: gap),
            SizedBox(
              height: footerHeight,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    bucket.label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: bucket.isCurrentPeriod
                              ? FontWeight.w700
                              : FontWeight.w500,
                          fontSize: 9,
                          height: 1.15,
                          color: bucket.isOverdue ? AppColors.error : null,
                        ),
                  ),
                  if (bucket.installmentCount > 0)
                    Text(
                      '${bucket.installmentCount} parc.',
                      maxLines: 1,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontSize: 8,
                            height: 1.1,
                            color: context.appTheme.textSecondary,
                          ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DashboardAlertCard extends StatelessWidget {
  const _DashboardAlertCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _DashboardSurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: AppDecorations.iconBadge(color: AppColors.error),
            child: const AttentionLucideIcon(
              icon: LucideIcons.triangle_alert,
              size: 22,
              color: AppColors.error,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          Icon(
            LucideIcons.chevron_right,
            size: 20,
            color: context.appTheme.textSecondary,
          ),
        ],
      ),
    );
  }
}

class _DashboardSectionLabel extends StatelessWidget {
  const _DashboardSectionLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final lineColor = context.appTheme.border;
    final titleStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        );

    return Row(
      children: [
        Expanded(child: _DashedDividerLine(color: lineColor)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(title, style: titleStyle),
        ),
        Expanded(child: _DashedDividerLine(color: lineColor)),
      ],
    );
  }
}

class _DashedDividerLine extends StatelessWidget {
  const _DashedDividerLine({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          height: 20,
          width: constraints.maxWidth,
          child: Center(
            child: CustomPaint(
              size: Size(constraints.maxWidth, 1),
              painter: _DashedLinePainter(color: color),
            ),
          ),
        );
      },
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  _DashedLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    const dashWidth = 5.0;
    const dashSpace = 4.0;
    var x = 0.0;
    final y = size.height / 2;

    while (x < size.width) {
      final end = (x + dashWidth).clamp(0.0, size.width);
      canvas.drawLine(Offset(x, y), Offset(end, y), paint);
      x += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}

class _UpcomingDueTile extends StatelessWidget {
  const _UpcomingDueTile({required this.due});

  final UpcomingDueItem due;

  @override
  Widget build(BuildContext context) {
    final isOverdue = due.isOverdue;
    final accent = isOverdue ? AppColors.error : AppColors.accent;

    return _DashboardSurfaceCard(
      onTap: () => context.push(
        AppRoutes.loanDetail(
          due.loanId,
          highlightInstallment: due.installmentNumber,
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: AppDecorations.iconBadge(color: accent),
            child: isOverdue
                ? const AttentionLucideIcon(
                    icon: LucideIcons.triangle_alert,
                    size: 20,
                    color: AppColors.error,
                  )
                : Icon(
                    LucideIcons.calendar,
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
                  due.clientName,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Parcela ${due.installmentNumber} · '
                  '${LoanSimulator.formatDate(due.dueDate)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.appTheme.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                LoanSimulator.formatMoney(due.amount),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Icon(
                LucideIcons.chevron_right,
                size: 18,
                color: context.appTheme.textSecondary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
