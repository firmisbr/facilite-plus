import 'package:drift/drift.dart';

class ClientsTable extends Table {
  @override
  String get tableName => 'clients';

  @override
  Set<Column> get primaryKey => {id};

  TextColumn get id => text()();
  TextColumn get userId => text().named('user_id')();
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get document => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get createdAt => text().named('created_at').nullable()();
}
