import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_mode_provider.dart';
import '../../../../features/auth/presentation/providers/auth_controller.dart';
import '../../../../services/sync/sync_providers.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_page_header.dart';
import '../../../../shared/widgets/floating_notched_nav_bar.dart';
import '../../../../shared/widgets/app_page_scaffold.dart';
import '../../../../shared/widgets/sync_feedback.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncSummary = ref.watch(syncQueueSummaryProvider);
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;

    return AppPageScaffold(
      title: 'Configurações',
      body: ListView(
        padding: const EdgeInsets.only(bottom: kBottomNavReservedHeight + AppSpacing.lg),
        children: [
          const AppPageHeader(
            title: 'Ajustes do app',
            subtitle: 'Sincronização, aparência e conta.',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.people_outline,
                  title: 'Clientes',
                  subtitle: 'Lista, cadastro e edição',
                  onTap: () => context.push(AppRoutes.clients),
                ),
                const SizedBox(height: AppSpacing.md),
                syncSummary.when(
                  data: (summary) {
                    if (summary.total <= 0) return const SizedBox.shrink();
                    final color =
                        summary.hasFailures ? AppColors.error : AppColors.accent;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: AppCard(
                        accent: summary.hasFailures
                            ? AppCardAccent.error
                            : AppCardAccent.primary,
                        child: Row(
                          children: [
                            Icon(
                              summary.hasFailures
                                  ? Icons.cloud_off_outlined
                                  : Icons.cloud_upload_outlined,
                              color: color,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(
                                summary.hasFailures
                                    ? summary.hasPending
                                        ? '${summary.pending} pendente(s), ${summary.failed} com erro'
                                        : '${summary.failed} erro(s) na fila'
                                    : '${summary.pending} alteração(ões) aguardando envio',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: color,
                                    ),
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
                _SettingsTile(
                  icon: Icons.sync_rounded,
                  title: 'Sincronizar agora',
                  subtitle: 'Envia alterações locais para a nuvem',
                  onTap: () async {
                    final container = ProviderScope.containerOf(context);
                    final messenger = ScaffoldMessenger.of(context);
                    final result = await runFullSync(container);
                    ref.invalidate(syncQueueSummaryProvider);
                    if (context.mounted) {
                      showSyncSnackBarWithMessenger(messenger, result);
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                _SettingsTile(
                  icon: isDark
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                  title: isDark ? 'Tema claro' : 'Tema escuro',
                  subtitle: 'Alternar aparência do aplicativo',
                  onTap: () =>
                      ref.read(themeModeProvider.notifier).toggle(),
                ),
                const SizedBox(height: AppSpacing.md),
                _SettingsTile(
                  icon: Icons.logout_rounded,
                  title: 'Sair da conta',
                  subtitle: 'Encerrar sessão neste dispositivo',
                  iconColor: AppColors.error,
                  onTap: () =>
                      ref.read(authControllerProvider.notifier).signOut(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final accent = iconColor ?? AppColors.accent;

    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
