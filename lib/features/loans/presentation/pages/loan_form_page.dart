import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../services/sync/sync_providers.dart';
import '../../../../shared/widgets/app_bar_actions.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../providers/loans_providers.dart';

class LoanFormPage extends ConsumerStatefulWidget {
  const LoanFormPage({
    super.key,
    this.clientId,
    this.loanId,
  });

  final String? clientId;
  final String? loanId;

  bool get isEditing => loanId != null;

  @override
  ConsumerState<LoanFormPage> createState() => _LoanFormPageState();
}

class _LoanFormPageState extends ConsumerState<LoanFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _interestController = TextEditingController();
  final _installmentsController = TextEditingController();
  String _status = 'ativo';
  String? _resolvedClientId;
  bool _loading = false;
  bool _initialLoad = true;

  static const _statusOptions = ['ativo', 'quitado', 'atrasado'];

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _loadLoan();
    } else {
      _resolvedClientId = widget.clientId;
      _initialLoad = false;
    }
  }

  Future<void> _loadLoan() async {
    final loan =
        await ref.read(loansRepositoryProvider).getById(widget.loanId!);
    if (loan == null || !mounted) return;
    _amountController.text = loan.amount;
    _interestController.text = loan.interest ?? '';
    _installmentsController.text =
        loan.installments?.toString() ?? '';
    _status = loan.status ?? 'ativo';
    _resolvedClientId = loan.clientId;
    setState(() => _initialLoad = false);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _interestController.dispose();
    _installmentsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    final repo = ref.read(loansRepositoryProvider);

    try {
      final installments = int.tryParse(_installmentsController.text.trim());
      final interest = _interestController.text.trim();
      final interestVal = interest.isEmpty ? null : interest;

      if (widget.isEditing) {
        final existing = await repo.getById(widget.loanId!);
        if (existing == null) throw StateError('Empréstimo não encontrado');
        await repo.update(
          existing.copyWith(
            amount: _amountController.text.trim(),
            interest: interestVal,
            installments: installments,
            status: _status,
          ),
        );
      } else {
        final clientId = _resolvedClientId ?? widget.clientId;
        if (clientId == null) throw StateError('Cliente não informado');
        await repo.create(
          clientId: clientId,
          amount: _amountController.text.trim(),
          interest: interestVal,
          installments: installments,
          status: _status,
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
        title: Text(widget.isEditing ? 'Editar empréstimo' : 'Novo empréstimo'),
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
                    controller: _interestController,
                    label: 'Juros (%)',
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _installmentsController,
                    label: 'Parcelas',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String>(
                    initialValue: _status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: _statusOptions
                        .map(
                          (s) => DropdownMenuItem(value: s, child: Text(s)),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _status = v);
                    },
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
