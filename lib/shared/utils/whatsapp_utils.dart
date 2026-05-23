import 'package:url_launcher/url_launcher.dart';

/// Abre WhatsApp com mensagem pré-preenchida (formato +55DDD9XXXXXXXX).
abstract final class WhatsAppUtils {
  /// Converte telefone cadastrado para dígitos usados em `wa.me/`.
  static String? normalizeBrazilPhone(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;

    var digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;

    if (digits.startsWith('00')) {
      digits = digits.substring(2);
    }

    if (digits.startsWith('55')) {
      return digits.length >= 12 ? digits : null;
    }

    if (digits.length == 10) {
      digits = '${digits.substring(0, 2)}9${digits.substring(2)}';
    }

    if (digits.length == 11) {
      return '55$digits';
    }

    return null;
  }

  static String overdueCollectionMessage({
    required String clientName,
    required int overdueInstallments,
    required String overdueAmountFormatted,
    required String? nextDueFormatted,
  }) {
    final buffer = StringBuffer()
      ..writeln('Fala, $clientName! Tranquilo aí?')
      ..writeln()
      ..writeln('Aqui é do *Facilite Plus* e estou entrando em contato sobre seu empréstimo.')
      ..writeln()
      ..writeln('📋 *Situação:*')
      ..writeln('• Parcela(s) em atraso: $overdueInstallments')
      ..writeln('• Valor em atraso: $overdueAmountFormatted');

    if (nextDueFormatted != null) {
      buffer.writeln('• Próximo vencimento: $nextDueFormatted');
    }

    buffer
      ..writeln()
      ..writeln('Vamos acertar o pagamento? Fico no aguardo do seu retorno.')
      ..writeln()
      ..writeln('Obrigado!');

    return buffer.toString();
  }

  static Future<bool> openCollectionChat({
    required String? phone,
    required String message,
  }) async {
    final normalized = normalizeBrazilPhone(phone);
    if (normalized == null) return false;

    final uri = Uri.parse(
      'https://wa.me/$normalized?text=${Uri.encodeComponent(message)}',
    );

    if (!await canLaunchUrl(uri)) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
