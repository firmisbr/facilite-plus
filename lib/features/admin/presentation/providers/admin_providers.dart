import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../clients/domain/entities/client.dart';
import '../../../dashboard/domain/dashboard_stats.dart';
import '../../../loans/domain/entities/loan.dart';
import '../../../loans/domain/entities/loan_with_client.dart';
import '../../../loans/domain/loan_installment_status.dart';
import '../../../loans/domain/loan_schedule_builder.dart';
import '../../../payments/domain/entities/payment.dart';
import '../../../reports/domain/report_period.dart';
import '../../../reports/domain/reports_builder.dart';
import '../../../reports/domain/reports_data.dart';
import '../../../../services/supabase/supabase_providers.dart';
import '../../data/admin_repository_impl.dart';
import '../../domain/admin_user.dart';
import '../../domain/repositories/admin_repository.dart';
import '../../domain/user_role.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepositoryImpl(ref.watch(supabaseClientProvider));
});

final userRoleProvider = FutureProvider<UserRole>((ref) async {
  final session = ref.watch(sessionProvider);
  if (session.isLoading) return UserRole.guest;
  if (session.valueOrNull == null) return UserRole.guest;

  ref.watch(sessionProvider);
  return ref.watch(adminRepositoryProvider).fetchCurrentUserRole();
});

final isAdminProvider = Provider<bool>((ref) {
  return ref.watch(userRoleProvider).valueOrNull == UserRole.admin;
});

final adminUsersProvider = FutureProvider<List<AdminUser>>((ref) async {
  ref.watch(sessionProvider);
  return ref.watch(adminRepositoryProvider).fetchAppUsers();
});

final adminUserProvider =
    FutureProvider.family<AdminUser?, String>((ref, userId) async {
  ref.watch(sessionProvider);
  return ref.watch(adminRepositoryProvider).fetchUserById(userId);
});

final adminClientsProvider =
    FutureProvider.family<List<Client>, String>((ref, userId) async {
  ref.watch(sessionProvider);
  return ref.watch(adminRepositoryProvider).fetchClientsForUser(userId);
});

final adminLoansProvider =
    FutureProvider.family<List<LoanWithClient>, String>((ref, userId) async {
  ref.watch(sessionProvider);
  return ref.watch(adminRepositoryProvider).fetchLoansForUser(userId);
});

final adminPaymentsProvider =
    FutureProvider.family<List<Payment>, String>((ref, userId) async {
  ref.watch(sessionProvider);
  return ref.watch(adminRepositoryProvider).fetchPaymentsForUser(userId);
});

final adminDashboardStatsProvider =
    FutureProvider.family<DashboardStats, String>((ref, userId) async {
  final loans = await ref.watch(adminLoansProvider(userId).future);
  final payments = await ref.watch(adminPaymentsProvider(userId).future);
  return DashboardStatsBuilder.build(loans: loans, payments: payments);
});

final adminReportPeriodSelectionProvider =
    StateProvider.family<ReportPeriodSelection, String>(
  (ref, userId) => ReportPeriodSelection.initial,
);

final adminReportPeriodRangeProvider =
    Provider.family<ReportPeriodRange, String>((ref, userId) {
  final selection = ref.watch(adminReportPeriodSelectionProvider(userId));
  return ReportPeriodRange.resolve(selection: selection);
});

final adminReportsDataProvider =
    FutureProvider.family<ReportsData, String>((ref, userId) async {
  final loans = await ref.watch(adminLoansProvider(userId).future);
  final payments = await ref.watch(adminPaymentsProvider(userId).future);
  final period = ref.watch(adminReportPeriodRangeProvider(userId));
  final now = DateTime.now();

  return ReportsData(
    periodReport: ReportsBuilder.build(
      loans: loans,
      payments: payments,
      period: period,
      asOf: now,
    ),
    portfolio: ReportsBuilder.buildPortfolio(
      loans: loans,
      payments: payments,
      asOf: now,
    ),
    generatedAt: now,
  );
});

final adminClientLoansProvider =
    FutureProvider.family<List<Loan>, (String userId, String clientId)>(
  (ref, params) async {
    final loans = await ref.watch(adminLoansProvider(params.$1).future);
    return loans
        .where((item) => item.loan.clientId == params.$2)
        .map((item) => item.loan)
        .toList();
  },
);

class AdminLoanDetailBundle {
  const AdminLoanDetailBundle({
    required this.loan,
    required this.client,
    required this.clientName,
    required this.payments,
    required this.detail,
  });

  final Loan loan;
  final Client client;
  final String clientName;
  final List<Payment> payments;
  final LoanDetailData? detail;
}

final adminLoanDetailProvider =
    FutureProvider.family<AdminLoanDetailBundle?, (String userId, String loanId)>(
  (ref, params) async {
    final repo = ref.watch(adminRepositoryProvider);
    final loan = await repo.fetchLoanById(params.$2);
    if (loan == null) return null;

    final client = await repo.fetchClientById(loan.clientId);
    if (client == null) return null;

  final loans = await ref.watch(adminLoansProvider(params.$1).future);
    String clientName = client.name;
    for (final item in loans) {
      if (item.loan.id == loan.id) {
        clientName = item.clientName;
        break;
      }
    }

    final payments = await repo.fetchPaymentsForLoan(loan.id);
    return AdminLoanDetailBundle(
      loan: loan,
      client: client,
      clientName: clientName,
      payments: payments,
      detail: LoanScheduleBuilder.build(loan: loan, payments: payments),
    );
  },
);

final adminClientSummaryProvider =
    FutureProvider.family<AdminClientSummary?, (String userId, String clientId)>(
  (ref, params) async {
    final loans = await ref.watch(adminClientLoansProvider(params).future);
    if (loans.isEmpty) {
      final client = await ref
          .watch(adminRepositoryProvider)
          .fetchClientById(params.$2);
      if (client == null) return null;
      return AdminClientSummary(
        client: client,
        activeLoans: 0,
        totalLent: 0,
        totalRemaining: 0,
        overdueInstallments: 0,
      );
    }

    final allLoans = await ref.watch(adminLoansProvider(params.$1).future);
    final payments = await ref.watch(adminPaymentsProvider(params.$1).future);
    final clientName = allLoans
        .firstWhere(
          (item) => item.loan.clientId == params.$2,
          orElse: () => LoanWithClient(
            loan: loans.first,
            clientName: 'Cliente',
          ),
        )
        .clientName;

    final client = await ref
        .watch(adminRepositoryProvider)
        .fetchClientById(params.$2);
    if (client == null) return null;

    var activeLoans = 0;
    var totalLent = 0.0;
    var totalRemaining = 0.0;
    var overdueInstallments = 0;

    final paymentsByLoan = <String, List<Payment>>{};
    for (final payment in payments) {
      paymentsByLoan.putIfAbsent(payment.loanId, () => []).add(payment);
    }

    for (final loan in loans) {
      final detail = LoanScheduleBuilder.build(
        loan: loan,
        payments: paymentsByLoan[loan.id] ?? [],
      );
      if (detail == null) continue;
      if (detail.overview.remainingInstallments == 0) continue;

      activeLoans++;
      totalLent += detail.manager.principal;
      totalRemaining += detail.overview.remainingAmount;
      overdueInstallments += detail.overview.overdueInstallments;
    }

    return AdminClientSummary(
      client: client.copyWith(name: clientName),
      activeLoans: activeLoans,
      totalLent: totalLent,
      totalRemaining: totalRemaining,
      overdueInstallments: overdueInstallments,
    );
  },
);

class AdminClientSummary {
  const AdminClientSummary({
    required this.client,
    required this.activeLoans,
    required this.totalLent,
    required this.totalRemaining,
    required this.overdueInstallments,
  });

  final Client client;
  final int activeLoans;
  final double totalLent;
  final double totalRemaining;
  final int overdueInstallments;
}
