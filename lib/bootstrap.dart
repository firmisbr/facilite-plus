import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';

import 'services/supabase/supabase_service.dart';

Future<void> bootstrap() async {
  _configureLogging();
  WidgetsFlutterBinding.ensureInitialized();
  await initializeSupabase();
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
