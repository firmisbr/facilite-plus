import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../loans/domain/loan_simulator.dart';
import '../../domain/reports_portfolio_overview.dart';
import 'reports_received_pending_chart.dart';
import 'reports_shared_sections.dart';

/// Aba Visão geral — métricas da carteira ativa (sem filtro de período).
class ReportsPortfolioTab extends StatelessWidget {
  const ReportsPortfolioTab({required this.overview, super.key});

  final ReportsPortfolioOverview overview;

  static final _monthFmt = DateFormat('MMMM', 'pt_BR');

  String _monthLabel(int monthOffset) {
    final d = DateTime(DateTime.now().year, DateTime.now().month + monthOffset);
    final name = _monthFmt.format(d);
    if (name.isEmpty) return monthOffset == 0 ? 'Este mês' : 'Próximo mês';
    final cap = name[0].toUpperCase() + name.substring(1);
    return monthOffset == 0 ? cap : cap;
  }

  @override
  Widget build(BuildContext context) {
    if (!overview.hasAnyLoans) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: ReportsEmptyHint(
          icon: LucideIcons.wallet,
          title: 'Sem dados para relatório',
          subtitle: 'Cadastre empréstimos para ver a análise da carteira.',
        ),
      );
    }

    final historical = overview.isHistoricalOnly;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (historical)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              0,
            ),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.35),
                ),
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
                      'Todos os empréstimos estão quitados. '
                      'Abaixo, o histórico da sua carteira.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            height: 1.35,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        _PortfolioHeroCard(overview: overview),
        const SizedBox(height: AppSpacing.md),
        ReportSection(
          title: historical ? 'Recebido vs. contratado' : 'Recebido vs. Pendente',
          icon: LucideIcons.chart_pie,
          child: ReportsReceivedPendingChart(
            received: overview.totalReceived,
            pending: overview.totalRemaining,
          ),
        ),
        ReportSection(
          title: 'Indicadores',
          icon: LucideIcons.percent,
          child: _IndicatorsGrid(overview: overview),
        ),
        ReportSection(
          title: 'Carteira',
          icon: LucideIcons.layers,
          child: _PortfolioStatsRow(overview: overview),
        ),
        if (!historical) ...[
          ReportSection(
            title: 'Previsão por mês',
            icon: LucideIcons.calendar_clock,
            child: Row(
              children: [
                Expanded(
                  child: _ForecastTile(
                    label: _monthLabel(0),
                    value: overview.dueThisMonth,
                    subtitle: 'A vencer',
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _ForecastTile(
                    label: _monthLabel(1),
                    value: overview.dueNextMonth,
                    subtitle: 'A vencer',
                  ),
                ),
              ],
            ),
          ),
        ],
        if (!historical && overview.cashFlowByMonth.isNotEmpty)
          ReportSection(
            title: 'Entradas previstas (meses)',
            icon: LucideIcons.chart_column_increasing,
            child: ReportsCashFlowBars(buckets: overview.cashFlowByMonth),
          ),
        if (overview.hasDelinquency)
          ReportSection(
            title: 'Inadimplência atual',
            icon: LucideIcons.triangle_alert,
            child: ReportsAgingSection(
              aging: overview.aging,
              clients: overview.delinquentClients,
            ),
          ),
      ],
    );
  }
}

class _PortfolioHeroCard extends StatelessWidget {
  const _PortfolioHeroCard({required this.overview});

  final ReportsPortfolioOverview overview;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        0,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.accent.withValues(alpha: 0.16),
              AppColors.accentSecondary.withValues(alpha: 0.12),
            ],
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.35)),
          boxShadow: context.appTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              overview.isHistoricalOnly
                  ? 'Histórico da carteira'
                  : 'Carteira ativa',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _HeroLine(
              label: overview.hasMixedPortfolio
                  ? 'Emprestado (carteira ativa)'
                  : 'Total emprestado',
              value: LoanSimulator.formatMoney(overview.totalLent),
              color: AppColors.accent,
            ),
            if (overview.hasMixedPortfolio) ...[
              const SizedBox(height: AppSpacing.sm),
              _HeroLine(
                label: 'Emprestado (histórico — todos)',
                value: LoanSimulator.formatMoney(overview.lifetimeTotalLent),
                color: context.appTheme.textSecondary,
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            _HeroLine(
              label: 'Total recebido',
              value: LoanSimulator.formatMoney(overview.totalReceived),
              color: AppColors.success,
            ),
            if (!overview.isHistoricalOnly) ...[
              const SizedBox(height: AppSpacing.sm),
              _HeroLine(
                label: 'Total a receber (com juros)',
                value: LoanSimulator.formatMoney(overview.totalRemaining),
                color: AppColors.accentSecondary,
              ),
              const SizedBox(height: AppSpacing.sm),
              _HeroLine(
                label: 'Lucro a receber',
                value: LoanSimulator.formatMoney(overview.remainingProfit),
                color: AppColors.premium,
              ),
            ] else ...[
              const SizedBox(height: AppSpacing.sm),
              _HeroLine(
                label: 'Lucro realizado',
                value: LoanSimulator.formatMoney(overview.realizedProfit),
                color: AppColors.premium,
              ),
              const SizedBox(height: AppSpacing.sm),
              _HeroLine(
                label: 'Empréstimos quitados',
                value: '${overview.quitadosLoans}',
                color: AppColors.success,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HeroLine extends StatelessWidget {
  const _HeroLine({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.appTheme.textSecondary,
                ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: color,
              ),
        ),
      ],
    );
  }
}

class _IndicatorsGrid extends StatelessWidget {
  const _IndicatorsGrid({required this.overview});

  final ReportsPortfolioOverview overview;

  @override
  Widget build(BuildContext context) {
    final items = [
      _Indicator(
        'Média de lucro / empréstimo',
        LoanSimulator.formatMoney(overview.averageProfitPerLoan),
      ),
      _Indicator(
        'Ticket médio',
        LoanSimulator.formatMoney(overview.averageTicketPerLoan),
      ),
      _Indicator(
        'Taxa de recuperação',
        '${overview.recoveryRatePercent.toStringAsFixed(1)}%',
      ),
      _Indicator(
        'Margem de lucro',
        '${overview.profitMarginPercent.toStringAsFixed(1)}%',
      ),
      _Indicator(
        'Em atraso',
        LoanSimulator.formatMoney(overview.overdueAmount),
      ),
      _Indicator(
        'Parcelas em atraso',
        '${overview.overdueInstallments}',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final twoCol = constraints.maxWidth >= 300;
        if (!twoCol) {
          return Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(height: AppSpacing.sm),
                _IndicatorTile(item: items[i]),
              ],
            ],
          );
        }
        return Column(
          children: [
            for (var i = 0; i < items.length; i += 2) ...[
              if (i > 0) const SizedBox(height: AppSpacing.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _IndicatorTile(item: items[i])),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: i + 1 < items.length
                        ? _IndicatorTile(item: items[i + 1])
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

class _Indicator {
  const _Indicator(this.label, this.value);

  final String label;
  final String value;
}

class _IndicatorTile extends StatelessWidget {
  const _IndicatorTile({required this.item});

  final _Indicator item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.appTheme.border.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: context.appTheme.textSecondary,
                  height: 1.25,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            item.value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _PortfolioStatsRow extends StatelessWidget {
  const _PortfolioStatsRow({required this.overview});

  final ReportsPortfolioOverview overview;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        children: [
          Expanded(
            child: _StatChip(
              label: 'Ativos',
              value: '${overview.activeLoans}',
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _StatChip(
              label: 'Clientes',
              value: '${overview.activeClients}',
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _StatChip(
              label: 'Quitados',
              value: '${overview.quitadosLoans}',
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: context.appTheme.border),
      ),
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.accent,
                ),
          ),
        ],
      ),
    );
  }
}

class _ForecastTile extends StatelessWidget {
  const _ForecastTile({
    required this.label,
    required this.value,
    required this.subtitle,
  });

  final String label;
  final double value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            LoanSimulator.formatMoney(value),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: context.appTheme.textSecondary,
                  fontSize: 10,
                ),
          ),
        ],
      ),
    );
  }
}
