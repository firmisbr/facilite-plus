import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:facilite_plus/features/dashboard/domain/dashboard_stats.dart';
import 'package:facilite_plus/features/loans/domain/entities/loan.dart';
import 'package:facilite_plus/features/loans/domain/entities/loan_with_client.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
  });

  test('atraso de ontem nao entra no valor de hoje', () {
    const loan = Loan(
      id: 'l1',
      clientId: 'c1',
      amount: '2000',
      interest: '0',
      installments: 10,
      periodicity: 'diaria',
      firstDueDate: '2026-08-14',
      status: 'ativo',
    );

    final stats = DashboardStatsBuilder.build(
      loans: [LoanWithClient(loan: loan, clientName: 'Maria')],
      payments: const [],
      asOf: DateTime(2026, 8, 15, 12),
    );

    final timeline = stats.cashFlowTimeline;
    expect(timeline.overdueAmount, 200);
    expect(timeline.hasOverdue, isTrue);

    final home = DashboardStatsBuilder.radarHomeItemIndex(
      timeline: timeline,
      granularity: CashFlowGranularity.day,
    );
    final overdueBucket = DashboardStatsBuilder.radarBucketAt(
      timeline: timeline,
      granularity: CashFlowGranularity.day,
      itemIndex: home,
    );
    final todayBucket = DashboardStatsBuilder.radarBucketAt(
      timeline: timeline,
      granularity: CashFlowGranularity.day,
      itemIndex: home + 1,
    );

    expect(overdueBucket.label, 'Atrasado');
    expect(overdueBucket.amount, 200);
    expect(overdueBucket.isOverdue, isTrue);
    expect(overdueBucket.isConsolidatedOverdue, isTrue);
    expect(todayBucket.label, 'Hoje');
    expect(todayBucket.amount, 200);
    expect(todayBucket.isOverdue, isFalse);
  });

  test('coluna atrasado fica imediatamente antes de hoje', () {
    const loan = Loan(
      id: 'l1',
      clientId: 'c1',
      amount: '300',
      interest: '0',
      installments: 3,
      periodicity: 'diaria',
      firstDueDate: '2026-08-13',
      status: 'ativo',
    );

    final stats = DashboardStatsBuilder.build(
      loans: [LoanWithClient(loan: loan, clientName: 'Maria')],
      payments: const [],
      asOf: DateTime(2026, 8, 15, 12),
    );
    final timeline = stats.cashFlowTimeline;

    final home = DashboardStatsBuilder.radarHomeItemIndex(
      timeline: timeline,
      granularity: CashFlowGranularity.day,
    );
    final labels = [
      for (var i = 0; i < 4; i++)
        DashboardStatsBuilder.radarBucketAt(
          timeline: timeline,
          granularity: CashFlowGranularity.day,
          itemIndex: home + i,
        ).label,
    ];

    expect(labels[0], 'Atrasado');
    expect(labels[1], 'Hoje');
    expect(labels[2], 'Amanhã');
  });

  test('ao rolar para ontem o atraso aparece vermelho na data original', () {
    const loan = Loan(
      id: 'l1',
      clientId: 'c1',
      amount: '2000',
      interest: '0',
      installments: 10,
      periodicity: 'diaria',
      firstDueDate: '2026-08-14',
      status: 'ativo',
    );

    final stats = DashboardStatsBuilder.build(
      loans: [LoanWithClient(loan: loan, clientName: 'Maria')],
      payments: const [],
      asOf: DateTime(2026, 8, 15, 12),
    );
    final timeline = stats.cashFlowTimeline;

    final yesterdayIndex = DashboardStatsBuilder.radarItemIndexForPeriod(
      timeline: timeline,
      granularity: CashFlowGranularity.day,
      periodIndex: -1,
    );
    final yesterday = DashboardStatsBuilder.radarBucketAt(
      timeline: timeline,
      granularity: CashFlowGranularity.day,
      itemIndex: yesterdayIndex,
    );

    expect(yesterday.amount, 200);
    expect(yesterday.isOverdue, isTrue);
    expect(yesterday.isConsolidatedOverdue, isFalse);
    expect(yesterday.label, isNot('Atrasado'));
    expect(yesterday.label, isNot('Hoje'));
  });

  test('atrasos em dias distintos ficam separados ao rolar', () {
    const loan = Loan(
      id: 'l1',
      clientId: 'c1',
      amount: '600',
      interest: '0',
      installments: 3,
      periodicity: 'diaria',
      firstDueDate: '2026-08-13',
      status: 'ativo',
    );

    final stats = DashboardStatsBuilder.build(
      loans: [LoanWithClient(loan: loan, clientName: 'Maria')],
      payments: const [],
      asOf: DateTime(2026, 8, 15, 12),
    );
    final timeline = stats.cashFlowTimeline;

    // 13 e 14 atrasados (R$ 200 cada); 15 é hoje (R$ 200).
    expect(timeline.overdueAmount, 400);

    final dayBefore = DashboardStatsBuilder.radarBucketAt(
      timeline: timeline,
      granularity: CashFlowGranularity.day,
      itemIndex: DashboardStatsBuilder.radarItemIndexForPeriod(
        timeline: timeline,
        granularity: CashFlowGranularity.day,
        periodIndex: -2,
      ),
    );
    final yesterday = DashboardStatsBuilder.radarBucketAt(
      timeline: timeline,
      granularity: CashFlowGranularity.day,
      itemIndex: DashboardStatsBuilder.radarItemIndexForPeriod(
        timeline: timeline,
        granularity: CashFlowGranularity.day,
        periodIndex: -1,
      ),
    );

    expect(dayBefore.amount, 200);
    expect(dayBefore.isOverdue, isTrue);
    expect(yesterday.amount, 200);
    expect(yesterday.isOverdue, isTrue);
  });

  test('total da janela nao conta atraso duas vezes', () {
    const loan = Loan(
      id: 'l1',
      clientId: 'c1',
      amount: '2000',
      interest: '0',
      installments: 10,
      periodicity: 'diaria',
      firstDueDate: '2026-08-14',
      status: 'ativo',
    );

    final stats = DashboardStatsBuilder.build(
      loans: [LoanWithClient(loan: loan, clientName: 'Maria')],
      payments: const [],
      asOf: DateTime(2026, 8, 15, 12),
    );
    final timeline = stats.cashFlowTimeline;
    final home = DashboardStatsBuilder.radarHomeItemIndex(
      timeline: timeline,
      granularity: CashFlowGranularity.day,
    );

    // Ontem + Atrasado + Hoje + Amanhã na mesma janela.
    final buckets = [
      for (var i = home - 1; i <= home + 2; i++)
        DashboardStatsBuilder.radarBucketAt(
          timeline: timeline,
          granularity: CashFlowGranularity.day,
          itemIndex: i,
        ),
    ];

    final naiveSum = buckets.fold<double>(0, (s, b) => s + b.amount);
    final windowTotal = DashboardStatsBuilder.radarWindowTotal(buckets);

    expect(naiveSum, greaterThan(windowTotal));
    // Atrasado 200 + Hoje 200 + Amanhã 200 = 600 (ontem não soma de novo).
    expect(windowTotal, 600);
  });

  test('semana atual nao inclui atraso de dias desta semana', () {
    // Sábado 15/08/2026 — segunda da semana é 10/08.
    const loan = Loan(
      id: 'l1',
      clientId: 'c1',
      amount: '500',
      interest: '0',
      installments: 5,
      periodicity: 'diaria',
      firstDueDate: '2026-08-12', // quarta desta semana
      status: 'ativo',
    );

    final stats = DashboardStatsBuilder.build(
      loans: [LoanWithClient(loan: loan, clientName: 'Maria')],
      payments: const [],
      asOf: DateTime(2026, 8, 15, 12),
    );
    final timeline = stats.cashFlowTimeline;

    final thisWeekIndex = DashboardStatsBuilder.radarItemIndexForPeriod(
      timeline: timeline,
      granularity: CashFlowGranularity.week,
      periodIndex: 0,
    );
    final thisWeek = DashboardStatsBuilder.radarBucketAt(
      timeline: timeline,
      granularity: CashFlowGranularity.week,
      itemIndex: thisWeekIndex,
    );

    // 12,13,14 atrasados; 15 e 16 agendados nesta semana → só 15+16 = 200.
    expect(thisWeek.label, 'Esta sem.');
    expect(thisWeek.amount, 200);
    expect(thisWeek.isOverdue, isFalse);
    expect(timeline.overdueAmount, 300);
  });
}
