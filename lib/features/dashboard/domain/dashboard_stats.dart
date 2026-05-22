import '../../loans/domain/entities/loan_with_client.dart';
import '../../loans/domain/loan_installment_status.dart';
import '../../loans/domain/loan_schedule_builder.dart';
import '../../loans/domain/loan_simulator.dart';
import '../../payments/domain/entities/payment.dart';

class UpcomingDueItem {
  const UpcomingDueItem({
    required this.loanId,
    required this.clientName,
    required this.installmentNumber,
    required this.dueDate,
    required this.amount,
    required this.isOverdue,
  });

  final String loanId;
  final String clientName;
  final int installmentNumber;
  final DateTime dueDate;
  final double amount;
  final bool isOverdue;
}

class DashboardStats {
  const DashboardStats({
    required this.activeLoansCount,
    required this.clientsCount,
    required this.totalLent,
    required this.totalReceived,
    required this.totalRemaining,
    required this.expectedProfit,
    required this.overdueInstallments,
    required this.overdueAmount,
    required this.upcomingDues,
  });

  final int activeLoansCount;
  final int clientsCount;
  final double totalLent;
  final double totalReceived;
  final double totalRemaining;
  final double expectedProfit;
  final int overdueInstallments;
  final double overdueAmount;
  final List<UpcomingDueItem> upcomingDues;

  static const empty = DashboardStats(
    activeLoansCount: 0,
    clientsCount: 0,
    totalLent: 0,
    totalReceived: 0,
    totalRemaining: 0,
    expectedProfit: 0,
    overdueInstallments: 0,
    overdueAmount: 0,
    upcomingDues: [],
  );
}

abstract final class DashboardStatsBuilder {
  static DashboardStats build({
    required List<LoanWithClient> loans,
    required List<Payment> payments,
    DateTime? asOf,
  }) {
    if (loans.isEmpty) return DashboardStats.empty;

    final now = asOf ?? DateTime.now();

    final paymentsByLoan = <String, List<Payment>>{};
    for (final payment in payments) {
      paymentsByLoan.putIfAbsent(payment.loanId, () => []).add(payment);
    }

    var totalLent = 0.0;
    var totalReceived = 0.0;
    var totalRemaining = 0.0;
    var expectedProfit = 0.0;
    var overdueInstallments = 0;
    var overdueAmount = 0.0;
    var activeCount = 0;
    final clientIds = <String>{};
    final upcoming = <UpcomingDueItem>[];

    for (final item in loans) {
      clientIds.add(item.loan.clientId);
      final isActive = (item.loan.status ?? 'ativo') == 'ativo';
      if (!isActive) continue;

      activeCount++;
      final loanPayments = paymentsByLoan[item.loan.id] ?? [];
      final detail = LoanScheduleBuilder.build(
        loan: item.loan,
        payments: loanPayments,
        asOf: now,
      );

      if (detail == null) {
        totalLent += LoanSimulator.parseAmount(item.loan.amount) ?? 0;
        continue;
      }

      totalLent += detail.manager.principal;
      totalReceived += detail.overview.paidAmount;
      totalRemaining += detail.overview.remainingAmount;
      expectedProfit += detail.manager.totalProfit;
      overdueInstallments += detail.overview.overdueInstallments;

      LoanInstallmentItem? nextOpen;
      for (final installment in detail.installments) {
        if (installment.status == LoanInstallmentStatus.overdue) {
          overdueAmount += installment.amount;
        }

        if (installment.isPaid) continue;

        if (nextOpen == null ||
            installment.dueDate.isBefore(nextOpen.dueDate)) {
          nextOpen = installment;
        }
      }

      if (nextOpen != null) {
        upcoming.add(
          UpcomingDueItem(
            loanId: item.loan.id,
            clientName: item.clientName,
            installmentNumber: nextOpen.number,
            dueDate: nextOpen.dueDate,
            amount: nextOpen.amount,
            isOverdue: nextOpen.status == LoanInstallmentStatus.overdue,
          ),
        );
      }
    }

    upcoming.sort((a, b) {
      if (a.isOverdue != b.isOverdue) return a.isOverdue ? -1 : 1;
      return a.dueDate.compareTo(b.dueDate);
    });

    return DashboardStats(
      activeLoansCount: activeCount,
      clientsCount: clientIds.length,
      totalLent: totalLent,
      totalReceived: totalReceived,
      totalRemaining: totalRemaining,
      expectedProfit: expectedProfit,
      overdueInstallments: overdueInstallments,
      overdueAmount: overdueAmount,
      upcomingDues: upcoming,
    );
  }
}
