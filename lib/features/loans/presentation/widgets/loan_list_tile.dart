import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/loan_with_client.dart';
import '../providers/loan_list_layout_provider.dart';
import 'loan_list_card.dart';
import 'loan_list_card_compact.dart';

/// Empréstimo na lista — layout estendido ou compacto.
class LoanListTile extends ConsumerWidget {
  const LoanListTile({
    required this.item,
    super.key,
    this.selecting = false,
    this.selected = false,
    this.onSelectionToggle,
    this.onEnterSelection,
  });

  final LoanWithClient item;
  final bool selecting;
  final bool selected;
  final VoidCallback? onSelectionToggle;
  final VoidCallback? onEnterSelection;

  void _defaultTap(BuildContext context) {
    if (selecting) {
      onSelectionToggle?.call();
      return;
    }
    context.push(AppRoutes.loanDetail(item.loan.id));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layout = ref.watch(loanListLayoutProvider);

    final card = switch (layout) {
      LoanListCardLayout.extended => LoanListCard(
          item: item,
          selected: selected,
          selecting: selecting,
          onTap: () => _defaultTap(context),
          onLongPress: onEnterSelection,
        ),
      LoanListCardLayout.compact => LoanListCardCompact(
          item: item,
          selected: selected,
          selecting: selecting,
          onTap: () => _defaultTap(context),
          onLongPress: onEnterSelection,
        ),
    };

    if (!selecting) return card;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.sm),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onSelectionToggle,
              customBorder: const CircleBorder(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? AppColors.accent.withValues(alpha: 0.2)
                      : Colors.transparent,
                  border: Border.all(
                    color: selected
                        ? AppColors.accent
                        : context.appTheme.border,
                    width: selected ? 2 : 1.5,
                  ),
                ),
                child: selected
                    ? const Icon(
                        LucideIcons.check,
                        size: 16,
                        color: AppColors.accent,
                      )
                    : null,
              ),
            ),
          ),
        ),
        Expanded(child: card),
      ],
    );
  }
}
