import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/reports_snapshot.dart';
import 'report_period_filter_card.dart';
import 'reports_portfolio_highlight_card.dart';
import 'reports_shared_sections.dart';

/// Aba Por período — filtro + métricas e listas do intervalo.
class ReportsPeriodTab extends StatelessWidget {
  const ReportsPeriodTab({
    required this.snapshot,
    super.key,
    this.adminUserId,
  });

  final ReportsSnapshot snapshot;

  /// Painel admin: filtro de período isolado por usuário alvo.
  final String? adminUserId;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: ReportPeriodFilterCard(adminUserId: adminUserId),
        ),
        if (!snapshot.hasAnyLoans)
          const Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: ReportsEmptyHint(
              icon: LucideIcons.chart_column,
              title: 'Sem dados para relatório',
              subtitle:
                  'Cadastre clientes e empréstimos para gerar métricas.',
            ),
          )
        else if (!snapshot.hasPeriodData)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ReportsEmptyHint(
              icon: LucideIcons.calendar_off,
              title: 'Nada neste período',
              subtitle:
                  'Não há recebimentos nem parcelas com vencimento entre '
                  '${snapshot.period.rangeCaption}. Tente outro filtro.',
            ),
          )
        else ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              0,
            ),
            child: ReportsPeriodSummaryCard(
              summary: snapshot.summary,
              period: snapshot.period,
            ),
          ),
          if (snapshot.delinquentClients.isNotEmpty)
            ReportSection(
              title: 'Inadimplência no período',
              icon: LucideIcons.triangle_alert,
              child: ReportsAgingSection(
                aging: snapshot.aging,
                clients: snapshot.delinquentClients,
              ),
            ),
          if (snapshot.dueInPeriod.isNotEmpty)
            ReportSection(
              title: 'Parcelas a receber',
              icon: LucideIcons.calendar_clock,
              trailing: Text(
                '${snapshot.dueInPeriod.length}',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              child: ReportsDueSection(rows: snapshot.dueInPeriod),
            ),
          if (snapshot.paymentsInPeriod.isNotEmpty)
            ReportSection(
              title: 'Recebimentos',
              icon: LucideIcons.banknote,
              trailing: Text(
                '${snapshot.paymentsInPeriod.length}',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              child: ReportsPaymentsSection(rows: snapshot.paymentsInPeriod),
            ),
        ],
      ],
    );
  }
}
