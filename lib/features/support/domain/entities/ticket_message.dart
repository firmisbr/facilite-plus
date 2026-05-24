class TicketMessage {
  const TicketMessage({
    required this.id,
    required this.ticketId,
    required this.authorId,
    required this.authorRole,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String ticketId;
  final String authorId;
  final String authorRole;
  final String body;
  final String createdAt;

  bool get isFromAdmin => authorRole == 'admin';

  Map<String, dynamic> toSyncPayload() {
    return {
      'ticket_id': ticketId,
      'author_id': authorId,
      'author_role': authorRole,
      'body': body,
      'created_at': createdAt,
    };
  }
}
