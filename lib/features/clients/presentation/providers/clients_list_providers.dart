import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../loans/domain/loan_schedule_builder.dart';
import '../../../loans/presentation/providers/loans_providers.dart';
import '../../../payments/presentation/providers/payments_providers.dart';
import '../../../settings/presentation/providers/daily_loan_skip_sunday_provider.dart';
import '../../domain/client_list_entry.dart';
import 'clients_providers.dart';

final clientListEntriesProvider =
    Provider<AsyncValue<List<ClientListEntry>>>((ref) {
  ref.watch(dailyLoanSkipSundayProvider);
  final clients = ref.watch(clientsStreamProvider);
  final loans = ref.watch(allLoansProvider);
  final payments = ref.watch(allPaymentsForUserProvider);

  if (clients.isLoading || loans.isLoading || payments.isLoading) {
    return const AsyncValue.loading();
  }
  if (clients.hasError) {
    return AsyncValue.error(clients.error!, clients.stackTrace!);
  }
  if (loans.hasError) {
    return AsyncValue.error(loans.error!, loans.stackTrace!);
  }
  if (payments.hasError) {
    return AsyncValue.error(payments.error!, payments.stackTrace!);
  }

  final paymentList = payments.value ?? [];
  final overdueByClient = <String, int>{};
  final activeLoansByClient = <String, int>{};

  for (final item in loans.value ?? []) {
    final loan = item.loan;
    if ((loan.status ?? 'ativo') == 'quitado') continue;

    activeLoansByClient[loan.clientId] =
        (activeLoansByClient[loan.clientId] ?? 0) + 1;

    final loanPayments =
        paymentList.where((p) => p.loanId == loan.id).toList();
    final detail = LoanScheduleBuilder.build(
      loan: loan,
      payments: loanPayments,
    );
    if (detail != null && detail.overview.overdueInstallments > 0) {
      overdueByClient[loan.clientId] =
          (overdueByClient[loan.clientId] ?? 0) +
              detail.overview.overdueInstallments;
    }
  }

  final entries = (clients.value ?? []).map((client) {
    return ClientListEntry(
      client: client,
      overdueInstallments: overdueByClient[client.id] ?? 0,
      activeLoansCount: activeLoansByClient[client.id] ?? 0,
    );
  }).toList();

  return AsyncValue.data(entries);
});

List<ClientListEntry> filterClientEntries(
  List<ClientListEntry> entries,
  String query,
) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return entries;

  return entries.where((e) {
    final c = e.client;
    final haystack = [
      c.name,
      c.phone,
      c.document,
      c.email,
    ].whereType<String>().join(' ').toLowerCase();
    final digits = q.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 3) {
      final docDigits = (c.document ?? '').replaceAll(RegExp(r'\D'), '');
      final phoneDigits = (c.phone ?? '').replaceAll(RegExp(r'\D'), '');
      if (docDigits.contains(digits) || phoneDigits.contains(digits)) {
        return true;
      }
    }
    return haystack.contains(q);
  }).toList();
}
