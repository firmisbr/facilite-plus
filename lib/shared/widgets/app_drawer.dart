import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/theme_mode_provider.dart';
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
    final brightness = Theme.of(context).brightness;

    return Drawer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              MediaQuery.paddingOf(context).top + AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            decoration: BoxDecoration(
              gradient: AppDecorations.drawerHeader(brightness),
            ),
            child: const BrandLogo(size: BrandLogoSize.small),
          ),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              'MENU',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          _DrawerNavItem(
            icon: Icons.dashboard_outlined,
            label: 'Dashboard',
            selected: location == AppRoutes.dashboard,
            onTap: () => _go(context, AppRoutes.dashboard),
          ),
          _DrawerNavItem(
            icon: Icons.people_outline,
            label: 'Clientes',
            selected: location == AppRoutes.clients,
            onTap: () => _go(context, AppRoutes.clients),
          ),
          _DrawerNavItem(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Empréstimos',
            selected: location == AppRoutes.loans,
            onTap: () => _go(context, AppRoutes.loans),
          ),
          _DrawerNavItem(
            icon: Icons.payments_outlined,
            label: 'Pagamentos',
            selected: location == AppRoutes.payments,
            onTap: () => _go(context, AppRoutes.payments),
          ),
          const Spacer(),
          const Divider(height: 1, indent: AppSpacing.lg, endIndent: AppSpacing.lg),
          syncSummary.when(
            data: (summary) {
              if (summary.total <= 0) return const SizedBox.shrink();
              final color =
                  summary.hasFailures ? AppColors.error : AppColors.accent;
              return Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(color: color.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        summary.hasFailures
                            ? Icons.cloud_off_outlined
                            : Icons.cloud_upload_outlined,
                        size: 18,
                        color: color,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          summary.hasFailures
                              ? summary.hasPending
                                  ? '${summary.pending} pendente(s), ${summary.failed} erro(s)'
                                  : '${summary.failed} erro(s) de sync'
                              : '${summary.pending} aguardando envio',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: color),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
          _DrawerActionItem(
            icon: Icons.sync_rounded,
            label: 'Sincronizar agora',
            onTap: () async {
              final container = ProviderScope.containerOf(context);
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              final result = await runFullSync(container);
              showSyncSnackBarWithMessenger(messenger, result);
            },
          ),
          Consumer(
            builder: (context, ref, _) {
              final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
              return _DrawerActionItem(
                icon: isDark
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
                label: isDark ? 'Tema claro' : 'Tema escuro',
                onTap: () {
                  Navigator.pop(context);
                  ref.read(themeModeProvider.notifier).toggle();
                },
              );
            },
          ),
          _DrawerActionItem(
            icon: Icons.logout_rounded,
            label: 'Sair',
            onTap: () {
              Navigator.pop(context);
              ref.read(authControllerProvider.notifier).signOut();
            },
          ),
          SizedBox(height: MediaQuery.paddingOf(context).bottom + AppSpacing.sm),
        ],
      ),
    );
  }

  void _go(BuildContext context, String route) {
    Navigator.pop(context);
    context.go(route);
  }
}

class _DrawerNavItem extends StatelessWidget {
  const _DrawerNavItem({
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

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.accent.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: selected
                  ? Border.all(
                      color: AppColors.accent.withValues(alpha: 0.25),
                    )
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: selected ? AppColors.accent : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w500,
                          color: selected ? AppColors.accent : scheme.onSurface,
                        ),
                  ),
                ),
                if (selected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DrawerActionItem extends StatelessWidget {
  const _DrawerActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant),
      title: Text(label),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      onTap: onTap,
    );
  }
}
