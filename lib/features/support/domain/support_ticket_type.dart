enum SupportTicketType {
  bug('bug'),
  sugestao('sugestao'),
  suporte('suporte');

  const SupportTicketType(this.value);

  final String value;

  static SupportTicketType fromValue(String raw) {
    return SupportTicketType.values.firstWhere(
      (t) => t.value == raw,
      orElse: () => SupportTicketType.suporte,
    );
  }

  String get label {
    switch (this) {
      case SupportTicketType.bug:
        return 'Bug';
      case SupportTicketType.sugestao:
        return 'Sugestão';
      case SupportTicketType.suporte:
        return 'Suporte';
    }
  }

  String get emoji {
    switch (this) {
      case SupportTicketType.bug:
        return '🐛';
      case SupportTicketType.sugestao:
        return '💡';
      case SupportTicketType.suporte:
        return '❓';
    }
  }

  String get newPageTitle {
    switch (this) {
      case SupportTicketType.bug:
        return 'Reportar bug';
      case SupportTicketType.sugestao:
        return 'Enviar sugestão';
      case SupportTicketType.suporte:
        return 'Abrir chamado';
    }
  }
}
