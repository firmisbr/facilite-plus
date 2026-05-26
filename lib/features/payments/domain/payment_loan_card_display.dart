import '../../loans/domain/loan_installment_status.dart';
import '../../loans/domain/loan_simulator.dart';
import '../../../shared/utils/portuguese_date_list_formatter.dart';
import 'payments_overview.dart';

extension PaymentLoanCardDisplay on PaymentLoanCardItem {
  List<LoanInstallmentItem> get overdueInstallmentItems {
    final list = installments
        .where((i) => i.status == LoanInstallmentStatus.overdue)
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return list;
  }

  String? get dueDatesLabel {
    if (hasOverdue) {
      return PortugueseDateListFormatter.formatDueDates(
        overdueInstallmentItems.map((i) => i.dueDate),
      );
    }
    if (nextDueDate != null) {
      return LoanSimulator.formatDate(nextDueDate!);
    }
    return null;
  }

  String get overdueChipLabel {
    final overdue = overdueInstallmentItems;
    final count = overdue.length;
    if (count == 0) return '';

    final distinctAmounts = overdue.map((i) => i.amount).toSet();
    final unitAmount = distinctAmounts.length == 1
        ? distinctAmounts.first
        : overdueAmount / count;

    return '${count}x ${LoanSimulator.formatMoney(unitAmount)} em atraso · '
        '${LoanSimulator.formatMoney(overdueAmount)}';
  }
}
