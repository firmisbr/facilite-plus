import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../services/database/drift/drift_providers.dart';
import '../../../../services/sync/sync_providers.dart';
import '../../../../services/supabase/supabase_providers.dart';
import '../../../../shared/providers/app_data_invalidation.dart';
import '../../data/backup_service.dart';
import '../../domain/backup_snapshot.dart';

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(
    database: ref.watch(appDatabaseProvider),
    syncQueue: ref.watch(syncQueueRepositoryProvider),
  );
});

final backupPreviewProvider = FutureProvider<BackupSnapshot>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) throw StateError('Sem sessão');
  final session = ref.watch(sessionProvider).valueOrNull;
  return ref.watch(backupServiceProvider).buildSnapshot(
        userId: userId,
        userEmail: session?.user.email,
      );
});

void invalidateDataAfterBackupRestore(WidgetRef ref) {
  invalidateAppDataCacheWidgetRef(ref);
}
