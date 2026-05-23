import '../../dashboard/domain/dashboard_stats.dart';
import '../../loans/domain/entities/loan_with_client.dart';
import '../../loans/domain/loan_installment_status.dart';
import '../../loans/domain/loan_schedule_builder.dart';
import '../../loans/domain/loan_simulator.dart';
import '../../loans/domain/portfolio_lifetime_builder.dart';
import '../../payments/domain/entities/payment.dart';
import 'report_period.dart';
import 'reports_portfolio_overview.dart';
import 'reports_snapshot.dart';

abstract final class ReportsBuilder {
  static ReportsSnapshot build({
    required List<LoanWithClient> loans,
    required List<Payment> payments,
    required ReportPeriodRange period,
    DateTime? asOf,
  }) {
    final now = asOf ?? DateTime.now();

    final paymentsByLoan = <String, List<Payment>>{};
    for (final p in payments) {
      paymentsByLoan.putIfAbsent(p.loanId, () => []).add(p);
    }

    final loanById = {for (final l in loans) l.loan.id: l};
    var receivedInPeriod = 0.0;
    var paymentsCount = 0;
    final paymentRows = <ReportPaymentRow>[];

    for (final payment in payments) {
      final date = _paymentDate(payment);
      if (date == null || !period.contains(date)) continue;

      final amount = LoanSimulator.parseAmount(payment.amount) ?? 0;
      receivedInPeriod += amount;
      paymentsCount++;

      final loan = loanById[payment.loanId];
      paymentRows.add(
        ReportPaymentRow(
          date: date,
          clientName: loan?.clientName ?? 'Cliente',
          loanId: payment.loanId,
          installmentNumber: payment.installmentNumber,
          amount: amount,
          method: payment.method,
        ),
      );
    }

    paymentRows.sort((a, b) => b.date.compareTo(a.date));

    var dueInPeriod = 0.0;
    var dueInstallmentsCount = 0;
    var overdueInPeriod = 0.0;
    var overdueInstallmentsCount = 0;
    final dueRows = <ReportDueRow>[];

    var hasActiveLoans = false;
    final hasAnyLoans = loans.isNotEmpty;
    final today = DateTime(now.year, now.month, now.day);

    for (final item in loans) {
      if ((item.loan.status ?? 'ativo') == 'quitado') continue;
      hasActiveLoans = true;

      final loanPayments = paymentsByLoan[item.loan.id] ?? [];
      final detail = LoanScheduleBuilder.build(
        loan: item.loan,
        payments: loanPayments,
        asOf: now,
      );
      if (detail == null) continue;

      for (final inst in detail.installments) {
        final due = DateTime(
          inst.dueDate.year,
          inst.dueDate.month,
          inst.dueDate.day,
        );
        if (!period.contains(due)) continue;

        if (inst.status == LoanInstallmentStatus.overdue) {
          overdueInPeriod += inst.amount;
          overdueInstallmentsCount++;
        } else if (inst.status == LoanInstallmentStatus.pending) {
          dueInPeriod += inst.amount;
          dueInstallmentsCount++;
          dueRows.add(
            ReportDueRow(
              dueDate: due,
              clientName: item.clientName,
              loanId: item.loan.id,
              installmentNumber: inst.number,
              amount: inst.amount,
            ),
          );
        }
      }
    }

    dueRows.sort((a, b) => a.dueDate.compareTo(b.dueDate));

    final delinquency = _aggregateDelinquency(
      loans: loans,
      paymentsByLoan: paymentsByLoan,
      today: today,
      periodFilter: period,
    );
    final aging = delinquency.aging;
    final delinquentClients = delinquency.clients;

    final summary = ReportsPeriodSummary(
      receivedInPeriod: receivedInPeriod,
      paymentsCount: paymentsCount,
      dueInPeriod: dueInPeriod,
      dueInstallmentsCount: dueInstallmentsCount,
      overdueInPeriod: overdueInPeriod,
      overdueInstallmentsCount: overdueInstallmentsCount,
    );

    return ReportsSnapshot(
      period: period,
      generatedAt: now,
      summary: summary,
      aging: aging,
      delinquentClients: delinquentClients,
      paymentsInPeriod: paymentRows,
      dueInPeriod: dueRows,
      hasActiveLoans: hasActiveLoans,
      hasAnyLoans: hasAnyLoans,
    );
  }

  static ReportsPortfolioOverview buildPortfolio({
    required List<LoanWithClient> loans,
    required List<Payment> payments,
    DateTime? asOf,
  }) {
    final now = asOf ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final stats = DashboardStatsBuilder.build(
      loans: loans,
      payments: payments,
      asOf: now,
    );
    final lifetime = PortfolioLifetimeBuilder.build(
      loans: loans,
      payments: payments,
      asOf: now,
    );
    final hasAnyLoans = lifetime.hasLoans;
    final historicalOnly = hasAnyLoans && stats.activeLoansCount == 0;

    final paymentsByLoan = <String, List<Payment>>{};
    for (final p in payments) {
      paymentsByLoan.putIfAbsent(p.loanId, () => []).add(p);
    }

    var quitados = 0;
    var hasActiveLoans = false;
    var dueThisMonth = 0.0;
    var dueNextMonth = 0.0;

    final thisMonthStart = DateTime(today.year, today.month);
    final thisMonthEnd = DateTime(today.year, today.month + 1, 0);
    final nextMonthStart = DateTime(today.year, today.month + 1);
    final nextMonthEnd = DateTime(today.year, today.month + 2, 0);

    final delinquency = _aggregateDelinquency(
      loans: loans,
      paymentsByLoan: paymentsByLoan,
      today: today,
      periodFilter: null,
    );

    for (final item in loans) {
      if ((item.loan.status ?? 'ativo') == 'quitado') {
        quitados++;
        continue;
      }
      hasActiveLoans = true;

      final detail = LoanScheduleBuilder.build(
        loan: item.loan,
        payments: paymentsByLoan[item.loan.id] ?? [],
        asOf: now,
      );
      if (detail == null) continue;

      for (final inst in detail.installments) {
        if (inst.status != LoanInstallmentStatus.pending) continue;
        final due = DateTime(
          inst.dueDate.year,
          inst.dueDate.month,
          inst.dueDate.day,
        );
        if (due.isBefore(today)) continue;
        if (!due.isBefore(thisMonthStart) && !due.isAfter(thisMonthEnd)) {
          dueThisMonth += inst.amount;
        }
        if (!due.isBefore(nextMonthStart) && !due.isAfter(nextMonthEnd)) {
          dueNextMonth += inst.amount;
        }
      }
    }

    final active = stats.activeLoansCount;
    final totalLent =
        historicalOnly ? lifetime.totalLent : stats.totalLent;
    final totalReceived =
        historicalOnly ? lifetime.totalReceived : stats.totalReceived;
    final totalRemaining = historicalOnly ? 0.0 : stats.totalRemaining;
    final remainingProfit =
        historicalOnly ? 0.0 : stats.remainingProfit;
    final expectedProfit =
        historicalOnly ? lifetime.realizedProfit : stats.expectedProfit;
    final realizedProfit = lifetime.realizedProfit;

    final contractTotal = historicalOnly
        ? lifetime.contractTotal
        : totalReceived + totalRemaining;
    final recoveryRatePercent = contractTotal > 0
        ? (totalReceived / contractTotal) * 100
        : 0.0;
    final profitMarginPercent = totalLent > 0
        ? (expectedProfit / totalLent) * 100
        : 0.0;
    final loanCountForAvg = historicalOnly ? lifetime.totalLoans : active;
    final averageProfitPerLoan = loanCountForAvg > 0
        ? expectedProfit / loanCountForAvg
        : 0.0;
    final averageTicketPerLoan = loanCountForAvg > 0
        ? totalLent / loanCountForAvg
        : 0.0;

    return ReportsPortfolioOverview(
      totalLent: totalLent,
      lifetimeTotalLent: lifetime.totalLent,
      totalReceived: totalReceived,
      totalRemaining: totalRemaining,
      remainingProfit: remainingProfit,
      expectedProfit: expectedProfit,
      averageProfitPerLoan: averageProfitPerLoan,
      averageTicketPerLoan: averageTicketPerLoan,
      recoveryRatePercent: recoveryRatePercent,
      profitMarginPercent: profitMarginPercent,
      activeLoans: active,
      activeClients: historicalOnly
          ? lifetime.clientCount
          : stats.clientsCount,
      quitadosLoans: historicalOnly ? lifetime.quitadosLoans : quitados,
      overdueInstallments: stats.overdueInstallments,
      overdueAmount: stats.overdueAmount,
      dueThisMonth: dueThisMonth,
      dueNextMonth: dueNextMonth,
      aging: delinquency.aging,
      delinquentClients: delinquency.clients,
      cashFlowByMonth: stats.cashFlowByMonth,
      hasActiveLoans: hasActiveLoans,
      hasAnyLoans: hasAnyLoans,
      realizedProfit: realizedProfit,
      isHistoricalOnly: historicalOnly,
    );
  }

  static _DelinquencyAggregate _aggregateDelinquency({
    required List<LoanWithClient> loans,
    required Map<String, List<Payment>> paymentsByLoan,
    required DateTime today,
    required ReportPeriodRange? periodFilter,
  }) {
    final agingAmounts = <String, double>{
      '1–7 dias': 0,
      '8–15 dias': 0,
      '16–30 dias': 0,
      '31+ dias': 0,
    };
    final agingCounts = <String, int>{
      '1–7 dias': 0,
      '8–15 dias': 0,
      '16–30 dias': 0,
      '31+ dias': 0,
    };
    final clientAgg = <String, DelinquencyClientRow>{};

    for (final item in loans) {
      if ((item.loan.status ?? 'ativo') == 'quitado') continue;

      final detail = LoanScheduleBuilder.build(
        loan: item.loan,
        payments: paymentsByLoan[item.loan.id] ?? [],
        asOf: today,
      );
      if (detail == null) continue;

      for (final inst in detail.installments) {
        if (inst.status != LoanInstallmentStatus.overdue) continue;

        final due = DateTime(
          inst.dueDate.year,
          inst.dueDate.month,
          inst.dueDate.day,
        );
        if (periodFilter != null && !periodFilter.contains(due)) continue;

        final days = today.difference(due).inDays;
        final bucket = _agingLabel(days);
        agingAmounts[bucket] = (agingAmounts[bucket] ?? 0) + inst.amount;
        agingCounts[bucket] = (agingCounts[bucket] ?? 0) + 1;

        final cid = item.loan.clientId;
        final existing = clientAgg[cid];
        if (existing == null) {
          clientAgg[cid] = DelinquencyClientRow(
            clientId: cid,
            clientName: item.clientName,
            overdueInstallments: 1,
            overdueAmount: inst.amount,
            maxDaysOverdue: days,
          );
        } else {
          clientAgg[cid] = DelinquencyClientRow(
            clientId: cid,
            clientName: item.clientName,
            overdueInstallments: existing.overdueInstallments + 1,
            overdueAmount: existing.overdueAmount + inst.amount,
            maxDaysOverdue:
                days > existing.maxDaysOverdue ? days : existing.maxDaysOverdue,
          );
        }
      }
    }

    final agingClientsByBucket = <String, Set<String>>{
      for (final k in agingAmounts.keys) k: {},
    };
    for (final row in clientAgg.values) {
      agingClientsByBucket[_agingLabel(row.maxDaysOverdue)]?.add(row.clientId);
    }

    final aging = [
      '1–7 dias',
      '8–15 dias',
      '16–30 dias',
      '31+ dias',
    ]
        .map(
          (label) => DelinquencyAgingBucket(
            label: label,
            installmentCount: agingCounts[label] ?? 0,
            amount: agingAmounts[label] ?? 0,
            clientCount: agingClientsByBucket[label]?.length ?? 0,
          ),
        )
        .toList();

    final clients = clientAgg.values.toList()
      ..sort((a, b) => b.overdueAmount.compareTo(a.overdueAmount));

    return _DelinquencyAggregate(aging: aging, clients: clients);
  }

  static String _agingLabel(int daysOverdue) {
    if (daysOverdue <= 7) return '1–7 dias';
    if (daysOverdue <= 15) return '8–15 dias';
    if (daysOverdue <= 30) return '16–30 dias';
    return '31+ dias';
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

class _DelinquencyAggregate {
  const _DelinquencyAggregate({
    required this.aging,
    required this.clients,
  });

  final List<DelinquencyAgingBucket> aging;
  final List<DelinquencyClientRow> clients;
}
