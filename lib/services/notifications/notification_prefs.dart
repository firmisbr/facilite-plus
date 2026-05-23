import 'package:shared_preferences/shared_preferences.dart';

/// Preferências locais de notificações (offline).
class NotificationPrefs {
  const NotificationPrefs({
    required this.enabled,
    required this.dueTodayEnabled,
    required this.overdueEnabled,
    required this.hour,
    required this.minute,
  });

  final bool enabled;
  final bool dueTodayEnabled;
  final bool overdueEnabled;
  final int hour;
  final int minute;

  static const _keyEnabled = 'notifications_enabled';
  static const _keyDueToday = 'notifications_due_today';
  static const _keyOverdue = 'notifications_overdue';
  static const _keyHour = 'notifications_hour';
  static const _keyMinute = 'notifications_minute';

  static const defaults = NotificationPrefs(
    enabled: true,
    dueTodayEnabled: true,
    overdueEnabled: true,
    hour: 8,
    minute: 0,
  );

  String get timeLabel {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static Future<NotificationPrefs> load() async {
    final sp = await SharedPreferences.getInstance();
    return NotificationPrefs(
      enabled: sp.getBool(_keyEnabled) ?? defaults.enabled,
      dueTodayEnabled: sp.getBool(_keyDueToday) ?? defaults.dueTodayEnabled,
      overdueEnabled: sp.getBool(_keyOverdue) ?? defaults.overdueEnabled,
      hour: sp.getInt(_keyHour) ?? defaults.hour,
      minute: sp.getInt(_keyMinute) ?? defaults.minute,
    );
  }

  Future<void> save() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_keyEnabled, enabled);
    await sp.setBool(_keyDueToday, dueTodayEnabled);
    await sp.setBool(_keyOverdue, overdueEnabled);
    await sp.setInt(_keyHour, hour);
    await sp.setInt(_keyMinute, minute);
  }

  NotificationPrefs copyWith({
    bool? enabled,
    bool? dueTodayEnabled,
    bool? overdueEnabled,
    int? hour,
    int? minute,
  }) {
    return NotificationPrefs(
      enabled: enabled ?? this.enabled,
      dueTodayEnabled: dueTodayEnabled ?? this.dueTodayEnabled,
      overdueEnabled: overdueEnabled ?? this.overdueEnabled,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
    );
  }
}
