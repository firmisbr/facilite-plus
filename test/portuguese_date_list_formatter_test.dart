import 'package:facilite_plus/shared/utils/portuguese_date_list_formatter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
  });

  test('um vencimento', () {
    final text = PortugueseDateListFormatter.formatDueDates([
      DateTime(2026, 5, 22),
    ]);
    expect(text, contains('22'));
    expect(text, contains('maio'));
    expect(text, contains('2026'));
  });

  test('tres dias no mesmo mes', () {
    final text = PortugueseDateListFormatter.formatDueDates([
      DateTime(2026, 5, 22),
      DateTime(2026, 5, 23),
      DateTime(2026, 5, 24),
    ]);
    expect(text, '22, 23 e 24 de maio de 2026');
  });

  test('dois dias no mesmo mes', () {
    final text = PortugueseDateListFormatter.formatDueDates([
      DateTime(2026, 5, 22),
      DateTime(2026, 5, 23),
    ]);
    expect(text, '22 e 23 de maio de 2026');
  });
}
