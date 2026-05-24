import 'package:drift/drift.dart';

class TicketMessagesTable extends Table {
  @override
  String get tableName => 'ticket_messages';

  @override
  Set<Column> get primaryKey => {id};

  TextColumn get id => text()();
  TextColumn get ticketId => text().named('ticket_id')();
  TextColumn get authorId => text().named('author_id')();
  TextColumn get authorRole => text().named('author_role')();
  TextColumn get body => text()();
  TextColumn get createdAt => text().named('created_at')();
}
