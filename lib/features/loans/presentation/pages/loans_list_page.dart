import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_bar_actions.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/floating_notched_nav_bar.dart';
import '../providers/loans_providers.dart';
import '../widgets/loan_list_card.dart';
import '../../domain/entities/loan_with_client.dart';

class LoansListPage extends ConsumerWidget {
  const LoansListPage({super.key, required this.clientId});

  final String clientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loansAsync = ref.watch(loansByClientProvider(clientId));
    final clientAsync = ref.watch(clientForLoansProvider(clientId));

    final clientName = clientAsync.valueOrNull?.name ?? 'Cliente';

    return Scaffold(
      appBar: AppBar(
        title: Text('Empréstimos — $clientName'),
        actions: const [
          AppBarActions(showSync: false, showLogout: false),
        ],
      ),
      body: loansAsync.when(
        data: (loans) {
          if (loans.isEmpty) {
            return const AppEmptyState(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Nenhum empréstimo',
              subtitle: 'Cadastre o primeiro empréstimo deste cliente.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              kBottomNavReservedHeight + AppSpacing.xxl + 48,
            ),
            itemCount: loans.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              final loan = loans[index];
              return LoanListCard(
                item: LoanWithClient(
                  loan: loan,
                  clientName: clientName,
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppEmptyState(
          icon: Icons.error_outline,
          title: 'Erro ao carregar',
          subtitle: e.toString(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.loanNew(clientId)),
        icon: const Icon(Icons.add),
        label: const Text('Novo empréstimo'),
      ),
    );
  }
}
