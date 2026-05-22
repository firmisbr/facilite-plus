import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:facilite_plus/features/dashboard/domain/dashboard_stats.dart';
import 'package:facilite_plus/features/loans/domain/entities/loan.dart';
import 'package:facilite_plus/features/loans/domain/entities/loan_with_client.dart';
import 'package:facilite_plus/features/payments/domain/entities/payment.dart';
void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
  });

  test('agrega totais de emprestimos ativos', () {
    const loan = Loan(
      id: 'l1',
      clientId: 'c1',
      amount: '1000',
      interest: '0',
      installments: 2,
      periodicity: 'mensal',
      firstDueDate: '2026-06-01',
      status: 'ativo',
    );

    final stats = DashboardStatsBuilder.build(
      loans: [LoanWithClient(loan: loan, clientName: 'Maria')],
      payments: const [],
      asOf: DateTime(2026, 5, 25),
    );

    expect(stats.activeLoansCount, 1);
    expect(stats.totalLent, 1000);
    expect(stats.totalRemaining, 1000);
    expect(stats.upcomingDues, hasLength(1));
    expect(stats.upcomingDues.first.installmentNumber, 1);
    expect(stats.cashFlowByWeek, isNotEmpty);
    expect(stats.cashFlowByWeek.length, lessThanOrEqualTo(7));
    expect(stats.cashFlowByDay.length, lessThanOrEqualTo(7));
    expect(
      DashboardStatsBuilder.insightFor(
        granularity: CashFlowGranularity.week,
        buckets: stats.cashFlowByWeek,
        totalRemaining: stats.totalRemaining,
      ),
      isNotNull,
    );
  });

  test('lista proxima parcela de cada emprestimo ativo sem limite de dias', () {
    const loanNear = Loan(
      id: 'l1',
      clientId: 'c1',
      amount: '1000',
      interest: '0',
      installments: 2,
      periodicity: 'mensal',
      firstDueDate: '2026-06-01',
      status: 'ativo',
    );
    const loanFar = Loan(
      id: 'l2',
      clientId: 'c2',
      amount: '500',
      interest: '0',
      installments: 3,
      periodicity: 'mensal',
      firstDueDate: '2027-01-01',
      status: 'ativo',
    );
    const loanDone = Loan(
      id: 'l3',
      clientId: 'c1',
      amount: '200',
      interest: '0',
      installments: 1,
      periodicity: 'mensal',
      firstDueDate: '2025-01-01',
      status: 'quitado',
    );

    final stats = DashboardStatsBuilder.build(
      loans: [
        LoanWithClient(loan: loanNear, clientName: 'Maria'),
        LoanWithClient(loan: loanFar, clientName: 'João'),
        LoanWithClient(loan: loanDone, clientName: 'Maria'),
      ],
      payments: const [
        Payment(
          id: 'p3',
          loanId: 'l3',
          amount: '200',
          installmentNumber: 1,
          paymentDate: '2025-01-02',
        ),
      ],
      asOf: DateTime(2026, 5, 25),
    );

    expect(stats.activeLoansCount, 2);
    expect(stats.upcomingDues, hasLength(2));
    expect(stats.upcomingDues.map((d) => d.loanId), containsAll(['l1', 'l2']));
  });

  test('inclui emprestimo com status atrasado apos desfazer parcelas', () {
    const loan = Loan(
      id: 'l1',
      clientId: 'c1',
      amount: '300',
      interest: '0',
      installments: 3,
      periodicity: 'mensal',
      firstDueDate: '2026-01-01',
      status: 'atrasado',
    );
    const payments = [
      Payment(
        id: 'p1',
        loanId: 'l1',
        amount: '100',
        installmentNumber: 1,
        paymentDate: '2026-01-05',
      ),
    ];

    final stats = DashboardStatsBuilder.build(
      loans: [LoanWithClient(loan: loan, clientName: 'Maria')],
      payments: payments,
      asOf: DateTime(2026, 5, 25),
    );

    expect(stats.activeLoansCount, 1);
    expect(stats.overdueInstallments, 2);
    expect(stats.overdueAmount, greaterThan(0));
    expect(stats.upcomingDues, isNotEmpty);
    expect(stats.upcomingDues.any((d) => d.isOverdue), isTrue);
    expect(
      stats.cashFlowByWeek.any((b) => b.isOverdue && b.amount > 0),
      isTrue,
    );
  });
}
