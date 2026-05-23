import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/backup/presentation/providers/backup_providers.dart';
import '../../features/clients/presentation/providers/clients_list_providers.dart';
import '../../features/clients/presentation/providers/clients_providers.dart';
import '../../features/dashboard/presentation/providers/dashboard_providers.dart';
import '../../features/loans/presentation/providers/loans_providers.dart';
import '../../features/payments/presentation/providers/payments_overview_providers.dart';
import '../../features/payments/presentation/providers/payments_providers.dart';
import '../../services/sync/sync_providers.dart';

/// Recarrega telas que leem SQLite (backup, dashboard, relatórios, etc.).
void invalidateAppDataCache(void Function(ProviderOrFamily provider) invalidate) {
  invalidate(backupPreviewProvider);
  invalidate(allLoansProvider);
  invalidate(allPaymentsForUserProvider);
  invalidate(paymentsOverviewProvider);
  invalidate(dashboardStatsProvider);
  invalidate(clientsStreamProvider);
  invalidate(clientListEntriesProvider);
  invalidate(syncQueueSummaryProvider);
  invalidate(pendingSyncCountProvider);
}

void invalidateAppDataCacheWidgetRef(WidgetRef ref) =>
    invalidateAppDataCache(ref.invalidate);

void invalidateAppDataCacheContainer(ProviderContainer container) =>
    invalidateAppDataCache(container.invalidate);
