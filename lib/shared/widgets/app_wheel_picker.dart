import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Seletor em roda estilo iOS (Cupertino), com rótulo e valor no topo.
class AppWheelPicker<T> extends StatefulWidget {
  const AppWheelPicker({
    super.key,
    required this.label,
    required this.items,
    required this.itemLabel,
    required this.value,
    required this.onChanged,
    this.height = 200,
    this.itemExtent = 40,
  });

  final String label;
  final List<T> items;
  final String Function(T item) itemLabel;
  final T value;
  final ValueChanged<T> onChanged;
  final double height;
  final double itemExtent;

  @override
  State<AppWheelPicker<T>> createState() => _AppWheelPickerState<T>();
}

class _AppWheelPickerState<T> extends State<AppWheelPicker<T>> {
  late FixedExtentScrollController _controller;

  int get _selectedIndex {
    final i = widget.items.indexOf(widget.value);
    return i < 0 ? 0 : i;
  }

  @override
  void initState() {
    super.initState();
    _controller = FixedExtentScrollController(initialItem: _selectedIndex);
  }

  @override
  void didUpdateWidget(covariant AppWheelPicker<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final index = _selectedIndex;
    if (_controller.selectedItem != index) {
      _controller.animateToItem(
        index,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final divider = theme.dividerColor.withValues(alpha: 0.65);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Text(
                  widget.label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  widget.itemLabel(widget.value),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: divider),
          SizedBox(
            height: widget.height,
            child: Stack(
              alignment: Alignment.center,
              children: [
                IgnorePointer(
                  child: Container(
                    height: widget.itemExtent,
                    margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: divider, width: 0.8),
                        bottom: BorderSide(color: divider, width: 0.8),
                      ),
                    ),
                  ),
                ),
                CupertinoTheme(
                  data: CupertinoTheme.of(context).copyWith(
                    brightness: theme.brightness,
                    textTheme: CupertinoTextThemeData(
                      pickerTextStyle: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: onSurface,
                          ),
                    ),
                  ),
                  child: CupertinoPicker(
                    scrollController: _controller,
                    itemExtent: widget.itemExtent,
                    magnification: 1.12,
                    squeeze: 1.05,
                    useMagnifier: true,
                    onSelectedItemChanged: (index) {
                      widget.onChanged(widget.items[index]);
                    },
                    children: widget.items
                        .map(
                          (item) => Center(
                            child: Text(
                              widget.itemLabel(item),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
