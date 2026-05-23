import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_date_picker.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../domain/loan_installment_status.dart';
import '../../domain/loan_simulator.dart';

class PayInstallmentDialog extends StatefulWidget {
  const PayInstallmentDialog({super.key, required this.item});

  final LoanInstallmentItem item;

  static Future<DateTime?> show(
    BuildContext context,
    LoanInstallmentItem item,
  ) {
    return showDialog<DateTime>(
      context: context,
      builder: (ctx) => PayInstallmentDialog(item: item),
    );
  }

  @override
  State<PayInstallmentDialog> createState() => _PayInstallmentDialogState();
}

class _PayInstallmentDialogState extends State<PayInstallmentDialog> {
  late final TextEditingController _dateController;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _dateController = TextEditingController(
      text: AppDatePicker.formatMedium(_selectedDate),
    );
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await AppDatePicker.open(
      context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Data do pagamento',
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = AppDatePicker.formatMedium(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

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
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: const Icon(
                      LucideIcons.circle_check,
                      color: AppColors.accent,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Registrar pagamento',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'Parcela ${item.number}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                            color: context.appTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(color: context.appTheme.border),
                ),
                child: Column(
                  children: [
                    Text(
                      'Valor da parcela',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: context.appTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      LoanSimulator.formatMoney(item.amount),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Vencimento ${LoanSimulator.formatDate(item.dueDate)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.appTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _dateController,
                label: 'Data do pagamento',
                readOnly: true,
                onTap: _pickDate,
                suffixIcon: const Icon(Icons.calendar_today_outlined),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.pop(context, _selectedDate),
                      icon: const Icon(LucideIcons.check, size: 18),
                      label: const Text('Confirmar'),
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

class UndoInstallmentPaymentDialog extends StatelessWidget {
  const UndoInstallmentPaymentDialog({super.key, required this.item});

  final LoanInstallmentItem item;

  static Future<bool> show(BuildContext context, LoanInstallmentItem item) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => UndoInstallmentPaymentDialog(item: item),
    ).then((v) => v ?? false);
  }

  @override
  Widget build(BuildContext context) {
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
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: const Icon(
                      LucideIcons.undo_2,
                      color: AppColors.warning,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Desfazer pagamento?',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'Parcela ${item.number}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                            color: context.appTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'A parcela volta a ficar em aberto. O registro de pagamento '
                'será removido.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.appTheme.textSecondary,
                ),
              ),
              if (item.paidDate != null) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(color: context.appTheme.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.calendar,
                        size: 16,
                        color: AppColors.accent,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Pago em ${LoanSimulator.formatDate(item.paidDate!)}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.error,
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Desfazer'),
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
