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
import '../../../../shared/utils/br_cpf_input_formatter.dart';
import '../../../../shared/utils/br_currency_input_formatter.dart';
import '../../../../shared/utils/br_phone_input_formatter.dart';
import '../../../../shared/widgets/app_date_picker.dart';
import '../../../../shared/widgets/app_wheel_picker_dialog.dart';
import '../../../../shared/widgets/floating_label_input_card.dart';
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
  String? _matchedClientName;

  final _pageController = PageController();
  int _pageIndex = 0;

  static const _stepLabels = ['Empréstimo', 'Resumo', 'Cliente'];

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
    final client = await ref
        .read(clientsRepositoryProvider)
        .getById(widget.clientId!);
    if (client == null || !mounted) return;
    _nameController.text = client.name;
    _cpfController.text = BrCpfInputFormatter.formatDisplay(client.document);
    _whatsappController.text = BrPhoneInputFormatter.formatDisplay(client.phone);
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
    _pageController.dispose();
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

  bool get _clientStepValid {
    if (_lockPersonalFields && widget.clientId != null) return true;
    return _nameController.text.trim().isNotEmpty;
  }

  bool get _loanStepValid {
    final principal = LoanSimulator.parseAmount(_amountController.text);
    final installments = int.tryParse(_installmentsController.text.trim());
    final interest = double.tryParse(
      _interestController.text.trim().replaceAll(',', '.'),
    );
    return principal != null &&
        installments != null &&
        installments >= 1 &&
        interest != null &&
        _parseDueDate() != null;
  }

  void _goToPage(int index) {
    FocusScope.of(context).unfocus();
    setState(() => _pageIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  void _onNextStep() {
    if (_pageIndex == 0) {
      if (!_formKey.currentState!.validate() || !_loanStepValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Complete valor, parcelas, juros e vencimento.'),
          ),
        );
        return;
      }
      _goToPage(1);
      return;
    }
    if (_pageIndex == 1) {
      if (_simulation == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ajuste os dados do empréstimo para simular.'),
          ),
        );
        return;
      }
      _goToPage(2);
    }
  }

  void _onPreviousStep() {
    if (_pageIndex > 0) _goToPage(_pageIndex - 1);
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
      interestPercent: interest,
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
            content: Text(
              'Nome e WhatsApp são obrigatórios para novo cliente.',
            ),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao salvar: $e')));
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
    final isLastStep = _pageIndex == 2;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Novo empréstimo'),
        actions: const [AppBarActions(showSync: false, showLogout: false)],
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppDecorations.screenBackground(brightness),
        ),
        child: Form(
          key: _formKey,
          child: SafeArea(
            child: Column(
              children: [
                _StepHeader(
                  labels: _stepLabels,
                  currentIndex: _pageIndex,
                  onStepTap: _goToPage,
                ),
                if (simulation != null && _pageIndex == 0)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.sm,
                    ),
                    child: _LivePreviewStrip(result: simulation),
                  ),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const BouncingScrollPhysics(),
                    onPageChanged: (i) => setState(() => _pageIndex = i),
                    children: [
                      _LoanStepPage(
                        amountController: _amountController,
                        installmentsController: _installmentsController,
                        interestController: _interestController,
                        periodicity: _periodicity,
                        dueDateLabel: _dueDateDisplayLabel,
                        onPeriodicityTap: _openPeriodicityPicker,
                        onDueDateTap: _openDueDatePicker,
                      ),
                      _SummaryStepPage(
                        clientName: _lockPersonalFields
                            ? (_matchedClientName ?? _nameController.text.trim())
                            : _nameController.text.trim(),
                        amountText: _amountController.text.trim(),
                        installments: installments ?? 0,
                        interestText: _interestController.text.trim(),
                        periodicity: _periodicity,
                        dueDateLabel: _dueDateDisplayLabel,
                        simulation: simulation,
                        showFullSchedule: _showFullSchedule,
                        onToggleSchedule: () => setState(
                          () => _showFullSchedule = !_showFullSchedule,
                        ),
                      ),
                      _ClientStepPage(
                        lockPersonalFields: _lockPersonalFields,
                        matchedClientName: _matchedClientName,
                        nameController: _nameController,
                        cpfController: _cpfController,
                        whatsappController: _whatsappController,
                        emailController: _emailController,
                        addressController: _addressController,
                      ),
                    ],
                  ),
                ),
                _FlowBottomBar(
                  loading: _loading,
                  pageIndex: _pageIndex,
                  isLastStep: isLastStep,
                  canAdvance: _pageIndex == 0
                      ? _loanStepValid
                      : _pageIndex == 1
                      ? simulation != null
                      : _clientStepValid,
                  onBack: _pageIndex > 0 ? _onPreviousStep : null,
                  onNext: isLastStep ? null : _onNextStep,
                  onCancel: () => context.pop(),
                  onSave: () => _save(createNewClient: false),
                  onSaveWithClient: () => _save(createNewClient: true),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// —— Navegação em etapas ——

class _StepHeader extends StatelessWidget {
  const _StepHeader({
    required this.labels,
    required this.currentIndex,
    required this.onStepTap,
  });

  final List<String> labels;
  final int currentIndex;
  final ValueChanged<int> onStepTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Row(
        children: List.generate(labels.length * 2 - 1, (i) {
          if (i.isOdd) {
            final stepDone = (i ~/ 2) < currentIndex;
            return Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.only(bottom: 22),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(1),
                  color: stepDone
                      ? AppColors.accent
                      : Theme.of(context).dividerColor.withValues(alpha: 0.5),
                ),
              ),
            );
          }
          final index = i ~/ 2;
          final active = index == currentIndex;
          final done = index < currentIndex;
          return GestureDetector(
            onTap: () => onStepTap(index),
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  width: active ? 36 : 30,
                  height: active ? 36 : 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: active || done
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.accent,
                              AppColors.accent.withValues(alpha: 0.75),
                            ],
                          )
                        : null,
                    color: active || done
                        ? null
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    border: Border.all(
                      color: active
                          ? AppColors.premium.withValues(alpha: 0.6)
                          : Theme.of(context).dividerColor,
                      width: active ? 2 : 1,
                    ),
                    boxShadow: active
                        ? [
                            BoxShadow(
                              color: AppColors.accent.withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: done
                        ? const Icon(
                            LucideIcons.check,
                            size: 16,
                            color: Colors.white,
                          )
                        : Text(
                            '${index + 1}',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: active || done
                                      ? Colors.white
                                      : Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  labels[index],
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: active
                        ? AppColors.accent
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _LivePreviewStrip extends StatelessWidget {
  const _LivePreviewStrip({required this.result});

  final LoanSimulationResult result;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(AppSpacing.radius2xl),
        border: Border.all(color: AppColors.premium.withValues(alpha: 0.35)),
        boxShadow: context.appTheme.cardShadow,
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.zap, size: 18, color: AppColors.premium),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Prévia: ${LoanSimulator.formatMoney(result.installmentAmount)}/parcela',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            LoanSimulator.formatMoney(result.totalAmount),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.accent,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// —— Etapa 1: Cliente ——

class _ClientStepPage extends StatelessWidget {
  const _ClientStepPage({
    required this.lockPersonalFields,
    required this.matchedClientName,
    required this.nameController,
    required this.cpfController,
    required this.whatsappController,
    required this.emailController,
    required this.addressController,
  });

  final bool lockPersonalFields;
  final String? matchedClientName;
  final TextEditingController nameController;
  final TextEditingController cpfController;
  final TextEditingController whatsappController;
  final TextEditingController emailController;
  final TextEditingController addressController;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (lockPersonalFields && matchedClientName != null)
            _LinkedClientHero(name: matchedClientName!)
          else ...[
            FloatingLabelInputCard(
              icon: LucideIcons.user_round,
              label: 'Nome',
              controller: nameController,
              required: true,
              hintText: 'fi de Deus',
              textCapitalization: TextCapitalization.words,
              fieldStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Obrigatório' : null,
            ),
            const SizedBox(height: AppSpacing.lg),
            FloatingLabelInputCard(
              icon: LucideIcons.id_card,
              label: 'CPF',
              controller: cpfController,
              keyboardType: TextInputType.number,
              inputFormatters: const [BrCpfInputFormatter()],
              hintText: '000.000.000-00',
            ),
            const SizedBox(height: AppSpacing.lg),
            FloatingLabelInputCard(
              icon: LucideIcons.phone,
              label: 'WhatsApp',
              controller: whatsappController,
              required: true,
              keyboardType: TextInputType.phone,
              inputFormatters: const [BrPhoneInputFormatter()],
              hintText: '(00) 0 0000-0000',
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Obrigatório';
                final digits = BrPhoneInputFormatter.digitsOnly(v);
                if (digits == null || digits.length < 10) {
                  return 'Número inválido';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            FloatingLabelInputCard(
              icon: LucideIcons.mail,
              label: 'E-mail',
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              hintText: 'fidedeus@gmail.com',
              autocorrect: false,
            ),
            const SizedBox(height: AppSpacing.lg),
            FloatingLabelInputCard(
              icon: LucideIcons.map_pin,
              label: 'Endereço',
              controller: addressController,
              hintText: 'baixa da égua',
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

class _LinkedClientHero extends StatelessWidget {
  const _LinkedClientHero({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 28),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            48,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.accent.withValues(alpha: 0.18),
                Theme.of(context).colorScheme.surface,
              ],
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radius2xl),
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.25)),
            boxShadow: context.appTheme.cardShadow,
          ),
          child: Column(
            children: [
              Text(
                name,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radius2xl),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      LucideIcons.link_2,
                      size: 14,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Cliente já vinculado',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.accent,
                    AppColors.accentSecondary,
                  ],
                ),
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// —— Etapa 2: Empréstimo ——

class _LoanStepPage extends StatelessWidget {
  const _LoanStepPage({
    required this.amountController,
    required this.installmentsController,
    required this.interestController,
    required this.periodicity,
    required this.dueDateLabel,
    required this.onPeriodicityTap,
    required this.onDueDateTap,
  });

  final TextEditingController amountController;
  final TextEditingController installmentsController;
  final TextEditingController interestController;
  final LoanPeriodicity periodicity;
  final String dueDateLabel;
  final VoidCallback onPeriodicityTap;
  final VoidCallback onDueDateTap;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AmountField(controller: amountController),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _ProminentMetricField(
                  icon: LucideIcons.layers,
                  label: 'Parcelas',
                  controller: installmentsController,
                  keyboardType: TextInputType.number,
                  hintText: '1',
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
                child: _ProminentMetricField(
                  icon: LucideIcons.percent,
                  label: 'Juros',
                  controller: interestController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  hintText: '70',
                  suffixText: '%',
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
          _DueDateCard(label: dueDateLabel, onTap: onDueDateTap),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

class _AmountField extends StatelessWidget {
  const _AmountField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return _ProminentMetricField(
      icon: LucideIcons.banknote,
      label: 'Valor principal',
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: const [BrCurrencyInputFormatter()],
      prefixText: 'R\$ ',
      hintText: '1.000,00',
      validator: (v) {
        final amount = LoanSimulator.parseAmount(v ?? '');
        if (amount == null || amount <= 0) {
          return 'Informe o valor';
        }
        return null;
      },
    );
  }
}

class _ProminentMetricField extends StatelessWidget {
  const _ProminentMetricField({
    required this.icon,
    required this.label,
    required this.controller,
    required this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.prefixText,
    this.suffixText,
    this.hintText,
  });

  final IconData icon;
  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final String? prefixText;
  final String? suffixText;
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    final fieldStyle = Theme.of(context).textTheme.displaySmall?.copyWith(
      fontWeight: FontWeight.w800,
      color: AppColors.accent,
      height: 1.1,
      letterSpacing: -0.5,
    );

    return FloatingLabelInputCard(
      icon: icon,
      label: label,
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      textAlign: TextAlign.center,
      prefixText: prefixText,
      suffixText: suffixText,
      hintText: hintText,
      fieldStyle: fieldStyle,
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
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: context.appTheme.border),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.accent, size: 20),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: Theme.of(context).textTheme.labelMedium),
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

class _DueDateCard extends StatelessWidget {
  const _DueDateCard({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            border: Border.all(color: context.appTheme.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: AppDecorations.iconBadge(color: AppColors.premium),
                child: const Icon(
                  LucideIcons.calendar_clock,
                  color: AppColors.premium,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '1º vencimento',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    Text(
                      label,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(LucideIcons.chevron_right, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// —— Etapa 3: Resumo ——

class _SummaryStepPage extends StatelessWidget {
  const _SummaryStepPage({
    required this.clientName,
    required this.amountText,
    required this.installments,
    required this.interestText,
    required this.periodicity,
    required this.dueDateLabel,
    required this.simulation,
    required this.showFullSchedule,
    required this.onToggleSchedule,
  });

  final String clientName;
  final String amountText;
  final int installments;
  final String interestText;
  final LoanPeriodicity periodicity;
  final String dueDateLabel;
  final LoanSimulationResult? simulation;
  final bool showFullSchedule;
  final VoidCallback onToggleSchedule;

  String get _amountDisplay {
    if (amountText.trim().isEmpty) return '—';
    final parsed = LoanSimulator.parseAmount(amountText);
    if (parsed != null) return LoanSimulator.formatMoney(parsed);
    return 'R\$ $amountText';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ContractSummaryCard(
            amountDisplay: _amountDisplay,
            installments: installments,
            periodicityLabel: periodicity.label,
            interestText: interestText,
            dueDateLabel: dueDateLabel,
            clientName: clientName,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (simulation != null)
            _SimulationPreview(
              result: simulation!,
              totalInstallments: installments,
              showFullSchedule: showFullSchedule,
              onToggleSchedule: onToggleSchedule,
            )
          else
            _EmptySimulation(),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

class _ContractSummaryCard extends StatelessWidget {
  const _ContractSummaryCard({
    required this.amountDisplay,
    required this.installments,
    required this.periodicityLabel,
    required this.interestText,
    required this.dueDateLabel,
    required this.clientName,
  });

  final String amountDisplay;
  final int installments;
  final String periodicityLabel;
  final String interestText;
  final String dueDateLabel;
  final String clientName;

  @override
  Widget build(BuildContext context) {
    final hasClient = clientName.trim().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: context.appTheme.border),
        boxShadow: context.appTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: Column(
              children: [
                Text(
                  'Valor emprestado',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: context.appTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  amountDisplay,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.accent,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            indent: AppSpacing.lg,
            endIndent: AppSpacing.lg,
            color: context.appTheme.border,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _SummaryCompactItem(
                        label: 'Parcelas',
                        value: installments > 0 ? '$installments' : '—',
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _SummaryCompactItem(
                        label: 'Juros',
                        value: interestText.trim().isEmpty
                            ? '—'
                            : '$interestText%',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _SummaryCompactItem(
                        label: 'Periodicidade',
                        value: periodicityLabel,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _SummaryCompactItem(
                        label: '1º vencimento',
                        value: dueDateLabel,
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (hasClient)
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                bottom: AppSpacing.md,
              ),
              child: Text(
                'Cliente: $clientName',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.appTheme.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}

class _SummaryCompactItem extends StatelessWidget {
  const _SummaryCompactItem({
    required this.label,
    required this.value,
    this.maxLines = 1,
  });

  final String label;
  final String value;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: context.appTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
        ),
      ],
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
              ? [const Color(0xFF1E2420), const Color(0xFF1A1F1C)]
              : [const Color(0xFF2C2C2A), const Color(0xFF232321)],
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
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusSm,
                        ),
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
                  'Valor da parcela',
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
                ...result.schedule.asMap().entries.map((entry) {
                  final item = entry.value;
                  final isLast = entry.key == result.schedule.length - 1;
                  return _TimelineRow(
                    number: item.number,
                    date: LoanSimulator.formatDate(item.dueDate),
                    amount: LoanSimulator.formatMoney(item.amount),
                    showLine: !isLast,
                  );
                }),
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
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: const Color(0xFF8E8E8A)),
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

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.number,
    required this.date,
    required this.amount,
    required this.showLine,
  });

  final int number;
  final String date;
  final String amount;
  final bool showLine;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.accent,
                        AppColors.accent.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                  child: Text(
                    '$number',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (showLine)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: AppColors.accent.withValues(alpha: 0.35),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.sm,
                bottom: AppSpacing.md,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      date,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFFC8C5BE),
                      ),
                    ),
                  ),
                  Text(
                    amount,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: const Color(0xFFF4F1EA),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
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
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(AppSpacing.radius2xl),
        border: Border.all(color: context.appTheme.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: AppDecorations.iconBadge(color: AppColors.accent),
            child: const Icon(
              LucideIcons.chart_line,
              size: 36,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Simulação indisponível',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Volte à etapa Empréstimo e preencha os campos.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.appTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _FlowBottomBar extends StatelessWidget {
  const _FlowBottomBar({
    required this.loading,
    required this.pageIndex,
    required this.isLastStep,
    required this.canAdvance,
    required this.onBack,
    required this.onNext,
    required this.onCancel,
    required this.onSave,
    required this.onSaveWithClient,
  });

  final bool loading;
  final int pageIndex;
  final bool isLastStep;
  final bool canAdvance;
  final VoidCallback? onBack;
  final VoidCallback? onNext;
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
        AppSpacing.md + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.96),
        border: Border(top: BorderSide(color: context.appTheme.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isLastStep) ...[
            FilledButton.icon(
              onPressed: loading ? null : onSave,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
              ),
              icon: loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(LucideIcons.circle_check),
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
                        Text('+ novo cliente'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ] else
            Row(
              children: [
                if (onBack != null)
                  IconButton.outlined(
                    onPressed: loading ? null : onBack,
                    icon: const Icon(LucideIcons.arrow_left),
                  )
                else
                  IconButton.outlined(
                    onPressed: loading ? null : onCancel,
                    icon: const Icon(LucideIcons.x),
                  ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: loading || !canAdvance ? null : onNext,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
                    ),
                    icon: Icon(
                      pageIndex == 0
                          ? LucideIcons.clipboard_check
                          : pageIndex == 1
                          ? LucideIcons.user_round
                          : LucideIcons.arrow_right,
                    ),
                    label: Text(
                      pageIndex == 0
                          ? 'Ver resumo'
                          : pageIndex == 1
                          ? 'Dados do cliente'
                          : 'Continuar',
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
