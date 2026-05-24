/// Vencimentos de empréstimo com periodicidade diária.
abstract final class DailyLoanDueDates {
  /// Índice da parcela (0 = primeira). Com [skipSunday], domingo não entra.
  static DateTime dueDate(
    DateTime firstDueDate, {
    required int installmentIndex,
    required bool skipSunday,
  }) {
    final first = DateTime(
      firstDueDate.year,
      firstDueDate.month,
      firstDueDate.day,
    );
    if (!skipSunday) {
      return first.add(Duration(days: installmentIndex));
    }

    var date = first;
    if (date.weekday == DateTime.sunday) {
      date = date.add(const Duration(days: 1));
    }
    for (var n = 0; n < installmentIndex; n++) {
      do {
        date = date.add(const Duration(days: 1));
      } while (date.weekday == DateTime.sunday);
    }
    return date;
  }
}
