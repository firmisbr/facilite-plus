import 'package:flutter_test/flutter_test.dart';
import 'package:facilite_plus/features/loans/domain/entities/loan.dart';
import 'package:facilite_plus/features/loans/domain/loan_installment_status.dart';
import 'package:facilite_plus/features/loans/domain/loan_schedule_builder.dart';
import 'package:facilite_plus/features/payments/domain/entities/payment.dart';

void main() {
  test('parcela vinculada por installment_number', () {
    const loan = Loan(
      id: 'l1',
      clientId: 'c1',
      amount: '1000',
      interest: '0',
      installments: 2,
      periodicity: 'mensal',
      firstDueDate: '2026-01-01',
      status: 'ativo',
    );

    final payments = [
      const Payment(
        id: 'p1',
        loanId: 'l1',
        amount: '500.00',
        installmentNumber: 1,
        paymentDate: '2026-01-05',
      ),
    ];

    final detail = LoanScheduleBuilder.build(
      loan: loan,
      payments: payments,
      asOf: DateTime(2026, 6, 1),
    );

    expect(detail, isNotNull);
    expect(detail!.installments[0].status, LoanInstallmentStatus.paid);
    expect(detail.installments[0].paymentId, 'p1');
    expect(detail.installments[1].status, LoanInstallmentStatus.overdue);
    expect(detail.overview.paidInstallments, 1);
  });
}
