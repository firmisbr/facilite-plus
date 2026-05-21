import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_bar_actions.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_page_header.dart';
import '../../../../shared/widgets/app_page_scaffold.dart';
import '../../../payments/presentation/providers/payments_providers.dart';
import '../../domain/loan_list_filter.dart';
import '../providers/loans_providers.dart';
import '../../../../shared/widgets/app_filter_chip.dart';
import '../widgets/loan_list_card.dart';

class AllLoansListPage extends ConsumerStatefulWidget {
  const AllLoansListPage({super.key});

  @override
  ConsumerState<AllLoansListPage> createState() => _AllLoansListPageState();
}

class _AllLoansListPageState extends ConsumerState<AllLoansListPage> {
  LoanListFilter _filter = LoanListFilter.ativos;

  @override
  Widget build(BuildContext context) {
    final loansAsync = ref.watch(allLoansProvider);
    final paymentsAsync = ref.watch(allPaymentsForUserProvider);

    return AppPageScaffold(
      title: 'Empréstimos',
      actions: const [AppBarActions(showSync: false, showLogout: false)],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.loanCreate),
        icon: const Icon(Icons.add),
        label: const Text('Novo empréstimo'),
      ),
      body: loansAsync.when(
        data: (allLoans) {
          return paymentsAsync.when(
            data: (payments) {
              final loans = LoanListFilterHelper.apply(
                items: allLoans,
                payments: payments,
                filter: _filter,
              );

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
                          AppFilterChip(
                            label: 'Ativos',
                            selected: _filter == LoanListFilter.ativos,
                            onSelected: () => setState(
                              () => _filter = LoanListFilter.ativos,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          AppFilterChip(
                            label: 'Todos',
                            selected: _filter == LoanListFilter.todos,
                            onSelected: () => setState(
                              () => _filter = LoanListFilter.todos,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          AppFilterChip(
                            label: 'Quitados',
                            selected: _filter == LoanListFilter.quitados,
                            onSelected: () => setState(
                              () => _filter = LoanListFilter.quitados,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          AppFilterChip(
                            label: 'Atrasados',
                            selected: _filter == LoanListFilter.atrasados,
                            onSelected: () => setState(
                              () => _filter = LoanListFilter.atrasados,
                            ),
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
                        title: _filter == LoanListFilter.ativos
                            ? 'Nenhum empréstimo ativo'
                            : 'Nenhum empréstimo',
                        subtitle: _filter == LoanListFilter.ativos
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
              title: 'Erro ao carregar pagamentos',
              subtitle: e.toString(),
            ),
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
