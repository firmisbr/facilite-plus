import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';
import 'database_connection.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase(openLocalDatabase());
  ref.onDispose(db.close);
  return db;
});
