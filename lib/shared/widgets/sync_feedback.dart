import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../services/sync/sync_messages.dart';
import '../../services/sync/sync_providers.dart';
import '../../services/sync/sync_service.dart';
import '../providers/app_data_invalidation.dart';

void showSyncSnackBar(BuildContext context, SyncRunResult result) {
  showSyncSnackBarWithMessenger(ScaffoldMessenger.of(context), result);
}

void showSyncSnackBarWithMessenger(
  ScaffoldMessengerState messenger,
  SyncRunResult result,
) {
  final text = SyncMessages.forRunResult(result);
  final hasFailure = !result.skipped && result.failed > 0;

  messenger.showSnackBar(
    SnackBar(
      content: Text(text),
      backgroundColor: hasFailure ? AppColors.error : null,
      duration: Duration(seconds: hasFailure ? 5 : 3),
    ),
  );
}

/// Upload da fila + download da nuvem + refresh das telas em cache.
Future<SyncRunResult> runFullSync(ProviderContainer container) async {
  final sync = container.read(syncServiceProvider);
  final result = await sync.processQueue();
  await sync.pullRemoteChanges();
  invalidateAppDataCacheContainer(container);
  return result;
}

/// Mesmo fluxo do sync automático, para uso com [Ref] (ex.: coordinator).
Future<SyncRunResult> runBackgroundSync(Ref ref) async {
  final sync = ref.read(syncServiceProvider);
  final result = await sync.processQueue();
  await sync.pullRemoteChanges();
  invalidateAppDataCache(ref.invalidate);
  return result;
}
