import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../services/sync/sync_providers.dart';
import '../../../../shared/utils/br_currency_input_formatter.dart';
import '../../../../shared/widgets/app_bar_actions.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../clients/presentation/providers/clients_providers.dart';
import '../../../notifications/notification_reschedule.dart';
import '../../../payments/presentation/providers/payments_providers.dart';
import '../../domain/loan_periodicity.dart';
import '../../domain/loan_simulator.dart';
import '../../domain/loan_status_sync.dart';
import '../providers/loans_providers.dart';

class LoanFormPage extends ConsumerStatefulWidget {
  const LoanFormPage({
    super.key,
    this.loanId,
  });

  final String? loanId;

  @override
  ConsumerState<LoanFormPage> createState() => _LoanFormPageState();
}

class _LoanFormPageState extends ConsumerState<LoanFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _interestController = TextEditingController();
  final _installmentsController = TextEditingController();
  final _dueDateController = TextEditingController();
  LoanPeriodicity _periodicity = LoanPeriodicity.mensal;
  String _status = 'ativo';
  String? _clientId;
  String _originalClientName = '';
  bool _loading = false;
  bool _initialLoad = true;

  static const _statusOptions = ['ativo', 'quitado', 'atrasado'];

  @override
  void initState() {
    super.initState();
    _loadLoan();
  }

  static String _formatIsoDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> _loadLoan() async {
    final loan =
        await ref.read(loansRepositoryProvider).getById(widget.loanId!);
    if (loan == null || !mounted) return;

    final client =
        await ref.read(clientsRepositoryProvider).getById(loan.clientId);
    _clientId = loan.clientId;
    _originalClientName = client?.name ?? '';
    _nameController.text = _originalClientName;

    _amountController.text = LoanSimulator.amountForCurrencyInput(loan.amount);
    _interestController.text = loan.interest ?? '';
    _installmentsController.text =
        loan.installments?.toString() ?? '';
    _dueDateController.text = _normalizeDueDate(loan.firstDueDate);
    _periodicity = LoanPeriodicity.fromValue(loan.periodicity);
    _status = loan.status ?? 'ativo';
    setState(() => _initialLoad = false);
  }

  /// Garante `yyyy-MM-dd` no campo (evita ISO com hora que confunde o picker).
  static String _normalizeDueDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';
    final parsed = DateTime.tryParse(raw.trim());
    if (parsed == null) return raw.trim();
    return _formatIsoDate(parsed);
  }

  Future<void> _pickDueDate() async {
    final initial =
        DateTime.tryParse(_dueDateController.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      _dueDateController.text = _formatIsoDate(picked);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _interestController.dispose();
    _installmentsController.dispose();
    _dueDateController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    final repo = ref.read(loansRepositoryProvider);
    final clientsRepo = ref.read(clientsRepositoryProvider);

    try {
      final clientName = _nameController.text.trim();
      final amountText = _amountController.text.trim();
      final amount = LoanSimulator.parseAmount(amountText);
      if (amount == null || amount <= 0) {
        throw StateError('Valor do empréstimo inválido');
      }

      final installmentsRaw = _installmentsController.text.trim();
      final installments = installmentsRaw.isEmpty
          ? null
          : int.tryParse(installmentsRaw);
      if (installmentsRaw.isNotEmpty &&
          (installments == null || installments < 1)) {
        throw StateError('Número de parcelas inválido');
      }

      final interest = _interestController.text.trim();
      final interestVal = interest.isEmpty ? null : interest;
      final due = _dueDateController.text.trim();
      final dueVal = due.isEmpty ? null : due;

      final existing = await repo.getById(widget.loanId!);
      if (existing == null) throw StateError('Empréstimo não encontrado');

      final clientId = _clientId ?? existing.clientId;
      if (clientName != _originalClientName) {
        final client = await clientsRepo.getById(clientId);
        if (client == null) throw StateError('Cliente não encontrado');
        await clientsRepo.update(client.copyWith(name: clientName));
      }

      // Persiste no mesmo formato da criação (máscara BR) para o cronograma.
      await repo.update(
        existing.copyWith(
          amount: amountText,
          interest: interestVal,
          installments: installments,
          periodicity: _periodicity.value,
          firstDueDate: dueVal,
          status: _status,
        ),
      );

      await LoanStatusSync.refresh(
        loansRepo: repo,
        paymentsRepo: ref.read(paymentsRepositoryProvider),
        loanId: widget.loanId!,
      );
      ref.invalidate(allLoansProvider);
      ref.invalidate(loanForPaymentsProvider(widget.loanId!));
      ref.invalidate(clientsStreamProvider);
      ref.invalidate(clientForLoansProvider(clientId));
      await rescheduleLoanNotifications(ref);

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
        title: const Text('Editar empréstimo'),
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
                    controller: _nameController,
                    label: 'Nome do cliente *',
                    hint: 'Nome completo',
                    textCapitalization: TextCapitalization.words,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Obrigatório' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _amountController,
                    label: 'Valor (R\$) *',
                    hint: '1.000,00',
                    prefixText: 'R\$ ',
                    keyboardType: TextInputType.number,
                    inputFormatters: const [BrCurrencyInputFormatter()],
                    validator: (v) {
                      final amount = LoanSimulator.parseAmount(v ?? '');
                      if (amount == null || amount <= 0) {
                        return 'Informe um valor válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _installmentsController,
                    label: 'Parcelas',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) {
                      final t = v?.trim() ?? '';
                      if (t.isEmpty) return null;
                      final n = int.tryParse(t);
                      if (n == null || n < 1) return 'Parcelas inválidas';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<LoanPeriodicity>(
                    initialValue: _periodicity,
                    decoration: const InputDecoration(
                      labelText: 'Periodicidade',
                    ),
                    items: LoanPeriodicity.values
                        .map(
                          (p) => DropdownMenuItem(
                            value: p,
                            child: Text(p.label),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _periodicity = v);
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _interestController,
                    label: 'Juros (% do valor emprestado)',
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _dueDateController,
                    label: 'Data do 1º vencimento',
                    readOnly: true,
                    onTap: _pickDueDate,
                    suffixIcon: const Icon(Icons.calendar_today_outlined),
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
