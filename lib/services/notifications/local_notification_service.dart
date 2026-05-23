import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Inicialização e exibição de notificações locais.
abstract final class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'facilite_reminders',
    'Lembretes de cobrança',
    description: 'Avisos de parcelas a vencer e em atraso',
    importance: Importance.high,
  );

  static Future<void> ensureInitialized() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
    } catch (e) {
      debugPrint('LocalNotificationService: timezone fallback UTC ($e)');
      tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));
    }

    const android = AndroidInitializationSettings('ic_notification');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(android: android, iOS: ios);

    final ok = await _plugin.initialize(settings);
    if (ok != true) {
      debugPrint(
        'LocalNotificationService: initialize retornou $ok — '
        'verifique ic_notification em res/drawable-*',
      );
    }
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    _initialized = true;
  }

  static Future<bool> requestPermissions() async {
    await ensureInitialized();
    var granted = true;

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final notif = await android.requestNotificationsPermission();
      granted = notif ?? true;
      await android.requestExactAlarmsPermission();
    }

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final ok = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      granted = ok ?? granted;
    }

    return granted;
  }

  static const _brandColor = 0xFF4C6B5A;

  static NotificationDetails _details({
    required String title,
    required String body,
    String? summary,
  }) {
    final android = AndroidNotificationDetails(
      'facilite_reminders',
      'Lembretes de cobrança',
      channelDescription: 'Avisos de parcelas a vencer e em atraso',
      importance: Importance.high,
      priority: Priority.high,
      icon: 'ic_notification',
      largeIcon: const DrawableResourceAndroidBitmap('ic_logo_compact'),
      color: Color(_brandColor),
      colorized: true,
      category: AndroidNotificationCategory.reminder,
      ticker: title,
      subText: summary,
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: summary,
      ),
    );
    final ios = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      subtitle: summary,
    );
    return NotificationDetails(android: android, iOS: ios);
  }

  static Future<void> showNow({
    required int id,
    required String title,
    required String body,
    String? summary,
  }) async {
    await ensureInitialized();
    await _plugin.show(
      id,
      title,
      body,
      _details(title: title, body: body, summary: summary),
    );
  }

  static Future<void> scheduleZoned({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    String? summary,
  }) async {
    await ensureInitialized();
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      _details(title: title, body: body, summary: summary),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancel(int id) => _plugin.cancel(id);

  static Future<void> cancelRange(int fromId, int toId) async {
    for (var id = fromId; id <= toId; id++) {
      await cancel(id);
    }
  }
}
