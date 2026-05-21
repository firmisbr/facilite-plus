import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/loan_installment_status.dart';
import '../../domain/loan_simulator.dart';
import '../../../../shared/widgets/app_bar_actions.dart';
import '../../../../shared/widgets/app_card.dart';
import '../providers/loan_detail_providers.dart';

class LoanDetailPage extends ConsumerWidget {
  const LoanDetailPage({super.key, required this.loanId});

  final String loanId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bundle = ref.watch(loanDetailProvider(loanId));
    final isLoading = ref.watch(loanDetailLoadingProvider(loanId));

    if (isLoading && bundle == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
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
      appBar: AppBar(
        title: Text(client.name),
        actions: [
          IconButton(
            tooltip: 'Editar',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push(AppRoutes.loanEdit(loanId)),
          ),
          IconButton(
            tooltip: 'Pagamentos',
            icon: const Icon(Icons.receipt_long_outlined),
            onPressed: () => context.push(AppRoutes.loanPayments(loanId)),
          ),
          const AppBarActions(showSync: false, showLogout: false),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SectionHeader(title: 'Dados pessoais'),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _InfoRow(label: 'Nome', value: client.name),
                      if (client.document != null)
                        _InfoRow(label: 'CPF', value: client.document!),
                      if (client.phone != null)
                        _InfoRow(label: 'WhatsApp', value: client.phone!),
                      if (client.email != null)
                        _InfoRow(label: 'E-mail', value: client.email!),
                      if (client.address != null)
                        _InfoRow(label: 'Endereço', value: client.address!),
                    ],
                  ),
                ),
                if (detail != null) ...[
                  const SizedBox(height: AppSpacing.xl),
                  _SectionHeader(title: 'Visão do gerente'),
                  AppCard(
                    child: Column(
                      children: [
                        _MetricGrid(
                          items: [
                            _MetricItem(
                              label: 'Valor emprestado',
                              value: LoanSimulator.formatMoney(
                                detail.manager.principal,
                              ),
                            ),
                            _MetricItem(
                              label: 'Total com juros',
                              value: LoanSimulator.formatMoney(
                                detail.manager.totalWithInterest,
                              ),
                            ),
                            _MetricItem(
                              label: 'Parcelas',
                              value: '${detail.manager.installmentCount}',
                            ),
                            _MetricItem(
                              label: 'Valor da parcela',
                              value: LoanSimulator.formatMoney(
                                detail.manager.installmentAmount,
                              ),
                            ),
                            _MetricItem(
                              label: 'Taxa de juros',
                              value:
                                  '${detail.manager.monthlyInterestPercent.toStringAsFixed(2)}% a.m.',
                            ),
                            _MetricItem(
                              label: 'Periodicidade',
                              value: detail.manager.periodicityLabel,
                            ),
                            _MetricItem(
                              label: 'Lucro total',
                              value: LoanSimulator.formatMoney(
                                detail.manager.totalProfit,
                              ),
                              highlight: true,
                            ),
                            _MetricItem(
                              label: 'Lucro por parcela',
                              value: LoanSimulator.formatMoney(
                                detail.manager.profitPerInstallment,
                              ),
                              highlight: true,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _SectionHeader(title: 'Parcelas'),
                  ...detail.installments.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: AppCard(
                        child: Row(
                          children: [
                            _InstallmentBadge(number: item.number),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      _StatusChip(status: item.status),
                                      const Spacer(),
                                      Text(
                                        LoanSimulator.formatMoney(item.amount),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    'Vencimento: ${LoanSimulator.formatDate(item.dueDate)}',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _SectionHeader(title: 'Visão geral'),
                  AppCard(
                    child: Column(
                      children: [
                        _OverviewRow(
                          label: 'Já pago',
                          value: LoanSimulator.formatMoney(
                            detail.overview.paidAmount,
                          ),
                        ),
                        _OverviewRow(
                          label: 'Falta pagar',
                          value: LoanSimulator.formatMoney(
                            detail.overview.remainingAmount,
                          ),
                        ),
                        _OverviewRow(
                          label: 'Parcelas pagas',
                          value:
                              '${detail.overview.paidInstallments} de ${detail.overview.totalInstallments}',
                        ),
                        _OverviewRow(
                          label: 'Parcelas restantes',
                          value: '${detail.overview.remainingInstallments}',
                        ),
                        _OverviewRow(
                          label: 'Parcelas em atraso',
                          value: '${detail.overview.overdueInstallments}',
                          alert: detail.overview.overdueInstallments > 0,
                        ),
                        _OverviewRow(
                          label: 'Próximo vencimento',
                          value: detail.overview.nextDueDate != null
                              ? LoanSimulator.formatDate(
                                  detail.overview.nextDueDate!,
                                )
                              : '—',
                        ),
                      ],
                    ),
                  ),
                ] else
                  AppCard(
                    child: Text(
                      'Complete parcelas, juros e vencimento do empréstimo '
                      'para ver o cronograma e resumos.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }
}

class _MetricItem {
  const _MetricItem({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.items});

  final List<_MetricItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth > 400;
        final children = items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 2),
                Text(
                  item.value,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: item.highlight ? AppColors.accent : null,
                        fontWeight:
                            item.highlight ? FontWeight.w700 : FontWeight.w600,
                      ),
                ),
              ],
            ),
          );
        }).toList();

        if (!twoColumns) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          );
        }

        return Wrap(
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.sm,
          children: children
              .map(
                (c) => SizedBox(
                  width: (constraints.maxWidth - AppSpacing.lg) / 2,
                  child: c,
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _OverviewRow extends StatelessWidget {
  const _OverviewRow({
    required this.label,
    required this.value,
    this.alert = false,
  });

  final String label;
  final String value;
  final bool alert;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: alert ? AppColors.error : null,
                ),
          ),
        ],
      ),
    );
  }
}

class _InstallmentBadge extends StatelessWidget {
  const _InstallmentBadge({required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 18,
      backgroundColor: AppColors.accent.withValues(alpha: 0.15),
      child: Text(
        '$number',
        style: const TextStyle(
          color: AppColors.accent,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final LoanInstallmentStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      LoanInstallmentStatus.paid => AppColors.lightTextSecondary,
      LoanInstallmentStatus.overdue => AppColors.error,
      LoanInstallmentStatus.pending => AppColors.accent,
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        status.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
