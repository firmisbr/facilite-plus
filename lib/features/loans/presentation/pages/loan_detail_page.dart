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
import '../widgets/loan_installment_card.dart';

class LoanDetailPage extends ConsumerStatefulWidget {
  const LoanDetailPage({super.key, required this.loanId});

  final String loanId;

  @override
  ConsumerState<LoanDetailPage> createState() => _LoanDetailPageState();
}

class _LoanDetailPageState extends ConsumerState<LoanDetailPage> {
  bool _deleting = false;

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
            icon: const Icon(Icons.edit_outlined),
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
                : const Icon(Icons.delete_outline),
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
                        principal: LoanSimulator.formatMoney(
                          detail.manager.principal,
                        ),
                        installmentAmount: LoanSimulator.formatMoney(
                          detail.manager.installmentAmount,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _LoanContractCard(manager: detail.manager),
                      const SizedBox(height: AppSpacing.lg),
                      _SimulationSummaryCard(
                        installmentAmount: detail.manager.installmentAmount,
                        totalAmount: detail.manager.totalWithInterest,
                        totalInterest:
                            detail.manager.totalWithInterest -
                            detail.manager.principal,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    _ClientInfoSection(client: client),
                    if (detail != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Parcelas',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Toque em pagar na parcela ou desfaça se registrou por engano.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.appTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      ...detail.installments.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppSpacing.sm,
                          ),
                          child: LoanInstallmentCard(
                            loanId: widget.loanId,
                            item: item,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _OverviewCard(overview: detail.overview),
                    ] else
                      DetailValueCard(
                        icon: LucideIcons.info,
                        label: 'Cronograma',
                        value:
                            'Complete parcelas, juros e vencimento do empréstimo '
                            'para ver o cronograma e resumos.',
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
    required this.principal,
    required this.installmentAmount,
  });

  final String principal;
  final String installmentAmount;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: context.appTheme.border),
        boxShadow: context.appTheme.cardShadow,
      ),
      child: Column(
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
                  principal,
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
            padding: const EdgeInsets.all(AppSpacing.lg),
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
                  installmentAmount,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.accent,
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

class _LoanContractCard extends StatelessWidget {
  const _LoanContractCard({required this.manager});

  final LoanManagerStats manager;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: context.appTheme.border),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: DetailCompactCell(
                  label: 'Parcelas',
                  value: '${manager.installmentCount}',
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: DetailCompactCell(
                  label: 'Juros',
                  value:
                      '${manager.interestPercent.toStringAsFixed(2)}%',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: DetailCompactCell(
                  label: 'Periodicidade',
                  value: manager.periodicityLabel,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: DetailCompactCell(
                  label: 'Total com juros',
                  value: LoanSimulator.formatMoney(manager.totalWithInterest),
                  maxLines: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                  value: LoanSimulator.formatMoney(manager.profitPerInstallment),
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

class _SimulationSummaryCard extends StatelessWidget {
  const _SimulationSummaryCard({
    required this.installmentAmount,
    required this.totalAmount,
    required this.totalInterest,
  });

  final double installmentAmount;
  final double totalAmount;
  final double totalInterest;

  @override
  Widget build(BuildContext context) {
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
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.sparkles,
                size: 16,
                color: AppColors.accent,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Resumo financeiro',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: const Color(0xFFF4F1EA),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            LoanSimulator.formatMoney(installmentAmount),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.accent,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'por parcela',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF8E8E8A),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _DarkMiniMetric(
                  label: 'Total',
                  value: LoanSimulator.formatMoney(totalAmount),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _DarkMiniMetric(
                  label: 'Juros',
                  value: LoanSimulator.formatMoney(totalInterest),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DarkMiniMetric extends StatelessWidget {
  const _DarkMiniMetric({required this.label, required this.value});

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
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
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

class _ClientInfoSection extends StatelessWidget {
  const _ClientInfoSection({required this.client});

  final Client client;

  @override
  Widget build(BuildContext context) {
    final cpf = client.document != null
        ? BrCpfInputFormatter.formatDisplay(client.document)
        : null;
    final phone = client.phone != null
        ? BrPhoneInputFormatter.formatDisplay(client.phone)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DetailValueCard(
          icon: LucideIcons.user_round,
          label: 'Nome',
          value: client.name,
          emphasized: true,
        ),
        if (cpf != null && cpf.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          DetailValueCard(
            icon: LucideIcons.id_card,
            label: 'CPF',
            value: cpf,
          ),
        ],
        if (phone != null && phone.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          DetailValueCard(
            icon: LucideIcons.phone,
            label: 'WhatsApp',
            value: phone,
          ),
        ],
        if (client.email != null) ...[
          const SizedBox(height: AppSpacing.md),
          DetailValueCard(
            icon: LucideIcons.mail,
            label: 'E-mail',
            value: client.email!,
          ),
        ],
        if (client.address != null) ...[
          const SizedBox(height: AppSpacing.md),
          DetailValueCard(
            icon: LucideIcons.map_pin,
            label: 'Endereço',
            value: client.address!,
            maxLines: 4,
          ),
        ],
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
