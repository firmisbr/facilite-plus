import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:facilite_plus/core/repositories/syncable_repository.dart';
import 'package:facilite_plus/core/sync/sync_entity_type.dart';
import 'package:facilite_plus/core/sync/sync_operation_type.dart';
import 'package:facilite_plus/features/payments/domain/entities/payment.dart';
import 'package:facilite_plus/features/payments/domain/repositories/payments_repository.dart';
import 'package:facilite_plus/services/database/drift/app_database.dart';
import 'package:facilite_plus/services/sync/sync_queue_repository.dart';

class PaymentsRepositoryImpl extends SyncableRepository
    implements PaymentsRepository {
  PaymentsRepositoryImpl({
    required AppDatabase database,
    required SyncQueueRepository syncQueue,
  })  : _db = database,
        super(syncQueue);

  final AppDatabase _db;
  final _uuid = const Uuid();

  @override
  Stream<List<Payment>> watchByLoan(String loanId) {
    return (_db.select(_db.paymentsTable)
          ..where((p) => p.loanId.equals(loanId))
          ..orderBy([(p) => OrderingTerm.desc(p.createdAt)]))
        .watch()
        .map((rows) => rows.map(_mapRow).toList());
  }

  @override
  Future<Payment?> getById(String id) async {
    final row = await (_db.select(_db.paymentsTable)
          ..where((p) => p.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _mapRow(row);
  }

  @override
  Future<Payment> create({
    required String loanId,
    required String amount,
    String? paymentDate,
    String? method,
  }) async {
    final id = _uuid.v4();
    final createdAt = DateTime.now().toUtc().toIso8601String();
    final payment = Payment(
      id: id,
      loanId: loanId,
      amount: amount,
      paymentDate: paymentDate,
      method: method,
      createdAt: createdAt,
    );

    await _db.into(_db.paymentsTable).insert(
          PaymentsTableCompanion.insert(
            id: id,
            loanId: loanId,
            amount: amount,
            paymentDate: Value(paymentDate),
            method: Value(method),
            createdAt: Value(createdAt),
          ),
        );

    await enqueueSync(
      entityType: SyncEntityType.payment,
      entityId: id,
      operation: SyncOperationType.insert,
      payload: payment.toSyncPayload(),
    );

    return payment;
  }

  @override
  Future<Payment> update(Payment payment) async {
    await (_db.update(_db.paymentsTable)..where((p) => p.id.equals(payment.id)))
        .write(
      PaymentsTableCompanion(
        amount: Value(payment.amount),
        paymentDate: Value(payment.paymentDate),
        method: Value(payment.method),
      ),
    );

    await enqueueSync(
      entityType: SyncEntityType.payment,
      entityId: payment.id,
      operation: SyncOperationType.update,
      payload: payment.toSyncPayload(),
    );

    return payment;
  }

  @override
  Future<void> delete(String id) async {
    final existing = await getById(id);
    if (existing == null) return;

    await (_db.delete(_db.paymentsTable)..where((p) => p.id.equals(id))).go();

    await enqueueSync(
      entityType: SyncEntityType.payment,
      entityId: id,
      operation: SyncOperationType.delete,
      payload: existing.toSyncPayload(),
    );
  }

  Payment _mapRow(PaymentsTableData row) {
    return Payment(
      id: row.id,
      loanId: row.loanId,
      amount: row.amount,
      paymentDate: row.paymentDate,
      method: row.method,
      createdAt: row.createdAt,
    );
  }
}
