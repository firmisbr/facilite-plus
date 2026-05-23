import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../services/sync/sync_providers.dart';
import '../../../../shared/widgets/app_bar_actions.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../providers/payments_providers.dart';

class PaymentFormPage extends ConsumerStatefulWidget {
  const PaymentFormPage({
    super.key,
    this.loanId,
    this.paymentId,
  });

  final String? loanId;
  final String? paymentId;

  bool get isEditing => paymentId != null;

  @override
  ConsumerState<PaymentFormPage> createState() => _PaymentFormPageState();
}

class _PaymentFormPageState extends ConsumerState<PaymentFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _dateController = TextEditingController();
  String? _method;
  String? _resolvedLoanId;
  bool _loading = false;
  bool _initialLoad = true;

  static const _methodOptions = [
    ('dinheiro', 'Dinheiro'),
    ('pix', 'PIX'),
    ('transferencia', 'Transferência'),
    ('outro', 'Outro'),
  ];

  static String _formatIsoDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _loadPayment();
    } else {
      _resolvedLoanId = widget.loanId;
      _dateController.text = _formatIsoDate(DateTime.now());
      _initialLoad = false;
    }
  }

  Future<void> _loadPayment() async {
    final payment =
        await ref.read(paymentsRepositoryProvider).getById(widget.paymentId!);
    if (payment == null || !mounted) return;
    _amountController.text = payment.amount;
    _dateController.text = payment.paymentDate ?? '';
    _method = payment.method;
    _resolvedLoanId = payment.loanId;
    setState(() => _initialLoad = false);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final initial = DateTime.tryParse(_dateController.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      _dateController.text = _formatIsoDate(picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    final repo = ref.read(paymentsRepositoryProvider);

    try {
      final paymentDate = _dateController.text.trim();
      final paymentDateVal = paymentDate.isEmpty ? null : paymentDate;
      final method = _method;

      if (widget.isEditing) {
        final existing = await repo.getById(widget.paymentId!);
        if (existing == null) throw StateError('Pagamento não encontrado');
        await repo.update(
          existing.copyWith(
            amount: _amountController.text.trim(),
            paymentDate: paymentDateVal,
            method: method,
          ),
        );
      } else {
        final loanId = _resolvedLoanId ?? widget.loanId;
        if (loanId == null) throw StateError('Empréstimo não informado');
        await repo.create(
          loanId: loanId,
          amount: _amountController.text.trim(),
          paymentDate: paymentDateVal,
          method: method,
        );
      }

      await ref.read(syncServiceProvider).processQueue();
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_initialLoad) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Editar pagamento' : 'Novo pagamento'),
        actions: const [
          AppBarActions(showSync: false, showLogout: false),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    controller: _amountController,
                    label: 'Valor (R\$) *',
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Obrigatório' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _dateController,
                    label: 'Data do pagamento',
                    readOnly: true,
                    onTap: _pickDate,
                    suffixIcon: const Icon(Icons.calendar_today_outlined),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String>(
                    initialValue: _method,
                    decoration: const InputDecoration(
                      labelText: 'Forma de pagamento',
                    ),
                    items: _methodOptions
                        .map(
                          (e) => DropdownMenuItem(
                            value: e.$1,
                            child: Text(e.$2),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _method = v),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppPrimaryButton(
                    label: 'Salvar',
                    isLoading: _loading,
                    onPressed: _save,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
