import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/drift/drift_providers.dart';
import '../supabase/supabase_providers.dart';
import 'sync_queue_repository.dart';
import 'sync_queue_summary.dart';
import 'sync_service.dart';

final syncQueueRepositoryProvider = Provider<SyncQueueRepository>((ref) {
  return SyncQueueRepository(ref.watch(appDatabaseProvider));
});

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
    queueRepository: ref.watch(syncQueueRepositoryProvider),
    database: ref.watch(appDatabaseProvider),
    supabase: ref.watch(supabaseClientProvider),
  );
});

final pendingSyncCountProvider = FutureProvider<int>((ref) async {
  return ref.watch(syncQueueRepositoryProvider).countPending();
});

final syncQueueSummaryProvider = FutureProvider<SyncQueueSummary>((ref) async {
  final repo = ref.watch(syncQueueRepositoryProvider);
  final pending = await repo.countAwaitingUpload();
  final failed = await repo.countFailed();
  return SyncQueueSummary(pending: pending, failed: failed);
});
