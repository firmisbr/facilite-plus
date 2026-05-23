import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Confirma exclusão de um ou vários empréstimos.
class DeleteLoansDialog extends StatelessWidget {
  const DeleteLoansDialog({
    super.key,
    required this.count,
    this.highlightName,
  });

  final int count;
  final String? highlightName;

  static Future<bool> show(
    BuildContext context, {
    required int count,
    String? highlightName,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: count == 1,
      builder: (ctx) => DeleteLoansDialog(
        count: count,
        highlightName: highlightName,
      ),
    ).then((v) => v ?? false);
  }

  @override
  Widget build(BuildContext context) {
    final plural = count != 1;
    final title = plural
        ? 'Excluir $count empréstimos?'
        : 'Excluir empréstimo?';

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.12),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: const Icon(
                      LucideIcons.trash_2,
                      color: AppColors.error,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        if (highlightName != null && !plural) ...[
                          const SizedBox(height: 2),
                          Text(
                            highlightName!,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: context.appTheme.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                plural
                    ? 'Todos os empréstimos selecionados e os pagamentos '
                        'vinculados serão removidos deste aparelho e da fila '
                        'de sincronização. Esta ação não pode ser desfeita.'
                    : 'O empréstimo e todos os pagamentos registrados serão '
                        'removidos. Esta ação não pode ser desfeita.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: context.appTheme.textSecondary,
                      height: 1.45,
                    ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      icon: const Icon(LucideIcons.trash_2, size: 18),
                      label: Text(plural ? 'Excluir $count' : 'Excluir'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
