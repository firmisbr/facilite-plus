import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/sync/sync_entity_type.dart';
import '../../../core/sync/sync_operation_type.dart';
import '../../../features/clients/domain/entities/client.dart';
import '../../../features/loans/domain/entities/loan.dart';
import '../../../features/payments/domain/entities/payment.dart';
import '../../../services/database/drift/app_database.dart';
import '../../../services/sync/sync_queue_repository.dart';
import 'backup_downloads_storage.dart';
import '../domain/backup_snapshot.dart';
import '../domain/backup_transfer_pin.dart';

class BackupService {
  BackupService({
    required AppDatabase database,
    required this._syncQueue,
  })  : _db = database;

  final AppDatabase _db;
  final SyncQueueRepository _syncQueue;

  Future<BackupSnapshot> buildSnapshot({
    required String userId,
    String? userEmail,
    String? transferPin,
  }) async {
    String? pinSalt;
    String? pinHash;
    if (transferPin != null) {
      final pinData = BackupTransferPin.createForExport(transferPin);
      pinSalt = pinData.salt;
      pinHash = pinData.hash;
    }
    final clientRows = await (_db.select(_db.clientsTable)
          ..where((c) => c.userId.equals(userId)))
        .get();
    final clientIds = clientRows.map((c) => c.id).toList();

    final loanRows = clientIds.isEmpty
        ? <LoansTableData>[]
        : await (_db.select(_db.loansTable)
              ..where((l) => l.clientId.isIn(clientIds)))
            .get();
    final loanIds = loanRows.map((l) => l.id).toList();

    final paymentRows = loanIds.isEmpty
        ? <PaymentsTableData>[]
        : await (_db.select(_db.paymentsTable)
              ..where((pay) => pay.loanId.isIn(loanIds)))
            .get();

    return BackupSnapshot(
      version: BackupSnapshot.currentVersion,
      app: BackupSnapshot.appId,
      exportedAt: DateTime.now().toUtc().toIso8601String(),
      userId: userId,
      userEmail: userEmail,
      transferPinSalt: pinSalt,
      transferPinHash: pinHash,
      clients: clientRows.map(_clientToMap).toList(),
      loans: loanRows.map(_loanToMap).toList(),
      payments: paymentRows.map(_paymentToMap).toList(),
    );
  }

  Future<BackupExportFile> exportToFile({
    required String userId,
    String? userEmail,
    required String transferPin,
  }) async {
    final snapshot = await buildSnapshot(
      userId: userId,
      userEmail: userEmail,
      transferPin: transferPin,
    );
    final dir = await getTemporaryDirectory();
    final stamp = DateFormat('yyyy-MM-dd_HHmm').format(DateTime.now());
    final fileName = 'facilite-backup_$stamp.json';
    final filePath = p.join(dir.path, fileName);
    final jsonBytes = utf8.encode(
      const JsonEncoder.withIndent('  ').convert(snapshot.toJson()),
    );
    await File(filePath).writeAsBytes(jsonBytes);
    final downloadsPath = await BackupDownloadsStorage.saveJsonFile(
      fileName: fileName,
      bytes: jsonBytes,
    );
    return BackupExportFile(
      snapshot: snapshot,
      filePath: filePath,
      fileName: fileName,
      downloadsPath: downloadsPath,
    );
  }

  Future<BackupSnapshot> parseFileBytes(List<int> bytes) async {
    try {
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map<String, dynamic>) {
        throw BackupException('Arquivo JSON inválido.');
      }
      return BackupSnapshot.fromJson(decoded);
    } on BackupException {
      rethrow;
    } on FormatException {
      throw BackupException('Arquivo JSON inválido.');
    }
  }

  Future<BackupRestoreSummary> restoreSnapshot({
    required BackupSnapshot snapshot,
    required String currentUserId,
    bool importToCurrentAccount = false,
    String? transferPin,
    bool enqueueCloudSync = true,
  }) async {
    if (importToCurrentAccount) {
      if (transferPin == null) {
        throw BackupException('Informe o PIN do backup.');
      }
      snapshot.validateForCrossAccountImport(pin: transferPin);
    } else {
      snapshot.validateForSameAccountRestore(currentUserId: currentUserId);
    }

    await _db.transaction(() async {
      await _clearUserData(currentUserId);

      for (final raw in snapshot.clients) {
        await _db.into(_db.clientsTable).insert(
              _clientCompanion(raw, currentUserId),
            );
      }
      for (final raw in snapshot.loans) {
        await _db.into(_db.loansTable).insert(_loanCompanion(raw));
      }
      for (final raw in snapshot.payments) {
        await _db.into(_db.paymentsTable).insert(_paymentCompanion(raw));
      }
    });

    if (enqueueCloudSync) {
      await _enqueueFullUpload(currentUserId);
    }

    return BackupRestoreSummary(
      clients: snapshot.clients.length,
      loans: snapshot.loans.length,
      payments: snapshot.payments.length,
      importedFromOtherAccount: importToCurrentAccount,
      sourceUserEmail: importToCurrentAccount ? snapshot.userEmail : null,
    );
  }

  Future<void> _clearUserData(String userId) async {
    final clients = await (_db.select(_db.clientsTable)
          ..where((c) => c.userId.equals(userId)))
        .get();
    final clientIds = clients.map((c) => c.id).toList();

    if (clientIds.isNotEmpty) {
      final loans = await (_db.select(_db.loansTable)
            ..where((l) => l.clientId.isIn(clientIds)))
          .get();
      final loanIds = loans.map((l) => l.id).toList();
      if (loanIds.isNotEmpty) {
        await (_db.delete(_db.paymentsTable)
              ..where((pay) => pay.loanId.isIn(loanIds)))
            .go();
      }
      await (_db.delete(_db.loansTable)
            ..where((l) => l.clientId.isIn(clientIds)))
          .go();
      await (_db.delete(_db.clientsTable)
            ..where((c) => c.userId.equals(userId)))
          .go();
    }
    await _db.delete(_db.syncQueueTable).go();
  }

  Future<void> _enqueueFullUpload(String userId) async {
    final clientRows = await (_db.select(_db.clientsTable)
          ..where((c) => c.userId.equals(userId)))
        .get();
    for (final row in clientRows) {
      final client = _mapClient(row);
      await _syncQueue.enqueue(
        entityType: SyncEntityType.client,
        entityId: client.id,
        operation: SyncOperationType.update,
        payload: client.toSyncPayload(),
      );
    }

    final clientIds = clientRows.map((c) => c.id).toList();
    if (clientIds.isEmpty) return;

    final loanRows = await (_db.select(_db.loansTable)
          ..where((l) => l.clientId.isIn(clientIds)))
        .get();
    for (final row in loanRows) {
      final loan = _mapLoan(row);
      await _syncQueue.enqueue(
        entityType: SyncEntityType.loan,
        entityId: loan.id,
        operation: SyncOperationType.update,
        payload: loan.toSyncPayload(),
      );
    }

    final loanIds = loanRows.map((l) => l.id).toList();
    if (loanIds.isEmpty) return;

    final paymentRows = await (_db.select(_db.paymentsTable)
          ..where((pay) => pay.loanId.isIn(loanIds)))
        .get();
    for (final row in paymentRows) {
      final payment = _mapPayment(row);
      await _syncQueue.enqueue(
        entityType: SyncEntityType.payment,
        entityId: payment.id,
        operation: SyncOperationType.update,
        payload: payment.toSyncPayload(),
      );
    }
  }

  Map<String, dynamic> _clientToMap(ClientsTableData row) => {
        'id': row.id,
        'user_id': row.userId,
        'name': row.name,
        'phone': row.phone,
        'email': row.email,
        'document': row.document,
        'address': row.address,
        'notes': row.notes,
        'created_at': row.createdAt,
      };

  Map<String, dynamic> _loanToMap(LoansTableData row) => {
        'id': row.id,
        'client_id': row.clientId,
        'amount': row.amount,
        'interest': row.interest,
        'installments': row.installments,
        'periodicity': row.periodicity,
        'first_due_date': row.firstDueDate,
        'status': row.status,
        'created_at': row.createdAt,
      };

  Map<String, dynamic> _paymentToMap(PaymentsTableData row) => {
        'id': row.id,
        'loan_id': row.loanId,
        'amount': row.amount,
        'installment_number': row.installmentNumber,
        'payment_date': row.paymentDate,
        'method': row.method,
        'created_at': row.createdAt,
      };

  ClientsTableCompanion _clientCompanion(
    Map<String, dynamic> raw,
    String userId,
  ) {
    return ClientsTableCompanion.insert(
      id: raw['id'] as String,
      userId: userId,
      name: raw['name'] as String,
      phone: Value(raw['phone'] as String?),
      email: Value(raw['email'] as String?),
      document: Value(raw['document'] as String?),
      address: Value(raw['address'] as String?),
      notes: Value(raw['notes'] as String?),
      createdAt: Value(raw['created_at'] as String?),
    );
  }

  LoansTableCompanion _loanCompanion(Map<String, dynamic> raw) {
    return LoansTableCompanion.insert(
      id: raw['id'] as String,
      clientId: raw['client_id'] as String,
      amount: raw['amount'] as String,
      interest: Value(raw['interest'] as String?),
      installments: Value(_readInt(raw['installments'])),
      periodicity: Value(raw['periodicity'] as String?),
      firstDueDate: Value(raw['first_due_date'] as String?),
      status: Value(raw['status'] as String?),
      createdAt: Value(raw['created_at'] as String?),
    );
  }

  PaymentsTableCompanion _paymentCompanion(Map<String, dynamic> raw) {
    return PaymentsTableCompanion.insert(
      id: raw['id'] as String,
      loanId: raw['loan_id'] as String,
      amount: raw['amount'] as String,
      installmentNumber: Value(_readInt(raw['installment_number'])),
      paymentDate: Value(raw['payment_date'] as String?),
      method: Value(raw['method'] as String?),
      createdAt: Value(raw['created_at'] as String?),
    );
  }

  Client _mapClient(ClientsTableData row) => Client(
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

  Loan _mapLoan(LoansTableData row) => Loan(
        id: row.id,
        clientId: row.clientId,
        amount: row.amount,
        interest: row.interest,
        installments: row.installments,
        periodicity: row.periodicity,
        firstDueDate: row.firstDueDate,
        status: row.status,
        createdAt: row.createdAt,
      );

  static int? _readInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  Payment _mapPayment(PaymentsTableData row) => Payment(
        id: row.id,
        loanId: row.loanId,
        amount: row.amount,
        installmentNumber: row.installmentNumber,
        paymentDate: row.paymentDate,
        method: row.method,
        createdAt: row.createdAt,
      );
}
