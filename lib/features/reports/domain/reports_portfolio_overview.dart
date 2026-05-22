import '../../dashboard/domain/dashboard_stats.dart';
import 'reports_snapshot.dart';

/// Análise da carteira inteira (aba Visão geral — não usa filtro de período).
class ReportsPortfolioOverview {
  const ReportsPortfolioOverview({
    required this.totalLent,
    required this.totalReceived,
    required this.totalRemaining,
    required this.expectedProfit,
    required this.averageProfitPerLoan,
    required this.averageTicketPerLoan,
    required this.recoveryRatePercent,
    required this.profitMarginPercent,
    required this.activeLoans,
    required this.activeClients,
    required this.quitadosLoans,
    required this.overdueInstallments,
    required this.overdueAmount,
    required this.dueThisMonth,
    required this.dueNextMonth,
    required this.aging,
    required this.delinquentClients,
    required this.cashFlowByMonth,
    required this.hasActiveLoans,
  });

  final double totalLent;
  final double totalReceived;
  final double totalRemaining;
  final double expectedProfit;
  final double averageProfitPerLoan;
  final double averageTicketPerLoan;

  /// % do contratado já recebido: recebido / (recebido + em aberto).
  final double recoveryRatePercent;

  /// Lucro esperado sobre principal emprestado.
  final double profitMarginPercent;

  final int activeLoans;
  final int activeClients;
  final int quitadosLoans;
  final int overdueInstallments;
  final double overdueAmount;
  final double dueThisMonth;
  final double dueNextMonth;
  final List<DelinquencyAgingBucket> aging;
  final List<DelinquencyClientRow> delinquentClients;
  final List<CashFlowBucket> cashFlowByMonth;
  final bool hasActiveLoans;

  bool get hasDelinquency => delinquentClients.isNotEmpty;
}
