import 'package:drift/drift.dart';
import 'clients_table.dart';

class LoansTable extends Table {
  @override
  String get tableName => 'loans';

  TextColumn get id => text()();
  TextColumn get clientId => text().named('client_id').references(ClientsTable, #id)();
  TextColumn get amount => text()();
  TextColumn get interest => text().nullable()();
  IntColumn get installments => integer().nullable()();
  TextColumn get periodicity =>
      text().nullable()(); // diaria, semanal, quinzenal, mensal
  TextColumn get firstDueDate =>
      text().named('first_due_date').nullable()();
  TextColumn get status => text().nullable()();
  TextColumn get createdAt => text().named('created_at').nullable()();
}
