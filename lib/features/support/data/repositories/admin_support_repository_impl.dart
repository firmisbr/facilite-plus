import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/admin_support_ticket.dart';
import '../../domain/entities/support_ticket.dart';
import '../../domain/entities/ticket_message.dart';
import '../../domain/repositories/admin_support_repository.dart';
import '../../domain/support_ticket_status.dart';
import '../support_row_mapper.dart';

class AdminSupportRepositoryImpl implements AdminSupportRepository {
  AdminSupportRepositoryImpl(this._supabase);

  final SupabaseClient _supabase;
  final _uuid = const Uuid();

  @override
  Future<List<AdminSupportTicket>> fetchAllTickets() async {
    final rows = await _supabase
        .from('support_tickets')
        .select()
        .order('updated_at', ascending: false);

    final list = (rows as List<dynamic>)
        .map((raw) => Map<String, dynamic>.from(raw as Map))
        .toList();
    if (list.isEmpty) return [];

    final userIds = list.map((r) => r['user_id'] as String).toSet().toList();
    final profiles = await _fetchProfiles(userIds);

    return list.map((row) {
      final userId = row['user_id'] as String;
      final profile = profiles[userId];
      final email = profile?['email'] as String? ?? '';
      final name = profile?['name'] as String?;
      return AdminSupportTicket(
        ticket: SupportRowMapper.ticketFromRow(row),
        userName: name?.trim().isNotEmpty == true ? name!.trim() : email,
        userEmail: email,
      );
    }).toList();
  }

  @override
  Future<AdminSupportTicket?> fetchTicketById(String ticketId) async {
    final row = await _supabase
        .from('support_tickets')
        .select()
        .eq('id', ticketId)
        .maybeSingle();
    if (row == null) return null;

    final map = Map<String, dynamic>.from(row);
    final userId = map['user_id'] as String;
    final profiles = await _fetchProfiles([userId]);
    final profile = profiles[userId];
    final email = profile?['email'] as String? ?? '';
    final name = profile?['name'] as String?;

    return AdminSupportTicket(
      ticket: SupportRowMapper.ticketFromRow(map),
      userName: name?.trim().isNotEmpty == true ? name!.trim() : email,
      userEmail: email,
    );
  }

  @override
  Future<List<TicketMessage>> fetchMessages(String ticketId) async {
    final rows = await _supabase
        .from('ticket_messages')
        .select()
        .eq('ticket_id', ticketId)
        .order('created_at', ascending: true);

    return (rows as List<dynamic>)
        .map((raw) => SupportRowMapper.messageFromRow(
              Map<String, dynamic>.from(raw as Map),
            ))
        .toList();
  }

  @override
  Future<SupportTicket> updateTicket({
    required String ticketId,
    SupportTicketStatus? status,
    String? devResponse,
  }) async {
    final patch = <String, dynamic>{};
    if (status != null) patch['status'] = status.value;
    if (devResponse != null) {
      patch['dev_response'] = devResponse.trim().isEmpty ? null : devResponse.trim();
    }
    if (patch.isEmpty) {
      final current = await fetchTicketById(ticketId);
      if (current == null) throw StateError('Chamado não encontrado');
      return current.ticket;
    }

    final row = await _supabase
        .from('support_tickets')
        .update(patch)
        .eq('id', ticketId)
        .select()
        .single();

    return SupportRowMapper.ticketFromRow(Map<String, dynamic>.from(row));
  }

  @override
  Future<TicketMessage> sendAdminMessage({
    required String ticketId,
    required String authorId,
    required String body,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now().toUtc().toIso8601String();

    final row = await _supabase.from('ticket_messages').insert({
      'id': id,
      'ticket_id': ticketId,
      'author_id': authorId,
      'author_role': 'admin',
      'body': body.trim(),
      'created_at': now,
    }).select().single();

    return SupportRowMapper.messageFromRow(Map<String, dynamic>.from(row));
  }

  Future<Map<String, Map<String, dynamic>>> _fetchProfiles(
    List<String> userIds,
  ) async {
    if (userIds.isEmpty) return {};
    final rows = await _supabase
        .from('profiles')
        .select('id, name, email')
        .inFilter('id', userIds);

    final map = <String, Map<String, dynamic>>{};
    for (final raw in rows as List<dynamic>) {
      final row = Map<String, dynamic>.from(raw as Map);
      map[row['id'] as String] = row;
    }
    return map;
  }
}
