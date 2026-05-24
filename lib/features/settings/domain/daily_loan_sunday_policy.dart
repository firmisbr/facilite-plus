import '../../loans/domain/loan_periodicity.dart';

/// Preferência local: empréstimos diários sem vencimento aos domingos.
abstract final class DailyLoanSundayPolicy {
  static bool skipSunday = false;

  static bool appliesTo(LoanPeriodicity periodicity) =>
      skipSunday && periodicity == LoanPeriodicity.diaria;
}
