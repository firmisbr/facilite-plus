import '../../dashboard/domain/dashboard_stats.dart';
import 'reports_snapshot.dart';

/// Análise da carteira inteira (aba Visão geral — não usa filtro de período).
class ReportsPortfolioOverview {
  const ReportsPortfolioOverview({
    required this.totalLent,
    required this.lifetimeTotalLent,
    required this.totalReceived,
    required this.totalRemaining,
    required this.remainingProfit,
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
    required this.hasAnyLoans,
    required this.realizedProfit,
    required this.isHistoricalOnly,
  });

  /// Principal emprestado na carteira ativa.
  final double totalLent;

  /// Principal emprestado em todos os contratos (ativos + quitados).
  final double lifetimeTotalLent;

  final double totalReceived;
  final double totalRemaining;

  /// Juros/lucro ainda nas parcelas em aberto.
  final double remainingProfit;

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
  final bool hasAnyLoans;

  /// Lucro já realizado (contratos quitados).
  final double realizedProfit;

  /// Sem empréstimos ativos; exibe histórico da carteira.
  final bool isHistoricalOnly;

  bool get hasDelinquency => delinquentClients.isNotEmpty;

  /// Há quitados e ativos ao mesmo tempo — vale exibir os dois totais.
  bool get hasMixedPortfolio => hasAnyLoans && activeLoans > 0 && quitadosLoans > 0;
}
