import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:facilite_plus/core/repositories/syncable_repository.dart';
import 'package:facilite_plus/core/sync/sync_entity_type.dart';
import 'package:facilite_plus/core/sync/sync_operation_type.dart';
import 'package:facilite_plus/features/loans/domain/entities/loan.dart';
import 'package:facilite_plus/features/loans/domain/repositories/loans_repository.dart';
import 'package:facilite_plus/services/database/drift/app_database.dart';
import 'package:facilite_plus/services/sync/sync_queue_repository.dart';

class LoansRepositoryImpl extends SyncableRepository implements LoansRepository {
  LoansRepositoryImpl({
    required AppDatabase database,
    required SyncQueueRepository syncQueue,
  })  : _db = database,
        super(syncQueue);

  final AppDatabase _db;
  final _uuid = const Uuid();

  @override
  Stream<List<Loan>> watchByClient(String clientId) {
    return (_db.select(_db.loansTable)
          ..where((l) => l.clientId.equals(clientId))
          ..orderBy([(l) => OrderingTerm.desc(l.createdAt)]))
        .watch()
        .map((rows) => rows.map(_mapRow).toList());
  }

  @override
  Future<Loan?> getById(String id) async {
    final row = await (_db.select(_db.loansTable)
          ..where((l) => l.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _mapRow(row);
  }

  @override
  Future<Loan> create({
    required String clientId,
    required String amount,
    String? interest,
    int? installments,
    String? status,
  }) async {
    final id = _uuid.v4();
    final createdAt = DateTime.now().toUtc().toIso8601String();
    final loan = Loan(
      id: id,
      clientId: clientId,
      amount: amount,
      interest: interest,
      installments: installments,
      status: status ?? 'ativo',
      createdAt: createdAt,
    );

    await _db.into(_db.loansTable).insert(
          LoansTableCompanion.insert(
            id: id,
            clientId: clientId,
            amount: amount,
            interest: Value(interest),
            installments: Value(installments),
            status: Value(loan.status),
            createdAt: Value(createdAt),
          ),
        );

    await enqueueSync(
      entityType: SyncEntityType.loan,
      entityId: id,
      operation: SyncOperationType.insert,
      payload: loan.toSyncPayload(),
    );

    return loan;
  }

  @override
  Future<Loan> update(Loan loan) async {
    await (_db.update(_db.loansTable)..where((l) => l.id.equals(loan.id)))
        .write(
      LoansTableCompanion(
        amount: Value(loan.amount),
        interest: Value(loan.interest),
        installments: Value(loan.installments),
        status: Value(loan.status),
      ),
    );

    await enqueueSync(
      entityType: SyncEntityType.loan,
      entityId: loan.id,
      operation: SyncOperationType.update,
      payload: loan.toSyncPayload(),
    );

    return loan;
  }

  @override
  Future<void> delete(String id) async {
    final existing = await getById(id);
    if (existing == null) return;

    await (_db.delete(_db.loansTable)..where((l) => l.id.equals(id))).go();

    await enqueueSync(
      entityType: SyncEntityType.loan,
      entityId: id,
      operation: SyncOperationType.delete,
      payload: existing.toSyncPayload(),
    );
  }

  Loan _mapRow(LoansTableData row) {
    return Loan(
      id: row.id,
      clientId: row.clientId,
      amount: row.amount,
      interest: row.interest,
      installments: row.installments,
      status: row.status,
      createdAt: row.createdAt,
    );
  }
}
