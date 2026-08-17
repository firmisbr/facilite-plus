/// Quinzenal com dois dias fixos no mês (ex.: todo dia 5 e dia 20).
///
/// Quando [day1]/[day2] estão ativos, o cronograma alterna esses dias
/// em vez de somar 14 dias corridos.
abstract final class QuinzenalFixedDays {
  static bool isActive(int? day1, int? day2) {
    if (day1 == null || day2 == null) return false;
    if (day1 < 1 || day1 > 31 || day2 < 1 || day2 > 31) return false;
    return day1 != day2;
  }

  static (int lo, int hi) sorted(int day1, int day2) =>
      day1 < day2 ? (day1, day2) : (day2, day1);

  /// Dia do mês limitado ao último dia existente (ex.: 31 → 28/29 em fev).
  static DateTime dateInMonth(int year, int month, int day) {
    final lastDay = DateTime(year, month + 1, 0).day;
    final clamped = day.clamp(1, lastDay);
    return DateTime(year, month, clamped);
  }

  /// Próxima ocorrência de [day1]/[day2] a partir de [from] (inclusive).
  static DateTime nextOccurrence(DateTime from, int day1, int day2) {
    final (lo, hi) = sorted(day1, day2);
    final today = DateTime(from.year, from.month, from.day);
    final loThis = dateInMonth(from.year, from.month, lo);
    final hiThis = dateInMonth(from.year, from.month, hi);
    if (!loThis.isBefore(today)) return loThis;
    if (!hiThis.isBefore(today)) return hiThis;
    final nextMonth = DateTime(from.year, from.month + 1);
    return dateInMonth(nextMonth.year, nextMonth.month, lo);
  }

  /// Vencimento da parcela [index] (0 = 1º vencimento).
  static DateTime dueDate({
    required DateTime firstDueDate,
    required int day1,
    required int day2,
    required int index,
  }) {
    var current = DateTime(
      firstDueDate.year,
      firstDueDate.month,
      firstDueDate.day,
    );
    for (var i = 0; i < index; i++) {
      current = nextAfter(current, day1, day2);
    }
    return current;
  }

  /// Próximo vencimento após [from], seguindo os dois dias fixos.
  static DateTime nextAfter(DateTime from, int day1, int day2) {
    final (lo, hi) = sorted(day1, day2);
    final fromDay = DateTime(from.year, from.month, from.day);
    final hiDate = dateInMonth(from.year, from.month, hi);

    if (fromDay.isBefore(hiDate)) {
      return hiDate;
    }

    final nextMonth = DateTime(from.year, from.month + 1);
    return dateInMonth(nextMonth.year, nextMonth.month, lo);
  }

  static String label(int day1, int day2) {
    final (lo, hi) = sorted(day1, day2);
    return 'Dias $lo e $hi';
  }
}
