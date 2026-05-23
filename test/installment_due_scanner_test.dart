import 'package:flutter_test/flutter_test.dart';
import 'package:facilite_plus/features/loans/domain/entities/loan.dart';
import 'package:facilite_plus/features/loans/domain/entities/loan_with_client.dart';
import 'package:facilite_plus/services/notifications/installment_due_scanner.dart';

void main() {
  test('conta parcelas com vencimento no dia', () {
    const loan = Loan(
      id: 'l1',
      clientId: 'c1',
      amount: '1000',
      interest: '0',
      installments: 2,
      periodicity: 'mensal',
      firstDueDate: '2026-05-22',
      status: 'ativo',
    );

    final scan = InstallmentDueScanner.scan(
      loans: [LoanWithClient(loan: loan, clientName: 'Maria')],
      payments: const [],
      onDay: DateTime(2026, 5, 22),
    );

    expect(scan.dueOnDayCount, 1);
    expect(scan.dueOnDayClientNames, ['Maria']);
  });
}
