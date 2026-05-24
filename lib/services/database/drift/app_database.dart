import 'package:drift/drift.dart';

import 'tables/clients_table.dart';
import 'tables/loans_table.dart';
import 'tables/payments_table.dart';
import 'tables/support_tickets_table.dart';
import 'tables/sync_queue_table.dart';
import 'tables/ticket_messages_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    ClientsTable,
    LoansTable,
    PaymentsTable,
    SupportTicketsTable,
    TicketMessagesTable,
    SyncQueueTable,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(syncQueueTable);
          }
          if (from < 3) {
            await m.addColumn(clientsTable, clientsTable.email);
            await m.addColumn(loansTable, loansTable.periodicity);
            await m.addColumn(loansTable, loansTable.firstDueDate);
          }
          if (from < 4) {
            await m.addColumn(
              paymentsTable,
              paymentsTable.installmentNumber,
            );
          }
          if (from < 5) {
            await customStatement(
              'CREATE UNIQUE INDEX IF NOT EXISTS idx_clients_id ON clients(id)',
            );
            await customStatement(
              'CREATE UNIQUE INDEX IF NOT EXISTS idx_loans_id ON loans(id)',
            );
            await customStatement(
              'CREATE UNIQUE INDEX IF NOT EXISTS idx_payments_id ON payments(id)',
            );
          }
          if (from < 6) {
            await m.createTable(supportTicketsTable);
            await m.createTable(ticketMessagesTable);
          }
        },
      );
}
