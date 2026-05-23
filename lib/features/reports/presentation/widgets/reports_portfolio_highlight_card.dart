import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../loans/domain/loan_simulator.dart';
import '../../domain/report_period.dart';
import '../../domain/reports_snapshot.dart';

/// Resumo em destaque — somente valores do período filtrado.
class ReportsPeriodSummaryCard extends StatelessWidget {
  const ReportsPeriodSummaryCard({
    super.key,
    required this.summary,
    required this.period,
  });

  final ReportsPeriodSummary summary;
  final ReportPeriodRange period;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accent.withValues(alpha: 0.14),
            AppColors.accentSecondary.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.35)),
        boxShadow: context.appTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: const Icon(
                  LucideIcons.chart_column,
                  size: 22,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resumo do período',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    Text(
                      period.rangeCaption,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: context.appTheme.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _HeroMetric(
            label: 'Recebido',
            value: LoanSimulator.formatMoney(summary.receivedInPeriod),
            subtitle: '${summary.paymentsCount} pagamento(s)',
            icon: LucideIcons.banknote,
            color: AppColors.success,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _CompactMetric(
                  label: 'A receber',
                  value: LoanSimulator.formatMoney(summary.dueInPeriod),
                  subtitle:
                      '${summary.dueInstallmentsCount} parcela(s) com vencimento no período',
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _CompactMetric(
                  label: 'Em atraso',
                  value: LoanSimulator.formatMoney(summary.overdueInPeriod),
                  subtitle:
                      '${summary.overdueInstallmentsCount} parcela(s) vencidas no período',
                  color: AppColors.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: context.appTheme.textSecondary,
                      ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: color,
                        height: 1.1,
                      ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: context.appTheme.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactMetric extends StatelessWidget {
  const _CompactMetric({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  final String label;
  final String value;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: context.appTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: color,
                  height: 1.1,
                ),
          ),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: context.appTheme.textSecondary,
                  fontSize: 10,
                  height: 1.25,
                ),
          ),
        ],
      ),
    );
  }
}
