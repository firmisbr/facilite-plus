import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../dashboard/domain/dashboard_stats.dart';
import '../../../loans/domain/loan_simulator.dart';
import '../../domain/reports_snapshot.dart';

class ReportsEmptyHint extends StatelessWidget {
  const ReportsEmptyHint({
    required this.icon,
    required this.title,
    required this.subtitle,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 48, color: context.appTheme.textSecondary),
        const SizedBox(height: AppSpacing.md),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.appTheme.textSecondary,
              ),
        ),
      ],
    );
  }
}

class ReportSection extends StatelessWidget {
  const ReportSection({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
    super.key,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        0,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(color: context.appTheme.border),
          boxShadow: context.appTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: AppColors.accent),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            child,
          ],
        ),
      ),
    );
  }
}

class ReportsAgingSection extends StatelessWidget {
  const ReportsAgingSection({
    required this.aging,
    required this.clients,
    super.key,
  });

  final List<DelinquencyAgingBucket> aging;
  final List<DelinquencyClientRow> clients;

  @override
  Widget build(BuildContext context) {
    final topClients = clients.take(8).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IntrinsicHeight(
          child: Row(
            children: [
              for (var i = 0; i < aging.length; i++) ...[
                if (i > 0) const SizedBox(width: AppSpacing.xs),
                Expanded(child: _AgingBucketTile(bucket: aging[i])),
              ],
            ],
          ),
        ),
        if (topClients.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Clientes',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (var i = 0; i < topClients.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.xs),
            _DelinquentClientRow(row: topClients[i]),
          ],
          if (clients.length > 8)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                '+ ${clients.length - 8} no CSV',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: context.appTheme.textSecondary,
                    ),
              ),
            ),
        ],
      ],
    );
  }
}

class _AgingBucketTile extends StatelessWidget {
  const _AgingBucketTile({required this.bucket});

  final DelinquencyAgingBucket bucket;

  @override
  Widget build(BuildContext context) {
    final hasData = bucket.installmentCount > 0;
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.sm,
        horizontal: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: hasData
            ? AppColors.error.withValues(alpha: 0.08)
            : context.appTheme.border.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: hasData
              ? AppColors.error.withValues(alpha: 0.25)
              : context.appTheme.border,
        ),
      ),
      child: Column(
        children: [
          Text(
            bucket.label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 9,
                  height: 1.2,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${bucket.installmentCount}',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: hasData ? AppColors.error : null,
                ),
          ),
          Text(
            LoanSimulator.formatMoney(bucket.amount),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 9,
                  color: context.appTheme.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

class _DelinquentClientRow extends StatelessWidget {
  const _DelinquentClientRow({required this.row});

  final DelinquencyClientRow row;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        color: AppColors.error.withValues(alpha: 0.06),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.clientName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  '${row.overdueInstallments} parcela(s) · ${row.maxDaysOverdue} dia(s) atraso',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: context.appTheme.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          Text(
            LoanSimulator.formatMoney(row.overdueAmount),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.error,
                ),
          ),
        ],
      ),
    );
  }
}

class ReportsCashFlowBars extends StatelessWidget {
  const ReportsCashFlowBars({required this.buckets, super.key});

  final List<CashFlowBucket> buckets;

  @override
  Widget build(BuildContext context) {
    final scheduled = buckets.where((b) => !b.isOverdue).toList();
    if (scheduled.isEmpty) {
      return Text(
        'Sem entradas previstas.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: context.appTheme.textSecondary,
            ),
      );
    }

    final maxAmount =
        scheduled.map((b) => b.amount).fold(0.0, (a, b) => a > b ? a : b);

    return Column(
      children: scheduled.map((bucket) {
        final fraction = maxAmount > 0 ? bucket.amount / maxAmount : 0.0;
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Row(
            children: [
              SizedBox(
                width: 72,
                child: Text(
                  bucket.label,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  child: LinearProgressIndicator(
                    value: fraction.clamp(0.05, 1.0),
                    minHeight: 8,
                    backgroundColor:
                        context.appTheme.border.withValues(alpha: 0.5),
                    color: bucket.isCurrentPeriod
                        ? AppColors.accent
                        : AppColors.accentSecondary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              SizedBox(
                width: 88,
                child: Text(
                  LoanSimulator.formatMoney(bucket.amount),
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class ReportsDueSection extends StatelessWidget {
  const ReportsDueSection({required this.rows, super.key});

  final List<ReportDueRow> rows;

  static final _dateFmt = DateFormat('dd/MM/yyyy', 'pt_BR');

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return Text(
        'Nenhuma parcela com vencimento neste período.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: context.appTheme.textSecondary,
            ),
      );
    }

    final visible = rows.take(20).toList();

    return Column(
      children: [
        for (var i = 0; i < visible.length; i++) ...[
          if (i > 0) const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        visible[i].clientName,
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      Text(
                        'Venc. ${_dateFmt.format(visible[i].dueDate)} · '
                        'Parc. ${visible[i].installmentNumber}',
                        style: Theme.of(context).textTheme.labelSmall
                            ?.copyWith(
                              color: context.appTheme.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                Text(
                  LoanSimulator.formatMoney(visible[i].amount),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                      ),
                ),
              ],
            ),
          ),
        ],
        if (rows.length > 20)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              '+ ${rows.length - 20} no CSV',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: context.appTheme.textSecondary,
                  ),
            ),
          ),
      ],
    );
  }
}

class ReportsPaymentsSection extends StatelessWidget {
  const ReportsPaymentsSection({required this.rows, super.key});

  final List<ReportPaymentRow> rows;

  static final _dateFmt = DateFormat('dd/MM/yyyy', 'pt_BR');

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return Text(
        'Nenhum pagamento neste período.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: context.appTheme.textSecondary,
            ),
      );
    }

    final visible = rows.take(20).toList();

    return Column(
      children: [
        for (var i = 0; i < visible.length; i++) ...[
          if (i > 0) const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        visible[i].clientName,
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      Text(
                        '${_dateFmt.format(visible[i].date)}'
                        '${visible[i].installmentNumber != null ? ' · Parc. ${visible[i].installmentNumber}' : ''}'
                        '${visible[i].method != null ? ' · ${visible[i].method}' : ''}',
                        style: Theme.of(context).textTheme.labelSmall
                            ?.copyWith(
                              color: context.appTheme.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                Text(
                  LoanSimulator.formatMoney(visible[i].amount),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.success,
                      ),
                ),
              ],
            ),
          ),
        ],
        if (rows.length > 20)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              '+ ${rows.length - 20} no CSV',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: context.appTheme.textSecondary,
                  ),
            ),
          ),
      ],
    );
  }
}
