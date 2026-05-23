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
  Stream<List<Payment>> watchAllForUser(String userId) {
    final payments = _db.paymentsTable;
    final loans = _db.loansTable;
    final clients = _db.clientsTable;

    final query = _db.select(payments).join([
      innerJoin(loans, loans.id.equalsExp(payments.loanId)),
      innerJoin(clients, clients.id.equalsExp(loans.clientId)),
    ])
      ..where(clients.userId.equals(userId))
      ..orderBy([OrderingTerm.desc(payments.createdAt)]);

    return query
        .watch()
        .map((rows) => rows.map((row) => _mapRow(row.readTable(payments))).toList());
  }

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
  Future<Payment?> getByLoanAndInstallment(
    String loanId,
    int installmentNumber,
  ) async {
    final row = await (_db.select(_db.paymentsTable)
          ..where(
            (p) =>
                p.loanId.equals(loanId) &
                p.installmentNumber.equals(installmentNumber),
          ))
        .getSingleOrNull();
    return row == null ? null : _mapRow(row);
  }

  @override
  Future<Payment> create({
    required String loanId,
    required String amount,
    int? installmentNumber,
    String? paymentDate,
    String? method,
  }) async {
    final id = _uuid.v4();
    final createdAt = DateTime.now().toUtc().toIso8601String();
    final payment = Payment(
      id: id,
      loanId: loanId,
      amount: amount,
      installmentNumber: installmentNumber,
      paymentDate: paymentDate,
      method: method,
      createdAt: createdAt,
    );

    await _db.into(_db.paymentsTable).insert(
          PaymentsTableCompanion.insert(
            id: id,
            loanId: loanId,
            amount: amount,
            installmentNumber: Value(installmentNumber),
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
  Future<Payment> payInstallment({
    required String loanId,
    required int installmentNumber,
    required String amount,
    String? paymentDate,
  }) async {
    final existing =
        await getByLoanAndInstallment(loanId, installmentNumber);
    if (existing != null) {
      throw StateError('Parcela $installmentNumber já está paga');
    }

    return create(
      loanId: loanId,
      amount: amount,
      installmentNumber: installmentNumber,
      paymentDate: paymentDate ?? _todayIso(),
      method: 'parcela',
    );
  }

  @override
  Future<void> undoInstallment(String loanId, int installmentNumber) async {
    final existing =
        await getByLoanAndInstallment(loanId, installmentNumber);
    if (existing == null) {
      throw StateError('Parcela $installmentNumber não possui pagamento');
    }
    await delete(existing.id);
  }

  @override
  Future<Payment> update(Payment payment) async {
    await (_db.update(_db.paymentsTable)..where((p) => p.id.equals(payment.id)))
        .write(
      PaymentsTableCompanion(
        amount: Value(payment.amount),
        installmentNumber: Value(payment.installmentNumber),
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

  String _todayIso() {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Payment _mapRow(PaymentsTableData row) {
    return Payment(
      id: row.id,
      loanId: row.loanId,
      amount: row.amount,
      installmentNumber: row.installmentNumber,
      paymentDate: row.paymentDate,
      method: row.method,
      createdAt: row.createdAt,
    );
  }
}
