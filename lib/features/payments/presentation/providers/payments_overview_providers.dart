import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../clients/presentation/providers/clients_providers.dart';
import '../../../loans/presentation/providers/loans_providers.dart';
import '../../../settings/presentation/providers/daily_loan_skip_sunday_provider.dart';
import '../../domain/payments_overview.dart';
import 'payments_providers.dart';

final paymentsOverviewProvider =
    Provider<AsyncValue<PaymentsOverview>>((ref) {
  ref.watch(dailyLoanSkipSundayProvider);
  final loans = ref.watch(allLoansProvider);
  final payments = ref.watch(allPaymentsForUserProvider);
  final clients = ref.watch(clientsStreamProvider);

  if (loans.isLoading || payments.isLoading || clients.isLoading) {
    return const AsyncValue.loading();
  }
  if (loans.hasError) {
    return AsyncValue.error(loans.error!, loans.stackTrace!);
  }
  if (payments.hasError) {
    return AsyncValue.error(payments.error!, payments.stackTrace!);
  }
  if (clients.hasError) {
    return AsyncValue.error(clients.error!, clients.stackTrace!);
  }

  final phoneByClient = Map<String, String?>.fromEntries(
    (clients.value ?? []).map((c) => MapEntry(c.id, c.phone)),
  );

  return AsyncValue.data(
    PaymentsOverviewBuilder.build(
      loans: loans.value ?? [],
      payments: payments.value ?? [],
      phoneByClientId: phoneByClient,
    ),
  );
});
