import 'package:drift/drift.dart';

import 'tables/clients_table.dart';
import 'tables/loans_table.dart';
import 'tables/payments_table.dart';
import 'tables/sync_queue_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [ClientsTable, LoansTable, PaymentsTable, SyncQueueTable],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(syncQueueTable);
          }
        },
      );
}
