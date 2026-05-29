import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

/// Abre um dialog com seletor em roda estilo iOS.
class AppWheelPickerDialog {
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required List<T> items,
    required String Function(T item) itemLabel,
    required T initialValue,
  }) async {
    T? selected = initialValue;

    final result = await showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _WheelPickerSheet<T>(
        title: title,
        items: items,
        itemLabel: itemLabel,
        initialValue: initialValue,
        onChanged: (value) => selected = value,
      ),
    );

    return result ?? selected;
  }
}

class _WheelPickerSheet<T> extends StatefulWidget {
  const _WheelPickerSheet({
    required this.title,
    required this.items,
    required this.itemLabel,
    required this.initialValue,
    required this.onChanged,
  });

  final String title;
  final List<T> items;
  final String Function(T item) itemLabel;
  final T initialValue;
  final ValueChanged<T> onChanged;

  @override
  State<_WheelPickerSheet<T>> createState() => _WheelPickerSheetState<T>();
}

class _WheelPickerSheetState<T> extends State<_WheelPickerSheet<T>> {
  late FixedExtentScrollController _controller;
  late T _current;

  // ignore: unused_element
  int get _selectedIndex {
    final i = widget.items.indexOf(_current);
    return i < 0 ? 0 : i;
  }

  @override
  void initState() {
    super.initState();
    _current = widget.initialValue;
    _controller = FixedExtentScrollController(
      initialItem: widget.items.indexOf(_current),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final divider = theme.dividerColor.withValues(alpha: 0.6);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, _current),
                    child: const Text('Confirmar'),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: divider),
            SizedBox(
              height: 240,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  IgnorePointer(
                    child: Container(
                      height: 44,
                      margin: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
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
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    child: CupertinoPicker(
                      scrollController: _controller,
                      itemExtent: 44,
                      magnification: 1.15,
                      squeeze: 1.05,
                      useMagnifier: true,
                      onSelectedItemChanged: (index) {
                        setState(() => _current = widget.items[index]);
                        widget.onChanged(_current);
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
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}
