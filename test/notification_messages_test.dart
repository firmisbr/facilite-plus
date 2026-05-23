import 'package:flutter_test/flutter_test.dart';
import 'package:facilite_plus/services/notifications/installment_due_scanner.dart';
import 'package:facilite_plus/services/notifications/notification_messages.dart';

void main() {
  test('mensagem de uma parcela hoje inclui cliente e valor', () {
    const scan = DueInstallmentScanResult(
      dueOnDayCount: 1,
      overdueCount: 0,
      dueOnDayClientNames: ['Maria'],
      dueOnDayAmount: 500,
      dueOnDayLines: [DueOnDayLine(clientName: 'Maria', amount: 500)],
      overdueAmount: 0,
    );

    final copy = NotificationMessages.dueToday(scan);

    expect(copy.title, contains('R\$'));
    expect(copy.body, contains('Maria'));
    expect(copy.summary, NotificationMessages.appName);
  });

  test('mensagem de atraso inclui total', () {
    const scan = DueInstallmentScanResult(
      dueOnDayCount: 0,
      overdueCount: 2,
      dueOnDayClientNames: [],
      dueOnDayAmount: 0,
      dueOnDayLines: [],
      overdueAmount: 1200,
    );

    final copy = NotificationMessages.overdue(scan);

    expect(copy.title, contains('2 parcelas'));
    expect(copy.title, contains('R\$'));
  });
}
