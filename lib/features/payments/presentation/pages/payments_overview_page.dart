import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/utils/whatsapp_utils.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_metric_card.dart';
import '../../../../shared/widgets/app_page_header.dart';
import '../../../../shared/widgets/app_page_scaffold.dart';
import '../../../../shared/widgets/app_section_title.dart';
import '../../../../shared/widgets/floating_notched_nav_bar.dart';
import '../../../loans/domain/loan_simulator.dart';
import '../../../loans/presentation/providers/loans_providers.dart';
import '../../domain/payments_overview.dart';
import '../providers/payments_overview_providers.dart';
import '../providers/payments_providers.dart';

class PaymentsOverviewPage extends ConsumerWidget {
  const PaymentsOverviewPage({super.key, this.inShell = false});

  /// Aba da barra inferior (sem botão voltar).
  final bool inShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref.watch(paymentsOverviewProvider);
    final bottomPad = inShell ? kBottomNavReservedHeight + AppSpacing.lg : AppSpacing.lg;

    return AppPageScaffold(
      title: 'Cobranças',
      showBackButton: !inShell,
      body: overviewAsync.when(
        data: (overview) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(allLoansProvider);
              ref.invalidate(allPaymentsForUserProvider);
              ref.invalidate(paymentsOverviewProvider);
              await Future<void>.delayed(const Duration(milliseconds: 400));
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                const SliverToBoxAdapter(
                  child: AppPageHeader(
                    title: 'Cobranças',
                    subtitle:
                        'Valores em aberto, atrasos e parcelas a vencer nos próximos 7 dias.',
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: AppSpacing.md,
                      crossAxisSpacing: AppSpacing.md,
                      childAspectRatio: 1.15,
                    ),
                    delegate: SliverChildListDelegate([
                      AppMetricCard(
                        icon: Icons.schedule_outlined,
                        label: 'Total a receber',
                        value: LoanSimulator.formatMoney(overview.totalToReceive),
                        color: AppColors.accent,
                      ),
                      AppMetricCard(
                        icon: Icons.warning_amber_rounded,
                        label: 'Total em atraso',
                        value: LoanSimulator.formatMoney(overview.totalOverdue),
                        color: AppColors.error,
                        accent: AppCardAccent.error,
                      ),
                      AppMetricCard(
                        icon: Icons.person_off_outlined,
                        label: 'Clientes em atraso',
                        value: '${overview.clientsOverdueCount}',
                        subtitle: 'com parcela vencida',
                      ),
                      AppMetricCard(
                        icon: Icons.event_available_outlined,
                        label: 'A vencer (7 dias)',
                        value: '${overview.clientsDueSoonCount}',
                        subtitle: 'clientes',
                        color: AppColors.info,
                      ),
                    ]),
                  ),
                ),
                if (overview.loanCards.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: AppEmptyState(
                      icon: Icons.payments_outlined,
                      title: 'Nenhuma cobrança em aberto',
                      subtitle:
                          'Empréstimos quitados ou sem parcelas pendentes aparecerão aqui quando houver saldo.',
                    ),
                  )
                else
                  const SliverToBoxAdapter(
                    child: AppSectionTitle(title: 'Empréstimos'),
                  ),
                if (overview.loanCards.isNotEmpty)
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      bottomPad,
                    ),
                    sliver: SliverList.separated(
                      itemCount: overview.loanCards.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, index) {
                        return _PaymentLoanCard(
                          item: overview.loanCards[index],
                        );
                      },
                    ),
                  ),
              ],
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

class _PaymentLoanCard extends StatelessWidget {
  const _PaymentLoanCard({required this.item});

  final PaymentLoanCardItem item;

  Future<void> _openWhatsApp(BuildContext context) async {
    final message = WhatsAppUtils.overdueCollectionMessage(
      clientName: item.clientName,
      overdueInstallments: item.overdueInstallments,
      overdueAmountFormatted: LoanSimulator.formatMoney(item.overdueAmount),
      nextDueFormatted: item.nextDueDate != null
          ? LoanSimulator.formatDate(item.nextDueDate!)
          : null,
    );

    final opened = await WhatsAppUtils.openCollectionChat(
      phone: item.clientPhone,
      message: message,
    );

    if (!context.mounted) return;

    if (!opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível abrir o WhatsApp. Verifique o telefone do cliente.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loan = item.loanItem.loan;
    final statusParts = <String>[];

    if (item.hasOverdue) {
      statusParts.add(
        '${item.overdueInstallments} em atraso · '
        '${LoanSimulator.formatMoney(item.overdueAmount)}',
      );
    }
    if (item.hasDueSoon) {
      statusParts.add('${item.dueSoonInstallments} a vencer');
    }

    final canWhatsApp =
        item.hasOverdue && WhatsAppUtils.normalizeBrazilPhone(item.clientPhone) != null;

    return AppCard(
      accent: item.hasOverdue ? AppCardAccent.error : AppCardAccent.none,
      onTap: () => context.push(AppRoutes.loanDetail(loan.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.clientName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Saldo: ${LoanSimulator.formatMoney(item.remainingAmount)}',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
              if (canWhatsApp)
                IconButton(
                  tooltip: 'Cobrar no WhatsApp',
                  onPressed: () => _openWhatsApp(context),
                  icon: const Icon(Icons.chat_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366).withValues(alpha: 0.15),
                    foregroundColor: const Color(0xFF25D366),
                  ),
                )
              else if (item.hasOverdue)
                Icon(
                  Icons.phone_disabled_outlined,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 22,
                ),
              const SizedBox(width: AppSpacing.xs),
              Icon(
                Icons.chevron_right_rounded,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
          if (statusParts.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                if (item.hasOverdue) _StatusBadge.overdue(statusParts.first),
                if (item.hasDueSoon)
                  _StatusBadge.dueSoon('${item.dueSoonInstallments} parcela(s) a vencer'),
              ],
            ),
          ],
          if (item.nextDueDate != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(
                  Icons.event_outlined,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Próximo vencimento: ${LoanSimulator.formatDate(item.nextDueDate!)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge._({
    required this.label,
    required this.color,
  });

  factory _StatusBadge.overdue(String label) =>
      _StatusBadge._(label: label, color: AppColors.error);

  factory _StatusBadge.dueSoon(String label) =>
      _StatusBadge._(label: label, color: AppColors.info);

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
