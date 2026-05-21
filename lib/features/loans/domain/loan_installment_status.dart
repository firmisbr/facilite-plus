enum LoanInstallmentStatus {
  paid('Paga', 'paga'),
  overdue('Atrasada', 'atrasada'),
  pending('No prazo', 'no_prazo');

  const LoanInstallmentStatus(this.label, this.value);

  final String label;
  final String value;
}

class LoanInstallmentItem {
  const LoanInstallmentItem({
    required this.number,
    required this.dueDate,
    required this.amount,
    required this.status,
    this.paidAmount = 0,
    this.paymentId,
    this.paidDate,
  });

  final int number;
  final DateTime dueDate;
  final double amount;
  final LoanInstallmentStatus status;
  final double paidAmount;
  final String? paymentId;
  final DateTime? paidDate;

  bool get isPaid => status == LoanInstallmentStatus.paid;
  bool get canPay => !isPaid;
  bool get canUndo => isPaid && paymentId != null;

  /// Texto curto: no dia, X dias em atraso, ou antecipado.
  String? get paymentTimingLabel {
    if (paidDate == null) return null;
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final paid = DateTime(paidDate!.year, paidDate!.month, paidDate!.day);
    final diff = paid.difference(due).inDays;
    if (diff == 0) return 'No dia do vencimento';
    if (diff > 0) return '$diff dia(s) após o vencimento';
    return '${diff.abs()} dia(s) antes do vencimento';
  }
}

class LoanOverviewStats {
  const LoanOverviewStats({
    required this.paidAmount,
    required this.remainingAmount,
    required this.paidInstallments,
    required this.remainingInstallments,
    required this.overdueInstallments,
    required this.totalInstallments,
    this.nextDueDate,
  });

  final double paidAmount;
  final double remainingAmount;
  final int paidInstallments;
  final int remainingInstallments;
  final int overdueInstallments;
  final int totalInstallments;
  final DateTime? nextDueDate;
}

class LoanManagerStats {
  const LoanManagerStats({
    required this.principal,
    required this.totalWithInterest,
    required this.installmentCount,
    required this.installmentAmount,
    required this.interestPercent,
    required this.periodicityLabel,
    required this.totalProfit,
    required this.profitPerInstallment,
  });

  final double principal;
  final double totalWithInterest;
  final int installmentCount;
  final double installmentAmount;
  final double interestPercent;
  final String periodicityLabel;
  final double totalProfit;
  final double profitPerInstallment;
}

class LoanDetailData {
  const LoanDetailData({
    required this.installments,
    required this.manager,
    required this.overview,
  });

  final List<LoanInstallmentItem> installments;
  final LoanManagerStats manager;
  final LoanOverviewStats overview;
}

class LoanCardSummary {
  const LoanCardSummary({
    required this.paidInstallments,
    required this.totalInstallments,
    this.nextDueDate,
    this.isNextDueOverdue = false,
    this.overdueInstallments = 0,
  });

  final int paidInstallments;
  final int totalInstallments;
  final DateTime? nextDueDate;
  final bool isNextDueOverdue;
  final int overdueInstallments;

  String get progressLabel {
    final paid = paidInstallments.toString().padLeft(2, '0');
    final total = totalInstallments.toString().padLeft(2, '0');
    return '$paid/$total parcelas pagas';
  }

  double get progress =>
      totalInstallments > 0 ? paidInstallments / totalInstallments : 0;
}
