import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../clients/domain/entities/client.dart';
import '../../../clients/presentation/providers/clients_providers.dart';
import '../../data/repositories/loans_repository_impl.dart';
import '../../domain/entities/loan.dart';
import '../../domain/entities/loan_with_client.dart';
import '../../domain/repositories/loans_repository.dart';
import '../../../../services/database/drift/drift_providers.dart';
import '../../../../services/supabase/supabase_providers.dart';
import '../../../../services/sync/sync_providers.dart';

final loansRepositoryProvider = Provider<LoansRepository>((ref) {
  return LoansRepositoryImpl(
    database: ref.watch(appDatabaseProvider),
    syncQueue: ref.watch(syncQueueRepositoryProvider),
  );
});

final allLoansProvider = StreamProvider<List<LoanWithClient>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return const Stream.empty();
  }
  return ref.watch(loansRepositoryProvider).watchAllForUser(userId);
});

final loansByClientProvider =
    StreamProvider.family<List<Loan>, String>((ref, clientId) {
  return ref.watch(loansRepositoryProvider).watchByClient(clientId);
});

final clientForLoansProvider =
    FutureProvider.family<Client?, String>((ref, clientId) {
  return ref.watch(clientsRepositoryProvider).getById(clientId);
});
