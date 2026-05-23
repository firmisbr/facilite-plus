import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.wifi_off, size: 48, color: AppColors.error),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Não foi possível verificar atualizações.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Verifique sua conexão com a internet.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton.icon(
                      onPressed: () => ref.invalidate(updateCheckProvider),
                      icon: const Icon(LucideIcons.refresh_cw),
                      label: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
            ),
          ),
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

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _VersionStatusCard(result: result),
        if (result.hasUpdate && result.info != null) ...[
          const SizedBox(height: AppSpacing.lg),
          _ChangelogCard(info: result.info!),
          const SizedBox(height: AppSpacing.lg),
          _DownloadSection(
            download: download,
            apkUrl: result.info!.apkUrl,
            onStart: () => notifier.downloadAndInstall(result.info!.apkUrl),
            onRetry: () {
              notifier.reset();
              notifier.downloadAndInstall(result.info!.apkUrl);
            },
          ),
        ],
        if (!result.hasUpdate) ...[
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: TextButton.icon(
              onPressed: () => ref.invalidate(updateCheckProvider),
              icon: const Icon(LucideIcons.refresh_cw, size: 16),
              label: const Text('Verificar novamente'),
            ),
          ),
        ],
      ],
    );
  }
}

class _VersionStatusCard extends StatelessWidget {
  const _VersionStatusCard({required this.result});

  final UpdateCheckResult result;

  @override
  Widget build(BuildContext context) {
    final hasUpdate = result.hasUpdate;
    final color = hasUpdate ? AppColors.warning : AppColors.success;
    final icon = hasUpdate ? LucideIcons.cloud_download : LucideIcons.circle_check;
    final title = hasUpdate
        ? result.status == UpdateStatus.required
            ? 'Atualização obrigatória'
            : 'Nova versão disponível'
        : 'Você está atualizado';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Versão instalada: v${result.currentVersion ?? '—'}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (result.info != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Versão disponível: v${result.info!.version}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
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

class _ChangelogCard extends StatelessWidget {
  const _ChangelogCard({required this.info});

  final AppUpdateInfo info;

  @override
  Widget build(BuildContext context) {
    final changelog = info.changelog;
    if (changelog == null || changelog.trim().isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'O que há de novo',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            changelog,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _DownloadSection extends StatelessWidget {
  const _DownloadSection({
    required this.download,
    required this.apkUrl,
    required this.onStart,
    required this.onRetry,
  });

  final DownloadState download;
  final String apkUrl;
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
            Text(
              'Baixando… ${(download.progress * 100).toStringAsFixed(0)}%',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: LinearProgressIndicator(
                value: download.progress,
                minHeight: 8,
                backgroundColor: AppColors.accent.withValues(alpha: 0.15),
                valueColor: const AlwaysStoppedAnimation(AppColors.accent),
              ),
            ),
          ],
        ),
      DownloadPhase.installing => const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: AppSpacing.sm),
            Text('Abrindo instalador…'),
          ],
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
                'Erro: ${download.errorMessage ?? 'Falha desconhecida'}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.error,
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
