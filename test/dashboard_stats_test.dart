import 'package:flutter_test/flutter_test.dart';
import 'package:facilite_plus/features/dashboard/domain/dashboard_stats.dart';
import 'package:facilite_plus/features/loans/domain/entities/loan.dart';
import 'package:facilite_plus/features/loans/domain/entities/loan_with_client.dart';
void main() {
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
    expect(stats.upcomingDues, isNotEmpty);
  });
}
