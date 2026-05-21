import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/providers/auth_controller.dart';
import '../../services/sync/sync_providers.dart';
import 'sync_status_chip.dart';
import 'theme_toggle_button.dart';

/// Ações padrão da AppBar: tema, sync pendente, sincronizar, sair.
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
    final pendingSync = ref.watch(pendingSyncCountProvider);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const ThemeToggleButton(),
        if (showSync) ...[
          pendingSync.when(
            data: (n) => SyncStatusChip(pendingCount: n),
            loading: () => const SizedBox.shrink(),
            error: (e, _) => const SizedBox.shrink(),
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
    await sync.processQueue();
    await sync.pullRemoteChanges();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sincronização concluída')),
      );
    }
  }
}
