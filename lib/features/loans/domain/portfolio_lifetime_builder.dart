import '../../payments/domain/entities/payment.dart';
import 'entities/loan_with_client.dart';
import 'loan_list_filter.dart';
import 'loan_schedule_builder.dart';
import 'loan_simulator.dart';

/// Totais de toda a carteira (ativos + quitados) para histórico e relatórios.
class PortfolioLifetimeStats {
  const PortfolioLifetimeStats({
    required this.totalLoans,
    required this.quitadosLoans,
    required this.totalLent,
    required this.totalReceived,
    required this.realizedProfit,
    required this.clientCount,
  });

  final int totalLoans;
  final int quitadosLoans;
  final double totalLent;
  final double totalReceived;
  final double realizedProfit;
  final int clientCount;

  static const empty = PortfolioLifetimeStats(
    totalLoans: 0,
    quitadosLoans: 0,
    totalLent: 0,
    totalReceived: 0,
    realizedProfit: 0,
    clientCount: 0,
  );

  bool get hasLoans => totalLoans > 0;

  /// Contrato total (principal + juros) nos empréstimos com cronograma válido.
  double get contractTotal => totalLent + realizedProfit;
}

abstract final class PortfolioLifetimeBuilder {
  static PortfolioLifetimeStats build({
    required List<LoanWithClient> loans,
    required List<Payment> payments,
    DateTime? asOf,
  }) {
    if (loans.isEmpty) return PortfolioLifetimeStats.empty;

    final now = asOf ?? DateTime.now();
    final paymentsByLoan = <String, List<Payment>>{};
    for (final payment in payments) {
      paymentsByLoan.putIfAbsent(payment.loanId, () => []).add(payment);
    }

    var totalLent = 0.0;
    var totalReceived = 0.0;
    var realizedProfit = 0.0;
    var quitados = 0;
    final clientIds = <String>{};

    for (final item in loans) {
      clientIds.add(item.loan.clientId);
      final loanPayments = paymentsByLoan[item.loan.id] ?? [];
      final flags = LoanListFilterHelper.flags(
        item: item,
        payments: loanPayments,
        asOf: now,
      );
      final detail = LoanScheduleBuilder.build(
        loan: item.loan,
        payments: loanPayments,
        asOf: now,
      );

      if (detail != null) {
        totalLent += detail.manager.principal;
        totalReceived += detail.overview.paidAmount;
        if (flags.isQuitado) {
          quitados++;
          realizedProfit += detail.manager.totalProfit;
        }
      } else {
        totalLent += LoanSimulator.parseAmount(item.loan.amount) ?? 0;
        if (flags.isQuitado) quitados++;
      }
    }

    return PortfolioLifetimeStats(
      totalLoans: loans.length,
      quitadosLoans: quitados,
      totalLent: totalLent,
      totalReceived: totalReceived,
      realizedProfit: realizedProfit,
      clientCount: clientIds.length,
    );
  }
}
