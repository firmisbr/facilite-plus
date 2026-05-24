import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

enum SupportTicketStatus {
  aberto('aberto'),
  emAndamento('em_andamento'),
  resolvido('resolvido');

  const SupportTicketStatus(this.value);

  final String value;

  static SupportTicketStatus fromValue(String raw) {
    return SupportTicketStatus.values.firstWhere(
      (s) => s.value == raw,
      orElse: () => SupportTicketStatus.aberto,
    );
  }

  String get label {
    switch (this) {
      case SupportTicketStatus.aberto:
        return 'Aberto';
      case SupportTicketStatus.emAndamento:
        return 'Em andamento';
      case SupportTicketStatus.resolvido:
        return 'Resolvido';
    }
  }

  Color get color {
    switch (this) {
      case SupportTicketStatus.aberto:
        return AppColors.info;
      case SupportTicketStatus.emAndamento:
        return AppColors.warning;
      case SupportTicketStatus.resolvido:
        return AppColors.success;
    }
  }
}
