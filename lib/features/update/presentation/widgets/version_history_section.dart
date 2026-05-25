import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart'; // AppThemeContext
import '../../../../core/theme/app_spacing.dart';
import '../../domain/app_version_history_entry.dart';
import 'changelog_notes_card.dart';

class VersionHistorySection extends StatefulWidget {
  const VersionHistorySection({
    super.key,
    required this.entries,
    required this.installedVersion,
    this.availableVersion,
    this.featuredVersion,
  });

  final List<AppVersionHistoryEntry> entries;
  final String installedVersion;
  final String? availableVersion;

  /// Versão já exibida no card de destaque (changelog do topo).
  /// Entradas com este valor são omitidas do histórico para evitar duplicação.
  final String? featuredVersion;

  static HistoryEntryStatus entryStatus(
    String version, {
    required String installedVersion,
    String? availableVersion,
  }) {
    if (version == availableVersion && version != installedVersion) {
      return HistoryEntryStatus.available;
    }
    if (version == installedVersion) {
      return HistoryEntryStatus.installed;
    }
    return HistoryEntryStatus.past;
  }

  @override
  State<VersionHistorySection> createState() => _VersionHistorySectionState();
}

class _VersionHistorySectionState extends State<VersionHistorySection> {
  final Set<String> _expandedKeys = {};

  String _entryKey(AppVersionHistoryEntry entry) =>
      '${entry.version}+${entry.build}';

  void _toggle(AppVersionHistoryEntry entry) {
    final key = _entryKey(entry);
    setState(() {
      if (_expandedKeys.contains(key)) {
        _expandedKeys.remove(key);
      } else {
        _expandedKeys.add(key);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final visibleEntries = widget.featuredVersion != null
        ? widget.entries
            .where((e) => e.version != widget.featuredVersion)
            .toList()
        : widget.entries;

    if (visibleEntries.isEmpty) {
      return _EmptyHistoryHint();
    }

    final dateFormat = DateFormat('d \'de\' MMMM \'de\' yyyy', 'pt_BR');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              LucideIcons.history,
              size: 20,
              color: AppColors.accent,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Histórico de versões',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Toque em uma versão para ver o que mudou. Só a mais recente '
          'pode ser instalada pelo app.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.appTheme.textSecondary,
                height: 1.35,
              ),
        ),
        const SizedBox(height: AppSpacing.lg),
        for (var i = 0; i < visibleEntries.length; i++) ...[
          _HistoryTimelineRow(
            entry: visibleEntries[i],
            isFirst: i == 0,
            isLast: i == visibleEntries.length - 1,
            dateLabel: dateFormat.format(visibleEntries[i].releasedAt.toLocal()),
            status: VersionHistorySection.entryStatus(
              visibleEntries[i].version,
              installedVersion: widget.installedVersion,
              availableVersion: widget.availableVersion,
            ),
            expanded: _expandedKeys.contains(_entryKey(visibleEntries[i])),
            onToggle: () => _toggle(visibleEntries[i]),
          ),
        ],
      ],
    );
  }
}

enum HistoryEntryStatus { installed, available, past }

class _HistoryTimelineRow extends StatelessWidget {
  const _HistoryTimelineRow({
    required this.entry,
    required this.isFirst,
    required this.isLast,
    required this.dateLabel,
    required this.status,
    required this.expanded,
    required this.onToggle,
  });

  final AppVersionHistoryEntry entry;
  final bool isFirst;
  final bool isLast;
  final String dateLabel;
  final HistoryEntryStatus status;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final accent = switch (status) {
      HistoryEntryStatus.installed => AppColors.success,
      HistoryEntryStatus.available => AppColors.warning,
      HistoryEntryStatus.past => context.appTheme.textSecondary,
    };

    final statusLabel = switch (status) {
      HistoryEntryStatus.installed => 'Instalada',
      HistoryEntryStatus.available => 'Disponível',
      HistoryEntryStatus.past => null,
    };

    final lineCount = parseChangelogLines(entry.changelog).length;
    final summaryLabel = lineCount == 0
        ? 'Sem notas publicadas'
        : lineCount == 1
            ? '1 novidade'
            : '$lineCount novidades';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 28,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isFirst)
                Container(
                  width: 2,
                  height: AppSpacing.md,
                  color: context.appTheme.border,
                ),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.surface,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.35),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: isLast ? 0 : AppSpacing.md,
            ),
            child: Material(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onToggle,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: expanded
                            ? accent.withValues(alpha: 0.35)
                            : context.appTheme.border,
                      ),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusLg),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md,
                            AppSpacing.md,
                            AppSpacing.sm,
                            AppSpacing.md,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding:
                                              const EdgeInsets.symmetric(
                                            horizontal: AppSpacing.sm,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: accent.withValues(
                                              alpha: 0.15,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              AppSpacing.radiusMd,
                                            ),
                                            border: Border.all(
                                              color: accent.withValues(
                                                alpha: 0.35,
                                              ),
                                            ),
                                          ),
                                          child: Text(
                                            'v${entry.version}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w800,
                                                  color: accent,
                                                ),
                                          ),
                                        ),
                                        if (statusLabel != null) ...[
                                          const SizedBox(
                                            width: AppSpacing.sm,
                                          ),
                                          Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                              horizontal: AppSpacing.sm,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: accent.withValues(
                                                alpha: 0.12,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                AppSpacing.radiusMd,
                                              ),
                                              border: Border.all(
                                                color: accent.withValues(
                                                  alpha: 0.35,
                                                ),
                                              ),
                                            ),
                                            child: Text(
                                              statusLabel,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelSmall
                                                  ?.copyWith(
                                                    fontWeight:
                                                        FontWeight.w700,
                                                    color: accent,
                                                    fontSize: 10,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      dateLabel,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: context
                                                .appTheme.textSecondary,
                                          ),
                                    ),
                                    if (!expanded) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        summaryLabel,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: context
                                                  .appTheme.textSecondary,
                                            ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Icon(
                                expanded
                                    ? LucideIcons.chevron_up
                                    : LucideIcons.chevron_down,
                                size: 20,
                                color: accent,
                              ),
                            ],
                          ),
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          alignment: Alignment.topCenter,
                          child: expanded
                              ? ChangelogNotesCard(
                                  versionLabel: entry.version,
                                  title: 'O que mudou',
                                  subtitle:
                                      'Notas da versão v${entry.version}',
                                  changelog: entry.changelog,
                                  accent: accent,
                                  compact: true,
                                  embedded: true,
                                  bulletIcon: LucideIcons.check,
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
  }
}

class _EmptyHistoryHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: context.appTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Histórico de versões',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'As próximas publicações aparecerão aqui com o changelog de cada '
            'versão.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.appTheme.textSecondary,
                  height: 1.4,
                ),
          ),
        ],
      ),
    );
  }
}
