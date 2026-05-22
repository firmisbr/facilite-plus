import 'package:intl/intl.dart';

/// Agrupamento visual dos presets na tela de relatórios.
enum ReportPeriodGroup {
  short('Curto'),
  monthly('Mensal'),
  extended('Amplo');

  const ReportPeriodGroup(this.label);

  final String label;
}

/// Presets de período para relatórios.
enum ReportPeriodPreset {
  today('Hoje', ReportPeriodGroup.short),
  yesterday('Ontem', ReportPeriodGroup.short),
  thisWeek('Esta semana', ReportPeriodGroup.short),
  last7Days('7 dias', ReportPeriodGroup.short),
  thisFortnight('Quinzena atual', ReportPeriodGroup.short),
  lastFortnight('Quinzena anterior', ReportPeriodGroup.short),
  last15Days('15 dias', ReportPeriodGroup.short),
  thisMonth('Este mês', ReportPeriodGroup.monthly),
  lastMonth('Mês passado', ReportPeriodGroup.monthly),
  last30Days('30 dias', ReportPeriodGroup.extended),
  thisYear('Este ano', ReportPeriodGroup.extended),
  allTime('Tudo', ReportPeriodGroup.extended),
  custom('Personalizado', ReportPeriodGroup.extended);

  const ReportPeriodPreset(this.label, this.group);

  final String label;
  final ReportPeriodGroup group;

  static List<ReportPeriodPreset> forGroup(ReportPeriodGroup group) =>
      ReportPeriodPreset.values.where((p) => p.group == group).toList();
}

/// Seleção ativa (preset ou intervalo customizado).
class ReportPeriodSelection {
  const ReportPeriodSelection({
    required this.preset,
    this.customStart,
    this.customEnd,
    this.uiGroup,
  });

  final ReportPeriodPreset preset;
  final DateTime? customStart;
  final DateTime? customEnd;

  /// Aba destacada na UI (pode diferir do [preset.group] em custom).
  final ReportPeriodGroup? uiGroup;

  static const initial = ReportPeriodSelection(
    preset: ReportPeriodPreset.thisMonth,
    uiGroup: ReportPeriodGroup.monthly,
  );

  ReportPeriodGroup get effectiveGroup => uiGroup ?? preset.group;

  ReportPeriodSelection copyWith({
    ReportPeriodPreset? preset,
    DateTime? customStart,
    DateTime? customEnd,
    ReportPeriodGroup? uiGroup,
    bool clearCustom = false,
  }) {
    return ReportPeriodSelection(
      preset: preset ?? this.preset,
      customStart: clearCustom ? null : (customStart ?? this.customStart),
      customEnd: clearCustom ? null : (customEnd ?? this.customEnd),
      uiGroup: uiGroup ?? this.uiGroup,
    );
  }
}

/// Intervalo inclusivo (início/fim do dia local).
class ReportPeriodRange {
  const ReportPeriodRange({
    required this.preset,
    required this.start,
    required this.end,
    required this.label,
    required this.rangeCaption,
  });

  final ReportPeriodPreset preset;
  final DateTime start;
  final DateTime end;
  final String label;
  final String rangeCaption;

  bool contains(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day);
    return !day.isBefore(s) && !day.isAfter(e);
  }

  static ReportPeriodRange resolve({
    required ReportPeriodSelection selection,
    DateTime? asOf,
  }) =>
      resolvePreset(
        preset: selection.preset,
        customStart: selection.customStart,
        customEnd: selection.customEnd,
        asOf: asOf,
      );

  static ReportPeriodRange resolvePreset({
    required ReportPeriodPreset preset,
    DateTime? customStart,
    DateTime? customEnd,
    DateTime? asOf,
  }) {
    final now = asOf ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final fmt = DateFormat('dd/MM/yyyy', 'pt_BR');

    late DateTime start;
    late DateTime end;
    late String label;

    switch (preset) {
      case ReportPeriodPreset.today:
        start = today;
        end = today;
        label = preset.label;
      case ReportPeriodPreset.yesterday:
        start = today.subtract(const Duration(days: 1));
        end = start;
        label = preset.label;
      case ReportPeriodPreset.thisWeek:
        start = _weekStartMonday(today);
        end = today;
        label = preset.label;
      case ReportPeriodPreset.last7Days:
        start = today.subtract(const Duration(days: 6));
        end = today;
        label = preset.label;
      case ReportPeriodPreset.thisFortnight:
        (start, end) = _calendarFortnight(today, current: true);
        label = preset.label;
      case ReportPeriodPreset.lastFortnight:
        (start, end) = _calendarFortnight(today, current: false);
        label = preset.label;
      case ReportPeriodPreset.last15Days:
        start = today.subtract(const Duration(days: 14));
        end = today;
        label = preset.label;
      case ReportPeriodPreset.thisMonth:
        start = DateTime(today.year, today.month);
        end = DateTime(today.year, today.month + 1, 0);
        label = preset.label;
      case ReportPeriodPreset.lastMonth:
        start = DateTime(today.year, today.month - 1);
        end = DateTime(today.year, today.month, 0);
        label = preset.label;
      case ReportPeriodPreset.last30Days:
        start = today.subtract(const Duration(days: 29));
        end = today;
        label = preset.label;
      case ReportPeriodPreset.thisYear:
        start = DateTime(today.year);
        end = today;
        label = preset.label;
      case ReportPeriodPreset.allTime:
        start = DateTime(2000);
        end = today;
        label = preset.label;
      case ReportPeriodPreset.custom:
        start = customStart != null
            ? DateTime(
                customStart.year,
                customStart.month,
                customStart.day,
              )
            : DateTime(today.year, today.month);
        end = customEnd != null
            ? DateTime(customEnd.year, customEnd.month, customEnd.day)
            : today;
        if (end.isBefore(start)) {
          final swap = start;
          start = end;
          end = swap;
        }
        label = preset.label;
    }

    final rangeCaption = start == end
        ? fmt.format(start)
        : '${fmt.format(start)} – ${fmt.format(end)}';

    return ReportPeriodRange(
      preset: preset,
      start: start,
      end: end,
      label: label,
      rangeCaption: rangeCaption,
    );
  }

  static DateTime _weekStartMonday(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  /// Quinzena de calendário: dias 1–15 e 16–fim do mês.
  static (DateTime, DateTime) _calendarFortnight(
    DateTime today, {
    required bool current,
  }) {
    if (current) {
      if (today.day <= 15) {
        return (
          DateTime(today.year, today.month),
          DateTime(today.year, today.month, 15),
        );
      }
      return (
        DateTime(today.year, today.month, 16),
        DateTime(today.year, today.month + 1, 0),
      );
    }

    if (today.day <= 15) {
      final prev = DateTime(today.year, today.month - 1);
      return (
        DateTime(prev.year, prev.month, 16),
        DateTime(today.year, today.month, 0),
      );
    }
    return (
      DateTime(today.year, today.month),
      DateTime(today.year, today.month, 15),
    );
  }
}
