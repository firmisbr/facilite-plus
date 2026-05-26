import '../../loans/domain/entities/loan_with_client.dart';
import '../../loans/domain/loan_list_filter.dart';
import '../../loans/domain/loan_schedule_builder.dart';
import '../../loans/domain/loan_simulator.dart';
import '../../payments/domain/entities/payment.dart';
import '../../reports/domain/report_period.dart';
import 'dashboard_stats.dart';
import 'dashboard_summary_scope.dart';

class DashboardSummaryHeroMetrics {
  const DashboardSummaryHeroMetrics({
    required this.scope,
    required this.periodCaption,
    required this.lentTitle,
    required this.totalLent,
    this.lentFootnote,
    required this.remainingTitle,
    required this.totalRemaining,
    required this.receivedTitle,
    required this.totalReceived,
    required this.profitTitle,
    required this.remainingProfit,
  });

  final DashboardSummaryScope scope;
  final String periodCaption;
  final String lentTitle;
  final double totalLent;
  final String? lentFootnote;
  final String remainingTitle;
  final double totalRemaining;
  final String receivedTitle;
  final double totalReceived;
  final String profitTitle;
  final double remainingProfit;
}

abstract final class DashboardSummaryHeroBuilder {
  static DashboardSummaryHeroMetrics build({
    required DashboardStats stats,
    required List<LoanWithClient> loans,
    required List<Payment> payments,
    required DashboardSummaryScope scope,
    DateTime? asOf,
  }) {
    return switch (scope) {
      DashboardSummaryScope.total => _fromActivePortfolio(stats),
      DashboardSummaryScope.currentMonth => _forCurrentMonth(
          loans: loans,
          payments: payments,
          asOf: asOf,
        ),
    };
  }

  static DashboardSummaryHeroMetrics _fromActivePortfolio(DashboardStats stats) {
    final hasHistorical = stats.lifetime.quitadosLoans > 0;
    return DashboardSummaryHeroMetrics(
      scope: DashboardSummaryScope.total,
      periodCaption: 'Carteira ativa',
      lentTitle: hasHistorical ? 'Emprestado (carteira ativa)' : 'Total emprestado',
      totalLent: stats.totalLent,
      lentFootnote: hasHistorical
          ? 'Histórico (todos): ${LoanSimulator.formatMoney(stats.lifetime.totalLent)}'
          : null,
      remainingTitle: 'Total a receber (com juros)',
      totalRemaining: stats.totalRemaining,
      receivedTitle: 'Recebido',
      totalReceived: stats.totalReceived,
      profitTitle: 'Lucro a receber',
      remainingProfit: stats.remainingProfit,
    );
  }

  static DashboardSummaryHeroMetrics _forCurrentMonth({
    required List<LoanWithClient> loans,
    required List<Payment> payments,
    DateTime? asOf,
  }) {
    final now = asOf ?? DateTime.now();
    final period = ReportPeriodRange.resolvePreset(
      preset: ReportPeriodPreset.thisMonth,
      asOf: now,
    );

    final paymentsByLoan = <String, List<Payment>>{};
    for (final payment in payments) {
      paymentsByLoan.putIfAbsent(payment.loanId, () => []).add(payment);
    }

    var lentInMonth = 0.0;
    var receivedInMonth = 0.0;
    var dueInMonth = 0.0;
    var profitInMonth = 0.0;

    for (final payment in payments) {
      final date = _paymentDate(payment);
      if (date == null || !period.contains(date)) continue;
      receivedInMonth += LoanSimulator.parseAmount(payment.amount) ?? 0;
    }

    for (final item in loans) {
      final createdAt = DateTime.tryParse(item.loan.createdAt ?? '');
      if (createdAt != null && period.contains(createdAt)) {
        final loanPayments = paymentsByLoan[item.loan.id] ?? [];
        final detail = LoanScheduleBuilder.build(
          loan: item.loan,
          payments: loanPayments,
          asOf: now,
        );
        lentInMonth += detail?.manager.principal ??
            (LoanSimulator.parseAmount(item.loan.amount) ?? 0);
      }

      final loanPayments = paymentsByLoan[item.loan.id] ?? [];
      final flags = LoanListFilterHelper.flags(
        item: item,
        payments: loanPayments,
        asOf: now,
      );
      if (flags.isQuitado) continue;

      final detail = LoanScheduleBuilder.build(
        loan: item.loan,
        payments: loanPayments,
        asOf: now,
      );
      if (detail == null) continue;

      final profitRatio = detail.manager.totalWithInterest > 0
          ? detail.manager.totalProfit / detail.manager.totalWithInterest
          : 0.0;

      for (final installment in detail.installments) {
        if (installment.isPaid) continue;

        final due = DateTime(
          installment.dueDate.year,
          installment.dueDate.month,
          installment.dueDate.day,
        );
        if (!period.contains(due)) continue;

        dueInMonth += installment.amount;
        profitInMonth += installment.amount * profitRatio;
      }
    }

    return DashboardSummaryHeroMetrics(
      scope: DashboardSummaryScope.currentMonth,
      periodCaption: period.rangeCaption,
      lentTitle: 'Emprestado no mês',
      totalLent: lentInMonth,
      remainingTitle: 'A receber no mês (com juros)',
      totalRemaining: dueInMonth,
      receivedTitle: 'Recebido no mês',
      totalReceived: receivedInMonth,
      profitTitle: 'Lucro a receber no mês',
      remainingProfit: profitInMonth,
    );
  }

  static DateTime? _paymentDate(Payment payment) {
    if (payment.paymentDate != null) {
      final parsed = DateTime.tryParse(payment.paymentDate!);
      if (parsed != null) {
        return DateTime(parsed.year, parsed.month, parsed.day);
      }
    }
    if (payment.createdAt != null) {
      final parsed = DateTime.tryParse(payment.createdAt!);
      if (parsed != null) {
        return DateTime(parsed.year, parsed.month, parsed.day);
      }
    }
    return null;
  }
}
