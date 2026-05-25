import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../../core/theme/app_colors.dart'; // AppThemeContext
import '../../../../core/theme/app_spacing.dart';

List<String> parseChangelogLines(String? raw) {
  final text = raw?.trim();
  if (text == null || text.isEmpty) return const [];
  return text
      .split(RegExp(r'\r?\n'))
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .map((l) => l.replaceFirst(RegExp(r'^[-•*]\s*'), ''))
      .toList();
}

/// Card de notas de versão reutilizado na tela de atualizações e no histórico.
class ChangelogNotesCard extends StatelessWidget {
  const ChangelogNotesCard({
    super.key,
    required this.versionLabel,
    required this.title,
    required this.subtitle,
    required this.changelog,
    required this.accent,
    this.compact = false,
    this.embedded = false,
    this.leadingIcon = LucideIcons.sparkles,
    this.bulletIcon = LucideIcons.circle_check,
  });

  final String versionLabel;
  final String title;
  final String subtitle;
  final String? changelog;
  final Color accent;
  final bool compact;

  /// Corpo do changelog sem card/header (ex.: histórico expandido).
  final bool embedded;
  final IconData leadingIcon;
  final IconData bulletIcon;

  @override
  Widget build(BuildContext context) {
    final lines = parseChangelogLines(changelog);
    final radius = compact ? AppSpacing.radiusLg : AppSpacing.radiusXl;
    final headerPad = compact
        ? const EdgeInsets.all(AppSpacing.md)
        : const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.md,
          );
    final bodyPad = compact
        ? const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.md,
          )
        : const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          );

    final body = _ChangelogBody(
      lines: lines,
      accent: accent,
      compact: compact,
      bulletIcon: bulletIcon,
      emptyMessage: embedded
          ? 'Nenhuma nota foi publicada para esta versão.'
          : 'Nenhuma nota foi publicada para esta versão.',
    );

    if (embedded) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Divider(
              height: 1,
              color: accent.withValues(alpha: 0.2),
            ),
            const SizedBox(height: AppSpacing.sm),
            body,
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
        boxShadow: context.appTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: headerPad,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accent.withValues(alpha: 0.12),
                  AppColors.premium.withValues(alpha: 0.06),
                ],
              ),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(radius),
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
                    Icon(leadingIcon, size: 20, color: accent),
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
          Padding(padding: bodyPad, child: body),
        ],
      ),
    );
  }
}

class _ChangelogBody extends StatelessWidget {
  const _ChangelogBody({
    required this.lines,
    required this.accent,
    required this.compact,
    required this.bulletIcon,
    required this.emptyMessage,
  });

  final List<String> lines;
  final Color accent;
  final bool compact;
  final IconData bulletIcon;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (lines.isEmpty) {
      return Text(
        emptyMessage,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.appTheme.textSecondary,
              height: 1.4,
            ),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < lines.length; i++) ...[
          if (i > 0)
            Divider(
              height: compact ? AppSpacing.md : AppSpacing.lg,
              color: context.appTheme.border.withValues(alpha: 0.6),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  bulletIcon,
                  size: 14,
                  color: accent,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  lines[i],
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.45,
                        fontSize: compact ? 13 : null,
                      ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
