import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../core/theme/theme_mode_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../features/auth/presentation/providers/auth_controller.dart';
import '../../services/sync/sync_providers.dart';
import 'brand_logo.dart';
import 'sync_feedback.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;
    final syncSummary = ref.watch(syncQueueSummaryProvider);

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: const BrandLogo(size: BrandLogoSize.small),
            ),
            const Divider(height: 1),
            _DrawerTile(
              icon: Icons.dashboard_outlined,
              label: 'Dashboard',
              selected: location == AppRoutes.dashboard,
              onTap: () {
                Navigator.pop(context);
                context.go(AppRoutes.dashboard);
              },
            ),
            _DrawerTile(
              icon: Icons.people_outline,
              label: 'Clientes',
              selected: location == AppRoutes.clients,
              onTap: () {
                Navigator.pop(context);
                context.go(AppRoutes.clients);
              },
            ),
            _DrawerTile(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Empréstimos',
              selected: location == AppRoutes.loans,
              onTap: () {
                Navigator.pop(context);
                context.go(AppRoutes.loans);
              },
            ),
            const Spacer(),
            const Divider(height: 1),
            syncSummary.when(
              data: (summary) {
                if (summary.total <= 0) return const SizedBox.shrink();
                final color =
                    summary.hasFailures ? AppColors.error : AppColors.accent;
                final icon = summary.hasFailures
                    ? Icons.cloud_off_outlined
                    : Icons.cloud_upload_outlined;
                final label = summary.hasFailures
                    ? summary.hasPending
                        ? '${summary.pending} pendente(s), ${summary.failed} com erro'
                        : '${summary.failed} alteração(ões) com erro de sync'
                    : '${summary.pending} aguardando envio';
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Icon(icon, size: 18, color: color),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          label,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: color),
                        ),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
            ListTile(
              leading: const Icon(Icons.sync_rounded),
              title: const Text('Sincronizar agora'),
              onTap: () async {
                Navigator.pop(context);
                final sync = ref.read(syncServiceProvider);
                final result = await sync.processQueue();
                await sync.pullRemoteChanges();
                ref.invalidate(syncQueueSummaryProvider);
                ref.invalidate(pendingSyncCountProvider);
                if (context.mounted) {
                  showSyncSnackBar(context, result);
                }
              },
            ),
            Consumer(
              builder: (context, ref, _) {
                final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
                return ListTile(
                  leading: Icon(
                    isDark
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                  ),
                  title: Text(isDark ? 'Tema claro' : 'Tema escuro'),
                  onTap: () {
                    Navigator.pop(context);
                    ref.read(themeModeProvider.notifier).toggle();
                  },
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout_rounded),
              title: const Text('Sair'),
              onTap: () {
                Navigator.pop(context);
                ref.read(authControllerProvider.notifier).signOut();
              },
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: Icon(
        icon,
        color: selected ? AppColors.accent : scheme.onSurfaceVariant,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          color: selected ? AppColors.accent : scheme.onSurface,
        ),
      ),
      selected: selected,
      selectedTileColor: AppColors.accent.withValues(alpha: 0.1),
      onTap: onTap,
    );
  }
}
