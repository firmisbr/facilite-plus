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
  Future<Client?> findByDocumentOrPhone({
    required String userId,
    String? document,
    String? phone,
  }) async {
    final docDigits = _digitsOnly(document);
    final phoneDigits = _digitsOnly(phone);
    if (docDigits == null && phoneDigits == null) return null;

    final rows = await (_db.select(_db.clientsTable)
          ..where((c) => c.userId.equals(userId)))
        .get();

    for (final row in rows) {
      if (docDigits != null &&
          row.document != null &&
          _digitsOnly(row.document) == docDigits) {
        return _mapRow(row);
      }
      if (phoneDigits != null &&
          row.phone != null &&
          _digitsOnly(row.phone) == phoneDigits) {
        return _mapRow(row);
      }
    }
    return null;
  }

  String? _digitsOnly(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final digits = value.replaceAll(RegExp(r'\D'), '');
    return digits.isEmpty ? null : digits;
  }

  @override
  Future<Client> create({
    required String userId,
    required String name,
    String? phone,
    String? email,
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
      email: email,
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
            email: Value(email),
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
        email: Value(client.email),
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
      email: row.email,
      document: row.document,
      address: row.address,
      notes: row.notes,
      createdAt: row.createdAt,
    );
  }
}
