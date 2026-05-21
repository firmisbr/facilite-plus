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
  });

  final int number;
  final DateTime dueDate;
  final double amount;
  final LoanInstallmentStatus status;
  final double paidAmount;

  bool get isPaid => status == LoanInstallmentStatus.paid;
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
    required this.monthlyInterestPercent,
    required this.periodicityLabel,
    required this.totalProfit,
    required this.profitPerInstallment,
  });

  final double principal;
  final double totalWithInterest;
  final int installmentCount;
  final double installmentAmount;
  final double monthlyInterestPercent;
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
  });

  final int paidInstallments;
  final int totalInstallments;
  final DateTime? nextDueDate;

  String get progressLabel {
    final paid = paidInstallments.toString().padLeft(2, '0');
    final total = totalInstallments.toString().padLeft(2, '0');
    return '$paid/$total parcelas pagas';
  }

  double get progress =>
      totalInstallments > 0 ? paidInstallments / totalInstallments : 0;
}
