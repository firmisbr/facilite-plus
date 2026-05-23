import '../sync/sync_entity_type.dart';
import '../sync/sync_operation_type.dart';
import '../../services/sync/sync_queue_repository.dart';

/// Base para repositories: grava local primeiro e enfileira sync.
abstract class SyncableRepository {
  SyncableRepository(this._syncQueue);

  final SyncQueueRepository _syncQueue;

  Future<void> enqueueSync({
    required SyncEntityType entityType,
    required String entityId,
    required SyncOperationType operation,
    required Map<String, dynamic> payload,
  }) {
    return _syncQueue.enqueue(
      entityType: entityType,
      entityId: entityId,
      operation: operation,
      payload: payload,
    );
  }
}
