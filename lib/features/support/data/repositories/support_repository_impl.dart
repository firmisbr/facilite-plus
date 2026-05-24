import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:facilite_plus/core/repositories/syncable_repository.dart';
import 'package:facilite_plus/core/sync/sync_entity_type.dart';
import 'package:facilite_plus/core/sync/sync_operation_type.dart';
import 'package:facilite_plus/features/support/domain/entities/support_ticket.dart';
import 'package:facilite_plus/features/support/domain/entities/ticket_message.dart';
import 'package:facilite_plus/features/support/domain/repositories/support_repository.dart';
import 'package:facilite_plus/features/support/domain/support_ticket_status.dart';
import 'package:facilite_plus/features/support/domain/support_ticket_type.dart';
import 'package:facilite_plus/services/database/drift/app_database.dart';
import 'package:facilite_plus/services/sync/sync_queue_repository.dart';

class SupportRepositoryImpl extends SyncableRepository
    implements SupportRepository {
  SupportRepositoryImpl({
    required AppDatabase database,
    required SyncQueueRepository syncQueue,
  })  : _db = database,
        super(syncQueue);

  final AppDatabase _db;
  final _uuid = const Uuid();

  @override
  Stream<List<SupportTicket>> watchTickets(String userId) {
    return (_db.select(_db.supportTicketsTable)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([
            (t) => OrderingTerm.desc(t.updatedAt),
          ]))
        .watch()
        .map((rows) => rows.map(_mapTicket).toList());
  }

  @override
  Stream<SupportTicket?> watchTicket(String ticketId) {
    return (_db.select(_db.supportTicketsTable)
          ..where((t) => t.id.equals(ticketId)))
        .watchSingleOrNull()
        .map((row) => row == null ? null : _mapTicket(row));
  }

  @override
  Stream<List<TicketMessage>> watchMessages(String ticketId) {
    return (_db.select(_db.ticketMessagesTable)
          ..where((m) => m.ticketId.equals(ticketId))
          ..orderBy([(m) => OrderingTerm.asc(m.createdAt)]))
        .watch()
        .map((rows) => rows.map(_mapMessage).toList());
  }

  @override
  Future<SupportTicket?> getTicket(String ticketId) async {
    final row = await (_db.select(_db.supportTicketsTable)
          ..where((t) => t.id.equals(ticketId)))
        .getSingleOrNull();
    return row == null ? null : _mapTicket(row);
  }

  @override
  Future<SupportTicket> createTicket({
    required String userId,
    required SupportTicketType type,
    required String title,
    required String description,
    String? extraField,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now().toUtc().toIso8601String();
    final ticket = SupportTicket(
      id: id,
      userId: userId,
      type: type,
      title: title,
      description: description,
      extraField: extraField,
      status: SupportTicketStatus.aberto,
      createdAt: now,
      updatedAt: now,
    );

    await _db.into(_db.supportTicketsTable).insert(
          SupportTicketsTableCompanion.insert(
            id: id,
            userId: userId,
            type: type.value,
            title: title,
            description: description,
            extraField: Value(extraField),
            status: SupportTicketStatus.aberto.value,
            createdAt: now,
            updatedAt: now,
          ),
        );

    await enqueueSync(
      entityType: SyncEntityType.supportTicket,
      entityId: id,
      operation: SyncOperationType.insert,
      payload: ticket.toSyncPayload(),
    );

    return ticket;
  }

  @override
  Future<TicketMessage> sendMessage({
    required String ticketId,
    required String authorId,
    required String body,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now().toUtc().toIso8601String();
    final message = TicketMessage(
      id: id,
      ticketId: ticketId,
      authorId: authorId,
      authorRole: 'user',
      body: body,
      createdAt: now,
    );

    await _db.into(_db.ticketMessagesTable).insert(
          TicketMessagesTableCompanion.insert(
            id: id,
            ticketId: ticketId,
            authorId: authorId,
            authorRole: 'user',
            body: body,
            createdAt: now,
          ),
        );

    await (_db.update(_db.supportTicketsTable)
          ..where((t) => t.id.equals(ticketId)))
        .write(
      SupportTicketsTableCompanion(updatedAt: Value(now)),
    );

    await enqueueSync(
      entityType: SyncEntityType.ticketMessage,
      entityId: id,
      operation: SyncOperationType.insert,
      payload: message.toSyncPayload(),
    );

    return message;
  }

  @override
  Future<void> upsertTicketFromRemote(Map<String, dynamic> row) async {
    final id = row['id'] as String;
    await _db.into(_db.supportTicketsTable).insert(
          SupportTicketsTableCompanion.insert(
            id: id,
            userId: row['user_id'] as String,
            type: row['type'] as String,
            title: row['title'] as String,
            description: row['description'] as String,
            extraField: Value(row['extra_field'] as String?),
            status: row['status'] as String,
            devResponse: Value(row['dev_response'] as String?),
            createdAt: _formatDate(row['created_at'])!,
            updatedAt: _formatDate(row['updated_at'])!,
          ),
          onConflict: DoUpdate(
            (old) => SupportTicketsTableCompanion(
              type: Value(row['type'] as String),
              title: Value(row['title'] as String),
              description: Value(row['description'] as String),
              extraField: Value(row['extra_field'] as String?),
              status: Value(row['status'] as String),
              devResponse: Value(row['dev_response'] as String?),
              updatedAt: Value(_formatDate(row['updated_at'])!),
            ),
          ),
        );
  }

  @override
  Future<void> upsertMessageFromRemote(Map<String, dynamic> row) async {
    final id = row['id'] as String;
    await _db.into(_db.ticketMessagesTable).insert(
          TicketMessagesTableCompanion.insert(
            id: id,
            ticketId: row['ticket_id'] as String,
            authorId: row['author_id'] as String,
            authorRole: row['author_role'] as String,
            body: row['body'] as String,
            createdAt: _formatDate(row['created_at'])!,
          ),
          onConflict: DoUpdate(
            (old) => TicketMessagesTableCompanion(
              body: Value(row['body'] as String),
            ),
          ),
        );
  }

  String? _formatDate(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is DateTime) return value.toUtc().toIso8601String();
    return value.toString();
  }

  SupportTicket _mapTicket(SupportTicketsTableData row) {
    return SupportTicket(
      id: row.id,
      userId: row.userId,
      type: SupportTicketType.fromValue(row.type),
      title: row.title,
      description: row.description,
      extraField: row.extraField,
      status: SupportTicketStatus.fromValue(row.status),
      devResponse: row.devResponse,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  TicketMessage _mapMessage(TicketMessagesTableData row) {
    return TicketMessage(
      id: row.id,
      ticketId: row.ticketId,
      authorId: row.authorId,
      authorRole: row.authorRole,
      body: row.body,
      createdAt: row.createdAt,
    );
  }
}
