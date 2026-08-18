import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'features/settings/domain/daily_loan_sunday_policy.dart';
import 'services/notifications/local_notification_service.dart';
import 'services/supabase/supabase_service.dart';

Future<void> bootstrap() async {
  _configureLogging();
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR');
  await _hydrateDailyLoanSundayPolicy();
  await LocalNotificationService.ensureInitialized();
  await initializeSupabase();
}

Future<void> _hydrateDailyLoanSundayPolicy() async {
  final prefs = await SharedPreferences.getInstance();
  DailyLoanSundayPolicy.apply(
    prefs.getBool(DailyLoanSundayPolicy.prefKey) ?? false,
  );
}

void _configureLogging() {
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    if (kDebugMode) {
      debugPrint(
        '[${record.loggerName}] ${record.level.name}: ${record.message}',
      );
    }
  });
}
