import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../services/database/drift/drift_providers.dart';
import '../../../../services/supabase/supabase_providers.dart';
import '../../../../services/sync/sync_providers.dart';
import '../../data/repositories/support_repository_impl.dart';
import '../../data/support_seen_store.dart';
import '../../domain/entities/support_ticket.dart';
import '../../domain/entities/ticket_message.dart';
import '../../domain/repositories/support_repository.dart';

final supportRepositoryProvider = Provider<SupportRepository>((ref) {
  return SupportRepositoryImpl(
    database: ref.watch(appDatabaseProvider),
    syncQueue: ref.watch(syncQueueRepositoryProvider),
  );
});

final supportSeenStoreProvider = FutureProvider<SupportSeenStore>((ref) async {
  return SupportSeenStore.open();
});

final supportTicketsProvider =
    StreamProvider.autoDispose<List<SupportTicket>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const Stream.empty();
  return ref.watch(supportRepositoryProvider).watchTickets(userId);
});

final supportTicketProvider =
    StreamProvider.autoDispose.family<SupportTicket?, String>((ref, id) {
  return ref.watch(supportRepositoryProvider).watchTicket(id);
});

final ticketMessagesProvider =
    StreamProvider.autoDispose.family<List<TicketMessage>, String>((ref, id) {
  return ref.watch(supportRepositoryProvider).watchMessages(id);
});

/// Badge no menu Config quando algum ticket foi atualizado após a última leitura.
final hasSupportAttentionBadgeProvider = Provider<bool>((ref) {
  final tickets = ref.watch(supportTicketsProvider).valueOrNull;
  final seenStore = ref.watch(supportSeenStoreProvider).valueOrNull;
  if (tickets == null || seenStore == null) return false;

  for (final ticket in tickets) {
    final seen = seenStore.lastSeenAt(ticket.id);
    if (seen == null || ticket.updatedAt.compareTo(seen) > 0) {
      return true;
    }
  }
  return false;
});

/// Realtime Supabase → SQLite para um ticket específico.
final ticketRealtimeProvider =
    Provider.autoDispose.family<RealtimeChannel?, String>((ref, ticketId) {
  final client = ref.watch(supabaseClientProvider);
  final repo = ref.watch(supportRepositoryProvider);

  final channel = client
      .channel('ticket-$ticketId')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'support_tickets',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'id',
          value: ticketId,
        ),
        callback: (payload) async {
          final record = payload.newRecord;
          if (record.isEmpty) return;
          await repo.upsertTicketFromRemote(record);
        },
      )
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'ticket_messages',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'ticket_id',
          value: ticketId,
        ),
        callback: (payload) async {
          final record = payload.newRecord;
          if (record.isEmpty) return;
          await repo.upsertMessageFromRemote(record);
        },
      )
      .subscribe();

  ref.onDispose(() {
    unawaited(client.removeChannel(channel));
  });

  return channel;
});

Future<void> markSupportTicketSeen(
  WidgetRef ref,
  SupportTicket ticket,
) async {
  final store = await ref.read(supportSeenStoreProvider.future);
  await store.markSeen(ticket.id, ticket.updatedAt);
  ref.invalidate(supportSeenStoreProvider);
  ref.invalidate(hasSupportAttentionBadgeProvider);
}
