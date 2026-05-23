import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../loans/domain/entities/loan.dart';
import '../../../loans/presentation/providers/loans_providers.dart';
import '../../data/repositories/payments_repository_impl.dart';
import '../../domain/entities/payment.dart';
import '../../domain/repositories/payments_repository.dart';
import '../../../../services/database/drift/drift_providers.dart';
import '../../../../services/supabase/supabase_providers.dart';
import '../../../../services/sync/sync_providers.dart';

final paymentsRepositoryProvider = Provider<PaymentsRepository>((ref) {
  return PaymentsRepositoryImpl(
    database: ref.watch(appDatabaseProvider),
    syncQueue: ref.watch(syncQueueRepositoryProvider),
  );
});

final allPaymentsForUserProvider = StreamProvider<List<Payment>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return const Stream.empty();
  }
  return ref.watch(paymentsRepositoryProvider).watchAllForUser(userId);
});

final paymentsByLoanProvider =
    StreamProvider.family<List<Payment>, String>((ref, loanId) {
  return ref.watch(paymentsRepositoryProvider).watchByLoan(loanId);
});

final loanForPaymentsProvider =
    StreamProvider.family<Loan?, String>((ref, loanId) {
  return ref.watch(loansRepositoryProvider).watchById(loanId);
});
