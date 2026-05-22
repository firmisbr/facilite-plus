import 'report_period.dart';

/// Métricas calculadas apenas para o período selecionado.
class ReportsPeriodSummary {
  const ReportsPeriodSummary({
    required this.receivedInPeriod,
    required this.paymentsCount,
    required this.dueInPeriod,
    required this.dueInstallmentsCount,
    required this.overdueInPeriod,
    required this.overdueInstallmentsCount,
  });

  final double receivedInPeriod;
  final int paymentsCount;
  final double dueInPeriod;
  final int dueInstallmentsCount;
  final double overdueInPeriod;
  final int overdueInstallmentsCount;

  bool get isEmpty =>
      receivedInPeriod <= 0 &&
      dueInPeriod <= 0 &&
      overdueInPeriod <= 0 &&
      paymentsCount == 0;
}

class DelinquencyAgingBucket {
  const DelinquencyAgingBucket({
    required this.label,
    required this.installmentCount,
    required this.amount,
    required this.clientCount,
  });

  final String label;
  final int installmentCount;
  final double amount;
  final int clientCount;
}

class DelinquencyClientRow {
  const DelinquencyClientRow({
    required this.clientId,
    required this.clientName,
    required this.overdueInstallments,
    required this.overdueAmount,
    required this.maxDaysOverdue,
  });

  final String clientId;
  final String clientName;
  final int overdueInstallments;
  final double overdueAmount;
  final int maxDaysOverdue;
}

class ReportPaymentRow {
  const ReportPaymentRow({
    required this.date,
    required this.clientName,
    required this.loanId,
    required this.installmentNumber,
    required this.amount,
    required this.method,
  });

  final DateTime date;
  final String clientName;
  final String loanId;
  final int? installmentNumber;
  final double amount;
  final String? method;
}

class ReportDueRow {
  const ReportDueRow({
    required this.dueDate,
    required this.clientName,
    required this.loanId,
    required this.installmentNumber,
    required this.amount,
  });

  final DateTime dueDate;
  final String clientName;
  final String loanId;
  final int installmentNumber;
  final double amount;
}

class ReportsSnapshot {
  const ReportsSnapshot({
    required this.period,
    required this.generatedAt,
    required this.summary,
    required this.aging,
    required this.delinquentClients,
    required this.paymentsInPeriod,
    required this.dueInPeriod,
    required this.hasActiveLoans,
  });

  final ReportPeriodRange period;
  final DateTime generatedAt;
  final ReportsPeriodSummary summary;
  final List<DelinquencyAgingBucket> aging;
  final List<DelinquencyClientRow> delinquentClients;
  final List<ReportPaymentRow> paymentsInPeriod;
  final List<ReportDueRow> dueInPeriod;
  final bool hasActiveLoans;

  bool get hasPeriodData => !summary.isEmpty || delinquentClients.isNotEmpty;
}
