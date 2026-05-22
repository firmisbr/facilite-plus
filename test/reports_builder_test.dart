import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:facilite_plus/features/loans/domain/entities/loan.dart';
import 'package:facilite_plus/features/loans/domain/entities/loan_with_client.dart';
import 'package:facilite_plus/features/payments/domain/entities/payment.dart';
import 'package:facilite_plus/features/reports/domain/report_period.dart';
import 'package:facilite_plus/features/reports/domain/reports_builder.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
  });

  group('ReportPeriodRange', () {
    test('thisMonth spans current calendar month', () {
      final range = ReportPeriodRange.resolvePreset(
        preset: ReportPeriodPreset.thisMonth,
        asOf: DateTime(2026, 5, 22),
      );
      expect(range.start, DateTime(2026, 5, 1));
      expect(range.end, DateTime(2026, 5, 31));
      expect(range.contains(DateTime(2026, 5, 15)), isTrue);
      expect(range.contains(DateTime(2026, 4, 30)), isFalse);
    });
  });

  group('ReportsBuilder', () {
    test('counts payment in period and overdue aging', () {
      final loan = Loan(
        id: 'l1',
        clientId: 'c1',
        amount: '1000',
        installments: 2,
        interest: '10',
        periodicity: 'mensal',
        firstDueDate: '2026-04-01',
        status: 'ativo',
      );
      final loans = [
        LoanWithClient(loan: loan, clientName: 'Maria'),
      ];
      final payments = [
        Payment(
          id: 'p1',
          loanId: 'l1',
          amount: '550',
          installmentNumber: 1,
          paymentDate: '2026-05-10',
        ),
      ];

      final period = ReportPeriodRange.resolvePreset(
        preset: ReportPeriodPreset.thisMonth,
        asOf: DateTime(2026, 5, 22),
      );

      final snapshot = ReportsBuilder.build(
        loans: loans,
        payments: payments,
        period: period,
        asOf: DateTime(2026, 5, 22),
      );

      expect(snapshot.summary.paymentsCount, 1);
      expect(snapshot.summary.receivedInPeriod, greaterThan(0));
      expect(snapshot.paymentsInPeriod, hasLength(1));
      expect(snapshot.paymentsInPeriod.first.clientName, 'Maria');
      expect(snapshot.hasPeriodData, isTrue);
    });

    test('buildPortfolio computes totals for active loan', () {
      final loan = Loan(
        id: 'l1',
        clientId: 'c1',
        amount: '1000',
        installments: 2,
        interest: '10',
        periodicity: 'mensal',
        firstDueDate: '2026-04-01',
        status: 'ativo',
      );
      final overview = ReportsBuilder.buildPortfolio(
        loans: [LoanWithClient(loan: loan, clientName: 'Maria')],
        payments: const [],
        asOf: DateTime(2026, 5, 22),
      );

      expect(overview.hasActiveLoans, isTrue);
      expect(overview.totalLent, greaterThan(0));
      expect(overview.averageProfitPerLoan, greaterThan(0));
    });
  });
}
