import 'package:flutter_test/flutter_test.dart';
import 'package:facilite_plus/features/loans/domain/daily_loan_due_dates.dart';
import 'package:facilite_plus/features/loans/domain/loan_schedule_builder.dart';
import 'package:facilite_plus/features/loans/domain/entities/loan.dart';
import 'package:facilite_plus/features/settings/domain/daily_loan_sunday_policy.dart';

void main() {
  tearDown(() {
    DailyLoanSundayPolicy.skipSunday = false;
  });
  group('DailyLoanDueDates', () {
    test('sem folga mantém dias corridos', () {
      final first = DateTime(2026, 5, 1); // sexta
      expect(
        DailyLoanDueDates.dueDate(first, installmentIndex: 2, skipSunday: false),
        DateTime(2026, 5, 3),
      );
    });

    test('com folga pula domingo entre parcelas', () {
      final first = DateTime(2026, 5, 1); // sexta
      expect(
        DailyLoanDueDates.dueDate(first, installmentIndex: 1, skipSunday: true),
        DateTime(2026, 5, 2),
      );
      expect(
        DailyLoanDueDates.dueDate(first, installmentIndex: 2, skipSunday: true),
        DateTime(2026, 5, 4), // segunda (domingo pulado)
      );
    });

    test('primeiro vencimento domingo vira segunda', () {
      final sunday = DateTime(2026, 5, 3);
      expect(
        DailyLoanDueDates.dueDate(sunday, installmentIndex: 0, skipSunday: true),
        DateTime(2026, 5, 4),
      );
    });
  });

  test('cronograma diário com folga não vence domingo', () {
    DailyLoanSundayPolicy.skipSunday = true;
    const loan = Loan(
      id: 'l1',
      clientId: 'c1',
      amount: '1000',
      interest: '0',
      installments: 4,
      periodicity: 'diaria',
      firstDueDate: '2026-05-01',
      status: 'ativo',
    );

    final detail = LoanScheduleBuilder.build(
      loan: loan,
      payments: const [],
      asOf: DateTime(2026, 5, 10),
    );

    expect(detail, isNotNull);
    for (final item in detail!.installments) {
      expect(item.dueDate.weekday, isNot(DateTime.sunday));
    }
    expect(detail.installments[2].dueDate, DateTime(2026, 5, 4));
  });
}
