import 'package:intl/intl.dart';

/// Lista de dias em português: "22, 23 e 24 de maio de 2026".
abstract final class PortugueseDateListFormatter {
  static String formatDueDates(Iterable<DateTime> dates) {
    final normalized = dates
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet()
        .toList()
      ..sort();

    if (normalized.isEmpty) return '';
    if (normalized.length == 1) {
      return DateFormat("d 'de' MMMM 'de' y", 'pt_BR').format(normalized.first);
    }

    final first = normalized.first;
    final sameMonthYear = normalized.every(
      (d) => d.year == first.year && d.month == first.month,
    );

    if (sameMonthYear) {
      final days = normalized.map((d) => '${d.day}').toList();
      final monthYear =
          DateFormat("MMMM 'de' y", 'pt_BR').format(first);
      return '${_joinWithE(days)} de $monthYear';
    }

    final parts = normalized
        .map((d) => DateFormat("d 'de' MMMM", 'pt_BR').format(d))
        .toList();
    final year = first.year;
    return '${_joinWithE(parts)} de $year';
  }

  static String _joinWithE(List<String> parts) {
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first;
    if (parts.length == 2) return '${parts[0]} e ${parts[1]}';
    return '${parts.sublist(0, parts.length - 1).join(', ')} e ${parts.last}';
  }
}
