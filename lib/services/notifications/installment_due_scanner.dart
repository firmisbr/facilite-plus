import '../../features/loans/domain/entities/loan_with_client.dart';
import '../../features/loans/domain/loan_installment_status.dart';
import '../../features/loans/domain/loan_list_filter.dart';
import '../../features/loans/domain/loan_schedule_builder.dart';
import '../../features/payments/domain/entities/payment.dart';

class DueOnDayLine {
  const DueOnDayLine({
    required this.clientName,
    required this.amount,
  });

  final String clientName;
  final double amount;
}

class DueInstallmentScanResult {
  const DueInstallmentScanResult({
    required this.dueOnDayCount,
    required this.overdueCount,
    required this.dueOnDayClientNames,
    required this.dueOnDayAmount,
    required this.dueOnDayLines,
    required this.overdueAmount,
  });

  final int dueOnDayCount;
  final int overdueCount;
  final List<String> dueOnDayClientNames;
  final double dueOnDayAmount;
  final List<DueOnDayLine> dueOnDayLines;
  final double overdueAmount;

  static const empty = DueInstallmentScanResult(
    dueOnDayCount: 0,
    overdueCount: 0,
    dueOnDayClientNames: [],
    dueOnDayAmount: 0,
    dueOnDayLines: [],
    overdueAmount: 0,
  );
}

/// Varre a carteira e conta parcelas por dia / em atraso.
abstract final class InstallmentDueScanner {
  static DueInstallmentScanResult scan({
    required List<LoanWithClient> loans,
    required List<Payment> payments,
    DateTime? onDay,
  }) {
    final day = onDay ?? DateTime.now();
    final target = DateTime(day.year, day.month, day.day);
    final asOf = DateTime(day.year, day.month, day.day, 23, 59, 59);

    final paymentsByLoan = <String, List<Payment>>{};
    for (final p in payments) {
      paymentsByLoan.putIfAbsent(p.loanId, () => []).add(p);
    }

    var dueOnDayCount = 0;
    var dueOnDayAmount = 0.0;
    var overdueCount = 0;
    var overdueAmount = 0.0;
    final clientNames = <String>[];
    final dueByClient = <String, double>{};

    for (final item in loans) {
      final loanPayments = paymentsByLoan[item.loan.id] ?? [];
      final flags = LoanListFilterHelper.flags(
        item: item,
        payments: loanPayments,
        asOf: asOf,
      );
      if (flags.isQuitado) continue;

      final detail = LoanScheduleBuilder.build(
        loan: item.loan,
        payments: loanPayments,
        asOf: asOf,
      );
      if (detail == null) continue;

      for (final inst in detail.installments) {
        if (inst.isPaid) continue;

        final due = DateTime(
          inst.dueDate.year,
          inst.dueDate.month,
          inst.dueDate.day,
        );

        if (inst.status == LoanInstallmentStatus.overdue) {
          overdueCount++;
          overdueAmount += inst.amount;
        }

        if (due == target) {
          dueOnDayCount++;
          dueOnDayAmount += inst.amount;
          dueByClient[item.clientName] =
              (dueByClient[item.clientName] ?? 0) + inst.amount;
          if (!clientNames.contains(item.clientName)) {
            clientNames.add(item.clientName);
          }
        }
      }
    }

    final dueLines = dueByClient.entries
        .map(
          (e) => DueOnDayLine(clientName: e.key, amount: e.value),
        )
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    return DueInstallmentScanResult(
      dueOnDayCount: dueOnDayCount,
      overdueCount: overdueCount,
      dueOnDayClientNames: clientNames.take(3).toList(),
      dueOnDayAmount: dueOnDayAmount,
      dueOnDayLines: dueLines,
      overdueAmount: overdueAmount,
    );
  }

}
