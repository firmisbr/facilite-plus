import 'package:flutter/foundation.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../features/loans/domain/entities/loan_with_client.dart';
import '../../features/payments/domain/entities/payment.dart';
import 'installment_due_scanner.dart';
import 'local_notification_service.dart';
import 'notification_messages.dart';
import 'notification_prefs.dart';

/// Reagenda lembretes com base na carteira e nas preferências.
abstract final class NotificationScheduler {
  static const _horizonDays = 14;
  static const _dueTodayBaseId = 1000;
  static const _overdueId = 2000;
  static const testNotificationId = 99;

  static Future<void> rescheduleFromData({
    required List<LoanWithClient> loans,
    required List<Payment> payments,
  }) async {
    try {
      await LocalNotificationService.ensureInitialized();
      final prefs = await NotificationPrefs.load();
      await LocalNotificationService.cancelRange(
        _dueTodayBaseId,
        _dueTodayBaseId + _horizonDays,
      );
      await LocalNotificationService.cancel(_overdueId);

      if (!prefs.enabled) return;

      final now = tz.TZDateTime.now(tz.local);
      final today = DateTime(now.year, now.month, now.day);

      for (var d = 0; d < _horizonDays; d++) {
        final day = today.add(Duration(days: d));
        final scan = InstallmentDueScanner.scan(
          loans: loans,
          payments: payments,
          onDay: day,
        );
        final scheduled = tz.TZDateTime(
          tz.local,
          day.year,
          day.month,
          day.day,
          prefs.hour,
          prefs.minute,
        );

        if (scheduled.isBefore(now)) continue;

        if (prefs.dueTodayEnabled && scan.dueOnDayCount > 0) {
          final copy = NotificationMessages.dueToday(scan);
          await LocalNotificationService.scheduleZoned(
            id: _dueTodayBaseId + d,
            title: copy.title,
            body: copy.body,
            summary: copy.summary,
            scheduledDate: scheduled,
          );
        }
      }

      if (prefs.overdueEnabled) {
        final todayScan = InstallmentDueScanner.scan(
          loans: loans,
          payments: payments,
        );
        if (todayScan.overdueCount > 0) {
          final scheduled = tz.TZDateTime(
            tz.local,
            today.year,
            today.month,
            today.day,
            prefs.hour,
            prefs.minute,
          );
          if (!scheduled.isBefore(now)) {
            final copy = NotificationMessages.overdue(todayScan);
            await LocalNotificationService.scheduleZoned(
              id: _overdueId,
              title: copy.title,
              body: copy.body,
              summary: copy.summary,
              scheduledDate: scheduled,
            );
          }
        }
      }
    } catch (e, st) {
      debugPrint('NotificationScheduler.reschedule: $e\n$st');
    }
  }

  static Future<void> showTestNotification() async {
    final copy = NotificationMessages.test();
    await LocalNotificationService.showNow(
      id: testNotificationId,
      title: copy.title,
      body: copy.body,
      summary: copy.summary,
    );
  }
}
