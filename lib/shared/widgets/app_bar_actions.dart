import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/providers/auth_controller.dart';
import '../../services/sync/sync_providers.dart';
import 'sync_feedback.dart';
import 'sync_status_chip.dart';

/// Ações padrão da AppBar: sync pendente, sincronizar, sair.
class AppBarActions extends ConsumerWidget {
  const AppBarActions({
    super.key,
    this.showSync = true,
    this.showLogout = true,
  });

  final bool showSync;
  final bool showLogout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncSummary = ref.watch(syncQueueSummaryProvider);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showSync) ...[
          syncSummary.when(
            data: (summary) => SyncStatusChip(summary: summary),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
          IconButton(
            icon: const Icon(Icons.sync_rounded),
            tooltip: 'Sincronizar',
            onPressed: () => _syncNow(context, ref),
          ),
        ],
        if (showLogout)
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sair',
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signOut(),
          ),
      ],
    );
  }

  Future<void> _syncNow(BuildContext context, WidgetRef ref) async {
    final sync = ref.read(syncServiceProvider);
    final queueResult = await sync.processQueue();
    await sync.pullRemoteChanges();
    ref.invalidate(syncQueueSummaryProvider);
    ref.invalidate(pendingSyncCountProvider);
    if (context.mounted) {
      showSyncSnackBar(context, queueResult);
    }
  }
}
