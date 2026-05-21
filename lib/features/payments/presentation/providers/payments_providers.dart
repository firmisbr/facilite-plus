import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../loans/domain/entities/loan.dart';
import '../../../loans/presentation/providers/loans_providers.dart';
import '../../data/repositories/payments_repository_impl.dart';
import '../../domain/entities/payment.dart';
import '../../domain/repositories/payments_repository.dart';
import '../../../../services/database/drift/drift_providers.dart';
import '../../../../services/sync/sync_providers.dart';

final paymentsRepositoryProvider = Provider<PaymentsRepository>((ref) {
  return PaymentsRepositoryImpl(
    database: ref.watch(appDatabaseProvider),
    syncQueue: ref.watch(syncQueueRepositoryProvider),
  );
});

final paymentsByLoanProvider =
    StreamProvider.family<List<Payment>, String>((ref, loanId) {
  return ref.watch(paymentsRepositoryProvider).watchByLoan(loanId);
});

final loanForPaymentsProvider =
    FutureProvider.family<Loan?, String>((ref, loanId) {
  return ref.watch(loansRepositoryProvider).getById(loanId);
});
