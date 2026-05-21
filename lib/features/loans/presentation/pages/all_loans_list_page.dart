import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../clients/domain/entities/client.dart';
import '../../../clients/presentation/providers/clients_providers.dart';
import '../../../../shared/widgets/app_bar_actions.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_page_header.dart';
import '../../../../shared/widgets/app_page_scaffold.dart';
import '../../domain/entities/loan_with_client.dart';
import '../providers/loans_providers.dart';

enum _LoanFilter { ativos, todos, quitados, atrasados }

class AllLoansListPage extends ConsumerStatefulWidget {
  const AllLoansListPage({super.key});

  @override
  ConsumerState<AllLoansListPage> createState() => _AllLoansListPageState();
}

class _AllLoansListPageState extends ConsumerState<AllLoansListPage> {
  _LoanFilter _filter = _LoanFilter.ativos;

  List<LoanWithClient> _applyFilter(List<LoanWithClient> items) {
    return switch (_filter) {
      _LoanFilter.todos => items,
      _LoanFilter.ativos =>
        items.where((e) => (e.loan.status ?? 'ativo') == 'ativo').toList(),
      _LoanFilter.quitados =>
        items.where((e) => e.loan.status == 'quitado').toList(),
      _LoanFilter.atrasados =>
        items.where((e) => e.loan.status == 'atrasado').toList(),
    };
  }

  String _statusLabel(String? status) {
    return switch (status) {
      'quitado' => 'Quitado',
      'atrasado' => 'Atrasado',
      _ => 'Ativo',
    };
  }

  Color _statusColor(String? status) {
    return switch (status) {
      'quitado' => AppColors.lightTextSecondary,
      'atrasado' => AppColors.error,
      _ => AppColors.accent,
    };
  }

  Future<void> _pickClientAndCreateLoan() async {
    final clients = ref.read(clientsStreamProvider).valueOrNull;
    if (clients == null || clients.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cadastre um cliente antes de criar um empréstimo.'),
        ),
      );
      return;
    }

    final client = await showModalBottomSheet<Client>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: Text(
                'Empréstimo para qual cliente?',
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: clients.length,
                itemBuilder: (context, index) {
                  final c = clients[index];
                  return ListTile(
                    title: Text(c.name),
                    onTap: () => Navigator.pop(ctx, c),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );

    if (client != null && mounted) {
      context.push(AppRoutes.loanNew(client.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loansAsync = ref.watch(allLoansProvider);

    return AppPageScaffold(
      title: 'Empréstimos',
      actions: const [
        AppBarActions(showSync: false, showLogout: false),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _pickClientAndCreateLoan,
        icon: const Icon(Icons.add),
        label: const Text('Novo empréstimo'),
      ),
      body: loansAsync.when(
        data: (allLoans) {
          final loans = _applyFilter(allLoans);

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const AppPageHeader(
                      title: 'Empréstimos atuais',
                      subtitle:
                          'Visão geral de todos os empréstimos dos seus clientes.',
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      child: Row(
                        children: [
                          _FilterChip(
                            label: 'Ativos',
                            selected: _filter == _LoanFilter.ativos,
                            onSelected: () =>
                                setState(() => _filter = _LoanFilter.ativos),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          _FilterChip(
                            label: 'Todos',
                            selected: _filter == _LoanFilter.todos,
                            onSelected: () =>
                                setState(() => _filter = _LoanFilter.todos),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          _FilterChip(
                            label: 'Quitados',
                            selected: _filter == _LoanFilter.quitados,
                            onSelected: () =>
                                setState(() => _filter = _LoanFilter.quitados),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          _FilterChip(
                            label: 'Atrasados',
                            selected: _filter == _LoanFilter.atrasados,
                            onSelected: () =>
                                setState(() => _filter = _LoanFilter.atrasados),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ),
              ),
              if (loans.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: AppEmptyState(
                    icon: Icons.account_balance_wallet_outlined,
                    title: _filter == _LoanFilter.ativos
                        ? 'Nenhum empréstimo ativo'
                        : 'Nenhum empréstimo',
                    subtitle: _filter == _LoanFilter.ativos
                        ? 'Cadastre um empréstimo ou altere o filtro acima.'
                        : 'Nenhum registro neste filtro.',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.xxl + 72,
                  ),
                  sliver: SliverList.separated(
                    itemCount: loans.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, index) {
                      final item = loans[index];
                      final loan = item.loan;
                      final status = loan.status ?? 'ativo';
                      final details = [
                        if (loan.installments != null)
                          '${loan.installments}x',
                        if (loan.interest != null) 'juros ${loan.interest}%',
                      ].join(' · ');

                      return AppCard(
                        onTap: () => context.push(AppRoutes.loanEdit(loan.id)),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              decoration: BoxDecoration(
                                color: AppColors.accent
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusSm,
                                ),
                              ),
                              child: const Icon(
                                Icons.account_balance_wallet_outlined,
                                color: AppColors.accent,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.clientName,
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    'R\$ ${loan.amount}',
                                    style:
                                        Theme.of(context).textTheme.bodyLarge,
                                  ),
                                  if (details.isNotEmpty) ...[
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      details,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.sm,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _statusColor(status)
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusSm,
                                    ),
                                  ),
                                  child: Text(
                                    _statusLabel(status),
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: _statusColor(status),
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                IconButton(
                                  tooltip: 'Pagamentos',
                                  onPressed: () => context.push(
                                    AppRoutes.loanPayments(loan.id),
                                  ),
                                  icon: const Icon(
                                    Icons.receipt_long_outlined,
                                  ),
                                  color: AppColors.accent,
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppEmptyState(
          icon: Icons.error_outline,
          title: 'Erro ao carregar',
          subtitle: e.toString(),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: AppColors.accent.withValues(alpha: 0.2),
      checkmarkColor: AppColors.accent,
    );
  }
}
