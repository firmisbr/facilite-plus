import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart';
import 'package:logging/logging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/sync/sync_operation_type.dart';
import '../database/drift/app_database.dart';
import 'sync_queue_repository.dart';

final _log = Logger('sync-service');

/// Orquestra fila local → Supabase e download Supabase → SQLite.
class SyncService {
  SyncService({
    required SyncQueueRepository queueRepository,
    required AppDatabase database,
    required this._supabase,
    Connectivity? connectivity,
  })  : _queue = queueRepository,
        _db = database,
        _connectivity = connectivity ?? Connectivity();

  final SyncQueueRepository _queue;
  final AppDatabase _db;
  final SupabaseClient _supabase;
  final Connectivity _connectivity;

  bool _isProcessing = false;

  Future<bool> get hasConnectivity async {
    final result = await _connectivity.checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  Future<SyncRunResult> processQueue() async {
    if (_isProcessing) {
      return SyncRunResult.skipped('Sync já em andamento');
    }

    if (_supabase.auth.currentSession == null) {
      return SyncRunResult.skipped('Sem sessão autenticada');
    }

    if (!await hasConnectivity) {
      return SyncRunResult.skipped('Sem conexão');
    }

    _isProcessing = true;
    var synced = 0;
    var failed = 0;

    try {
      final items = await _queue.pending();
      for (final item in items) {
        await _queue.markSyncing(item.id);
        try {
          await _applyToSupabase(item);
          await _queue.markSynced(item.id);
          synced++;
        } catch (e, st) {
          _log.warning('Falha ao sincronizar item ${item.id}', e, st);
          await _queue.markFailed(item.id, e.toString());
          failed++;
        }
      }
      return SyncRunResult.completed(synced: synced, failed: failed);
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> pullRemoteChanges() async {
    if (_supabase.auth.currentSession == null || !await hasConnectivity) {
      return;
    }

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    await _pullClients(userId);
    await _pullLoans(userId);
    await _pullPayments(userId);
  }

  Future<void> _pullLoans(String userId) async {
    final clientRows = await (_db.select(_db.clientsTable)
          ..where((c) => c.userId.equals(userId)))
        .get();
    if (clientRows.isEmpty) return;

    final clientIds = clientRows.map((c) => c.id).toList();
    final rows = await _supabase
        .from('loans')
        .select()
        .inFilter('client_id', clientIds);

    final list = rows as List<dynamic>;
    if (list.isEmpty) return;

    await _db.batch((batch) {
      for (final raw in list) {
        final row = Map<String, dynamic>.from(raw as Map);
        final id = row['id'] as String;
        batch.insert(
          _db.loansTable,
          LoansTableCompanion.insert(
            id: id,
            clientId: row['client_id'] as String,
            amount: row['amount'] as String,
            interest: Value(row['interest'] as String?),
            installments: Value(row['installments'] as int?),
            periodicity: Value(row['periodicity'] as String?),
            firstDueDate: Value(row['first_due_date'] as String?),
            status: Value(row['status'] as String?),
            createdAt: Value(_formatRemoteDate(row['created_at'])),
          ),
          onConflict: DoUpdate(
            (old) => LoansTableCompanion(
              amount: Value(row['amount'] as String),
              interest: Value(row['interest'] as String?),
              installments: Value(row['installments'] as int?),
              periodicity: Value(row['periodicity'] as String?),
              firstDueDate: Value(row['first_due_date'] as String?),
              status: Value(row['status'] as String?),
              createdAt: Value(_formatRemoteDate(row['created_at'])),
            ),
          ),
        );
      }
    });

    _log.info('Pull loans: ${list.length} registro(s)');
  }

  Future<void> _pullPayments(String userId) async {
    final clientRows = await (_db.select(_db.clientsTable)
          ..where((c) => c.userId.equals(userId)))
        .get();
    if (clientRows.isEmpty) return;

    final clientIds = clientRows.map((c) => c.id).toList();
    final loanRows = await (_db.select(_db.loansTable)
          ..where((l) => l.clientId.isIn(clientIds)))
        .get();
    if (loanRows.isEmpty) return;

    final loanIds = loanRows.map((l) => l.id).toList();
    final rows = await _supabase
        .from('payments')
        .select()
        .inFilter('loan_id', loanIds);

    final list = rows as List<dynamic>;
    if (list.isEmpty) return;

    await _db.batch((batch) {
      for (final raw in list) {
        final row = Map<String, dynamic>.from(raw as Map);
        final id = row['id'] as String;
        batch.insert(
          _db.paymentsTable,
          PaymentsTableCompanion.insert(
            id: id,
            loanId: row['loan_id'] as String,
            amount: row['amount'] as String,
            paymentDate: Value(row['payment_date'] as String?),
            method: Value(row['method'] as String?),
            createdAt: Value(_formatRemoteDate(row['created_at'])),
          ),
          onConflict: DoUpdate(
            (old) => PaymentsTableCompanion(
              amount: Value(row['amount'] as String),
              paymentDate: Value(row['payment_date'] as String?),
              method: Value(row['method'] as String?),
              createdAt: Value(_formatRemoteDate(row['created_at'])),
            ),
          ),
        );
      }
    });

    _log.info('Pull payments: ${list.length} registro(s)');
  }

  Future<void> _pullClients(String userId) async {
    final rows = await _supabase
        .from('clients')
        .select()
        .eq('user_id', userId);

    final list = rows as List<dynamic>;
    if (list.isEmpty) return;

    await _db.batch((batch) {
      for (final raw in list) {
        final row = Map<String, dynamic>.from(raw as Map);
        final id = row['id'] as String;
        batch.insert(
          _db.clientsTable,
          ClientsTableCompanion.insert(
            id: id,
            userId: row['user_id'] as String,
            name: row['name'] as String,
            phone: Value(row['phone'] as String?),
            email: Value(row['email'] as String?),
            document: Value(row['document'] as String?),
            address: Value(row['address'] as String?),
            notes: Value(row['notes'] as String?),
            createdAt: Value(_formatRemoteDate(row['created_at'])),
          ),
          onConflict: DoUpdate(
            (old) => ClientsTableCompanion(
              name: Value(row['name'] as String),
              phone: Value(row['phone'] as String?),
              email: Value(row['email'] as String?),
              document: Value(row['document'] as String?),
              address: Value(row['address'] as String?),
              notes: Value(row['notes'] as String?),
              createdAt: Value(_formatRemoteDate(row['created_at'])),
            ),
          ),
        );
      }
    });

    _log.info('Pull clients: ${list.length} registro(s)');
  }

  String? _formatRemoteDate(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is DateTime) return value.toUtc().toIso8601String();
    return value.toString();
  }

  Future<void> _applyToSupabase(SyncQueueTableData item) async {
    final table = _supabase.from(item.entityType);
    final payload = jsonDecode(item.payload) as Map<String, dynamic>;
    final op = SyncOperationType.fromValue(item.operation);

    switch (op) {
      case SyncOperationType.insert:
      case SyncOperationType.update:
        payload['id'] = item.entityId;
        await table.upsert(payload);
      case SyncOperationType.delete:
        await table.delete().eq('id', item.entityId);
    }
  }
}

class SyncRunResult {
  const SyncRunResult._({
    required this.skipped,
    this.reason,
    this.synced = 0,
    this.failed = 0,
  });

  factory SyncRunResult.skipped(String reason) =>
      SyncRunResult._(skipped: true, reason: reason);

  factory SyncRunResult.completed({required int synced, required int failed}) =>
      SyncRunResult._(skipped: false, synced: synced, failed: failed);

  final bool skipped;
  final String? reason;
  final int synced;
  final int failed;

  bool get success => !skipped && failed == 0;
}
