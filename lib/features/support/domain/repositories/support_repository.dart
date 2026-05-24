import '../entities/support_ticket.dart';
import '../entities/ticket_message.dart';
import '../support_ticket_type.dart';

abstract class SupportRepository {
  Stream<List<SupportTicket>> watchTickets(String userId);

  Stream<SupportTicket?> watchTicket(String ticketId);

  Stream<List<TicketMessage>> watchMessages(String ticketId);

  Future<SupportTicket?> getTicket(String ticketId);

  Future<SupportTicket> createTicket({
    required String userId,
    required SupportTicketType type,
    required String title,
    required String description,
    String? extraField,
  });

  Future<TicketMessage> sendMessage({
    required String ticketId,
    required String authorId,
    required String body,
  });

  Future<void> upsertTicketFromRemote(Map<String, dynamic> row);

  Future<void> upsertMessageFromRemote(Map<String, dynamic> row);
}
