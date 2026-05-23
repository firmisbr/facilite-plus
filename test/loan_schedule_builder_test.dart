import 'package:flutter_test/flutter_test.dart';
import 'package:facilite_plus/features/loans/domain/entities/loan.dart';
import 'package:facilite_plus/features/loans/domain/loan_installment_status.dart';
import 'package:facilite_plus/features/loans/domain/loan_periodicity.dart';
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
    expect(detail.installments[0].paidDate, DateTime(2026, 1, 5));
    expect(detail.installments[0].paymentTimingLabel, '4 dia(s) após o vencimento');
    expect(detail.installments[1].status, LoanInstallmentStatus.overdue);
    expect(detail.overview.paidInstallments, 1);
  });

  test('cronograma reflete periodicidade do emprestimo', () {
    const base = Loan(
      id: 'l1',
      clientId: 'c1',
      amount: '1000',
      interest: '0',
      installments: 3,
      firstDueDate: '2026-05-01',
      status: 'ativo',
    );

    final weekly = LoanScheduleBuilder.build(
      loan: base.copyWith(periodicity: LoanPeriodicity.semanal.value),
      payments: const [],
      asOf: DateTime(2026, 5, 1),
    );
    final daily = LoanScheduleBuilder.build(
      loan: base.copyWith(periodicity: LoanPeriodicity.diaria.value),
      payments: const [],
      asOf: DateTime(2026, 5, 1),
    );

    expect(weekly, isNotNull);
    expect(daily, isNotNull);
    expect(weekly!.installments[1].dueDate, DateTime(2026, 5, 8));
    expect(daily!.installments[1].dueDate, DateTime(2026, 5, 2));
  });
}
