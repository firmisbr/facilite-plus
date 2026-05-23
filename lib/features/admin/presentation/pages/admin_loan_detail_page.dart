import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../clients/domain/entities/client.dart';
import '../../../loans/domain/loan_installment_status.dart';
import '../../../loans/domain/loan_simulator.dart';
import '../../../../shared/utils/br_cpf_input_formatter.dart';
import '../../../../shared/utils/br_phone_input_formatter.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/detail_value_card.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_app_bar_actions.dart';
import '../widgets/admin_installment_tile.dart';

class AdminLoanDetailPage extends ConsumerWidget {
  const AdminLoanDetailPage({
    super.key,
    required this.userId,
    required this.loanId,
  });

  final String userId;
  final String loanId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bundleAsync =
        ref.watch(adminLoanDetailProvider((userId, loanId)));
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Empréstimo'),
        actions: const [AdminAppBarActions()],
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppDecorations.screenBackground(brightness),
        ),
        child: SafeArea(
          child: bundleAsync.when(
            data: (bundle) {
              if (bundle == null || bundle.detail == null) {
                return const Center(
                  child: AppEmptyState(
                    icon: LucideIcons.circle_alert,
                    title: 'Dados incompletos',
                    subtitle:
                        'Empréstimo sem cronograma (parcelas, juros ou vencimento).',
                  ),
                );
              }
              return _LoanDetailBody(bundle: bundle);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
          ),
        ),
      ),
    );
  }
}

class _LoanDetailBody extends ConsumerWidget {
  const _LoanDetailBody({required this.bundle});

  final AdminLoanDetailBundle bundle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = bundle.detail!;
    final overview = detail.overview;
    final manager = detail.manager;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(adminLoanDetailProvider((bundle.client.userId, bundle.loan.id)));
        await ref.read(
          adminLoanDetailProvider((bundle.client.userId, bundle.loan.id)).future,
        );
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppSpacing.maxContentWidth,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        bundle.clientName,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Somente leitura — painel administrativo',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _FinancialSummaryCard(manager: manager, overview: overview),
                      const SizedBox(height: AppSpacing.md),
                      _ClientInfoSection(client: bundle.client),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppSpacing.maxContentWidth,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.sm,
                  ),
                  child: Text(
                    'Parcelas (${overview.paidInstallments}/${overview.totalInstallments} pagas)',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            sliver: SliverList.separated(
              itemCount: detail.installments.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final item = detail.installments[index];
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppSpacing.maxContentWidth,
                    ),
                    child: AdminInstallmentTile(item: item),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FinancialSummaryCard extends StatelessWidget {
  const _FinancialSummaryCard({
    required this.manager,
    required this.overview,
  });

  final LoanManagerStats manager;
  final LoanOverviewStats overview;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: Theme.of(context).dividerColor),
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
                  label: 'Principal',
                  value: LoanSimulator.formatMoney(manager.principal),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: DetailCompactCell(
                  label: 'Total c/ juros',
                  value: LoanSimulator.formatMoney(manager.totalWithInterest),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: DetailCompactCell(
                  label: 'Recebido',
                  value: LoanSimulator.formatMoney(overview.paidAmount),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: DetailCompactCell(
                  label: 'Em aberto',
                  value: LoanSimulator.formatMoney(overview.remainingAmount),
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
                  label: 'Lucro em aberto',
                  value: LoanSimulator.formatMoney(overview.remainingProfit),
                  valueColor: AppColors.accent,
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

    return DetailInfoListCard(title: 'Dados do cliente', entries: entries);
  }
}
