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

/// Agrupamento do radar de caixa (5 colunas no máximo).
enum CashFlowGranularity { day, week, month }

/// Coluna do radar: quanto pode entrar no período (ou atrasado).
class CashFlowBucket {
  const CashFlowBucket({
    required this.label,
    required this.amount,
    required this.installmentCount,
    this.isOverdue = false,
    this.isConsolidatedOverdue = false,
    this.isCurrentPeriod = false,
  });

  final String label;
  final double amount;
  final int installmentCount;
  final bool isOverdue;

  /// Coluna única "Atrasado" (soma de todos os atrasos).
  final bool isConsolidatedOverdue;

  /// Destaque visual do período atual (hoje / esta semana / este mês).
  final bool isCurrentPeriod;
}

/// Dados brutos do radar — permite paginar janelas de tempo na UI.
class CashFlowTimeline {
  const CashFlowTimeline({
    required this.today,
    required this.currentWeekStart,
    required this.overdueAmount,
    required this.overdueCount,
    required this.dayAmounts,
    required this.dayCounts,
    required this.weekAmounts,
    required this.weekCounts,
    required this.monthAmounts,
    required this.monthCounts,
  });

  static final empty = CashFlowTimeline(
    today: _epoch,
    currentWeekStart: _epoch,
    overdueAmount: 0,
    overdueCount: 0,
    dayAmounts: const {},
    dayCounts: const {},
    weekAmounts: const {},
    weekCounts: const {},
    monthAmounts: const {},
    monthCounts: const {},
  );

  static final _epoch = DateTime(1970);

  final DateTime today;
  final DateTime currentWeekStart;
  final double overdueAmount;
  final int overdueCount;
  final Map<DateTime, double> dayAmounts;
  final Map<DateTime, int> dayCounts;
  final Map<DateTime, double> weekAmounts;
  final Map<DateTime, int> weekCounts;
  final Map<DateTime, double> monthAmounts;
  final Map<DateTime, int> monthCounts;

  bool get hasOverdue => overdueAmount > 0;
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
    required this.cashFlowTimeline,
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
  final CashFlowTimeline cashFlowTimeline;
  final PortfolioLifetimeStats lifetime;

  bool get hasAnyLoans => lifetime.hasLoans;

  /// Carteira só com empréstimos quitados (ou sem saldo em aberto).
  bool get isHistoricalOnly => lifetime.hasLoans && activeLoansCount == 0;

  static final empty = DashboardStats(
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
    cashFlowTimeline: CashFlowTimeline.empty,
    lifetime: PortfolioLifetimeStats.empty,
  );

  List<CashFlowBucket> cashFlowFor(
    CashFlowGranularity granularity, {
    int offset = 0,
  }) {
    if (offset == 0) {
      return switch (granularity) {
        CashFlowGranularity.day => cashFlowByDay,
        CashFlowGranularity.week => cashFlowByWeek,
        CashFlowGranularity.month => cashFlowByMonth,
      };
    }
    return DashboardStatsBuilder.bucketsFor(
      granularity: granularity,
      timeline: cashFlowTimeline,
      offset: offset,
    );
  }

  String periodCaption(CashFlowGranularity granularity, int offset) =>
      DashboardStatsBuilder.periodCaption(
        granularity: granularity,
        timeline: cashFlowTimeline,
        offset: offset,
      );

  String periodCaptionForVisible({
    required CashFlowGranularity granularity,
    required int firstItemIndex,
    required int visibleCount,
    required int itemCount,
  }) =>
      DashboardStatsBuilder.periodCaptionForVisible(
        granularity: granularity,
        timeline: cashFlowTimeline,
        firstItemIndex: firstItemIndex,
        visibleCount: visibleCount,
        itemCount: itemCount,
      );
}

abstract final class DashboardStatsBuilder {
  static const _maxRadarColumns = 5;

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

        final dueDay = DateTime(
          installment.dueDate.year,
          installment.dueDate.month,
          installment.dueDate.day,
        );
        final week = _weekStartMonday(dueDay);
        final month = DateTime(dueDay.year, dueDay.month);
        final currentMonth = DateTime(today.year, today.month);

        if (installment.status == LoanInstallmentStatus.overdue) {
          // Coluna consolidada "Atrasado" (não entra em Hoje / esta sem. / este mês).
          overdueBucketAmount += installment.amount;
          overdueBucketCount++;

          // Também na data original — ao rolar para trás a barra aparece vermelha.
          dayAmounts[dueDay] = (dayAmounts[dueDay] ?? 0) + installment.amount;
          dayCounts[dueDay] = (dayCounts[dueDay] ?? 0) + 1;

          // Semanas/meses já fechados: atraso aparece no período original.
          if (week.isBefore(currentWeekStart)) {
            weekAmounts[week] = (weekAmounts[week] ?? 0) + installment.amount;
            weekCounts[week] = (weekCounts[week] ?? 0) + 1;
          }
          if (month.isBefore(currentMonth)) {
            monthAmounts[month] =
                (monthAmounts[month] ?? 0) + installment.amount;
            monthCounts[month] = (monthCounts[month] ?? 0) + 1;
          }
        } else {
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

    final cashFlowTimeline = CashFlowTimeline(
      today: today,
      currentWeekStart: currentWeekStart,
      overdueAmount: overdueBucketAmount,
      overdueCount: overdueBucketCount,
      dayAmounts: dayAmounts,
      dayCounts: dayCounts,
      weekAmounts: weekAmounts,
      weekCounts: weekCounts,
      monthAmounts: monthAmounts,
      monthCounts: monthCounts,
    );
    final cashFlowByDay = bucketsFor(
      granularity: CashFlowGranularity.day,
      timeline: cashFlowTimeline,
    );
    final cashFlowByWeek = bucketsFor(
      granularity: CashFlowGranularity.week,
      timeline: cashFlowTimeline,
    );
    final cashFlowByMonth = bucketsFor(
      granularity: CashFlowGranularity.month,
      timeline: cashFlowTimeline,
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
      cashFlowTimeline: cashFlowTimeline,
      lifetime: lifetime,
    );
  }

  static List<CashFlowBucket> bucketsFor({
    required CashFlowGranularity granularity,
    required CashFlowTimeline timeline,
    int offset = 0,
  }) {
    return switch (granularity) {
      CashFlowGranularity.day => _buildDayBuckets(
          timeline: timeline,
          offset: offset,
        ),
      CashFlowGranularity.week => _buildWeekBuckets(
          timeline: timeline,
          offset: offset,
        ),
      CashFlowGranularity.month => _buildMonthBuckets(
          timeline: timeline,
          offset: offset,
        ),
    };
  }

  static String periodCaption({
    required CashFlowGranularity granularity,
    required CashFlowTimeline timeline,
    required int offset,
  }) {
    if (offset == 0) {
      return switch (granularity) {
        CashFlowGranularity.day => 'Próximos dias',
        CashFlowGranularity.week => 'Próximas semanas',
        CashFlowGranularity.month => 'Próximos meses',
      };
    }

    final buckets = bucketsFor(
      granularity: granularity,
      timeline: timeline,
      offset: offset,
    );
    return _captionFromBuckets(buckets);
  }

  static (int min, int max) radarPeriodRange(CashFlowGranularity granularity) =>
      switch (granularity) {
        CashFlowGranularity.day => (-90, 365),
        CashFlowGranularity.week => (-52, 104),
        CashFlowGranularity.month => (-24, 36),
      };

  static int radarItemCount({
    required CashFlowTimeline timeline,
    required CashFlowGranularity granularity,
  }) {
    final (min, max) = radarPeriodRange(granularity);
    return (timeline.hasOverdue ? 1 : 0) + (max - min + 1);
  }

  /// Slot da coluna "Atrasado": imediatamente antes de "Hoje".
  static int? radarOverdueItemIndex({
    required CashFlowTimeline timeline,
    required CashFlowGranularity granularity,
  }) {
    if (!timeline.hasOverdue) return null;
    final (min, _) = radarPeriodRange(granularity);
    // Índice de Hoje sem a coluna Atrasado = -min; com Atrasado, Hoje anda +1.
    return -min;
  }

  static int radarPeriodIndexForItem({
    required CashFlowTimeline timeline,
    required CashFlowGranularity granularity,
    required int itemIndex,
  }) {
    final (min, _) = radarPeriodRange(granularity);
    final overdueIndex = radarOverdueItemIndex(
      timeline: timeline,
      granularity: granularity,
    );
    if (overdueIndex != null && itemIndex > overdueIndex) {
      return min + itemIndex - 1;
    }
    return min + itemIndex;
  }

  static int radarItemIndexForPeriod({
    required CashFlowTimeline timeline,
    required CashFlowGranularity granularity,
    required int periodIndex,
  }) {
    final (min, _) = radarPeriodRange(granularity);
    final overdueIndex = radarOverdueItemIndex(
      timeline: timeline,
      granularity: granularity,
    );
    final raw = periodIndex - min;
    if (overdueIndex != null && raw >= overdueIndex) {
      return raw + 1;
    }
    return raw;
  }

  static CashFlowBucket radarBucketAt({
    required CashFlowTimeline timeline,
    required CashFlowGranularity granularity,
    required int itemIndex,
  }) {
    final overdueIndex = radarOverdueItemIndex(
      timeline: timeline,
      granularity: granularity,
    );
    if (overdueIndex != null && itemIndex == overdueIndex) {
      return CashFlowBucket(
        label: 'Atrasado',
        amount: timeline.overdueAmount,
        installmentCount: timeline.overdueCount,
        isOverdue: true,
        isConsolidatedOverdue: true,
      );
    }

    final periodIndex = radarPeriodIndexForItem(
      timeline: timeline,
      granularity: granularity,
      itemIndex: itemIndex,
    );

    return switch (granularity) {
      CashFlowGranularity.day => _dayBucket(timeline, periodIndex),
      CashFlowGranularity.week => _weekBucket(timeline, periodIndex),
      CashFlowGranularity.month => _monthBucket(timeline, periodIndex),
    };
  }

  static String periodCaptionForVisible({
    required CashFlowGranularity granularity,
    required CashFlowTimeline timeline,
    required int firstItemIndex,
    required int visibleCount,
    required int itemCount,
  }) {
    final homeIndex = radarHomeItemIndex(
      timeline: timeline,
      granularity: granularity,
    );
    if (firstItemIndex == homeIndex) {
      return switch (granularity) {
        CashFlowGranularity.day => 'Próximos dias',
        CashFlowGranularity.week => 'Próximas semanas',
        CashFlowGranularity.month => 'Próximos meses',
      };
    }

    final lastItem =
        (firstItemIndex + visibleCount - 1).clamp(0, itemCount - 1);
    final buckets = [
      radarBucketAt(
        timeline: timeline,
        granularity: granularity,
        itemIndex: firstItemIndex,
      ),
      radarBucketAt(
        timeline: timeline,
        granularity: granularity,
        itemIndex: lastItem,
      ),
    ];
    return _captionFromBuckets(buckets);
  }

  /// Índice inicial do radar: com atraso, começa na coluna "Atrasado" (ao lado de Hoje).
  static int radarHomeItemIndex({
    required CashFlowTimeline timeline,
    required CashFlowGranularity granularity,
  }) {
    final overdueIndex = radarOverdueItemIndex(
      timeline: timeline,
      granularity: granularity,
    );
    if (overdueIndex != null) return overdueIndex;
    return radarItemIndexForPeriod(
      timeline: timeline,
      granularity: granularity,
      periodIndex: 0,
    );
  }

  /// Soma da janela sem contar atraso duas vezes (coluna Atrasado + dia original).
  static double radarWindowTotal(Iterable<CashFlowBucket> buckets) {
    final list = buckets.toList();
    final hasConsolidated = list.any((b) => b.isConsolidatedOverdue);
    var total = 0.0;
    for (final bucket in list) {
      if (hasConsolidated &&
          bucket.isOverdue &&
          !bucket.isConsolidatedOverdue) {
        continue;
      }
      total += bucket.amount;
    }
    return total;
  }

  static String _captionFromBuckets(List<CashFlowBucket> buckets) {
    final scheduled = buckets.where((b) => !b.isOverdue).toList();
    if (scheduled.isEmpty) {
      final overdue = buckets.where((b) => b.isOverdue);
      if (overdue.isNotEmpty) return overdue.first.label;
      return '';
    }

    final first = scheduled.first.label;
    final last = scheduled.last.label;
    if (first == last) return first;
    return '$first – $last';
  }

  static CashFlowBucket _dayBucket(CashFlowTimeline timeline, int periodIndex) {
    final dayFmt = DateFormat('d/M', 'pt_BR');
    final day = timeline.today.add(Duration(days: periodIndex));
    final amount = timeline.dayAmounts[day] ?? 0;
    final label = switch (periodIndex) {
      0 => 'Hoje',
      1 => 'Amanhã',
      _ => dayFmt.format(day),
    };
    return CashFlowBucket(
      label: label,
      amount: amount,
      installmentCount: timeline.dayCounts[day] ?? 0,
      isOverdue: periodIndex < 0 && amount > 0,
      isCurrentPeriod: periodIndex == 0,
    );
  }

  static CashFlowBucket _weekBucket(
    CashFlowTimeline timeline,
    int periodIndex,
  ) {
    final weekStart =
        timeline.currentWeekStart.add(Duration(days: 7 * periodIndex));
    final amount = timeline.weekAmounts[weekStart] ?? 0;
    return CashFlowBucket(
      label: periodIndex == 0 ? 'Esta sem.' : _weekRangeLabel(weekStart),
      amount: amount,
      installmentCount: timeline.weekCounts[weekStart] ?? 0,
      isOverdue: periodIndex < 0 && amount > 0,
      isCurrentPeriod: periodIndex == 0,
    );
  }

  static CashFlowBucket _monthBucket(
    CashFlowTimeline timeline,
    int periodIndex,
  ) {
    final monthFmt = DateFormat('MMM/yy', 'pt_BR');
    final month = DateTime(
      timeline.today.year,
      timeline.today.month + periodIndex,
    );
    final currentMonth =
        DateTime(timeline.today.year, timeline.today.month);
    final amount = timeline.monthAmounts[month] ?? 0;
    return CashFlowBucket(
      label: month == currentMonth ? 'Este mês' : monthFmt.format(month),
      amount: amount,
      installmentCount: timeline.monthCounts[month] ?? 0,
      isOverdue: periodIndex < 0 && amount > 0,
      isCurrentPeriod: periodIndex == 0,
    );
  }

  static DateTime _weekStartMonday(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  static String _weekRangeLabel(DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 6));
    final fmt = DateFormat('d/MM', 'pt_BR');
    return '${fmt.format(weekStart)} • ${fmt.format(weekEnd)}';
  }

  static int _periodSlots({
    required CashFlowTimeline timeline,
    required int offset,
  }) {
    if (offset == 0 && timeline.hasOverdue) {
      return _maxRadarColumns - 1;
    }
    return _maxRadarColumns;
  }

  static int _startPeriodIndex({
    required CashFlowTimeline timeline,
    required int offset,
  }) {
    return offset;
  }

  static List<CashFlowBucket> _buildDayBuckets({
    required CashFlowTimeline timeline,
    int offset = 0,
  }) {
    final buckets = <CashFlowBucket>[];
    final slots = _periodSlots(timeline: timeline, offset: offset);
    final startIndex = _startPeriodIndex(timeline: timeline, offset: offset);

    if (offset == 0 && timeline.hasOverdue) {
      buckets.add(
        CashFlowBucket(
          label: 'Atrasado',
          amount: timeline.overdueAmount,
          installmentCount: timeline.overdueCount,
          isOverdue: true,
          isConsolidatedOverdue: true,
        ),
      );
    }

    for (var i = 0; i < slots; i++) {
      buckets.add(_dayBucket(timeline, startIndex + i));
    }

    return buckets;
  }

  static List<CashFlowBucket> _buildWeekBuckets({
    required CashFlowTimeline timeline,
    int offset = 0,
  }) {
    final buckets = <CashFlowBucket>[];
    final slots = _periodSlots(timeline: timeline, offset: offset);
    final startIndex = _startPeriodIndex(timeline: timeline, offset: offset);

    if (offset == 0 && timeline.hasOverdue) {
      buckets.add(
        CashFlowBucket(
          label: 'Atrasado',
          amount: timeline.overdueAmount,
          installmentCount: timeline.overdueCount,
          isOverdue: true,
          isConsolidatedOverdue: true,
        ),
      );
    }

    for (var i = 0; i < slots; i++) {
      buckets.add(_weekBucket(timeline, startIndex + i));
    }

    return buckets;
  }

  static List<CashFlowBucket> _buildMonthBuckets({
    required CashFlowTimeline timeline,
    int offset = 0,
  }) {
    final buckets = <CashFlowBucket>[];
    final slots = _periodSlots(timeline: timeline, offset: offset);
    final startIndex = _startPeriodIndex(timeline: timeline, offset: offset);

    if (offset == 0 && timeline.hasOverdue) {
      buckets.add(
        CashFlowBucket(
          label: 'Atrasado',
          amount: timeline.overdueAmount,
          installmentCount: timeline.overdueCount,
          isOverdue: true,
          isConsolidatedOverdue: true,
        ),
      );
    }

    for (var i = 0; i < slots; i++) {
      buckets.add(_monthBucket(timeline, startIndex + i));
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
