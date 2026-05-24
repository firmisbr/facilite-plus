import '../domain/entities/support_ticket.dart';
import '../domain/entities/ticket_message.dart';
import '../domain/support_ticket_status.dart';
import '../domain/support_ticket_type.dart';

abstract final class SupportRowMapper {
  static SupportTicket ticketFromRow(Map<String, dynamic> row) {
    return SupportTicket(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      type: SupportTicketType.fromValue(row['type'] as String),
      title: row['title'] as String,
      description: row['description'] as String,
      extraField: row['extra_field'] as String?,
      status: SupportTicketStatus.fromValue(row['status'] as String),
      devResponse: row['dev_response'] as String?,
      createdAt: _formatDate(row['created_at'])!,
      updatedAt: _formatDate(row['updated_at'])!,
    );
  }

  static TicketMessage messageFromRow(Map<String, dynamic> row) {
    return TicketMessage(
      id: row['id'] as String,
      ticketId: row['ticket_id'] as String,
      authorId: row['author_id'] as String,
      authorRole: row['author_role'] as String,
      body: row['body'] as String,
      createdAt: _formatDate(row['created_at'])!,
    );
  }

  static String? _formatDate(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is DateTime) return value.toUtc().toIso8601String();
    return value.toString();
  }
}
