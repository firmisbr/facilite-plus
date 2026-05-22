import 'package:intl/intl.dart';

import '../../loans/domain/entities/loan_with_client.dart';
import '../../loans/domain/loan_installment_status.dart';
import '../../loans/domain/loan_schedule_builder.dart';
import '../../loans/domain/loan_simulator.dart';
import '../../payments/domain/entities/payment.dart';

class UpcomingDueItem {
  const UpcomingDueItem({
    required this.loanId,
    required this.clientName,
    required this.installmentNumber,
    required this.dueDate,
    required this.amount,
    required this.isOverdue,
  });

  final String loanId;
  final String clientName;
  final int installmentNumber;
  final DateTime dueDate;
  final double amount;
  final bool isOverdue;
}

/// Coluna do radar: quanto pode entrar em uma semana (ou atrasado).
class CashFlowBucket {
  const CashFlowBucket({
    required this.label,
    required this.amount,
    required this.installmentCount,
    this.isOverdue = false,
    this.isCurrentWeek = false,
  });

  final String label;
  final double amount;
  final int installmentCount;
  final bool isOverdue;
  final bool isCurrentWeek;
}

class DashboardStats {
  const DashboardStats({
    required this.activeLoansCount,
    required this.clientsCount,
    required this.totalLent,
    required this.totalReceived,
    required this.totalRemaining,
    required this.expectedProfit,
    required this.overdueInstallments,
    required this.overdueAmount,
    required this.upcomingDues,
    required this.cashFlowBuckets,
    this.cashFlowInsight,
  });

  final int activeLoansCount;
  final int clientsCount;
  final double totalLent;
  final double totalReceived;
  final double totalRemaining;
  final double expectedProfit;
  final int overdueInstallments;
  final double overdueAmount;
  final List<UpcomingDueItem> upcomingDues;
  final List<CashFlowBucket> cashFlowBuckets;
  final String? cashFlowInsight;

  static const empty = DashboardStats(
    activeLoansCount: 0,
    clientsCount: 0,
    totalLent: 0,
    totalReceived: 0,
    totalRemaining: 0,
    expectedProfit: 0,
    overdueInstallments: 0,
    overdueAmount: 0,
    upcomingDues: [],
    cashFlowBuckets: [],
  );
}

abstract final class DashboardStatsBuilder {
  static const _weekHorizon = 6;

  static DashboardStats build({
    required List<LoanWithClient> loans,
    required List<Payment> payments,
    DateTime? asOf,
  }) {
    if (loans.isEmpty) return DashboardStats.empty;

    final now = asOf ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final currentWeekStart = _weekStartMonday(today);

    final paymentsByLoan = <String, List<Payment>>{};
    for (final payment in payments) {
      paymentsByLoan.putIfAbsent(payment.loanId, () => []).add(payment);
    }

    var totalLent = 0.0;
    var totalReceived = 0.0;
    var totalRemaining = 0.0;
    var expectedProfit = 0.0;
    var overdueInstallments = 0;
    var overdueAmount = 0.0;
    var activeCount = 0;
    final clientIds = <String>{};
    final upcoming = <UpcomingDueItem>[];

    var overdueBucketAmount = 0.0;
    var overdueBucketCount = 0;
    final weekAmounts = <DateTime, double>{};
    final weekCounts = <DateTime, int>{};

    for (final item in loans) {
      clientIds.add(item.loan.clientId);
      final isActive = (item.loan.status ?? 'ativo') == 'ativo';
      if (!isActive) continue;

      activeCount++;
      final loanPayments = paymentsByLoan[item.loan.id] ?? [];
      final detail = LoanScheduleBuilder.build(
        loan: item.loan,
        payments: loanPayments,
        asOf: now,
      );

      if (detail == null) {
        totalLent += LoanSimulator.parseAmount(item.loan.amount) ?? 0;
        continue;
      }

      totalLent += detail.manager.principal;
      totalReceived += detail.overview.paidAmount;
      totalRemaining += detail.overview.remainingAmount;
      expectedProfit += detail.manager.totalProfit;
      overdueInstallments += detail.overview.overdueInstallments;

      LoanInstallmentItem? nextOpen;
      for (final installment in detail.installments) {
        if (installment.status == LoanInstallmentStatus.overdue) {
          overdueAmount += installment.amount;
        }

        if (installment.isPaid) continue;

        if (installment.status == LoanInstallmentStatus.overdue) {
          overdueBucketAmount += installment.amount;
          overdueBucketCount++;
        } else {
          final week = _weekStartMonday(
            DateTime(
              installment.dueDate.year,
              installment.dueDate.month,
              installment.dueDate.day,
            ),
          );
          weekAmounts[week] = (weekAmounts[week] ?? 0) + installment.amount;
          weekCounts[week] = (weekCounts[week] ?? 0) + 1;
        }

        if (nextOpen == null ||
            installment.dueDate.isBefore(nextOpen.dueDate)) {
          nextOpen = installment;
        }
      }

      if (nextOpen != null) {
        upcoming.add(
          UpcomingDueItem(
            loanId: item.loan.id,
            clientName: item.clientName,
            installmentNumber: nextOpen.number,
            dueDate: nextOpen.dueDate,
            amount: nextOpen.amount,
            isOverdue: nextOpen.status == LoanInstallmentStatus.overdue,
          ),
        );
      }
    }

    upcoming.sort((a, b) {
      if (a.isOverdue != b.isOverdue) return a.isOverdue ? -1 : 1;
      return a.dueDate.compareTo(b.dueDate);
    });

    final cashFlowBuckets = _buildCashFlowBuckets(
      currentWeekStart: currentWeekStart,
      overdueAmount: overdueBucketAmount,
      overdueCount: overdueBucketCount,
      weekAmounts: weekAmounts,
      weekCounts: weekCounts,
    );

    final cashFlowInsight = _buildCashFlowInsight(
      buckets: cashFlowBuckets,
      totalRemaining: totalRemaining,
    );

    return DashboardStats(
      activeLoansCount: activeCount,
      clientsCount: clientIds.length,
      totalLent: totalLent,
      totalReceived: totalReceived,
      totalRemaining: totalRemaining,
      expectedProfit: expectedProfit,
      overdueInstallments: overdueInstallments,
      overdueAmount: overdueAmount,
      upcomingDues: upcoming,
      cashFlowBuckets: cashFlowBuckets,
      cashFlowInsight: cashFlowInsight,
    );
  }

  static DateTime _weekStartMonday(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  static List<CashFlowBucket> _buildCashFlowBuckets({
    required DateTime currentWeekStart,
    required double overdueAmount,
    required int overdueCount,
    required Map<DateTime, double> weekAmounts,
    required Map<DateTime, int> weekCounts,
  }) {
    final buckets = <CashFlowBucket>[];
    final monthFmt = DateFormat('d MMM', 'pt_BR');

    if (overdueAmount > 0) {
      buckets.add(
        CashFlowBucket(
          label: 'Atrasado',
          amount: overdueAmount,
          installmentCount: overdueCount,
          isOverdue: true,
        ),
      );
    }

    for (var i = 0; i < _weekHorizon; i++) {
      final weekStart = currentWeekStart.add(Duration(days: 7 * i));
      final isCurrent = weekStart == currentWeekStart;
      final amount = weekAmounts[weekStart] ?? 0;
      final count = weekCounts[weekStart] ?? 0;

      if (!isCurrent && amount <= 0) continue;

      final label = isCurrent
          ? 'Esta sem.'
          : monthFmt.format(weekStart);

      buckets.add(
        CashFlowBucket(
          label: label,
          amount: amount,
          installmentCount: count,
          isCurrentWeek: isCurrent,
        ),
      );
    }

    final horizonEnd = currentWeekStart.add(
      Duration(days: 7 * (_weekHorizon - 1)),
    );
    for (final weekStart in weekAmounts.keys.toList()..sort()) {
      if (!weekStart.isAfter(horizonEnd)) continue;
      buckets.add(
        CashFlowBucket(
          label: monthFmt.format(weekStart),
          amount: weekAmounts[weekStart]!,
          installmentCount: weekCounts[weekStart] ?? 0,
        ),
      );
    }

    return buckets;
  }

  static String? _buildCashFlowInsight({
    required List<CashFlowBucket> buckets,
    required double totalRemaining,
  }) {
    if (buckets.isEmpty || totalRemaining <= 0) return null;

    CashFlowBucket? overdue;
    for (final b in buckets) {
      if (b.isOverdue) {
        overdue = b;
        break;
      }
    }
    final scheduled = buckets.where((b) => !b.isOverdue && b.amount > 0).toList();

    if (scheduled.isEmpty && overdue != null) {
      return 'Tudo em aberto (${LoanSimulator.formatMoney(totalRemaining)}) está '
          'atrasado — hora de acionar a cobrança.';
    }

    if (scheduled.isEmpty) return null;

    final peak = scheduled.reduce(
      (a, b) => a.amount >= b.amount ? a : b,
    );
    final peakMoney = LoanSimulator.formatMoney(peak.amount);
    final share = peak.amount / totalRemaining;

    if (overdue != null && overdue.amount >= totalRemaining * 0.4) {
      return 'Atrasos pesam: ${LoanSimulator.formatMoney(overdue.amount)} já '
          'passaram do vencimento. Pico agendado: ${peak.label} ($peakMoney).';
    }

    if (share >= 0.55) {
      return 'Concentração em ${peak.label}: até $peakMoney '
          '(${(share * 100).round()}% do que falta receber).';
    }

    CashFlowBucket? thisWeek;
    for (final b in buckets) {
      if (b.isCurrentWeek && b.amount > 0) {
        thisWeek = b;
        break;
      }
    }
    if (thisWeek != null) {
      return 'Esta semana pode entrar até '
          '${LoanSimulator.formatMoney(thisWeek.amount)} '
          '(${thisWeek.installmentCount} parcela(s)).';
    }

    return 'Maior entrada prevista em ${peak.label}: até $peakMoney.';
  }
}
