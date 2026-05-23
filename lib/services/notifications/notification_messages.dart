import '../../features/loans/domain/loan_simulator.dart';
import 'installment_due_scanner.dart';

/// Textos exibidos nas notificações locais.
abstract final class NotificationMessages {
  static const appName = 'Facilite Plus';

  static NotificationCopy dueToday(DueInstallmentScanResult scan) {
    final count = scan.dueOnDayCount;
    final total = LoanSimulator.formatMoney(scan.dueOnDayAmount);

    if (count == 1 && scan.dueOnDayLines.isNotEmpty) {
      final line = scan.dueOnDayLines.first;
      final amount = LoanSimulator.formatMoney(line.amount);
      return NotificationCopy(
        title: 'Cobrança hoje · $amount',
        body: '${line.clientName} tem parcela vencendo hoje.',
        summary: appName,
      );
    }

    if (count == 1) {
      final name = scan.dueOnDayClientNames.isNotEmpty
          ? scan.dueOnDayClientNames.first
          : 'um cliente';
      return NotificationCopy(
        title: 'Cobrança hoje · $total',
        body: '$name tem parcela vencendo hoje.',
        summary: appName,
      );
    }

    final names = _formatClientList(scan.dueOnDayClientNames, count);
    return NotificationCopy(
      title: '$count parcelas hoje · $total',
      body: 'Vencem hoje: $names.',
      summary: appName,
    );
  }

  static NotificationCopy overdue(DueInstallmentScanResult scan) {
    final count = scan.overdueCount;
    final total = LoanSimulator.formatMoney(scan.overdueAmount);
    final title = count == 1
        ? 'Parcela em atraso · $total'
        : '$count parcelas em atraso · $total';

    final body = count == 1
        ? 'Há 1 parcela vencida na carteira. Abra o app para registrar o pagamento.'
        : 'Há $count parcelas vencidas na carteira. Abra o app para conferir os clientes.';

    return NotificationCopy(
      title: title,
      body: body,
      summary: appName,
    );
  }

  static NotificationCopy test() {
    return const NotificationCopy(
      title: 'Lembrete de cobrança',
      body:
          'Você receberá avisos neste horário quando houver parcelas '
          'a vencer ou em atraso na carteira.',
      summary: appName,
    );
  }

  static String _formatClientList(List<String> names, int totalCount) {
    if (names.isEmpty) return '$totalCount cliente(s)';
    if (names.length == 1 && totalCount == 1) return names.first;
    if (names.length == 1) return names.first;
    if (names.length == 2) return '${names[0]} e ${names[1]}';
    return '${names[0]}, ${names[1]} e mais';
  }
}

class NotificationCopy {
  const NotificationCopy({
    required this.title,
    required this.body,
    this.summary,
  });

  final String title;
  final String body;
  final String? summary;
}
