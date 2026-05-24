import '../entities/admin_support_ticket.dart';
import '../entities/support_ticket.dart';
import '../entities/ticket_message.dart';
import '../support_ticket_status.dart';

abstract class AdminSupportRepository {
  Future<List<AdminSupportTicket>> fetchAllTickets();

  Future<AdminSupportTicket?> fetchTicketById(String ticketId);

  Future<List<TicketMessage>> fetchMessages(String ticketId);

  Future<SupportTicket> updateTicket({
    required String ticketId,
    SupportTicketStatus? status,
    String? devResponse,
  });

  Future<TicketMessage> sendAdminMessage({
    required String ticketId,
    required String authorId,
    required String body,
  });
}
