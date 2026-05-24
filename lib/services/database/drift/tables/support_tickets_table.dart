import 'package:drift/drift.dart';

class SupportTicketsTable extends Table {
  @override
  String get tableName => 'support_tickets';

  @override
  Set<Column> get primaryKey => {id};

  TextColumn get id => text()();
  TextColumn get userId => text().named('user_id')();
  TextColumn get type => text()();
  TextColumn get title => text()();
  TextColumn get description => text()();
  TextColumn get extraField => text().named('extra_field').nullable()();
  TextColumn get status => text()();
  TextColumn get devResponse => text().named('dev_response').nullable()();
  TextColumn get createdAt => text().named('created_at')();
  TextColumn get updatedAt => text().named('updated_at')();
}
