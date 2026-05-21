import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_bar_actions.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../providers/payments_providers.dart';

class PaymentsListPage extends ConsumerWidget {
  const PaymentsListPage({super.key, required this.loanId});

  final String loanId;

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return iso;
    final local = parsed.toLocal();
    final d = local.day.toString().padLeft(2, '0');
    final m = local.month.toString().padLeft(2, '0');
    return '$d/$m/${local.year}';
  }

  String _formatMethod(String? method) {
    if (method == null || method.isEmpty) return '—';
    const labels = {
      'dinheiro': 'Dinheiro',
      'pix': 'PIX',
      'transferencia': 'Transferência',
      'outro': 'Outro',
    };
    return labels[method] ?? method;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(paymentsByLoanProvider(loanId));
    final loanAsync = ref.watch(loanForPaymentsProvider(loanId));

    final loanLabel = loanAsync.valueOrNull != null
        ? 'R\$ ${loanAsync.value!.amount}'
        : 'Empréstimo';

    return Scaffold(
      appBar: AppBar(
        title: Text('Pagamentos — $loanLabel'),
        actions: const [
          AppBarActions(showSync: false, showLogout: false),
        ],
      ),
      body: paymentsAsync.when(
        data: (payments) {
          if (payments.isEmpty) {
            return const AppEmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Nenhum pagamento',
              subtitle: 'Registre o primeiro pagamento deste empréstimo.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: payments.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              final payment = payments[index];
              return AppCard(
                onTap: () => context.push(AppRoutes.paymentEdit(payment.id)),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.12),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: const Icon(
                        Icons.receipt_long_outlined,
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'R\$ ${payment.amount}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            [
                              _formatDate(payment.paymentDate),
                              _formatMethod(payment.method),
                            ].join(' · '),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded),
                  ],
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
        onPressed: () => context.push(AppRoutes.paymentNew(loanId)),
        icon: const Icon(Icons.add),
        label: const Text('Novo pagamento'),
      ),
    );
  }
}
