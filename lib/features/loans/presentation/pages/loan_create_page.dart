import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../services/supabase/supabase_providers.dart';
import '../../../../services/sync/sync_providers.dart';
import '../../../clients/presentation/providers/clients_providers.dart';
import '../../../../shared/widgets/app_bar_actions.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../domain/loan_periodicity.dart';
import '../../domain/loan_simulator.dart';
import '../providers/loans_providers.dart';

class LoanCreatePage extends ConsumerStatefulWidget {
  const LoanCreatePage({super.key, this.clientId});

  /// Cliente já existente (ex.: fluxo pela lista do cliente).
  final String? clientId;

  @override
  ConsumerState<LoanCreatePage> createState() => _LoanCreatePageState();
}

class _LoanCreatePageState extends ConsumerState<LoanCreatePage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _cpfController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();

  final _amountController = TextEditingController();
  final _installmentsController = TextEditingController();
  final _interestController = TextEditingController();
  final _dueDateController = TextEditingController();

  LoanPeriodicity _periodicity = LoanPeriodicity.mensal;
  bool _loading = false;
  bool _showFullSchedule = false;
  bool _lockPersonalFields = false;
  String? _matchedClientName;

  @override
  void initState() {
    super.initState();
    _dueDateController.text = LoanSimulator.formatDate(DateTime.now());
    for (final c in [
      _amountController,
      _installmentsController,
      _interestController,
      _dueDateController,
    ]) {
      c.addListener(_onFormChanged);
    }
    if (widget.clientId != null) {
      _loadExistingClient();
    }
  }

  Future<void> _loadExistingClient() async {
    final client =
        await ref.read(clientsRepositoryProvider).getById(widget.clientId!);
    if (client == null || !mounted) return;
    _nameController.text = client.name;
    _cpfController.text = client.document ?? '';
    _whatsappController.text = client.phone ?? '';
    _emailController.text = client.email ?? '';
    _addressController.text = client.address ?? '';
    setState(() {
      _lockPersonalFields = true;
      _matchedClientName = client.name;
    });
  }

  void _onFormChanged() => setState(() {});

  @override
  void dispose() {
    _nameController.dispose();
    _cpfController.dispose();
    _whatsappController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _amountController.dispose();
    _installmentsController.dispose();
    _interestController.dispose();
    _dueDateController.dispose();
    super.dispose();
  }

  DateTime? _parseDueDate() {
    final raw = _dueDateController.text.trim();
    if (raw.isEmpty) return null;
    return DateTime.tryParse(raw) ??
        DateTime.tryParse('${raw}T12:00:00');
  }

  static String _formatIsoDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> _pickDueDate() async {
    final initial = _parseDueDate() ?? DateTime.now();
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

  LoanSimulationResult? get _simulation {
    final principal = LoanSimulator.parseAmount(_amountController.text);
    final installments = int.tryParse(_installmentsController.text.trim());
    final interest = double.tryParse(
      _interestController.text.trim().replaceAll(',', '.'),
    );
    final due = _parseDueDate();
    if (principal == null ||
        installments == null ||
        installments < 1 ||
        interest == null ||
        due == null) {
      return null;
    }
    return LoanSimulator.simulate(
      principal: principal,
      installments: installments,
      monthlyInterestPercent: interest,
      periodicity: _periodicity,
      firstDueDate: due,
      maxScheduleRows: _showFullSchedule ? installments : 6,
    );
  }

  bool _validatePersonal({required bool requireAll}) {
    if (_lockPersonalFields && widget.clientId != null) return true;
    if (_nameController.text.trim().isEmpty) return false;
    if (requireAll && _whatsappController.text.trim().isEmpty) return false;
    return true;
  }

  bool _validateLoan() {
    if (!_formKey.currentState!.validate()) return false;
    if (_parseDueDate() == null) return false;
    if (_simulation == null) return false;
    return true;
  }

  Future<void> _save({required bool createNewClient}) async {
    if (!_validateLoan()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha os dados do empréstimo para continuar.'),
        ),
      );
      return;
    }

    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    if (createNewClient) {
      if (!_validatePersonal(requireAll: true)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nome e WhatsApp são obrigatórios para novo cliente.'),
          ),
        );
        return;
      }
    } else if (!_validatePersonal(requireAll: false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o nome do cliente.')),
      );
      return;
    }

    setState(() => _loading = true);
    final clientsRepo = ref.read(clientsRepositoryProvider);
    final loansRepo = ref.read(loansRepositoryProvider);

    try {
      String clientId;

      if (widget.clientId != null && !createNewClient) {
        clientId = widget.clientId!;
        final existing = await clientsRepo.getById(clientId);
        if (existing != null) {
          await clientsRepo.update(
            existing.copyWith(
              name: _nameController.text.trim(),
              phone: _opt(_whatsappController.text),
              email: _opt(_emailController.text),
              document: _opt(_cpfController.text),
              address: _opt(_addressController.text),
            ),
          );
        }
      } else if (createNewClient) {
        final client = await clientsRepo.create(
          userId: userId,
          name: _nameController.text.trim(),
          phone: _whatsappController.text.trim(),
          email: _opt(_emailController.text),
          document: _opt(_cpfController.text),
          address: _opt(_addressController.text),
        );
        clientId = client.id;
      } else {
        final match = await clientsRepo.findByDocumentOrPhone(
          userId: userId,
          document: _opt(_cpfController.text),
          phone: _whatsappController.text.trim(),
        );
        if (match == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Cliente não encontrado. Use CPF ou WhatsApp já cadastrado, '
                'ou toque em "Criar empréstimo + cliente".',
              ),
            ),
          );
          return;
        }
        clientId = match.id;
        await clientsRepo.update(
          match.copyWith(
            name: _nameController.text.trim().isEmpty
                ? match.name
                : _nameController.text.trim(),
            phone: _opt(_whatsappController.text) ?? match.phone,
            email: _opt(_emailController.text) ?? match.email,
            document: _opt(_cpfController.text) ?? match.document,
            address: _opt(_addressController.text) ?? match.address,
          ),
        );
      }

      final dueIso = _formatIsoDate(_parseDueDate()!);
      await loansRepo.create(
        clientId: clientId,
        amount: _amountController.text.trim(),
        interest: _interestController.text.trim(),
        installments: int.parse(_installmentsController.text.trim()),
        periodicity: _periodicity.value,
        firstDueDate: dueIso,
      );

      await ref.read(syncServiceProvider).processQueue();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Empréstimo criado com sucesso')),
        );
        context.pop();
      }
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

  String? _opt(String value) {
    final t = value.trim();
    return t.isEmpty ? null : t;
  }

  @override
  Widget build(BuildContext context) {
    final simulation = _simulation;
    final installments = int.tryParse(_installmentsController.text.trim());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Novo empréstimo'),
        actions: const [
          AppBarActions(showSync: false, showLogout: false),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppSpacing.maxContentWidth,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_lockPersonalFields && _matchedClientName != null)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.md,
                            ),
                            child: Material(
                              color: AppColors.accent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusSm,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.person_outline,
                                      color: AppColors.accent,
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: Text(
                                        'Cliente: $_matchedClientName',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        _SectionTitle(
                          title: 'Dados pessoais',
                          subtitle: _lockPersonalFields
                              ? 'Vinculado ao cliente selecionado'
                              : 'Para vincular ou cadastrar o cliente',
                        ),
                        AppTextField(
                          controller: _nameController,
                          label: 'Nome *',
                          readOnly: _lockPersonalFields,
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Obrigatório'
                              : null,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          controller: _cpfController,
                          label: 'CPF (opcional)',
                          keyboardType: TextInputType.number,
                          readOnly: _lockPersonalFields,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          controller: _whatsappController,
                          label: 'WhatsApp *',
                          keyboardType: TextInputType.phone,
                          readOnly: _lockPersonalFields,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          controller: _emailController,
                          label: 'E-mail (opcional)',
                          keyboardType: TextInputType.emailAddress,
                          readOnly: _lockPersonalFields,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          controller: _addressController,
                          label: 'Endereço (opcional)',
                          maxLines: 2,
                          readOnly: _lockPersonalFields,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        const _SectionTitle(
                          title: 'Informações do empréstimo',
                          subtitle: null,
                        ),
                        AppTextField(
                          controller: _amountController,
                          label: 'Valor do empréstimo (R\$) *',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Obrigatório' : null,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          controller: _installmentsController,
                          label: 'Número de parcelas *',
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: (v) {
                            final n = int.tryParse(v?.trim() ?? '');
                            if (n == null || n < 1) return 'Mínimo 1 parcela';
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        DropdownButtonFormField<LoanPeriodicity>(
                          initialValue: _periodicity,
                          decoration: const InputDecoration(
                            labelText: 'Periodicidade *',
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
                          label: 'Taxa de juros (% ao mês) *',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Obrigatório' : null,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          controller: _dueDateController,
                          label: 'Data do 1º vencimento *',
                          readOnly: true,
                          onTap: _pickDueDate,
                          suffixIcon: const Icon(Icons.calendar_today_outlined),
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Obrigatório' : null,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        if (simulation != null) ...[
                          _SimulationPanel(
                            result: simulation,
                            totalInstallments: installments ?? 0,
                            showFullSchedule: _showFullSchedule,
                            onToggleSchedule: () {
                              setState(
                                () => _showFullSchedule = !_showFullSchedule,
                              );
                            },
                          ),
                        ] else
                          AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Simulação',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  'Preencha valor, parcelas, taxa e vencimento '
                                  'para ver a simulação em tempo real.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: AppSpacing.xxl),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Material(
              elevation: 8,
              color: Theme.of(context).colorScheme.surface,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      OutlinedButton(
                        onPressed: _loading ? null : () => context.pop(),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      FilledButton(
                        onPressed: _loading
                            ? null
                            : () => _save(createNewClient: false),
                        child: _loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Criar empréstimo'),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      FilledButton.tonal(
                        onPressed: _loading
                            ? null
                            : () => _save(createNewClient: true),
                        child: const Text('Criar empréstimo + cliente'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}

class _SimulationPanel extends StatelessWidget {
  const _SimulationPanel({
    required this.result,
    required this.totalInstallments,
    required this.showFullSchedule,
    required this.onToggleSchedule,
  });

  final LoanSimulationResult result;
  final int totalInstallments;
  final bool showFullSchedule;
  final VoidCallback onToggleSchedule;

  @override
  Widget build(BuildContext context) {
    final hidden = totalInstallments - result.schedule.length;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calculate_outlined, color: AppColors.accent),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Simulação do empréstimo',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _SimRow(
            label: 'Valor emprestado',
            value: LoanSimulator.formatMoney(result.principal),
          ),
          _SimRow(
            label: 'Parcela',
            value: LoanSimulator.formatMoney(result.installmentAmount),
            highlight: true,
          ),
          _SimRow(
            label: 'Total a pagar',
            value: LoanSimulator.formatMoney(result.totalAmount),
          ),
          _SimRow(
            label: 'Total de juros',
            value: LoanSimulator.formatMoney(result.totalInterest),
          ),
          const Divider(height: AppSpacing.lg),
          Text(
            'Cronograma',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          ...result.schedule.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                children: [
                  Text(
                    '${item.number}ª',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(LoanSimulator.formatDate(item.dueDate)),
                  ),
                  Text(
                    LoanSimulator.formatMoney(item.amount),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
          ),
          if (hidden > 0 && !showFullSchedule)
            Text(
              '… e mais $hidden parcela(s)',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          if (totalInstallments > 6)
            TextButton(
              onPressed: onToggleSchedule,
              child: Text(
                showFullSchedule
                    ? 'Mostrar menos'
                    : 'Ver todas as parcelas',
              ),
            ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Taxa mensal convertida conforme a periodicidade (sistema Price).',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _SimRow extends StatelessWidget {
  const _SimRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: highlight
                ? Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                    )
                : Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
