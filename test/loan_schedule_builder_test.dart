import 'package:flutter_test/flutter_test.dart';
import 'package:facilite_plus/features/loans/domain/entities/loan.dart';
import 'package:facilite_plus/features/loans/domain/loan_installment_status.dart';
import 'package:facilite_plus/features/loans/domain/loan_schedule_builder.dart';
import 'package:facilite_plus/features/payments/domain/entities/payment.dart';

void main() {
  test('marca parcelas pagas conforme pagamentos', () {
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
        amount: '500',
        paymentDate: '2026-01-05',
      ),
      const Payment(
        id: 'p2',
        loanId: 'l1',
        amount: '500',
        paymentDate: '2026-02-05',
      ),
    ];

    final detail = LoanScheduleBuilder.build(
      loan: loan,
      payments: payments,
      asOf: DateTime(2026, 6, 1),
    );

    expect(detail, isNotNull);
    expect(detail!.overview.paidInstallments, 2);
    expect(
      detail.installments.every((i) => i.status == LoanInstallmentStatus.paid),
      isTrue,
    );
  });
}
