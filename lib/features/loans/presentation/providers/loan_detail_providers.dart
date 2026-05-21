import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../clients/domain/entities/client.dart';
import '../../../payments/domain/entities/payment.dart';
import '../../../payments/presentation/providers/payments_providers.dart';
import '../../domain/entities/loan.dart';
import '../../domain/loan_installment_status.dart';
import '../../domain/loan_schedule_builder.dart';
import 'loans_providers.dart';

class LoanDetailBundle {
  const LoanDetailBundle({
    required this.loan,
    required this.client,
    required this.payments,
    required this.detail,
  });

  final Loan loan;
  final Client client;
  final List<Payment> payments;
  final LoanDetailData? detail;
}

final loanDetailProvider = Provider.family<LoanDetailBundle?, String>((ref, loanId) {
  final payments = ref.watch(paymentsByLoanProvider(loanId)).valueOrNull;
  if (payments == null) return null;

  final loan = ref.watch(loanForPaymentsProvider(loanId)).valueOrNull;
  if (loan == null) return null;

  final client =
      ref.watch(clientForLoansProvider(loan.clientId)).valueOrNull;
  if (client == null) return null;

  return LoanDetailBundle(
    loan: loan,
    client: client,
    payments: payments,
    detail: LoanScheduleBuilder.build(loan: loan, payments: payments),
  );
});

final loanDetailLoadingProvider =
    Provider.family<bool, String>((ref, loanId) {
  final loanAsync = ref.watch(loanForPaymentsProvider(loanId));
  if (loanAsync.isLoading) return true;
  final loan = loanAsync.valueOrNull;
  if (loan == null) return false;
  return ref.watch(paymentsByLoanProvider(loanId)).isLoading ||
      ref.watch(clientForLoansProvider(loan.clientId)).isLoading;
});

final loanCardSummaryProvider =
    Provider.family<LoanCardSummary?, String>((ref, loanId) {
  final payments = ref.watch(paymentsByLoanProvider(loanId)).valueOrNull;
  final loans = ref.watch(allLoansProvider).valueOrNull;
  if (payments == null || loans == null) return null;

  Loan? loan;
  for (final item in loans) {
    if (item.loan.id == loanId) {
      loan = item.loan;
      break;
    }
  }
  if (loan == null) return null;

  return LoanScheduleBuilder.cardSummary(loan: loan, payments: payments);
});
