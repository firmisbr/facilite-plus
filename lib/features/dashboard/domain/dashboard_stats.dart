import 'package:intl/intl.dart';

import '../../loans/domain/entities/loan_with_client.dart';
import '../../loans/domain/loan_installment_status.dart';
import '../../loans/domain/loan_list_filter.dart';
import '../../loans/domain/loan_schedule_builder.dart';
import '../../loans/domain/loan_simulator.dart';
import '../../loans/domain/portfolio_lifetime_builder.dart';
import '../../payments/domain/entities/payment.dart';

class UpcomingDueItem {
  const UpcomingDueItem({
    required this.loanId,
    required this.clientName,
    required this.installmentNumber,
    required this.paidInstallments,
    required this.totalInstallments,
    required this.dueDate,
    required this.amount,
    required this.status,
    required this.isDueToday,
  });

  final String loanId;
  final String clientName;
  final int installmentNumber;
  final int paidInstallments;
  final int totalInstallments;
  final DateTime dueDate;
  final double amount;
  final LoanInstallmentStatus status;
  final bool isDueToday;

  bool get isOverdue => status == LoanInstallmentStatus.overdue;

  String get installmentsProgressLabel =>
      '$paidInstallments/$totalInstallments';
}

/// Agrupamento do radar de caixa (7 colunas no máximo).
enum CashFlowGranularity { day, week, month }

/// Coluna do radar: quanto pode entrar no período (ou atrasado).
class CashFlowBucket {
  const CashFlowBucket({
    required this.label,
    required this.amount,
    required this.installmentCount,
    this.isOverdue = false,
    this.isCurrentPeriod = false,
  });

  final String label;
  final double amount;
  final int installmentCount;
  final bool isOverdue;

  /// Destaque visual do período atual (hoje / esta semana / este mês).
  final bool isCurrentPeriod;
}

class DashboardStats {
  const DashboardStats({
    required this.activeLoansCount,
    required this.clientsCount,
    required this.totalLent,
    required this.totalReceived,
    required this.totalRemaining,
    required this.remainingProfit,
    required this.expectedProfit,
    required this.overdueInstallments,
    required this.overdueAmount,
    required this.upcomingDues,
    required this.cashFlowByDay,
    required this.cashFlowByWeek,
    required this.cashFlowByMonth,
    required this.lifetime,
  });

  final int activeLoansCount;
  final int clientsCount;
  final double totalLent;
  final double totalReceived;
  final double totalRemaining;

  /// Juros/lucro ainda nas parcelas em aberto.
  final double remainingProfit;

  /// Lucro total dos contratos ativos (todas as parcelas).
  final double expectedProfit;
  final int overdueInstallments;
  final double overdueAmount;
  final List<UpcomingDueItem> upcomingDues;
  final List<CashFlowBucket> cashFlowByDay;
  final List<CashFlowBucket> cashFlowByWeek;
  final List<CashFlowBucket> cashFlowByMonth;
  final PortfolioLifetimeStats lifetime;

  bool get hasAnyLoans => lifetime.hasLoans;

  /// Carteira só com empréstimos quitados (ou sem saldo em aberto).
  bool get isHistoricalOnly => lifetime.hasLoans && activeLoansCount == 0;

  static const empty = DashboardStats(
    activeLoansCount: 0,
    clientsCount: 0,
    totalLent: 0,
    totalReceived: 0,
    totalRemaining: 0,
    remainingProfit: 0,
    expectedProfit: 0,
    overdueInstallments: 0,
    overdueAmount: 0,
    upcomingDues: [],
    cashFlowByDay: [],
    cashFlowByWeek: [],
    cashFlowByMonth: [],
    lifetime: PortfolioLifetimeStats.empty,
  );

  List<CashFlowBucket> cashFlowFor(CashFlowGranularity granularity) =>
      switch (granularity) {
        CashFlowGranularity.day => cashFlowByDay,
        CashFlowGranularity.week => cashFlowByWeek,
        CashFlowGranularity.month => cashFlowByMonth,
      };
}

abstract final class DashboardStatsBuilder {
  static const _maxRadarColumns = 7;

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

    final lifetime = PortfolioLifetimeBuilder.build(
      loans: loans,
      payments: payments,
      asOf: now,
    );

    var totalLent = 0.0;
    var totalReceived = 0.0;
    var totalRemaining = 0.0;
    var remainingProfit = 0.0;
    var expectedProfit = 0.0;
    var overdueInstallments = 0;
    var overdueAmount = 0.0;
    var activeCount = 0;
    final clientIds = <String>{};
    final upcoming = <UpcomingDueItem>[];

    var overdueBucketAmount = 0.0;
    var overdueBucketCount = 0;
    final dayAmounts = <DateTime, double>{};
    final dayCounts = <DateTime, int>{};
    final weekAmounts = <DateTime, double>{};
    final weekCounts = <DateTime, int>{};
    final monthAmounts = <DateTime, double>{};
    final monthCounts = <DateTime, int>{};

    for (final item in loans) {
      final loanPayments = paymentsByLoan[item.loan.id] ?? [];
      final flags = LoanListFilterHelper.flags(
        item: item,
        payments: loanPayments,
        asOf: now,
      );

      // Quitados saem; ativos e atrasados entram (cronograma, não só o campo status).
      if (flags.isQuitado) continue;

      clientIds.add(item.loan.clientId);
      activeCount++;
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
      remainingProfit += detail.overview.remainingProfit;
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
          final dueDay = DateTime(
            installment.dueDate.year,
            installment.dueDate.month,
            installment.dueDate.day,
          );
          final week = _weekStartMonday(dueDay);
          final month = DateTime(dueDay.year, dueDay.month);

          dayAmounts[dueDay] = (dayAmounts[dueDay] ?? 0) + installment.amount;
          dayCounts[dueDay] = (dayCounts[dueDay] ?? 0) + 1;
          weekAmounts[week] = (weekAmounts[week] ?? 0) + installment.amount;
          weekCounts[week] = (weekCounts[week] ?? 0) + 1;
          monthAmounts[month] = (monthAmounts[month] ?? 0) + installment.amount;
          monthCounts[month] = (monthCounts[month] ?? 0) + 1;
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
            paidInstallments: detail.overview.paidInstallments,
            totalInstallments: detail.overview.totalInstallments,
            dueDate: nextOpen.dueDate,
            amount: nextOpen.amount,
            status: nextOpen.status,
            isDueToday: nextOpen.isDueToday,
          ),
        );
      }
    }

    upcoming.sort((a, b) {
      if (a.isOverdue != b.isOverdue) return a.isOverdue ? -1 : 1;
      return a.dueDate.compareTo(b.dueDate);
    });

    final cashFlowByDay = _buildDayBuckets(
      today: today,
      overdueAmount: overdueBucketAmount,
      overdueCount: overdueBucketCount,
      dayAmounts: dayAmounts,
      dayCounts: dayCounts,
    );
    final cashFlowByWeek = _buildWeekBuckets(
      currentWeekStart: currentWeekStart,
      overdueAmount: overdueBucketAmount,
      overdueCount: overdueBucketCount,
      weekAmounts: weekAmounts,
      weekCounts: weekCounts,
    );
    final cashFlowByMonth = _buildMonthBuckets(
      today: today,
      overdueAmount: overdueBucketAmount,
      overdueCount: overdueBucketCount,
      monthAmounts: monthAmounts,
      monthCounts: monthCounts,
    );

    return DashboardStats(
      activeLoansCount: activeCount,
      clientsCount: clientIds.length,
      totalLent: totalLent,
      totalReceived: totalReceived,
      totalRemaining: totalRemaining,
      remainingProfit: remainingProfit,
      expectedProfit: expectedProfit,
      overdueInstallments: overdueInstallments,
      overdueAmount: overdueAmount,
      upcomingDues: upcoming,
      cashFlowByDay: cashFlowByDay,
      cashFlowByWeek: cashFlowByWeek,
      cashFlowByMonth: cashFlowByMonth,
      lifetime: lifetime,
    );
  }

  static DateTime _weekStartMonday(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  static int _periodSlots({required double overdueAmount}) {
    final hasOverdue = overdueAmount > 0;
    return _maxRadarColumns - (hasOverdue ? 1 : 0);
  }

  static List<CashFlowBucket> _buildDayBuckets({
    required DateTime today,
    required double overdueAmount,
    required int overdueCount,
    required Map<DateTime, double> dayAmounts,
    required Map<DateTime, int> dayCounts,
  }) {
    final buckets = <CashFlowBucket>[];
    final dayFmt = DateFormat('d/M', 'pt_BR');
    final slots = _periodSlots(overdueAmount: overdueAmount);

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

    for (var i = 0; i < slots; i++) {
      final day = today.add(Duration(days: i));
      final amount = dayAmounts[day] ?? 0;
      final count = dayCounts[day] ?? 0;
      final label = switch (i) {
        0 => 'Hoje',
        1 => 'Amanhã',
        _ => dayFmt.format(day),
      };

      buckets.add(
        CashFlowBucket(
          label: label,
          amount: amount,
          installmentCount: count,
          isCurrentPeriod: i == 0,
        ),
      );
    }

    return buckets;
  }

  static List<CashFlowBucket> _buildWeekBuckets({
    required DateTime currentWeekStart,
    required double overdueAmount,
    required int overdueCount,
    required Map<DateTime, double> weekAmounts,
    required Map<DateTime, int> weekCounts,
  }) {
    final buckets = <CashFlowBucket>[];
    final weekFmt = DateFormat('d MMM', 'pt_BR');
    final slots = _periodSlots(overdueAmount: overdueAmount);

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

    for (var i = 0; i < slots; i++) {
      final weekStart = currentWeekStart.add(Duration(days: 7 * i));
      final amount = weekAmounts[weekStart] ?? 0;
      final count = weekCounts[weekStart] ?? 0;
      final label = i == 0 ? 'Esta sem.' : weekFmt.format(weekStart);

      buckets.add(
        CashFlowBucket(
          label: label,
          amount: amount,
          installmentCount: count,
          isCurrentPeriod: i == 0,
        ),
      );
    }

    return buckets;
  }

  static List<CashFlowBucket> _buildMonthBuckets({
    required DateTime today,
    required double overdueAmount,
    required int overdueCount,
    required Map<DateTime, double> monthAmounts,
    required Map<DateTime, int> monthCounts,
  }) {
    final buckets = <CashFlowBucket>[];
    final monthFmt = DateFormat('MMM', 'pt_BR');
    final slots = _periodSlots(overdueAmount: overdueAmount);
    final currentMonth = DateTime(today.year, today.month);

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

    for (var i = 0; i < slots; i++) {
      final month = DateTime(today.year, today.month + i);
      final amount = monthAmounts[month] ?? 0;
      final count = monthCounts[month] ?? 0;
      final label = month == currentMonth
          ? 'Este mês'
          : monthFmt.format(month);

      buckets.add(
        CashFlowBucket(
          label: label,
          amount: amount,
          installmentCount: count,
          isCurrentPeriod: i == 0,
        ),
      );
    }

    return buckets;
  }

  static String? insightFor({
    required CashFlowGranularity granularity,
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

    CashFlowBucket? currentPeriod;
    for (final b in buckets) {
      if (b.isCurrentPeriod && b.amount > 0) {
        currentPeriod = b;
        break;
      }
    }
    if (currentPeriod != null) {
      final periodLabel = switch (granularity) {
        CashFlowGranularity.day => 'Hoje pode entrar até',
        CashFlowGranularity.week => 'Esta semana pode entrar até',
        CashFlowGranularity.month => 'Este mês pode entrar até',
      };
      return '$periodLabel '
          '${LoanSimulator.formatMoney(currentPeriod.amount)} '
          '(${currentPeriod.installmentCount} parcela(s)).';
    }

    final periodWord = switch (granularity) {
      CashFlowGranularity.day => 'dia',
      CashFlowGranularity.week => 'semana',
      CashFlowGranularity.month => 'mês',
    };
    return 'Maior entrada prevista neste $periodWord: ${peak.label} '
        '(até $peakMoney).';
  }
}
