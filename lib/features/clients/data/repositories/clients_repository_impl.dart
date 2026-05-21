import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:facilite_plus/core/repositories/syncable_repository.dart';
import 'package:facilite_plus/core/sync/sync_entity_type.dart';
import 'package:facilite_plus/core/sync/sync_operation_type.dart';
import 'package:facilite_plus/features/clients/domain/entities/client.dart';
import 'package:facilite_plus/features/clients/domain/repositories/clients_repository.dart';
import 'package:facilite_plus/services/database/drift/app_database.dart';
import 'package:facilite_plus/services/sync/sync_queue_repository.dart';

class ClientsRepositoryImpl extends SyncableRepository
    implements ClientsRepository {
  ClientsRepositoryImpl({
    required AppDatabase database,
    required SyncQueueRepository syncQueue,
  })  : _db = database,
        super(syncQueue);

  final AppDatabase _db;
  final _uuid = const Uuid();

  @override
  Stream<List<Client>> watchAll(String userId) {
    return (_db.select(_db.clientsTable)
          ..where((c) => c.userId.equals(userId))
          ..orderBy([(c) => OrderingTerm.desc(c.createdAt)]))
        .watch()
        .map((rows) => rows.map(_mapRow).toList());
  }

  @override
  Future<Client?> getById(String id) async {
    final row = await (_db.select(_db.clientsTable)
          ..where((c) => c.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _mapRow(row);
  }

  @override
  Future<Client> create({
    required String userId,
    required String name,
    String? phone,
    String? document,
    String? address,
    String? notes,
  }) async {
    final id = _uuid.v4();
    final createdAt = DateTime.now().toUtc().toIso8601String();
    final client = Client(
      id: id,
      userId: userId,
      name: name,
      phone: phone,
      document: document,
      address: address,
      notes: notes,
      createdAt: createdAt,
    );

    await _db.into(_db.clientsTable).insert(
          ClientsTableCompanion.insert(
            id: id,
            userId: userId,
            name: name,
            phone: Value(phone),
            document: Value(document),
            address: Value(address),
            notes: Value(notes),
            createdAt: Value(createdAt),
          ),
        );

    await enqueueSync(
      entityType: SyncEntityType.client,
      entityId: id,
      operation: SyncOperationType.insert,
      payload: client.toSyncPayload(),
    );

    return client;
  }

  @override
  Future<Client> update(Client client) async {
    await (_db.update(_db.clientsTable)..where((c) => c.id.equals(client.id)))
        .write(
      ClientsTableCompanion(
        name: Value(client.name),
        phone: Value(client.phone),
        document: Value(client.document),
        address: Value(client.address),
        notes: Value(client.notes),
      ),
    );

    await enqueueSync(
      entityType: SyncEntityType.client,
      entityId: client.id,
      operation: SyncOperationType.update,
      payload: client.toSyncPayload(),
    );

    return client;
  }

  @override
  Future<void> delete(String id) async {
    final existing = await getById(id);
    if (existing == null) return;

    await (_db.delete(_db.clientsTable)..where((c) => c.id.equals(id))).go();

    await enqueueSync(
      entityType: SyncEntityType.client,
      entityId: id,
      operation: SyncOperationType.delete,
      payload: existing.toSyncPayload(),
    );
  }

  Client _mapRow(ClientsTableData row) {
    return Client(
      id: row.id,
      userId: row.userId,
      name: row.name,
      phone: row.phone,
      document: row.document,
      address: row.address,
      notes: row.notes,
      createdAt: row.createdAt,
    );
  }
}
