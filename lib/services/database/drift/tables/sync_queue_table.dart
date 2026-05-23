import 'package:drift/drift.dart';

/// Fila local de operações pendentes para envio ao Supabase.
class SyncQueueTable extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Tabela remota: clients | loans | payments
  TextColumn get entityType => text().named('entity_type')();

  TextColumn get entityId => text().named('entity_id')();

  /// insert | update | delete
  TextColumn get operation => text()();

  /// JSON serializado do payload (campos da operação)
  TextColumn get payload => text()();

  /// pending | syncing | synced | failed
  TextColumn get status =>
      text().withDefault(const Constant('pending'))();

  IntColumn get retryCount =>
      integer().named('retry_count').withDefault(const Constant(0))();

  TextColumn get lastError => text().named('last_error').nullable()();

  DateTimeColumn get createdAt =>
      dateTime().named('created_at').withDefault(currentDateAndTime)();

  DateTimeColumn get syncedAt => dateTime().named('synced_at').nullable()();
}
