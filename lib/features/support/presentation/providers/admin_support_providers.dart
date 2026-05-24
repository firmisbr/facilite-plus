import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../admin/presentation/providers/admin_providers.dart';
import '../../../../services/supabase/supabase_providers.dart';
import '../../data/repositories/admin_support_repository_impl.dart';
import '../../domain/entities/admin_support_ticket.dart';
import '../../domain/entities/ticket_message.dart';
import '../../domain/repositories/admin_support_repository.dart';
import '../../domain/support_ticket_status.dart';

final adminSupportRepositoryProvider = Provider<AdminSupportRepository>((ref) {
  return AdminSupportRepositoryImpl(ref.watch(supabaseClientProvider));
});

final adminSupportTicketsProvider =
    FutureProvider.autoDispose<List<AdminSupportTicket>>((ref) async {
  if (!ref.watch(isAdminProvider)) return [];
  ref.watch(sessionProvider);
  return ref.watch(adminSupportRepositoryProvider).fetchAllTickets();
});

/// Chamados ainda não resolvidos (`aberto` + `em_andamento`).
final adminOpenSupportTicketsCountProvider = Provider<int>((ref) {
  final ticketsAsync = ref.watch(adminSupportTicketsProvider);
  return ticketsAsync.maybeWhen(
    data: (items) => items
        .where(
          (i) =>
              i.ticket.status == SupportTicketStatus.aberto ||
              i.ticket.status == SupportTicketStatus.emAndamento,
        )
        .length,
    orElse: () => 0,
  );
});

final adminSupportTicketProvider =
    FutureProvider.autoDispose.family<AdminSupportTicket?, String>(
  (ref, ticketId) async {
    if (!ref.watch(isAdminProvider)) return null;
    ref.watch(sessionProvider);
    return ref.watch(adminSupportRepositoryProvider).fetchTicketById(ticketId);
  },
);

final adminTicketMessagesProvider =
    FutureProvider.autoDispose.family<List<TicketMessage>, String>(
  (ref, ticketId) async {
    if (!ref.watch(isAdminProvider)) return [];
    ref.watch(sessionProvider);
    return ref.watch(adminSupportRepositoryProvider).fetchMessages(ticketId);
  },
);

/// Realtime → invalida lista/detalhe/mensagens (admin).
final adminSupportRealtimeProvider =
    Provider.autoDispose<void Function()>((ref) {
  if (!ref.watch(isAdminProvider)) return () {};

  final client = ref.watch(supabaseClientProvider);

  final channel = client
      .channel('admin-support')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'support_tickets',
        callback: (_) {
          ref.invalidate(adminSupportTicketsProvider);
        },
      )
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'ticket_messages',
        callback: (_) {
          ref.invalidate(adminSupportTicketsProvider);
        },
      )
      .subscribe();

  ref.onDispose(() {
    unawaited(client.removeChannel(channel));
  });

  return () => unawaited(client.removeChannel(channel));
});

final adminTicketDetailRealtimeProvider =
    Provider.autoDispose.family<void Function(), String>((ref, ticketId) {
  if (!ref.watch(isAdminProvider)) return () {};

  final client = ref.watch(supabaseClientProvider);

  final channel = client
      .channel('admin-ticket-$ticketId')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'support_tickets',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'id',
          value: ticketId,
        ),
        callback: (_) {
          ref.invalidate(adminSupportTicketProvider(ticketId));
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
        callback: (_) {
          ref.invalidate(adminTicketMessagesProvider(ticketId));
        },
      )
      .subscribe();

  ref.onDispose(() {
    unawaited(client.removeChannel(channel));
  });

  return () => unawaited(client.removeChannel(channel));
});
