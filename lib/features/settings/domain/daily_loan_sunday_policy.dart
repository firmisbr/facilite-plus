import '../../loans/domain/loan_periodicity.dart';

/// Preferência: empréstimos diários sem vencimento aos domingos.
abstract final class DailyLoanSundayPolicy {
  static const prefKey = 'daily_loan_skip_sunday';

  static bool skipSunday = false;
  static bool hydrated = false;

  static bool appliesTo(LoanPeriodicity periodicity) =>
      skipSunday && periodicity == LoanPeriodicity.diaria;

  static void apply(bool enabled) {
    skipSunday = enabled;
    hydrated = true;
  }
}
