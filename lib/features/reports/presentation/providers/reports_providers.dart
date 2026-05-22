import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../loans/presentation/providers/loans_providers.dart';
import '../../../payments/presentation/providers/payments_providers.dart';
import '../../domain/report_period.dart';
import '../../domain/reports_builder.dart';
import '../../domain/reports_data.dart';

final reportPeriodSelectionProvider = StateProvider<ReportPeriodSelection>(
  (ref) => ReportPeriodSelection.initial,
);

final reportPeriodRangeProvider = Provider<ReportPeriodRange>((ref) {
  final selection = ref.watch(reportPeriodSelectionProvider);
  return ReportPeriodRange.resolve(selection: selection);
});

final reportsDataProvider = Provider<AsyncValue<ReportsData>>((ref) {
  final loansAsync = ref.watch(allLoansProvider);
  final paymentsAsync = ref.watch(allPaymentsForUserProvider);
  final period = ref.watch(reportPeriodRangeProvider);

  if (loansAsync.isLoading || paymentsAsync.isLoading) {
    return const AsyncValue.loading();
  }
  if (loansAsync.hasError) {
    return AsyncValue.error(loansAsync.error!, loansAsync.stackTrace!);
  }
  if (paymentsAsync.hasError) {
    return AsyncValue.error(paymentsAsync.error!, paymentsAsync.stackTrace!);
  }

  final loans = loansAsync.value ?? [];
  final payments = paymentsAsync.value ?? [];
  final now = DateTime.now();

  return AsyncValue.data(
    ReportsData(
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
    ),
  );
});
