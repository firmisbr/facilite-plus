import 'dart:convert';

import 'package:drift/drift.dart';

import '../../core/sync/sync_entity_type.dart';
import '../../core/sync/sync_operation_type.dart';
import '../../core/sync/sync_queue_status.dart';
import '../database/drift/app_database.dart';

/// Persistência da fila de sincronização (SQLite).
class SyncQueueRepository {
  SyncQueueRepository(this._db);

  final AppDatabase _db;

  Future<int> enqueue({
    required SyncEntityType entityType,
    required String entityId,
    required SyncOperationType operation,
    required Map<String, dynamic> payload,
  }) async {
    return _db.into(_db.syncQueueTable).insert(
          SyncQueueTableCompanion.insert(
            entityType: entityType.tableName,
            entityId: entityId,
            operation: operation.value,
            payload: jsonEncode(payload),
          ),
        );
  }

  Future<List<SyncQueueTableData>> pending({int limit = 50}) {
    return (_db.select(_db.syncQueueTable)
          ..where(
            (q) => q.status.equals(SyncQueueStatus.pending.value) |
                q.status.equals(SyncQueueStatus.failed.value),
          )
          ..orderBy([(q) => OrderingTerm.asc(q.createdAt)])
          ..limit(limit))
        .get();
  }

  Future<int> countPending() async {
    final count = _db.syncQueueTable.id.count();
    final query = _db.selectOnly(_db.syncQueueTable)
      ..addColumns([count])
      ..where(
        _db.syncQueueTable.status.equals(SyncQueueStatus.pending.value) |
            _db.syncQueueTable.status.equals(SyncQueueStatus.failed.value),
      );
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  Future<void> markSyncing(int id) async {
    await (_db.update(_db.syncQueueTable)..where((q) => q.id.equals(id)))
        .write(
      SyncQueueTableCompanion(
        status: Value(SyncQueueStatus.syncing.value),
        lastError: const Value(null),
      ),
    );
  }

  Future<void> markSynced(int id) async {
    await (_db.update(_db.syncQueueTable)..where((q) => q.id.equals(id)))
        .write(
      SyncQueueTableCompanion(
        status: Value(SyncQueueStatus.synced.value),
        syncedAt: Value(DateTime.now().toUtc()),
        lastError: const Value(null),
      ),
    );
  }

  Future<void> markFailed(int id, String error) async {
    final row = await (_db.select(_db.syncQueueTable)
          ..where((q) => q.id.equals(id)))
        .getSingle();
    await (_db.update(_db.syncQueueTable)..where((q) => q.id.equals(id)))
        .write(
      SyncQueueTableCompanion(
        status: Value(SyncQueueStatus.failed.value),
        retryCount: Value(row.retryCount + 1),
        lastError: Value(error),
      ),
    );
  }
}
