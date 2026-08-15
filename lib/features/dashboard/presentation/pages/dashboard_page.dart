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
import '../../../loans/presentation/widgets/installment_card_style.dart';
import '../../../loans/domain/portfolio_lifetime_builder.dart';
import '../../../loans/presentation/providers/loans_providers.dart';
import '../../../payments/presentation/providers/payments_providers.dart';
import '../../../update/presentation/providers/whats_new_provider.dart';
import '../../../update/presentation/widgets/whats_new_dialog.dart';
import '../providers/dashboard_providers.dart';
import '../providers/dashboard_summary_hero_provider.dart';
import '../../domain/dashboard_stats.dart';
import '../../domain/dashboard_summary_scope.dart';
import '../widgets/dashboard_summary_scope_dialog.dart';

/// Índice da aba Cobranças no [StatefulNavigationShell].
const _paymentsShellBranchIndex = 1;

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  bool _whatsNewChecked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowWhatsNew());
  }

  void _maybeShowWhatsNew() {
    if (_whatsNewChecked) return;
    _whatsNewChecked = true;
    ref.read(whatsNewProvider.future).then((state) {
      if (!mounted) return;
      if (!state.shouldShow || state.entry == null) return;
      showWhatsNewDialog(
        context,
        ref,
        version: state.currentVersion,
        entry: state.entry!,
      );
    });
  }

  /// Entre o tamanho anterior (100) e o reduzido (72).
  static const _logoHeight = 100.0;

  static void _openOverdueCollections(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(paymentsOverviewFilterRequestProvider.notifier);
    notifier.state = null;
    notifier.state = PaymentListFilter.atrasados;
    StatefulNavigationShell.of(context).goBranch(_paymentsShellBranchIndex);
  }

  @override
  Widget build(BuildContext context) {
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
                              child: const _DashboardSummaryHero(),
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

class _DashboardSummaryHero extends ConsumerWidget {
  const _DashboardSummaryHero();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metrics = ref.watch(dashboardSummaryHeroMetricsProvider);
    if (metrics == null) {
      return const SizedBox.shrink();
    }

    return _DashboardSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (metrics.scope == DashboardSummaryScope.currentMonth) ...[
                Text(
                  metrics.periodCaption,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              Text(
                metrics.lentTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: context.appTheme.textSecondary,
                      letterSpacing: 0.3,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                LoanSimulator.formatMoney(metrics.totalLent),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.accent,
                      height: 1.05,
                    ),
              ),
              if (metrics.lentFootnote != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  metrics.lentFootnote!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: context.appTheme.textSecondary,
                      ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              Text(
                metrics.remainingTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: context.appTheme.textSecondary,
                      letterSpacing: 0.3,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                LoanSimulator.formatMoney(metrics.totalRemaining),
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
                      label: metrics.receivedTitle,
                      value: LoanSimulator.formatMoney(metrics.totalReceived),
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
                      label: metrics.profitTitle,
                      value: LoanSimulator.formatMoney(metrics.remainingProfit),
                      color: AppColors.premium,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            top: -AppSpacing.xs,
            right: -AppSpacing.xs,
            child: IconButton(
              tooltip: 'Período do resumo',
              icon: Icon(
                Icons.more_vert,
                color: context.appTheme.textSecondary,
              ),
              onPressed: () => showDashboardSummaryScopeDialog(context, ref),
            ),
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
  final ScrollController _scrollController = ScrollController();

  static const _visibleColumns = 5;
  static const _columnGap = 2.0;
  static const _chartHeight = 120.0;
  static const _valueRowHeight = 36.0;

  int _firstVisibleIndex = 0;
  double _visibleMaxAmount = 0;
  double _columnWidth = 0;
  double _windowTotal = 0;
  bool _isAtToday = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToToday());
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  CashFlowTimeline get _timeline => widget.stats.cashFlowTimeline;

  int get _itemCount => DashboardStatsBuilder.radarItemCount(
        timeline: _timeline,
        granularity: _granularity,
      );

  int get _homeItemIndex => DashboardStatsBuilder.radarHomeItemIndex(
        timeline: _timeline,
        granularity: _granularity,
      );

  void _onScroll() {
    if (!_scrollController.hasClients || _columnWidth <= 0) return;

    final stride = _columnWidth + _columnGap;
    final firstIndex =
        (_scrollController.offset / stride).floor().clamp(0, _itemCount - 1);
    final lastIndex = (firstIndex + _visibleColumns - 1).clamp(0, _itemCount - 1);

    var maxAmount = 0.0;
    final windowBuckets = <CashFlowBucket>[];
    for (var i = firstIndex; i <= lastIndex; i++) {
      final bucket = DashboardStatsBuilder.radarBucketAt(
        timeline: _timeline,
        granularity: _granularity,
        itemIndex: i,
      );
      windowBuckets.add(bucket);
      if (bucket.amount > maxAmount) maxAmount = bucket.amount;
    }
    final windowTotal =
        DashboardStatsBuilder.radarWindowTotal(windowBuckets);

    final atToday = firstIndex == _homeItemIndex;
    if (firstIndex == _firstVisibleIndex &&
        maxAmount == _visibleMaxAmount &&
        atToday == _isAtToday &&
        windowTotal == _windowTotal) {
      return;
    }

    setState(() {
      _firstVisibleIndex = firstIndex;
      _visibleMaxAmount = maxAmount;
      _isAtToday = atToday;
      _windowTotal = windowTotal;
    });
  }

  void _jumpToToday({bool animate = false}) {
    if (!_scrollController.hasClients || _columnWidth <= 0) return;
    final target = _homeItemIndex * (_columnWidth + _columnGap);
    if (animate) {
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    } else {
      _scrollController.jumpTo(target);
    }
    _onScroll();
  }

  List<CashFlowBucket> _visibleBuckets() {
    final lastIndex =
        (_firstVisibleIndex + _visibleColumns - 1).clamp(0, _itemCount - 1);
    return [
      for (var i = _firstVisibleIndex; i <= lastIndex; i++)
        DashboardStatsBuilder.radarBucketAt(
          timeline: _timeline,
          granularity: _granularity,
          itemIndex: i,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final visibleBuckets = _visibleBuckets();
    final insight = _isAtToday
        ? DashboardStatsBuilder.insightFor(
            granularity: _granularity,
            buckets: visibleBuckets,
            totalRemaining: widget.stats.totalRemaining,
          )
        : null;
    final periodCaption = widget.stats.periodCaptionForVisible(
      granularity: _granularity,
      firstItemIndex: _firstVisibleIndex,
      visibleCount: _visibleColumns,
      itemCount: _itemCount,
    );

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
          _CashFlowGranularityPicker(
            value: _granularity,
            onChanged: (value) {
              if (value == _granularity) return;
              setState(() {
                _granularity = value;
                _firstVisibleIndex = 0;
                _isAtToday = true;
              });
              WidgetsBinding.instance
                  .addPostFrameCallback((_) => _jumpToToday());
            },
          ),
          const SizedBox(height: AppSpacing.md),
          _CashFlowPeriodHeader(
            caption: periodCaption,
            windowTotal: _windowTotal,
            isOnToday: _isAtToday,
            onJumpToToday: () => _jumpToToday(animate: true),
          ),
          if (insight != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.premium.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: AppColors.premium.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 1),
                    child: Icon(
                      LucideIcons.sparkles,
                      size: 15,
                      color: AppColors.premium,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      insight,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            height: 1.45,
                            color: context.appTheme.textSecondary,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final columnWidth = (constraints.maxWidth -
                      _columnGap * (_visibleColumns - 1)) /
                  _visibleColumns;
              final columnStride = columnWidth + _columnGap;

              if (_columnWidth != columnWidth) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  setState(() => _columnWidth = columnWidth);
                  _jumpToToday();
                  _onScroll();
                });
              }

              return SizedBox(
                height: _valueRowHeight + AppSpacing.xs + _chartHeight,
                child: ListView.builder(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  itemCount: _itemCount,
                  itemExtent: columnStride,
                  itemBuilder: (context, index) {
                    final bucket = DashboardStatsBuilder.radarBucketAt(
                      timeline: _timeline,
                      granularity: _granularity,
                      itemIndex: index,
                    );

                    return Padding(
                      padding: EdgeInsets.only(
                        right: index < _itemCount - 1 ? _columnGap : 0,
                      ),
                      child: SizedBox(
                        width: columnWidth,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(
                              height: _valueRowHeight,
                              child: _CashFlowAmountLabel(bucket: bucket),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            SizedBox(
                              height: _chartHeight,
                              child: _CashFlowColumn(
                                bucket: bucket,
                                maxAmount: _visibleMaxAmount,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.chevron_left,
                size: 14,
                color: context.appTheme.textSecondary.withValues(alpha: 0.7),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Arraste livremente para explorar os períodos',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: context.appTheme.textSecondary,
                      fontSize: 10,
                    ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Icon(
                LucideIcons.chevron_right,
                size: 14,
                color: context.appTheme.textSecondary.withValues(alpha: 0.7),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CashFlowGranularityPicker extends StatelessWidget {
  const _CashFlowGranularityPicker({
    required this.value,
    required this.onChanged,
  });

  final CashFlowGranularity value;
  final ValueChanged<CashFlowGranularity> onChanged;

  static const _options = [
    (CashFlowGranularity.day, 'Dia', LucideIcons.calendar_days),
    (CashFlowGranularity.week, 'Semana', LucideIcons.calendar_range),
    (CashFlowGranularity.month, 'Mês', LucideIcons.calendar),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: context.appTheme.border.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final segmentWidth = constraints.maxWidth / _options.length;

          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                left: segmentWidth * value.index,
                width: segmentWidth,
                top: 0,
                bottom: 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.18),
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  for (final option in _options)
                    Expanded(
                      child: _CashFlowGranularitySegment(
                        label: option.$2,
                        icon: option.$3,
                        selected: value == option.$1,
                        onTap: () => onChanged(option.$1),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CashFlowGranularitySegment extends StatelessWidget {
  const _CashFlowGranularitySegment({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? AppColors.accent
        : context.appTheme.textSecondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm + 2,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(height: 3),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 11,
                      color: color,
                      height: 1.1,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CashFlowPeriodHeader extends StatelessWidget {
  const _CashFlowPeriodHeader({
    required this.caption,
    required this.windowTotal,
    required this.isOnToday,
    required this.onJumpToToday,
  });

  final String caption;
  final double windowTotal;
  final bool isOnToday;
  final VoidCallback onJumpToToday;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                caption,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isOnToday
                          ? AppColors.accent
                          : Theme.of(context).colorScheme.onSurface,
                    ),
              ),
              if (windowTotal > 0) ...[
                const SizedBox(height: 2),
                Text(
                  'Total na janela: ${LoanSimulator.formatMoney(windowTotal)}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: context.appTheme.textSecondary,
                        fontSize: 10,
                      ),
                ),
              ],
            ],
          ),
        ),
        if (!isOnToday)
          TextButton.icon(
            onPressed: onJumpToToday,
            icon: const Icon(LucideIcons.rotate_ccw, size: 14),
            label: const Text('Hoje'),
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              textStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
      ],
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
                fontSize: 12,
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
            (constraints.maxHeight - footerHeight - gap).clamp(4.0, 84.0);
        final barHeight = maxAmount <= 0 || bucket.amount <= 0
            ? 4.0
            : (bucket.amount / maxAmount * barMaxHeight)
                .clamp(4.0, barMaxHeight);
        final barWidth = (constraints.maxWidth * 0.88).clamp(40.0, 72.0);
        final hasValue = bucket.amount > 0;

        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(
              height: barMaxHeight,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Container(
                      width: barWidth,
                      height: barMaxHeight,
                      decoration: BoxDecoration(
                        color: context.appTheme.border.withValues(alpha: 0.4),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      width: barWidth,
                      height: barHeight,
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: hasValue
                              ? [
                                  color.withValues(alpha: 0.55),
                                  color,
                                ]
                              : [
                                  color.withValues(alpha: 0.2),
                                  color.withValues(alpha: 0.32),
                                ],
                        ),
                        boxShadow: hasValue && bucket.isCurrentPeriod
                            ? [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                    ),
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
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      bucket.label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: bucket.isCurrentPeriod
                                ? FontWeight.w700
                                : FontWeight.w500,
                            fontSize: 10,
                            height: 1.15,
                            color: bucket.isOverdue
                                ? AppColors.error
                                : bucket.isCurrentPeriod
                                    ? AppColors.accent
                                    : null,
                          ),
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
    final style = InstallmentCardStyle.resolveFor(
      status: due.status,
      isDueToday: due.isDueToday,
    );
    final accent = style.color;

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
                ? AttentionLucideIcon(
                    icon: LucideIcons.triangle_alert,
                    size: 20,
                    color: accent,
                  )
                : due.isDueToday
                    ? Icon(LucideIcons.bell, size: 20, color: accent)
                    : Icon(LucideIcons.calendar, size: 20, color: accent),
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
                  LoanSimulator.formatDate(due.dueDate),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.appTheme.textSecondary,
                      ),
                ),
                if (due.isDueToday) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Vence hoje',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${due.installmentsProgressLabel} · '
                '${LoanSimulator.formatMoney(due.amount)}',
                textAlign: TextAlign.end,
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
