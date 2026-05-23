import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../services/database/drift/drift_providers.dart';
import '../../../../services/sync/sync_providers.dart';
import '../../../../services/supabase/supabase_providers.dart';
import '../../../clients/presentation/providers/clients_list_providers.dart';
import '../../../clients/presentation/providers/clients_providers.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../../loans/presentation/providers/loans_providers.dart';
import '../../../payments/presentation/providers/payments_overview_providers.dart';
import '../../../payments/presentation/providers/payments_providers.dart';
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
  ref.invalidate(backupPreviewProvider);
  ref.invalidate(allLoansProvider);
  ref.invalidate(allPaymentsForUserProvider);
  ref.invalidate(paymentsOverviewProvider);
  ref.invalidate(dashboardStatsProvider);
  ref.invalidate(clientsStreamProvider);
  ref.invalidate(clientListEntriesProvider);
  ref.invalidate(syncQueueSummaryProvider);
  ref.invalidate(pendingSyncCountProvider);
}
