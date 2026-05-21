import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../services/supabase/supabase_providers.dart';
import '../../../../services/sync/sync_providers.dart';
import '../../../clients/presentation/providers/clients_providers.dart';
import '../../../../shared/widgets/app_bar_actions.dart';
import '../../../../shared/widgets/app_date_picker.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_wheel_picker_dialog.dart';
import '../../domain/loan_periodicity.dart';
import '../../domain/loan_simulator.dart';
import '../providers/loans_providers.dart';

class LoanCreatePage extends ConsumerStatefulWidget {
  const LoanCreatePage({super.key, this.clientId});

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
  bool _clientSectionExpanded = true;
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
      _clientSectionExpanded = false;
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
    return DateTime.tryParse(raw) ?? DateTime.tryParse('${raw}T12:00:00');
  }

  static String _formatIsoDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String get _dueDateDisplayLabel {
    final parsed = _parseDueDate();
    if (parsed == null) return 'Escolher data';
    return AppDatePicker.formatLong(parsed);
  }

  Future<void> _openDueDatePicker() async {
    final initial = _parseDueDate() ?? DateTime.now();
    final picked = await AppDatePicker.open(
      context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      helpText: '1º vencimento',
    );
    if (picked != null) {
      setState(() => _dueDateController.text = _formatIsoDate(picked));
    }
  }

  Future<void> _openPeriodicityPicker() async {
    final picked = await AppWheelPickerDialog.show<LoanPeriodicity>(
      context: context,
      title: 'Periodicidade',
      items: LoanPeriodicity.values,
      itemLabel: (p) => p.label,
      initialValue: _periodicity,
    );
    if (picked != null) {
      setState(() => _periodicity = picked);
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Novo Empréstimo'),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_lockPersonalFields && _matchedClientName != null)
                      _LinkedClientBanner(name: _matchedClientName!)
                    else
                      _ClientSection(
                        nameController: _nameController,
                        cpfController: _cpfController,
                        whatsappController: _whatsappController,
                        emailController: _emailController,
                        addressController: _addressController,
                        expanded: _clientSectionExpanded,
                        onToggle: () => setState(
                          () => _clientSectionExpanded = !_clientSectionExpanded,
                        ),
                      ),
                    const SizedBox(height: AppSpacing.lg),
                    _AmountSection(controller: _amountController),
                    const SizedBox(height: AppSpacing.lg),
                    _LoanConditions(
                      installmentsController: _installmentsController,
                      interestController: _interestController,
                      periodicity: _periodicity,
                      dueDateLabel: _dueDateDisplayLabel,
                      onPeriodicityTap: _openPeriodicityPicker,
                      onDueDateTap: _openDueDatePicker,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    if (simulation != null)
                      _SimulationPreview(
                        result: simulation,
                        totalInstallments: installments ?? 0,
                        showFullSchedule: _showFullSchedule,
                        onToggleSchedule: () => setState(
                          () => _showFullSchedule = !_showFullSchedule,
                        ),
                      )
                    else
                      _EmptySimulation(),
                  ],
                ),
              ),
            ),
            _ActionButtons(
              loading: _loading,
              onCancel: () => context.pop(),
              onSave: () => _save(createNewClient: false),
              onSaveWithClient: () => _save(createNewClient: true),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkedClientBanner extends StatelessWidget {
  const _LinkedClientBanner({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accent.withValues(alpha: 0.12),
            AppColors.accent.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.user_check,
              color: AppColors.accent,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cliente vinculado',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.accent,
                      ),
                ),
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
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

class _ClientSection extends StatelessWidget {
  const _ClientSection({
    required this.nameController,
    required this.cpfController,
    required this.whatsappController,
    required this.emailController,
    required this.addressController,
    required this.expanded,
    required this.onToggle,
  });

  final TextEditingController nameController;
  final TextEditingController cpfController;
  final TextEditingController whatsappController;
  final TextEditingController emailController;
  final TextEditingController addressController;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.user_round,
                    color: AppColors.accent,
                    size: 22,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Dados do cliente',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  Icon(
                    expanded ? LucideIcons.chevron_up : LucideIcons.chevron_down,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Column(
                children: [
                  AppTextField(
                    controller: nameController,
                    label: 'Nome *',
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Obrigatório' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: cpfController,
                          label: 'CPF',
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        flex: 2,
                        child: AppTextField(
                          controller: whatsappController,
                          label: 'WhatsApp *',
                          keyboardType: TextInputType.phone,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: emailController,
                    label: 'E-mail',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: addressController,
                    label: 'Endereço',
                    maxLines: 2,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _AmountSection extends StatelessWidget {
  const _AmountSection({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accent.withValues(alpha: 0.15),
            AppColors.accentSecondary.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: const Icon(
                  LucideIcons.coins,
                  color: AppColors.accent,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Valor do empréstimo',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.accent,
                  height: 1,
                ),
            decoration: InputDecoration(
              border: InputBorder.none,
              prefixText: 'R\$ ',
              prefixStyle: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.accent,
                    height: 1,
                  ),
              hintText: '0,00',
              hintStyle: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.accent.withValues(alpha: 0.25),
                    height: 1,
                  ),
              contentPadding: EdgeInsets.zero,
            ),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Informe o valor' : null,
          ),
        ],
      ),
    );
  }
}

class _LoanConditions extends StatelessWidget {
  const _LoanConditions({
    required this.installmentsController,
    required this.interestController,
    required this.periodicity,
    required this.dueDateLabel,
    required this.onPeriodicityTap,
    required this.onDueDateTap,
  });

  final TextEditingController installmentsController;
  final TextEditingController interestController;
  final LoanPeriodicity periodicity;
  final String dueDateLabel;
  final VoidCallback onPeriodicityTap;
  final VoidCallback onDueDateTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: installmentsController,
                label: 'Parcelas *',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  final n = int.tryParse(v?.trim() ?? '');
                  if (n == null || n < 1) return 'Mín. 1';
                  return null;
                },
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppTextField(
                controller: interestController,
                label: 'Juros % mês *',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Obrigatório' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _PickerTile(
          icon: LucideIcons.repeat,
          label: 'Periodicidade',
          value: periodicity.label,
          onTap: onPeriodicityTap,
        ),
        const SizedBox(height: AppSpacing.md),
        _PickerTile(
          icon: LucideIcons.calendar_days,
          label: '1º vencimento',
          value: dueDateLabel,
          onTap: onDueDateTap,
        ),
      ],
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Icon(icon, color: AppColors.accent, size: 20),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    Text(
                      value,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                LucideIcons.chevron_right,
                size: 18,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SimulationPreview extends StatelessWidget {
  const _SimulationPreview({
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF1E2420),
                  const Color(0xFF1A1F1C),
                ]
              : [
                  const Color(0xFF2C2C2A),
                  const Color(0xFF232321),
                ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.3),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: const Icon(
                        LucideIcons.sparkles,
                        color: AppColors.accent,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Simulação',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: const Color(0xFFF4F1EA),
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Parcela mensal',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF8E8E8A),
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  LoanSimulator.formatMoney(result.installmentAmount),
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: _DarkMetric(
                        label: 'Total',
                        value: LoanSimulator.formatMoney(result.totalAmount),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _DarkMetric(
                        label: 'Juros',
                        value: LoanSimulator.formatMoney(result.totalInterest),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFF3D3D3A)),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cronograma',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: const Color(0xFFF4F1EA),
                      ),
                ),
                const SizedBox(height: AppSpacing.md),
                ...result.schedule.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.15),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusSm),
                          ),
                          child: Text(
                            '${item.number}',
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            LoanSimulator.formatDate(item.dueDate),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: const Color(0xFFC8C5BE)),
                          ),
                        ),
                        Text(
                          LoanSimulator.formatMoney(item.amount),
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(
                                color: const Color(0xFFF4F1EA),
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (hidden > 0 && !showFullSchedule)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Text(
                      '… e mais $hidden parcela(s)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF8E8E8A),
                          ),
                    ),
                  ),
                if (totalInstallments > 6)
                  TextButton(
                    onPressed: onToggleSchedule,
                    child: Text(
                      showFullSchedule ? 'Mostrar menos' : 'Ver todas',
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

class _DarkMetric extends StatelessWidget {
  const _DarkMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: const Color(0xFF8E8E8A),
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFFF4F1EA),
                  fontWeight: FontWeight.w700,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _EmptySimulation extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.calculator,
              size: 32,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Aguardando dados',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Preencha valor, parcelas, juros e vencimento',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.loading,
    required this.onCancel,
    required this.onSave,
    required this.onSaveWithClient,
  });

  final bool loading;
  final VoidCallback onCancel;
  final VoidCallback onSave;
  final VoidCallback onSaveWithClient;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          FilledButton.icon(
            onPressed: loading ? null : onSave,
            icon: loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(LucideIcons.check),
            label: const Text('Criar empréstimo'),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: loading ? null : onCancel,
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                flex: 2,
                child: FilledButton.tonal(
                  onPressed: loading ? null : onSaveWithClient,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.user_plus, size: 18),
                      SizedBox(width: 6),
                      Text('+ cliente'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
