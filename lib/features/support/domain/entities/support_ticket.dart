import '../support_ticket_status.dart';
import '../support_ticket_type.dart';

class SupportTicket {
  const SupportTicket({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.description,
    this.extraField,
    required this.status,
    this.devResponse,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final SupportTicketType type;
  final String title;
  final String description;
  final String? extraField;
  final SupportTicketStatus status;
  final String? devResponse;
  final String createdAt;
  final String updatedAt;

  Map<String, dynamic> toSyncPayload() {
    return {
      'user_id': userId,
      'type': type.value,
      'title': title,
      'description': description,
      'extra_field': extraField,
      'status': status.value,
      'dev_response': devResponse,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
