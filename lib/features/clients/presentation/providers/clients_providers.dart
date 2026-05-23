import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/clients_repository_impl.dart';
import '../../domain/entities/client.dart';
import '../../domain/repositories/clients_repository.dart';
import '../../../../services/database/drift/drift_providers.dart';
import '../../../../services/supabase/supabase_providers.dart';
import '../../../../services/sync/sync_providers.dart';

final clientsRepositoryProvider = Provider<ClientsRepository>((ref) {
  return ClientsRepositoryImpl(
    database: ref.watch(appDatabaseProvider),
    syncQueue: ref.watch(syncQueueRepositoryProvider),
  );
});

final clientsStreamProvider = StreamProvider<List<Client>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return const Stream.empty();
  }
  return ref.watch(clientsRepositoryProvider).watchAll(userId);
});
