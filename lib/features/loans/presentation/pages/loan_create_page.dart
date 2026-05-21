import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../services/supabase/supabase_providers.dart';
import '../../../../services/sync/sync_providers.dart';
import '../../../clients/presentation/providers/clients_providers.dart';
import '../../../../shared/widgets/app_bar_actions.dart';
import '../../../../shared/widgets/app_text_field.dart';
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
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Novo empréstimo'),
        actions: const [
          AppBarActions(showSync: false, showLogout: false),
        ],
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppDecorations.screenBackground(brightness),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: _CreateHeroHeader(
                        hasClient: _lockPersonalFields,
                        clientName: _matchedClientName,
                        hasSimulation: simulation != null,
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.md,
                        AppSpacing.lg,
                        AppSpacing.sm,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: _SectionCard(
                          step: 1,
                          icon: LucideIcons.user_round,
                          title: 'Quem vai receber?',
                          subtitle: _lockPersonalFields
                              ? 'Cliente já vinculado'
                              : 'Vincule por CPF/WhatsApp ou cadastre novo',
                          expanded: _clientSectionExpanded,
                          onToggle: _lockPersonalFields
                              ? null
                              : () => setState(
                                    () => _clientSectionExpanded =
                                        !_clientSectionExpanded,
                                  ),
                          child: Column(
                            children: [
                              if (_lockPersonalFields &&
                                  _matchedClientName != null)
                                _LinkedClientChip(name: _matchedClientName!),
                              AppTextField(
                                controller: _nameController,
                                label: 'Nome *',
                                readOnly: _lockPersonalFields,
                                validator: (v) =>
                                    v == null || v.trim().isEmpty
                                        ? 'Obrigatório'
                                        : null,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Row(
                                children: [
                                  Expanded(
                                    child: AppTextField(
                                      controller: _cpfController,
                                      label: 'CPF',
                                      keyboardType: TextInputType.number,
                                      readOnly: _lockPersonalFields,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    flex: 2,
                                    child: AppTextField(
                                      controller: _whatsappController,
                                      label: 'WhatsApp *',
                                      keyboardType: TextInputType.phone,
                                      readOnly: _lockPersonalFields,
                                    ),
                                  ),
                                ],
                              ),
                              if (_clientSectionExpanded) ...[
                                const SizedBox(height: AppSpacing.md),
                                AppTextField(
                                  controller: _emailController,
                                  label: 'E-mail',
                                  keyboardType: TextInputType.emailAddress,
                                  readOnly: _lockPersonalFields,
                                ),
                                const SizedBox(height: AppSpacing.md),
                                AppTextField(
                                  controller: _addressController,
                                  label: 'Endereço',
                                  maxLines: 2,
                                  readOnly: _lockPersonalFields,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: _SectionCard(
                          step: 2,
                          icon: LucideIcons.percent,
                          title: 'Condições do empréstimo',
                          subtitle: 'Valor, parcelas e vencimento',
                          expanded: true,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _AmountHighlightField(
                                controller: _amountController,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: AppTextField(
                                      controller: _installmentsController,
                                      label: 'Parcelas *',
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      validator: (v) {
                                        final n = int.tryParse(v?.trim() ?? '');
                                        if (n == null || n < 1) {
                                          return 'Mín. 1';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: AppTextField(
                                      controller: _interestController,
                                      label: 'Juros %/mês *',
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                      validator: (v) => v == null ||
                                              v.trim().isEmpty
                                          ? 'Obrigatório'
                                          : null,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                'Periodicidade',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              _PeriodicitySelector(
                                value: _periodicity,
                                onChanged: (v) =>
                                    setState(() => _periodicity = v),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _DueDateTile(
                                label: _dueDateController.text,
                                onTap: _pickDueDate,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.md,
                        AppSpacing.lg,
                        AppSpacing.xxl,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: simulation != null
                            ? _SimulationShowcase(
                                result: simulation,
                                totalInstallments: installments ?? 0,
                                showFullSchedule: _showFullSchedule,
                                isDark: isDark,
                                onToggleSchedule: () => setState(
                                  () => _showFullSchedule = !_showFullSchedule,
                                ),
                              )
                            : _SimulationPlaceholder(isDark: isDark),
                      ),
                    ),
                  ],
                ),
              ),
              _CreateActionDock(
                loading: _loading,
                onCancel: () => context.pop(),
                onCreateLoan: () => _save(createNewClient: false),
                onCreateWithClient: () => _save(createNewClient: true),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateHeroHeader extends StatelessWidget {
  const _CreateHeroHeader({
    required this.hasClient,
    required this.clientName,
    required this.hasSimulation,
  });

  final bool hasClient;
  final String? clientName;
  final bool hasSimulation;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        MediaQuery.paddingOf(context).top + kToolbarHeight + AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.accent.withValues(alpha: 0.22),
              AppColors.accentSecondary.withValues(alpha: 0.35),
            ],
          ),
          border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.25),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: AppDecorations.iconBadge(color: AppColors.accent),
                  child: const Icon(
                    LucideIcons.sparkles,
                    color: AppColors.accent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Monte seu empréstimo',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              hasClient && clientName != null
                  ? 'Contrato para $clientName — ajuste valores e veja a simulação ao vivo.'
                  : 'Preencha cliente e condições. A simulação aparece em tempo real.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                _HeroPill(
                  icon: LucideIcons.user_round,
                  label: 'Cliente',
                  active: hasClient,
                ),
                const SizedBox(width: AppSpacing.sm),
                _HeroPill(
                  icon: LucideIcons.calculator,
                  label: 'Condições',
                  active: true,
                ),
                const SizedBox(width: AppSpacing.sm),
                _HeroPill(
                  icon: LucideIcons.chart_line,
                  label: 'Preview',
                  active: hasSimulation,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({
    required this.icon,
    required this.label,
    required this.active,
  });

  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.sm,
          horizontal: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: active
              ? AppColors.accent.withValues(alpha: 0.18)
              : Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: active
                ? AppColors.accent.withValues(alpha: 0.4)
                : Colors.transparent,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 18,
              color: active
                  ? AppColors.accent
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: active
                        ? AppColors.accent
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.step,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.expanded,
    this.onToggle,
  });

  final int step;
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;
  final bool expanded;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
      elevation: 0,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: onToggle,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppSpacing.radiusLg),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    _StepBadge(number: step),
                    const SizedBox(width: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: AppDecorations.iconBadge(
                        color: AppColors.accent,
                      ),
                      child: Icon(icon, size: 20, color: AppColors.accent),
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
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            subtitle,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    if (onToggle != null)
                      Icon(
                        expanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                child: child,
              ),
          ],
        ),
      ),
    );
  }
}

class _StepBadge extends StatelessWidget {
  const _StepBadge({required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.accent,
      ),
      child: Text(
        '$number',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: const Color(0xFF1A221C),
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _LinkedClientChip extends StatelessWidget {
  const _LinkedClientChip({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.badge_check, color: AppColors.accent, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                name,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AmountHighlightField extends StatelessWidget {
  const _AmountHighlightField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accent.withValues(alpha: 0.08),
            AppColors.accentSecondary.withValues(alpha: 0.12),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.accent,
            ),
        decoration: InputDecoration(
          border: InputBorder.none,
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 4, right: 8),
            child: Text(
              'R\$',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent,
                  ),
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          hintText: '0,00',
          hintStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.accent.withValues(alpha: 0.35),
              ),
          labelText: 'Valor emprestado *',
          floatingLabelStyle: Theme.of(context).textTheme.labelMedium,
        ),
        validator: (v) =>
            v == null || v.trim().isEmpty ? 'Informe o valor' : null,
      ),
    );
  }
}

class _PeriodicitySelector extends StatelessWidget {
  const _PeriodicitySelector({
    required this.value,
    required this.onChanged,
  });

  final LoanPeriodicity value;
  final ValueChanged<LoanPeriodicity> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: LoanPeriodicity.values.map((p) {
        final selected = p == value;
        return FilterChip(
          label: Text(p.label),
          selected: selected,
          onSelected: (_) => onChanged(p),
          showCheckmark: false,
          selectedColor: AppColors.accent.withValues(alpha: 0.22),
          labelStyle: TextStyle(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected
                ? AppColors.accent
                : Theme.of(context).colorScheme.onSurface,
          ),
          side: BorderSide(
            color: selected
                ? AppColors.accent
                : Theme.of(context).dividerColor,
          ),
        );
      }).toList(),
    );
  }
}

class _DueDateTile extends StatelessWidget {
  const _DueDateTile({required this.label, required this.onTap});

  final String label;
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
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: AppDecorations.iconBadge(color: AppColors.info),
                child: const Icon(
                  LucideIcons.calendar_days,
                  size: 20,
                  color: AppColors.info,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '1º vencimento *',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SimulationPlaceholder extends StatelessWidget {
  const _SimulationPlaceholder({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          style: BorderStyle.solid,
        ),
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.6),
      ),
      child: Column(
        children: [
          Icon(
            LucideIcons.chart_line,
            size: 40,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Preview da simulação',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Informe valor, parcelas, juros e vencimento para ver parcela, total e cronograma.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _SimulationShowcase extends StatelessWidget {
  const _SimulationShowcase({
    required this.result,
    required this.totalInstallments,
    required this.showFullSchedule,
    required this.isDark,
    required this.onToggleSchedule,
  });

  final LoanSimulationResult result;
  final int totalInstallments;
  final bool showFullSchedule;
  final bool isDark;
  final VoidCallback onToggleSchedule;

  @override
  Widget build(BuildContext context) {
    final hidden = totalInstallments - result.schedule.length;
    final surface = isDark ? const Color(0xFF1E2420) : const Color(0xFF2C2C2A);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        color: surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
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
                    const Icon(
                      LucideIcons.sparkles,
                      color: AppColors.accent,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Sua simulação',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: const Color(0xFFF4F1EA),
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Parcela',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF8E8E8A),
                      ),
                ),
                Text(
                  LoanSimulator.formatMoney(result.installmentAmount),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                ),
                const SizedBox(height: AppSpacing.md),
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
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _DarkMetric(
                        label: 'Emprestado',
                        value: LoanSimulator.formatMoney(result.principal),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFF3D3D3A)),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cronograma',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: const Color(0xFFF4F1EA),
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ...result.schedule.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.15),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusSm),
                          ),
                          child: Text(
                            '${item.number}',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
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
                              .bodyMedium
                              ?.copyWith(
                                color: const Color(0xFFF4F1EA),
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
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF8E8E8A),
                        ),
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
                Text(
                  'Taxa mensal convertida conforme periodicidade (Price).',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF8E8E8A),
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
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
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
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
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

class _CreateActionDock extends StatelessWidget {
  const _CreateActionDock({
    required this.loading,
    required this.onCancel,
    required this.onCreateLoan,
    required this.onCreateWithClient,
  });

  final bool loading;
  final VoidCallback onCancel;
  final VoidCallback onCreateLoan;
  final VoidCallback onCreateWithClient;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 12,
      shadowColor: Colors.black26,
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton(
                onPressed: loading ? null : onCreateLoan,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ),
                child: loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.check, size: 20),
                          SizedBox(width: AppSpacing.sm),
                          Text('Criar empréstimo'),
                        ],
                      ),
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
                      onPressed: loading ? null : onCreateWithClient,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.user_plus, size: 18),
                          SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '+ cliente',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
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
