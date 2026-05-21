import 'package:flutter_test/flutter_test.dart';
import 'package:facilite_plus/features/loans/domain/loan_periodicity.dart';
import 'package:facilite_plus/features/loans/domain/loan_simulator.dart';

void main() {
  test('juros percentual sobre o valor emprestado (parcelas iguais)', () {
    final result = LoanSimulator.simulate(
      principal: 1000,
      installments: 10,
      interestPercent: 10,
      periodicity: LoanPeriodicity.mensal,
      firstDueDate: DateTime(2026, 6, 1),
    );

    expect(result, isNotNull);
    expect(result!.totalInterest, closeTo(100, 0.01));
    expect(result.totalAmount, closeTo(1100, 0.01));
    expect(result.installmentAmount, closeTo(110, 0.01));
    expect(result.schedule.length, 6);
  });

  test('sem juros divide principal igualmente', () {
    final result = LoanSimulator.simulate(
      principal: 500,
      installments: 5,
      interestPercent: 0,
      periodicity: LoanPeriodicity.mensal,
      firstDueDate: DateTime(2026, 1, 1),
    );

    expect(result!.installmentAmount, closeTo(100, 0.01));
    expect(result.totalInterest, 0);
  });

  test('parseAmount aceita vírgula', () {
    expect(LoanSimulator.parseAmount('1.500,50'), 1500.50);
  });
}
