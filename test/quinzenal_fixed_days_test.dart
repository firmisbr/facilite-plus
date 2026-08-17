import 'package:flutter_test/flutter_test.dart';
import 'package:facilite_plus/features/loans/domain/loan_periodicity.dart';
import 'package:facilite_plus/features/loans/domain/loan_simulator.dart';
import 'package:facilite_plus/features/loans/domain/quinzenal_fixed_days.dart';

void main() {
  test('quinzenal fixo alterna dois dias do mes', () {
    final first = DateTime(2026, 8, 5);
    final dates = [
      for (var i = 0; i < 6; i++)
        QuinzenalFixedDays.dueDate(
          firstDueDate: first,
          day1: 5,
          day2: 20,
          index: i,
        ),
    ];

    expect(dates.map((d) => '${d.day}/${d.month}').toList(), [
      '5/8',
      '20/8',
      '5/9',
      '20/9',
      '5/10',
      '20/10',
    ]);
  });

  test('quinzenal fixo comeca no segundo dia do mes', () {
    final first = DateTime(2026, 8, 20);
    expect(
      QuinzenalFixedDays.dueDate(
        firstDueDate: first,
        day1: 5,
        day2: 20,
        index: 1,
      ),
      DateTime(2026, 9, 5),
    );
  });

  test('dia 31 clamp em fevereiro', () {
    final first = DateTime(2026, 1, 31);
    final next = QuinzenalFixedDays.nextAfter(first, 15, 31);
    expect(next, DateTime(2026, 2, 15));
    final after = QuinzenalFixedDays.nextAfter(next, 15, 31);
    expect(after, DateTime(2026, 2, 28));
  });

  test('simulador usa dias fixos quando informados', () {
    final sim = LoanSimulator.simulate(
      principal: 1000,
      installments: 4,
      interestPercent: 0,
      periodicity: LoanPeriodicity.quinzenal,
      firstDueDate: DateTime(2026, 8, 10),
      quinzenalDay1: 10,
      quinzenalDay2: 25,
      maxScheduleRows: 4,
    );

    expect(sim, isNotNull);
    expect(
      sim!.schedule.map((s) => LoanSimulator.formatDate(s.dueDate)).toList(),
      ['10/08/2026', '25/08/2026', '10/09/2026', '25/09/2026'],
    );
  });

  test('simulador quinzenal sem dias fixos continua +14', () {
    final sim = LoanSimulator.simulate(
      principal: 1000,
      installments: 3,
      interestPercent: 0,
      periodicity: LoanPeriodicity.quinzenal,
      firstDueDate: DateTime(2026, 8, 16),
      maxScheduleRows: 3,
    );

    expect(
      sim!.schedule.map((s) => LoanSimulator.formatDate(s.dueDate)).toList(),
      ['16/08/2026', '30/08/2026', '13/09/2026'],
    );
  });
}
