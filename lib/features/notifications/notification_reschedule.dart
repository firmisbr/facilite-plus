import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../loans/presentation/providers/loans_providers.dart';
import '../payments/presentation/providers/payments_providers.dart';
import '../../services/notifications/notification_scheduler.dart';

/// Reagenda lembretes a partir dos providers (UI ou coordinator).
Future<void> rescheduleLoanNotifications(WidgetRef ref) async {
  final loans = await ref.read(allLoansProvider.future);
  final payments = await ref.read(allPaymentsForUserProvider.future);
  await NotificationScheduler.rescheduleFromData(
    loans: loans,
    payments: payments,
  );
}

Future<void> rescheduleLoanNotificationsFromRef(Ref ref) async {
  final loans = await ref.read(allLoansProvider.future);
  final payments = await ref.read(allPaymentsForUserProvider.future);
  await NotificationScheduler.rescheduleFromData(
    loans: loans,
    payments: payments,
  );
}
