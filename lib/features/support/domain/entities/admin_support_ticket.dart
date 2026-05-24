import 'support_ticket.dart';

/// Chamado com dados do usuário (painel admin).
class AdminSupportTicket {
  const AdminSupportTicket({
    required this.ticket,
    required this.userName,
    required this.userEmail,
  });

  final SupportTicket ticket;
  final String userName;
  final String userEmail;
}
