import '../../loans/domain/entities/loan_with_client.dart';
import '../../loans/domain/loan_installment_status.dart';
import '../../loans/domain/loan_schedule_builder.dart';
import 'entities/payment.dart';

class PaymentLoanCardItem {
  const PaymentLoanCardItem({
    required this.loanItem,
    required this.clientPhone,
    required this.remainingAmount,
    required this.overdueAmount,
    required this.overdueInstallments,
    required this.dueSoonInstallments,
    required this.nextDueDate,
    required this.nextInstallmentNumber,
    required this.hasOverdue,
    required this.hasDueSoon,
  });

  final LoanWithClient loanItem;
  final String? clientPhone;
  final double remainingAmount;
  final double overdueAmount;
  final int overdueInstallments;
  final int dueSoonInstallments;
  final DateTime? nextDueDate;

  /// Parcela em aberto mais próxima (para destaque no detalhe do empréstimo).
  final int? nextInstallmentNumber;
  final bool hasOverdue;
  final bool hasDueSoon;

  String get clientName => loanItem.clientName;
  String get loanId => loanItem.loan.id;
}

class PaymentsOverview {
  const PaymentsOverview({
    required this.totalToReceive,
    required this.totalOverdue,
    required this.clientsOverdueCount,
    required this.loanCards,
  });

  final double totalToReceive;
  final double totalOverdue;
  final int clientsOverdueCount;
  final List<PaymentLoanCardItem> loanCards;

  static const empty = PaymentsOverview(
    totalToReceive: 0,
    totalOverdue: 0,
    clientsOverdueCount: 0,
    loanCards: [],
  );
}

abstract final class PaymentsOverviewBuilder {
  static PaymentsOverview build({
    required List<LoanWithClient> loans,
    required List<Payment> payments,
    required Map<String, String?> phoneByClientId,
    DateTime? asOf,
  }) {
    if (loans.isEmpty) return PaymentsOverview.empty;

    final now = asOf ?? DateTime.now();

    final paymentsByLoan = <String, List<Payment>>{};
    for (final payment in payments) {
      paymentsByLoan.putIfAbsent(payment.loanId, () => []).add(payment);
    }

    var totalToReceive = 0.0;
    var totalOverdue = 0.0;
    final clientsOverdue = <String>{};
    final cards = <PaymentLoanCardItem>[];

    for (final item in loans) {
      if ((item.loan.status ?? 'ativo') == 'quitado') continue;

      final loanPayments = paymentsByLoan[item.loan.id] ?? [];
      final detail = LoanScheduleBuilder.build(
        loan: item.loan,
        payments: loanPayments,
        asOf: now,
      );

      if (detail == null) continue;

      var overdueAmount = 0.0;
      var overdueCount = 0;
      LoanInstallmentItem? nextOpen;

      for (final installment in detail.installments) {
        if (installment.isPaid) continue;

        if (installment.status == LoanInstallmentStatus.overdue) {
          overdueCount++;
          overdueAmount += installment.amount;
        }

        if (nextOpen == null ||
            installment.dueDate.isBefore(nextOpen.dueDate)) {
          nextOpen = installment;
        }
      }

      final nextDue = nextOpen != null
          ? DateTime(
              nextOpen.dueDate.year,
              nextOpen.dueDate.month,
              nextOpen.dueDate.day,
            )
          : null;
      final hasDueSoon = nextOpen != null &&
          nextOpen.status != LoanInstallmentStatus.overdue;

      final remaining = detail.overview.remainingAmount;
      if (remaining <= 0 && overdueCount == 0 && !hasDueSoon) {
        continue;
      }

      totalToReceive += remaining;
      totalOverdue += overdueAmount;

      final clientId = item.loan.clientId;
      if (overdueCount > 0) clientsOverdue.add(clientId);

      cards.add(
        PaymentLoanCardItem(
          loanItem: item,
          clientPhone: phoneByClientId[clientId],
          remainingAmount: remaining,
          overdueAmount: overdueAmount,
          overdueInstallments: overdueCount,
          dueSoonInstallments: hasDueSoon ? 1 : 0,
          nextDueDate: nextDue,
          nextInstallmentNumber: nextOpen?.number,
          hasOverdue: overdueCount > 0,
          hasDueSoon: hasDueSoon,
        ),
      );
    }

    cards.sort((a, b) {
      if (a.hasOverdue != b.hasOverdue) return a.hasOverdue ? -1 : 1;
      if (a.hasDueSoon != b.hasDueSoon) return a.hasDueSoon ? -1 : 1;
      if (a.hasOverdue && b.hasOverdue) {
        return b.overdueAmount.compareTo(a.overdueAmount);
      }
      final aDue = a.nextDueDate;
      final bDue = b.nextDueDate;
      if (aDue == null && bDue == null) return 0;
      if (aDue == null) return 1;
      if (bDue == null) return -1;
      return aDue.compareTo(bDue);
    });

    return PaymentsOverview(
      totalToReceive: totalToReceive,
      totalOverdue: totalOverdue,
      clientsOverdueCount: clientsOverdue.length,
      loanCards: cards,
    );
  }
}
