import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_version.dart';
import '../../../../core/config/app_version_provider.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_mode_provider.dart';
import '../../../../features/auth/presentation/providers/auth_controller.dart';
import '../../../../features/support/presentation/providers/support_providers.dart';
import '../../../../features/update/presentation/providers/update_providers.dart';
import '../../../../services/supabase/supabase_providers.dart';
import '../../../../services/sync/sync_providers.dart';
import '../../../../services/sync/sync_queue_summary.dart';
import '../../../../shared/widgets/floating_notched_nav_bar.dart';
import '../../../../shared/widgets/sync_feedback.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncSummary = ref.watch(syncQueueSummaryProvider);
    final session = ref.watch(sessionProvider).valueOrNull;
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    final brightness = Theme.of(context).brightness;
    final hasUpdate = ref.watch(hasUpdateBadgeProvider);
    final hasSupportUpdate = ref.watch(hasSupportAttentionBadgeProvider);

    return Scaffold(
      extendBody: true,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppDecorations.screenBackground(brightness),
        ),
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: () async {
              final container = ProviderScope.containerOf(context);
              final result = await runFullSync(container);
              if (context.mounted) {
                showSyncSnackBar(context, result);
              }
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppSpacing.maxContentWidth,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.md,
                        AppSpacing.lg,
                        AppSpacing.sm,
                      ),
                      child: _SettingsAccountCard(
                        email: session?.user.email ?? 'Conta ativa',
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppSpacing.maxContentWidth,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.lg,
                        AppSpacing.lg,
                        AppSpacing.sm,
                      ),
                      child: const _SettingsSectionLabel(title: 'Dados'),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppSpacing.maxContentWidth,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      child: Column(
                        children: [
                          _SettingsActionTile(
                            icon: LucideIcons.bell,
                            title: 'Notificações',
                            subtitle:
                                'Horário e lembretes de parcelas a vencer',
                            onTap: () =>
                                context.push(AppRoutes.notifications),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _SettingsActionTile(
                            icon: LucideIcons.chart_column,
                            title: 'Relatórios',
                            subtitle:
                                'Resumo, inadimplência, previsão e exportar CSV',
                            onTap: () => context.push(AppRoutes.reports),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _SettingsActionTile(
                            icon: LucideIcons.users,
                            title: 'Clientes',
                            subtitle: 'Cadastro, edição e histórico',
                            onTap: () => context.push(AppRoutes.clients),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _SettingsActionTile(
                            icon: LucideIcons.hard_drive,
                            title: 'Backup',
                            subtitle:
                                'Exportar com PIN ou importar em outra conta',
                            onTap: () => context.push(AppRoutes.backup),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _SettingsActionTile(
                            icon: LucideIcons.cloud_download,
                            title: 'Atualizações',
                            subtitle: 'Verificar e instalar novas versões',
                            onTap: () => context.push(AppRoutes.updates),
                            badge: hasUpdate,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _SettingsActionTile(
                            icon: LucideIcons.life_buoy,
                            title: 'Suporte',
                            subtitle:
                                'Bugs, sugestões e chamados com a equipe',
                            onTap: () => context.push(AppRoutes.support),
                            badge: hasSupportUpdate,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppSpacing.maxContentWidth,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.lg,
                        AppSpacing.lg,
                        AppSpacing.sm,
                      ),
                      child: const _SettingsSectionLabel(title: 'Nuvem'),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppSpacing.maxContentWidth,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      child: Column(
                        children: [
                          const _SettingsCloudHintCard(),
                          const SizedBox(height: AppSpacing.sm),
                          syncSummary.when(
                            data: (summary) => _SyncStatusCard(
                              summary: summary,
                            ),
                            loading: () => const _SettingsSurfaceCard(
                              child: Center(
                                child: Padding(
                                  padding: EdgeInsets.all(AppSpacing.lg),
                                  child: SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            error: (_, _) => const SizedBox.shrink(),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _SettingsActionTile(
                            icon: LucideIcons.refresh_cw,
                            title: 'Sincronizar agora',
                            subtitle:
                                'Força envio e download agora (também é automático)',
                            onTap: () async {
                              final container =
                                  ProviderScope.containerOf(context);
                              final messenger =
                                  ScaffoldMessenger.of(context);
                              final result = await runFullSync(container);
                              if (context.mounted) {
                                showSyncSnackBarWithMessenger(
                                  messenger,
                                  result,
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppSpacing.maxContentWidth,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.lg,
                        AppSpacing.lg,
                        AppSpacing.sm,
                      ),
                      child: const _SettingsSectionLabel(title: 'Aparência'),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppSpacing.maxContentWidth,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      child: _SettingsActionTile(
                        icon: isDark
                            ? LucideIcons.sun
                            : LucideIcons.moon,
                        title: isDark ? 'Tema claro' : 'Tema escuro',
                        subtitle: 'Alternar aparência do aplicativo',
                        onTap: () =>
                            ref.read(themeModeProvider.notifier).toggle(),
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppSpacing.maxContentWidth,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.lg,
                        AppSpacing.lg,
                        kBottomNavReservedHeight + AppSpacing.lg,
                      ),
                      child: _SettingsActionTile(
                        icon: LucideIcons.log_out,
                        title: 'Sair da conta',
                        subtitle: 'Encerrar sessão neste dispositivo',
                        iconColor: AppColors.error,
                        titleColor: AppColors.error,
                        onTap: () =>
                            ref.read(authControllerProvider.notifier).signOut(),
                      ),
                    ),
                  ),
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

class _SettingsAccountCard extends ConsumerWidget {
  const _SettingsAccountCard({required this.email});

  final String email;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final versionAsync = ref.watch(appVersionProvider);
    final versionLabel = versionAsync.when(
      data: (v) => 'v$v',
      loading: () => 'v${AppVersion.fallback}',
      error: (_, _) => 'v${AppVersion.fallback}',
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accent.withValues(alpha: 0.18),
            AppColors.accentSecondary.withValues(alpha: 0.12),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.35)),
        boxShadow: context.appTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Sua conta',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: context.appTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            email,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => context.push(AppRoutes.updates),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surface
                      .withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      LucideIcons.smartphone,
                      size: 14,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Versão instalada $versionLabel',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.accent,
                          ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      LucideIcons.chevron_right,
                      size: 14,
                      color: AppColors.accent.withValues(alpha: 0.85),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsCloudHintCard extends StatelessWidget {
  const _SettingsCloudHintCard();

  @override
  Widget build(BuildContext context) {
    return _SettingsSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            LucideIcons.cloud,
            size: 20,
            color: AppColors.info,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Com internet, o app sincroniza sozinho ao abrir e quando a rede '
              'volta. Na mesma conta, seus dados aparecem em qualquer celular. '
              'O backup é cópia extra em arquivo.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.appTheme.textSecondary,
                    height: 1.45,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SyncStatusCard extends StatelessWidget {
  const _SyncStatusCard({required this.summary});

  final SyncQueueSummary summary;

  @override
  Widget build(BuildContext context) {
    if (summary.total <= 0) {
      return _SettingsSurfaceCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: AppDecorations.iconBadge(color: AppColors.success),
              child: const Icon(
                LucideIcons.cloud_check,
                size: 20,
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'Tudo sincronizado com a nuvem',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
              ),
            ),
          ],
        ),
      );
    }

    final color = summary.hasFailures ? AppColors.error : AppColors.accent;
    final icon = summary.hasFailures
        ? LucideIcons.cloud_off
        : LucideIcons.cloud_upload;
    final message = summary.hasFailures
        ? summary.hasPending
            ? '${summary.pending} pendente(s), ${summary.failed} com erro'
            : '${summary.failed} erro(s) na fila'
        : '${summary.pending} alteração(ões) aguardando envio';

    return _SettingsSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: AppDecorations.iconBadge(color: color),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
            ),
          ),
          if (summary.hasPending && !summary.hasFailures)
            const Padding(
              padding: EdgeInsets.only(left: AppSpacing.xs),
              child: Icon(
                LucideIcons.refresh_cw,
                size: 18,
                color: AppColors.accent,
              ),
            ),
        ],
      ),
    );
  }
}

class _SettingsActionTile extends StatelessWidget {
  const _SettingsActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
    this.titleColor,
    this.badge = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? titleColor;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    final accent = iconColor ?? AppColors.accent;

    return _SettingsSurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: AppDecorations.iconBadge(color: accent),
            child: Icon(icon, size: 20, color: accent),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: titleColor,
                            ),
                      ),
                    ),
                    if (badge) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warning,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: const Text(
                          'Novo',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.appTheme.textSecondary,
                        height: 1.35,
                      ),
                ),
              ],
            ),
          ),
          Icon(
            LucideIcons.chevron_right,
            size: 20,
            color: context.appTheme.textSecondary,
          ),
        ],
      ),
    );
  }
}

class _SettingsSurfaceCard extends StatelessWidget {
  const _SettingsSurfaceCard({
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: context.appTheme.border),
        boxShadow: context.appTheme.cardShadow,
      ),
      child: child,
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        child: content,
      ),
    );
  }
}

class _SettingsSectionLabel extends StatelessWidget {
  const _SettingsSectionLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final lineColor = context.appTheme.border;
    final titleStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        );

    return Row(
      children: [
        Expanded(child: _DashedDividerLine(color: lineColor)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(title, style: titleStyle),
        ),
        Expanded(child: _DashedDividerLine(color: lineColor)),
      ],
    );
  }
}

class _DashedDividerLine extends StatelessWidget {
  const _DashedDividerLine({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          height: 20,
          width: constraints.maxWidth,
          child: Center(
            child: CustomPaint(
              size: Size(constraints.maxWidth, 1),
              painter: _DashedLinePainter(color: color),
            ),
          ),
        );
      },
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  _DashedLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    const dashWidth = 5.0;
    const dashSpace = 4.0;
    var x = 0.0;
    final y = size.height / 2;

    while (x < size.width) {
      final end = (x + dashWidth).clamp(0.0, size.width);
      canvas.drawLine(Offset(x, y), Offset(end, y), paint);
      x += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}
