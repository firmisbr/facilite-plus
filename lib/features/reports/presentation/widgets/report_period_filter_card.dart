import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_date_picker.dart';
import '../../../../shared/widgets/floating_notched_nav_bar.dart';
import '../../domain/report_period.dart';
import '../providers/reports_providers.dart';

/// Filtro de período recolhível, com abas e datas personalizadas.
class ReportPeriodFilterCard extends ConsumerStatefulWidget {
  const ReportPeriodFilterCard({super.key});

  @override
  ConsumerState<ReportPeriodFilterCard> createState() =>
      _ReportPeriodFilterCardState();
}

class _ReportPeriodFilterCardState extends ConsumerState<ReportPeriodFilterCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final selection = ref.watch(reportPeriodSelectionProvider);
    final range = ref.watch(reportPeriodRangeProvider);
    final activeGroup = selection.effectiveGroup;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: context.appTheme.border),
        boxShadow: context.appTheme.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.calendar_range,
                      size: 20,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Período do relatório',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            range.rangeCaption,
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.accent,
                                ),
                          ),
                          Text(
                            range.label,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: context.appTheme.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      _expanded
                          ? LucideIcons.chevron_up
                          : LucideIcons.chevron_down,
                      color: context.appTheme.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: AppSpacing.lg),
                  SegmentedButton<ReportPeriodGroup>(
                    segments: ReportPeriodGroup.values
                        .map(
                          (g) => ButtonSegment(
                            value: g,
                            label: Text(
                              g.label,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        )
                        .toList(),
                    selected: {activeGroup},
                    onSelectionChanged: (selected) {
                      final group = selected.first;
                      final presets = ReportPeriodPreset.forGroup(group);
                      final presetInGroup = presets.contains(selection.preset)
                          ? selection.preset
                          : _defaultPresetFor(group);
                      ref
                          .read(reportPeriodSelectionProvider.notifier)
                          .state = ReportPeriodSelection(
                        preset: presetInGroup,
                        customStart: selection.customStart,
                        customEnd: selection.customEnd,
                        uiGroup: group,
                      );
                    },
                    style: ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: ReportPeriodPreset.forGroup(activeGroup)
                        .where((p) => p != ReportPeriodPreset.custom)
                        .map(
                          (preset) => _PeriodChip(
                            label: preset.label,
                            selected: selection.preset == preset,
                            onTap: () {
                              ref
                                  .read(
                                    reportPeriodSelectionProvider.notifier,
                                  )
                                  .state = ReportPeriodSelection(
                                preset: preset,
                                uiGroup: activeGroup,
                              );
                              setState(() => _expanded = false);
                            },
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton.icon(
                    onPressed: () => _openCustomRange(context, selection, range),
                    icon: Icon(
                      LucideIcons.calendar_days,
                      size: 18,
                      color: selection.preset == ReportPeriodPreset.custom
                          ? AppColors.accent
                          : context.appTheme.textSecondary,
                    ),
                    label: const Text('Personalizar datas'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          selection.preset == ReportPeriodPreset.custom
                              ? AppColors.accent
                              : null,
                      side: BorderSide(
                        color: selection.preset == ReportPeriodPreset.custom
                            ? AppColors.accent.withValues(alpha: 0.55)
                            : context.appTheme.border,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
            sizeCurve: Curves.easeOutCubic,
          ),
        ],
      ),
    );
  }

  Future<void> _openCustomRange(
    BuildContext context,
    ReportPeriodSelection selection,
    ReportPeriodRange currentRange,
  ) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = selection.customStart ?? currentRange.start;
    final end = selection.customEnd ?? currentRange.end;

    if (!mounted) return;

    final result = await showModalBottomSheet<(DateTime, DateTime)?>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (sheetContext) {
        final viewInsets = MediaQuery.viewInsetsOf(sheetContext).bottom;
        return Padding(
          padding: EdgeInsets.only(
            bottom: viewInsets + kBottomNavReservedHeight,
          ),
          child: _CustomRangeSheet(
            initialStart: start,
            initialEnd: end,
            lastDate: today,
          ),
        );
      },
    );

    if (result == null || !mounted) return;

    ref.read(reportPeriodSelectionProvider.notifier).state = ReportPeriodSelection(
      preset: ReportPeriodPreset.custom,
      customStart: result.$1,
      customEnd: result.$2,
      uiGroup: ReportPeriodGroup.extended,
    );
    setState(() => _expanded = false);
  }
}

ReportPeriodPreset _defaultPresetFor(ReportPeriodGroup group) =>
    switch (group) {
      ReportPeriodGroup.short => ReportPeriodPreset.today,
      ReportPeriodGroup.monthly => ReportPeriodPreset.thisMonth,
      ReportPeriodGroup.extended => ReportPeriodPreset.last30Days,
    };

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      selectedColor: AppColors.accent.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        color: selected ? AppColors.accent : null,
        fontSize: 13,
      ),
    );
  }
}

class _CustomRangeSheet extends StatefulWidget {
  const _CustomRangeSheet({
    required this.initialStart,
    required this.initialEnd,
    required this.lastDate,
  });

  final DateTime initialStart;
  final DateTime initialEnd;
  final DateTime lastDate;

  @override
  State<_CustomRangeSheet> createState() => _CustomRangeSheetState();
}

class _CustomRangeSheetState extends State<_CustomRangeSheet> {
  late DateTime _start;
  late DateTime _end;

  @override
  void initState() {
    super.initState();
    _start = widget.initialStart;
    _end = widget.initialEnd;
    if (_end.isBefore(_start)) _end = _start;
  }

  Future<void> _pickStart() async {
    final picked = await AppDatePicker.open(
      context,
      initialDate: _start,
      firstDate: DateTime(2000),
      lastDate: widget.lastDate,
      helpText: 'Data inicial',
    );
    if (picked != null) {
      setState(() {
        _start = DateTime(picked.year, picked.month, picked.day);
        if (_end.isBefore(_start)) _end = _start;
      });
    }
  }

  Future<void> _pickEnd() async {
    final picked = await AppDatePicker.open(
      context,
      initialDate: _end.isBefore(_start) ? _start : _end,
      firstDate: _start,
      lastDate: widget.lastDate,
      helpText: 'Data final',
    );
    if (picked != null) {
      setState(() {
        _end = DateTime(picked.year, picked.month, picked.day);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg + bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Intervalo personalizado',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _DateField(
            label: 'De',
            value: AppDatePicker.formatMedium(_start),
            onTap: _pickStart,
          ),
          const SizedBox(height: AppSpacing.md),
          _DateField(
            label: 'Até',
            value: AppDatePicker.formatMedium(_end),
            onTap: _pickEnd,
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: () => Navigator.pop(context, (_start, _end)),
            child: const Text('Aplicar período'),
          ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.appTheme.border.withValues(alpha: 0.25),
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md + 2,
          ),
          child: Row(
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              Icon(
                LucideIcons.calendar,
                size: 20,
                color: context.appTheme.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
