import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../services/supabase/supabase_providers.dart';
import '../../../loans/presentation/providers/loans_providers.dart';
import '../../../payments/presentation/providers/payments_providers.dart';
import '../../../settings/presentation/providers/daily_loan_skip_sunday_provider.dart';
import '../../../../services/notifications/local_notification_service.dart';
import '../../../../services/notifications/installment_due_scanner.dart';
import '../../../../services/notifications/notification_prefs.dart';
import '../../notification_reschedule.dart';

final notificationPrefsProvider =
    FutureProvider<NotificationPrefs>((ref) => NotificationPrefs.load());

final notificationPreviewProvider =
    FutureProvider<DueInstallmentScanResult>((ref) async {
  ref.watch(dailyLoanSkipSundayProvider);
  final loans = await ref.watch(allLoansProvider.future);
  final payments = await ref.watch(allPaymentsForUserProvider.future);
  return InstallmentDueScanner.scan(loans: loans, payments: payments);
});

final notificationCoordinatorProvider = Provider<void>((ref) {
  ref.listen(sessionProvider, (previous, next) {
    if (next.valueOrNull != null) {
      LocalNotificationService.ensureInitialized().then((_) {
        rescheduleLoanNotificationsFromRef(ref);
      });
    }
  });

  ref.listen(allLoansProvider, (previous, next) {
    if (next.hasValue && ref.read(sessionProvider).valueOrNull != null) {
      rescheduleLoanNotificationsFromRef(ref);
    }
  });
});
