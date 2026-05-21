import 'package:facilite_plus/core/repositories/syncable_repository.dart';
import 'package:facilite_plus/features/clients/domain/repositories/clients_repository.dart';
import 'package:facilite_plus/services/database/drift/app_database.dart';
import 'package:facilite_plus/services/sync/sync_queue_repository.dart';

/// SQLite primeiro; alterações vão para [SyncQueueRepository].
class ClientsRepositoryImpl extends SyncableRepository
    implements ClientsRepository {
  ClientsRepositoryImpl({
    required AppDatabase database,
    required SyncQueueRepository syncQueue,
  })  : _db = database,
        super(syncQueue);

  final AppDatabase _db;

  // ignore: unused_field — usado nas próximas etapas
  AppDatabase get database => _db;
}
