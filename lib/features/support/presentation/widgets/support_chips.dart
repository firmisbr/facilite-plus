import 'package:flutter/material.dart';

import '../../domain/support_ticket_status.dart';
import '../../domain/support_ticket_type.dart';

class SupportTypeChip extends StatelessWidget {
  const SupportTypeChip({super.key, required this.type});

  final SupportTicketType type;

  @override
  Widget build(BuildContext context) {
    final color = switch (type) {
      SupportTicketType.bug => const Color(0xFFC46A6A),
      SupportTicketType.sugestao => const Color(0xFFD6A85F),
      SupportTicketType.suporte => const Color(0xFF6B8FA3),
    };

    return _SupportChip(label: type.label, color: color);
  }
}

class SupportStatusChip extends StatelessWidget {
  const SupportStatusChip({super.key, required this.status});

  final SupportTicketStatus status;

  @override
  Widget build(BuildContext context) {
    return _SupportChip(label: status.label, color: status.color);
  }
}

class _SupportChip extends StatelessWidget {
  const _SupportChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
