import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_bar_actions.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_page_header.dart';
import '../../../../shared/widgets/app_page_scaffold.dart';
import '../../domain/entities/loan_with_client.dart';
import '../providers/loans_providers.dart';
import '../widgets/loan_list_card.dart';

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

  @override
  Widget build(BuildContext context) {
    final loansAsync = ref.watch(allLoansProvider);

    return AppPageScaffold(
      title: 'Empréstimos',
      actions: const [
        AppBarActions(showSync: false, showLogout: false),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.loanCreate),
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
                      return LoanListCard(item: loans[index]);
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
