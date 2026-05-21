import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
const _dbFileName = 'facilite_plus.db';

QueryExecutor openLocalDatabase() {
  return LazyDatabase(() async {
    final dir = await getApplicationSupportDirectory();
    final file = File(p.join(dir.path, _dbFileName));
    return NativeDatabase(file);
  });
}
