import 'package:flutter_test/flutter_test.dart';
import 'package:facilite_plus/features/loans/domain/loan_periodicity.dart';
import 'package:facilite_plus/features/loans/domain/loan_simulator.dart';

void main() {
  test('simula parcelas fixas com juros', () {
    final result = LoanSimulator.simulate(
      principal: 1000,
      installments: 12,
      monthlyInterestPercent: 5,
      periodicity: LoanPeriodicity.mensal,
      firstDueDate: DateTime(2026, 6, 1),
    );

    expect(result, isNotNull);
    expect(result!.installmentAmount, greaterThan(0));
    expect(result.totalAmount, greaterThan(result.principal));
    expect(result.schedule.length, 6);
  });

  test('parseAmount aceita vírgula', () {
    expect(LoanSimulator.parseAmount('1.500,50'), 1500.50);
  });
}
