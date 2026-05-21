import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
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

  static String _formatIsoDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _dateController = TextEditingController(
      text: _formatIsoDate(_selectedDate),
    );
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = _formatIsoDate(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return AlertDialog(
      title: Text('Registrar pagamento — parcela ${item.number}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Valor: ${LoanSimulator.formatMoney(item.amount)}',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _dateController,
            label: 'Data do pagamento',
            readOnly: true,
            onTap: _pickDate,
            suffixIcon: const Icon(Icons.calendar_today_outlined),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _selectedDate),
          child: const Text('Confirmar pagamento'),
        ),
      ],
    );
  }
}
