import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/whats_new_seen_store.dart';
import '../../domain/app_version_history_entry.dart';
import '../widgets/changelog_notes_card.dart';

const _devMessages = [
  'Se liga no que chegou! 🚀',
  'Novidade saindo do forno 🔥',
  'O dev não parou — confere o que mudou!',
  'Mais uma entrega fresquinha 📦',
  'Pode comemorar, tem coisa nova!',
];

Future<void> showWhatsNewDialog(
  BuildContext context,
  WidgetRef ref, {
  required String version,
  required AppVersionHistoryEntry entry,
}) async {
  final message = _devMessages[
      DateTime.now().millisecond % _devMessages.length];

  await showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Fechar',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 420),
    transitionBuilder: (context, anim, _, child) {
      final curved = CurvedAnimation(
        parent: anim,
        curve: Curves.easeOutBack,
      );
      return FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: ScaleTransition(scale: Tween(begin: 0.82, end: 1.0).animate(curved), child: child),
      );
    },
    pageBuilder: (ctx, anim1, anim2) => _WhatsNewDialogContent(
      version: version,
      entry: entry,
      devMessage: message,
    ),
  );

  await WhatsNewSeenStore.markSeen(version);
}

class _WhatsNewDialogContent extends StatelessWidget {
  const _WhatsNewDialogContent({
    required this.version,
    required this.entry,
    required this.devMessage,
  });

  final String version;
  final AppVersionHistoryEntry entry;
  final String devMessage;

  @override
  Widget build(BuildContext context) {
    final lines = parseChangelogLines(entry.changelog);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl + 4),
      ),
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xxl,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl + 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Header(version: version, devMessage: devMessage, isDark: isDark),
            _Body(lines: lines, isDark: isDark),
            _Footer(onClose: () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.version,
    required this.devMessage,
    required this.isDark,
  });

  final String version;
  final String devMessage;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
          colors: isDark
              ? [const Color(0xFF1F2E25), const Color(0xFF141513)]
              : [AppColors.accent.withValues(alpha: 0.12), Colors.white],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.6),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.3),
                      blurRadius: 18,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/dev.jpeg',
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => Container(
                      width: 80,
                      height: 80,
                      color: AppColors.accent.withValues(alpha: 0.15),
                      child: const Icon(
                        LucideIcons.user_round,
                        color: AppColors.accent,
                        size: 40,
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF141513)
                        : Colors.white,
                    width: 2,
                  ),
                ),
                child: const Icon(
                  LucideIcons.sparkles,
                  color: Colors.white,
                  size: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Bruno lançou uma nova versão',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            devMessage,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 3,
            ),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.35),
              ),
            ),
            child: Text(
              'v$version',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.lines, required this.isDark});

  final List<String> lines;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 280),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'O que há de novo',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: context.appTheme.textSecondary,
                    letterSpacing: 0.3,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...lines.map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 3),
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.check,
                        size: 11,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        line,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              height: 1.4,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: onClose,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
          ),
          child: const Text('Entendido, valeu! 🙌'),
        ),
      ),
    );
  }
}
