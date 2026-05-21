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

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;
    final pendingSync = ref.watch(pendingSyncCountProvider);

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
            _DrawerTile(
              icon: Icons.dashboard_outlined,
              label: 'Dashboard',
              selected: location == AppRoutes.dashboard,
              badge: 'Em breve',
              onTap: () {
                Navigator.pop(context);
                context.go(AppRoutes.dashboard);
              },
            ),
            const Spacer(),
            const Divider(height: 1),
            pendingSync.when(
              data: (n) => n > 0
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.sm,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.cloud_upload_outlined,
                            size: 18,
                            color: AppColors.accent,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            '$n item(ns) na fila de sync',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.accent),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
              loading: () => const SizedBox.shrink(),
              error: (e, _) => const SizedBox.shrink(),
            ),
            ListTile(
              leading: const Icon(Icons.sync_rounded),
              title: const Text('Sincronizar agora'),
              onTap: () async {
                Navigator.pop(context);
                final sync = ref.read(syncServiceProvider);
                await sync.processQueue();
                await sync.pullRemoteChanges();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sincronização concluída')),
                  );
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
    this.badge,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;

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
      trailing: badge != null
          ? Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: scheme.secondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Text(
                badge!,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            )
          : null,
      selected: selected,
      selectedTileColor: AppColors.accent.withValues(alpha: 0.1),
      onTap: onTap,
    );
  }
}
