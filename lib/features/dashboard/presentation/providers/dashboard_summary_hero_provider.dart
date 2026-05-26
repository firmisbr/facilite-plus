import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../loans/presentation/providers/loans_providers.dart';
import '../../../payments/presentation/providers/payments_providers.dart';
import '../../../settings/presentation/providers/daily_loan_skip_sunday_provider.dart';
import '../../domain/dashboard_summary_hero_metrics.dart';
import 'dashboard_providers.dart';
import 'dashboard_summary_scope_provider.dart';

final dashboardSummaryHeroMetricsProvider =
    Provider<DashboardSummaryHeroMetrics?>((ref) {
  ref.watch(dailyLoanSkipSundayProvider);
  final scope = ref.watch(dashboardSummaryScopeProvider);
  final stats = ref.watch(dashboardStatsProvider).valueOrNull;
  if (stats == null) return null;

  final loans = ref.watch(allLoansProvider).valueOrNull ?? [];
  final payments = ref.watch(allPaymentsForUserProvider).valueOrNull ?? [];

  return DashboardSummaryHeroBuilder.build(
    stats: stats,
    loans: loans,
    payments: payments,
    scope: scope,
  );
});
