import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../services/sync/sync_providers.dart';
import '../../../clients/domain/entities/client.dart';
import '../../../../shared/utils/br_cpf_input_formatter.dart';
import '../../../../shared/utils/br_phone_input_formatter.dart';
import '../../../../shared/widgets/detail_value_card.dart';
import '../../domain/loan_installment_status.dart';
import '../../domain/loan_simulator.dart';
import '../providers/loan_detail_providers.dart';
import '../providers/loans_providers.dart';
import '../widgets/installment_highlight_shell.dart';
import '../widgets/loan_installment_card.dart';

class LoanDetailPage extends ConsumerStatefulWidget {
  const LoanDetailPage({
    super.key,
    required this.loanId,
    this.highlightInstallment,
  });

  final String loanId;

  /// Parcela a rolar e destacar (ex.: vinda do dashboard).
  final int? highlightInstallment;

  @override
  ConsumerState<LoanDetailPage> createState() => _LoanDetailPageState();
}

class _LoanDetailPageState extends ConsumerState<LoanDetailPage> {
  bool _deleting = false;
  final _scrollController = ScrollController();
  final _installmentKeys = <int, GlobalKey>{};
  int? _highlightedInstallment;
  bool _highlightFocusDone = false;

  static const _highlightDuration = Duration(seconds: 3);

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(LoanDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.loanId != widget.loanId ||
        oldWidget.highlightInstallment != widget.highlightInstallment) {
      _highlightFocusDone = false;
      _highlightedInstallment = null;
      _installmentKeys.clear();
    }
  }

  void _scheduleInstallmentHighlight(List<LoanInstallmentItem> installments) {
    final target = widget.highlightInstallment;
    if (target == null || _highlightFocusDone) return;

    final exists = installments.any((i) => i.number == target);
    if (!exists) {
      _highlightFocusDone = true;
      return;
    }

    _highlightFocusDone = true;
    for (final item in installments) {
      _installmentKeys.putIfAbsent(item.number, GlobalKey.new);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(const Duration(milliseconds: 80), () {
        if (!mounted) return;
        final targetContext = _installmentKeys[target]?.currentContext;
        if (targetContext == null || !targetContext.mounted) return;

        Scrollable.ensureVisible(
          targetContext,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
          alignment: 0.28,
        ).then((_) {
          if (!mounted) return;
          setState(() => _highlightedInstallment = target);
          Future<void>.delayed(_highlightDuration, () {
            if (mounted) setState(() => _highlightedInstallment = null);
          });
        });
      });
    });
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir empréstimo?'),
        content: const Text(
          'O empréstimo e todos os pagamentos registrados serão '
          'removidos. Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      await ref.read(loansRepositoryProvider).delete(widget.loanId);
      await ref.read(syncServiceProvider).processQueue();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Empréstimo excluído')));
        context.go(AppRoutes.loans);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao excluir: $e')));
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bundle = ref.watch(loanDetailProvider(widget.loanId));
    final isLoading = ref.watch(loanDetailLoadingProvider(widget.loanId));
    final brightness = Theme.of(context).brightness;

    if (isLoading && bundle == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (bundle == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Empréstimo')),
        body: const Center(child: Text('Empréstimo não encontrado')),
      );
    }

    final client = bundle.client;
    final detail = bundle.detail;

    if (detail != null) {
      _scheduleInstallmentHighlight(detail.installments);
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(client.name),
        actions: [
          IconButton(
            tooltip: 'Editar empréstimo',
            icon: const Icon(LucideIcons.pencil, size: 22),
            onPressed: _deleting
                ? null
                : () => context.push(AppRoutes.loanEdit(widget.loanId)),
          ),
          IconButton(
            tooltip: 'Excluir empréstimo',
            icon: _deleting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(LucideIcons.trash_2, size: 22),
            onPressed: _deleting ? null : _confirmDelete,
          ),
        ],
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppDecorations.screenBackground(brightness),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.xxl,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppSpacing.maxContentWidth,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (detail != null) ...[
                      _LoanHeroCard(
                        manager: detail.manager,
                        paidInstallments: detail.overview.paidInstallments,
                        totalInstallments: detail.overview.totalInstallments,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _LoanTermsCard(manager: detail.manager),
                      const SizedBox(height: AppSpacing.md),
                      _FinancialSummaryCard(manager: detail.manager),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    _ClientInfoSection(client: client),
                    if (detail != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      _InstallmentsSection(
                        loanId: widget.loanId,
                        installments: detail.installments,
                        overview: detail.overview,
                        installmentKeys: _installmentKeys,
                        highlightedInstallment: _highlightedInstallment,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _OverviewCard(overview: detail.overview),
                    ] else
                      DetailInfoListCard(
                        entries: [
                          const DetailInfoEntry(
                            icon: LucideIcons.info,
                            label: 'Cronograma',
                            value:
                                'Complete parcelas, juros e vencimento para ver o resumo.',
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoanHeroCard extends StatelessWidget {
  const _LoanHeroCard({
    required this.manager,
    required this.paidInstallments,
    required this.totalInstallments,
  });

  final LoanManagerStats manager;
  final int paidInstallments;
  final int totalInstallments;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: context.appTheme.border),
        boxShadow: context.appTheme.cardShadow,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 88,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$paidInstallments/$totalInstallments',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.accent,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'parcelas',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: context.appTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            VerticalDivider(
              width: 1,
              color: context.appTheme.border,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Valor emprestado',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: context.appTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    LoanSimulator.formatMoney(manager.principal),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Valor da parcela',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: context.appTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    LoanSimulator.formatMoney(manager.installmentAmount),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoanTermsCard extends StatelessWidget {
  const _LoanTermsCard({required this.manager});

  final LoanManagerStats manager;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: context.appTheme.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: DetailCompactCell(
              label: 'Juros',
              value: '${manager.interestPercent.toStringAsFixed(2)}%',
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: DetailCompactCell(
              label: 'Periodicidade',
              value: manager.periodicityLabel,
            ),
          ),
        ],
      ),
    );
  }
}

class _FinancialSummaryCard extends StatelessWidget {
  const _FinancialSummaryCard({required this.manager});

  final LoanManagerStats manager;

  @override
  Widget build(BuildContext context) {
    final totalInterest = manager.totalWithInterest - manager.principal;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: context.appTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Resumo financeiro',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: DetailCompactCell(
                  label: 'Total',
                  value: LoanSimulator.formatMoney(manager.totalWithInterest),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: DetailCompactCell(
                  label: 'Juros',
                  value: LoanSimulator.formatMoney(totalInterest),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: DetailCompactCell(
                  label: 'Lucro total',
                  value: LoanSimulator.formatMoney(manager.totalProfit),
                  valueColor: AppColors.accent,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: DetailCompactCell(
                  label: 'Lucro / parcela',
                  value: LoanSimulator.formatMoney(
                    manager.profitPerInstallment,
                  ),
                  valueColor: AppColors.accent,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ClientInfoSection extends StatelessWidget {
  const _ClientInfoSection({required this.client});

  final Client client;

  @override
  Widget build(BuildContext context) {
    final entries = <DetailInfoEntry>[
      DetailInfoEntry(
        icon: LucideIcons.user_round,
        label: 'Nome',
        value: client.name,
      ),
    ];

    final cpf = BrCpfInputFormatter.formatDisplay(client.document);
    if (cpf.isNotEmpty) {
      entries.add(
        DetailInfoEntry(icon: LucideIcons.id_card, label: 'CPF', value: cpf),
      );
    }

    final phone = BrPhoneInputFormatter.formatDisplay(client.phone);
    if (phone.isNotEmpty) {
      entries.add(
        DetailInfoEntry(icon: LucideIcons.phone, label: 'WhatsApp', value: phone),
      );
    }

    if (client.email != null && client.email!.trim().isNotEmpty) {
      entries.add(
        DetailInfoEntry(
          icon: LucideIcons.mail,
          label: 'E-mail',
          value: client.email!,
        ),
      );
    }

    if (client.address != null && client.address!.trim().isNotEmpty) {
      entries.add(
        DetailInfoEntry(
          icon: LucideIcons.map_pin,
          label: 'Endereço',
          value: client.address!,
        ),
      );
    }

    return DetailInfoListCard(title: 'Dados pessoais', entries: entries);
  }
}

class _InstallmentsSection extends StatelessWidget {
  const _InstallmentsSection({
    required this.loanId,
    required this.installments,
    required this.overview,
    required this.installmentKeys,
    required this.highlightedInstallment,
  });

  final String loanId;
  final List<LoanInstallmentItem> installments;
  final LoanOverviewStats overview;
  final Map<int, GlobalKey> installmentKeys;
  final int? highlightedInstallment;

  @override
  Widget build(BuildContext context) {
    final progress = overview.totalInstallments > 0
        ? overview.paidInstallments / overview.totalInstallments
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Parcelas',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '${overview.paidInstallments}/${overview.totalInstallments} pagas',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: context.appTheme.border,
            color: AppColors.accent,
          ),
        ),
        if (overview.overdueInstallments > 0) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${overview.overdueInstallments} em atraso',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        ...installments.map(
          (item) => Padding(
            key: installmentKeys[item.number],
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: InstallmentHighlightShell(
              active: highlightedInstallment == item.number,
              child: LoanInstallmentCard(loanId: loanId, item: item),
            ),
          ),
        ),
      ],
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.overview});

  final LoanOverviewStats overview;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: context.appTheme.border),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Text(
              'Situação do contrato',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _OverviewRow(
            icon: LucideIcons.circle_check,
            label: 'Já pago',
            value: LoanSimulator.formatMoney(overview.paidAmount),
          ),
          _OverviewRow(
            icon: LucideIcons.wallet,
            label: 'Falta pagar',
            value: LoanSimulator.formatMoney(overview.remainingAmount),
          ),
          _OverviewRow(
            icon: LucideIcons.layers,
            label: 'Parcelas pagas',
            value:
                '${overview.paidInstallments} de ${overview.totalInstallments}',
          ),
          _OverviewRow(
            icon: LucideIcons.hourglass,
            label: 'Parcelas restantes',
            value: '${overview.remainingInstallments}',
          ),
          _OverviewRow(
            icon: LucideIcons.triangle_alert,
            label: 'Em atraso',
            value: '${overview.overdueInstallments}',
            alert: overview.overdueInstallments > 0,
          ),
          _OverviewRow(
            icon: LucideIcons.calendar,
            label: 'Próximo vencimento',
            value: overview.nextDueDate != null
                ? LoanSimulator.formatDate(overview.nextDueDate!)
                : '—',
            showDivider: false,
          ),
        ],
      ),
    );
  }
}

class _OverviewRow extends StatelessWidget {
  const _OverviewRow({
    required this.icon,
    required this.label,
    required this.value,
    this.alert = false,
    this.showDivider = true,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool alert;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: alert ? AppColors.error : AppColors.accent,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.appTheme.textSecondary,
                  ),
                ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: alert ? AppColors.error : null,
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            color: context.appTheme.border,
          ),
      ],
    );
  }
}
