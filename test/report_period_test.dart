import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:facilite_plus/features/reports/domain/report_period.dart';

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
      expect(range.rangeCaption, '01/05/2026 – 31/05/2026');
    });

    test('thisFortnight second half when day > 15', () {
      final range = ReportPeriodRange.resolvePreset(
        preset: ReportPeriodPreset.thisFortnight,
        asOf: DateTime(2026, 5, 22),
      );
      expect(range.start, DateTime(2026, 5, 16));
      expect(range.end, DateTime(2026, 5, 31));
    });

    test('lastFortnight first half when day > 15', () {
      final range = ReportPeriodRange.resolvePreset(
        preset: ReportPeriodPreset.lastFortnight,
        asOf: DateTime(2026, 5, 22),
      );
      expect(range.start, DateTime(2026, 5, 1));
      expect(range.end, DateTime(2026, 5, 15));
    });

    test('thisWeek starts on Monday', () {
      final range = ReportPeriodRange.resolvePreset(
        preset: ReportPeriodPreset.thisWeek,
        asOf: DateTime(2026, 5, 22), // Thursday
      );
      expect(range.start, DateTime(2026, 5, 18)); // Monday
      expect(range.end, DateTime(2026, 5, 22));
    });

    test('custom range swaps inverted dates', () {
      final range = ReportPeriodRange.resolvePreset(
        preset: ReportPeriodPreset.custom,
        customStart: DateTime(2026, 5, 20),
        customEnd: DateTime(2026, 5, 10),
      );
      expect(range.start, DateTime(2026, 5, 10));
      expect(range.end, DateTime(2026, 5, 20));
    });
  });

  group('ReportPeriodPreset', () {
    test('forGroup short excludes monthly presets', () {
      final short = ReportPeriodPreset.forGroup(ReportPeriodGroup.short);
      expect(short, contains(ReportPeriodPreset.today));
      expect(short, isNot(contains(ReportPeriodPreset.thisMonth)));
    });
  });
}
