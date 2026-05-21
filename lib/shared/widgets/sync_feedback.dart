import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../services/sync/sync_messages.dart';
import '../../services/sync/sync_providers.dart';
import '../../services/sync/sync_service.dart';

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

/// Sincroniza fila + pull remoto e atualiza providers da fila.
Future<SyncRunResult> runFullSync(ProviderContainer container) async {
  final sync = container.read(syncServiceProvider);
  final result = await sync.processQueue();
  await sync.pullRemoteChanges();
  container.invalidate(syncQueueSummaryProvider);
  container.invalidate(pendingSyncCountProvider);
  return result;
}
