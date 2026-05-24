import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../loans/presentation/providers/loans_providers.dart';
import '../../../payments/presentation/providers/payments_providers.dart';
import '../../../settings/presentation/providers/daily_loan_skip_sunday_provider.dart';
import '../../../../services/supabase/supabase_providers.dart';
import '../../domain/dashboard_stats.dart';

final dashboardStatsProvider = Provider<AsyncValue<DashboardStats>>((ref) {
  ref.watch(dailyLoanSkipSundayProvider);
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return const AsyncValue.data(DashboardStats.empty);
  }

  final loans = ref.watch(allLoansProvider);
  final payments = ref.watch(allPaymentsForUserProvider);

  if (loans.isLoading || payments.isLoading) {
    return const AsyncValue.loading();
  }
  if (loans.hasError) return AsyncValue.error(loans.error!, loans.stackTrace!);
  if (payments.hasError) {
    return AsyncValue.error(payments.error!, payments.stackTrace!);
  }

  return AsyncValue.data(
    DashboardStatsBuilder.build(
      loans: loans.value ?? [],
      payments: payments.value ?? [],
    ),
  );
});
