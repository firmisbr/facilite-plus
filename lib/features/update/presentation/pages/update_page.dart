import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_version_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/app_update_info.dart';
import '../providers/update_providers.dart';

class UpdatePage extends ConsumerWidget {
  const UpdatePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkAsync = ref.watch(updateCheckProvider);
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Atualizações'),
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppDecorations.screenBackground(brightness),
        ),
        child: SafeArea(
          child: checkAsync.when(
            data: (result) => _UpdateBody(result: result),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _UpdateErrorState(
              onRetry: () => ref.invalidate(updateCheckProvider),
            ),
          ),
        ),
      ),
    );
  }
}

class _UpdateErrorState extends StatelessWidget {
  const _UpdateErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.wifi_off,
                size: 40,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Não foi possível verificar',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Confira sua internet e tente de novo.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.appTheme.textSecondary,
                  ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(LucideIcons.refresh_cw),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpdateBody extends ConsumerWidget {
  const _UpdateBody({required this.result});

  final UpdateCheckResult result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final download = ref.watch(downloadNotifierProvider);
    final notifier = ref.read(downloadNotifierProvider.notifier);
    final installedVersion = ref.watch(appVersionProvider).valueOrNull ??
        result.currentVersion ??
        '—';

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      children: [
        _UpdateHeroBanner(
          result: result,
          installedVersion: installedVersion,
        ),
        if (result.info != null) ...[
          const SizedBox(height: AppSpacing.lg),
          _ReleaseNotesCard(
            changelog: result.info!.changelog,
            hasUpdate: result.hasUpdate,
            versionLabel: result.hasUpdate
                ? result.info!.version
                : installedVersion,
          ),
        ],
        if (result.hasUpdate && result.info != null) ...[
          const SizedBox(height: AppSpacing.lg),
          _DownloadPanel(
            download: download,
            onStart: () => notifier.downloadAndInstall(result.info!.apkUrl),
            onRetry: () {
              notifier.reset();
              notifier.downloadAndInstall(result.info!.apkUrl);
            },
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        _UpToDateFooter(
          onRefresh: () => ref.invalidate(updateCheckProvider),
        ),
      ],
    );
  }
}

class _UpdateHeroBanner extends StatelessWidget {
  const _UpdateHeroBanner({
    required this.result,
    required this.installedVersion,
  });

  final UpdateCheckResult result;
  final String installedVersion;

  @override
  Widget build(BuildContext context) {
    final hasUpdate = result.hasUpdate;
    final accent = hasUpdate ? AppColors.warning : AppColors.success;
    final available = result.info?.version;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.2),
            AppColors.accent.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
        boxShadow: context.appTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
                child: Icon(
                  hasUpdate ? LucideIcons.rocket : LucideIcons.sparkles,
                  color: accent,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  hasUpdate
                      ? result.status == UpdateStatus.required
                          ? 'Atualização obrigatória'
                          : 'Nova versão no ar'
                      : 'Tudo em dia',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _VersionPill(
                  label: 'Instalada',
                  version: installedVersion,
                  icon: LucideIcons.smartphone,
                  color: context.appTheme.textSecondary,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Icon(
                  hasUpdate ? LucideIcons.arrow_right : LucideIcons.check,
                  size: 20,
                  color: accent,
                ),
              ),
              Expanded(
                child: _VersionPill(
                  label: hasUpdate ? 'Disponível' : 'Servidor',
                  version: hasUpdate ? (available ?? '—') : installedVersion,
                  icon: hasUpdate
                      ? LucideIcons.cloud_download
                      : LucideIcons.circle_check,
                  color: accent,
                  highlighted: hasUpdate,
                ),
              ),
            ],
          ),
          if (hasUpdate) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'Baixe a nova versão para receber correções e novidades.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.appTheme.textSecondary,
                    height: 1.35,
                  ),
            ),
          ] else ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'Você já está com a versão mais recente publicada.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.appTheme.textSecondary,
                    height: 1.35,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _VersionPill extends StatelessWidget {
  const _VersionPill({
    required this.label,
    required this.version,
    required this.icon,
    required this.color,
    this.highlighted = false,
  });

  final String label;
  final String version;
  final IconData icon;
  final Color color;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: highlighted
              ? color.withValues(alpha: 0.45)
              : context.appTheme.border,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: context.appTheme.textSecondary,
                  fontSize: 10,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            'v$version',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: highlighted ? color : null,
                ),
          ),
        ],
      ),
    );
  }
}

List<String> _parseChangelogLines(String? raw) {
  final text = raw?.trim();
  if (text == null || text.isEmpty) return const [];
  return text
      .split(RegExp(r'\r?\n'))
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .map((l) => l.replaceFirst(RegExp(r'^[-•*]\s*'), ''))
      .toList();
}

class _ReleaseNotesCard extends StatelessWidget {
  const _ReleaseNotesCard({
    required this.changelog,
    required this.hasUpdate,
    required this.versionLabel,
  });

  final String? changelog;
  final bool hasUpdate;
  final String versionLabel;

  @override
  Widget build(BuildContext context) {
    final lines = _parseChangelogLines(changelog);
    final accent = hasUpdate ? AppColors.warning : AppColors.success;
    final title = hasUpdate ? 'Na próxima versão' : 'Nesta versão';
    final subtitle = hasUpdate
        ? 'Novidades da v$versionLabel disponível para instalar'
        : 'O que há de novo na v$versionLabel que você já usa';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
        boxShadow: context.appTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accent.withValues(alpha: 0.12),
                  AppColors.premium.withValues(alpha: 0.06),
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppSpacing.radiusXl),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.15),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Text(
                        'v$versionLabel',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: accent,
                            ),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      hasUpdate ? LucideIcons.rocket : LucideIcons.sparkles,
                      size: 20,
                      color: accent,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
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
          if (lines.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Text(
                'Nenhuma nota de versão foi publicada para esta release.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.appTheme.textSecondary,
                      height: 1.4,
                    ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Column(
                children: [
                  for (var i = 0; i < lines.length; i++) ...[
                    if (i > 0)
                      Divider(
                        height: AppSpacing.lg,
                        color: context.appTheme.border.withValues(alpha: 0.6),
                      ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            hasUpdate
                                ? LucideIcons.arrow_right
                                : LucideIcons.circle_check,
                            size: 14,
                            color: hasUpdate ? accent : AppColors.success,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            lines[i],
                            style:
                                Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      height: 1.45,
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DownloadPanel extends StatelessWidget {
  const _DownloadPanel({
    required this.download,
    required this.onStart,
    required this.onRetry,
  });

  final DownloadState download;
  final VoidCallback onStart;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.25)),
        boxShadow: context.appTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Instalação',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'O download usa a internet do aparelho. Mantenha o app aberto até '
            'concluir — se sair ou fechar o app, será preciso baixar de novo.',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: context.appTheme.textSecondary,
                  height: 1.35,
                ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _DownloadActions(
            download: download,
            onStart: onStart,
            onRetry: onRetry,
          ),
        ],
      ),
    );
  }
}

class _DownloadActions extends StatelessWidget {
  const _DownloadActions({
    required this.download,
    required this.onStart,
    required this.onRetry,
  });

  final DownloadState download;
  final VoidCallback onStart;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return switch (download.phase) {
      DownloadPhase.idle => SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onStart,
            icon: const Icon(LucideIcons.download),
            label: const Text('Baixar e instalar'),
          ),
        ),
      DownloadPhase.downloading => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Baixando… ${(download.progress * 100).toStringAsFixed(0)}%',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: LinearProgressIndicator(
                value: download.progress,
                minHeight: 10,
                backgroundColor: AppColors.accent.withValues(alpha: 0.12),
                valueColor: const AlwaysStoppedAnimation(AppColors.accent),
              ),
            ),
          ],
        ),
      DownloadPhase.installing => Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: AppSpacing.sm),
              Text('Abrindo instalador do Android…'),
            ],
          ),
        ),
      DownloadPhase.error => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
              child: Text(
                download.errorMessage ?? 'Falha desconhecida',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.error,
                      height: 1.35,
                    ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(LucideIcons.refresh_cw),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
    };
  }
}

class _UpToDateFooter extends StatelessWidget {
  const _UpToDateFooter({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: OutlinedButton.icon(
        onPressed: onRefresh,
        icon: const Icon(LucideIcons.refresh_cw, size: 16),
        label: const Text('Verificar novamente'),
      ),
    );
  }
}
