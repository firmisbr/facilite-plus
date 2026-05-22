import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/utils/whatsapp_utils.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_page_header.dart';
import '../../../../shared/widgets/attention_lucide_icon.dart';
import '../../../../shared/widgets/floating_notched_nav_bar.dart';
import '../../../loans/domain/loan_simulator.dart';
import '../../../loans/presentation/providers/loans_providers.dart';
import '../../domain/payment_list_filter.dart';
import '../../domain/payments_overview.dart';
import '../providers/payments_overview_filter_provider.dart';
import '../providers/payments_overview_providers.dart';
import '../providers/payments_providers.dart';
import '../widgets/payment_list_card.dart';

class PaymentsOverviewPage extends ConsumerStatefulWidget {
  const PaymentsOverviewPage({super.key, this.inShell = false});

  /// Aba da barra inferior (sem botão voltar).
  final bool inShell;

  @override
  ConsumerState<PaymentsOverviewPage> createState() =>
      _PaymentsOverviewPageState();
}

class _PaymentsOverviewPageState extends ConsumerState<PaymentsOverviewPage> {
  PaymentListFilter _filter = PaymentListFilter.atrasados;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _consumePendingFilter());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _consumePendingFilter() {
    final pending = ref.read(paymentsOverviewFilterRequestProvider);
    if (pending == null || !mounted) return;
    setState(() => _filter = pending);
    ref.read(paymentsOverviewFilterRequestProvider.notifier).state = null;
  }

  void _toggleFilter(PaymentListFilter filter) {
    setState(() {
      _filter = _filter == filter ? PaymentListFilter.todos : filter;
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<PaymentListFilter?>(
      paymentsOverviewFilterRequestProvider,
      (previous, next) {
        if (next == null) return;
        _consumePendingFilter();
      },
    );

    final brightness = Theme.of(context).brightness;

    final body = DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppDecorations.screenBackground(brightness),
      ),
      child: SafeArea(
        bottom: false,
        child: ref.watch(paymentsOverviewProvider).when(
              data: (overview) => RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(allLoansProvider);
                  ref.invalidate(allPaymentsForUserProvider);
                  ref.invalidate(paymentsOverviewProvider);
                  await Future<void>.delayed(
                    const Duration(milliseconds: 400),
                  );
                },
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    if (widget.inShell)
                      SliverToBoxAdapter(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: AppSpacing.maxContentWidth,
                            ),
                            child: const AppPageHeader(
                              title: 'Cobranças',
                              subtitle:
                                  'Parcelas em aberto e contatos por cliente.',
                              centered: true,
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
                            padding: EdgeInsets.fromLTRB(
                              AppSpacing.lg,
                              widget.inShell ? 0 : AppSpacing.md,
                              AppSpacing.lg,
                              AppSpacing.sm,
                            ),
                            child: _PaymentsSummaryCard(overview: overview),
                          ),
                        ),
                      ),
                    ),
                    if (overview.loanCards.isNotEmpty)
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
                                AppSpacing.sm,
                              ),
                              child: _PaymentsPortfolioCard(
                                counts: PaymentPortfolioCounts.fromCards(
                                  overview.loanCards,
                                ),
                                selected: _filter,
                                onFilterTap: _toggleFilter,
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (overview.loanCards.isNotEmpty)
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
                                AppSpacing.sm,
                              ),
                              child: _PaymentsSearchField(
                                key: const ValueKey('payments-search-field'),
                                controller: _searchController,
                              ),
                            ),
                          ),
                        ),
                      ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: AppSpacing.md),
                    ),
                    _buildFilteredListSliver(
                      overview: overview,
                      filter: _filter,
                      searchController: _searchController,
                    ),
                  ],
                ),
              ),
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: AppEmptyState(
                    icon: LucideIcons.circle_alert,
                    title: 'Erro ao carregar',
                    subtitle: e.toString(),
                  ),
                ),
              ),
            ),
      ),
    );

    if (widget.inShell) {
      return Scaffold(extendBody: true, body: body);
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Cobranças'),
      ),
      body: body,
    );
  }

  Widget _buildFilteredListSliver({
    required PaymentsOverview overview,
    required PaymentListFilter filter,
    required TextEditingController searchController,
  }) {
    return ListenableBuilder(
      listenable: searchController,
      builder: (context, _) {
        final query = searchController.text;
        final filtered = PaymentListFilterHelper.apply(
          items: overview.loanCards,
          filter: filter,
        );
        final cards = PaymentListFilterHelper.search(
          items: filtered,
          query: query,
        );

        if (overview.loanCards.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppSpacing.maxContentWidth,
                ),
                child: const Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: AppEmptyState(
                    icon: LucideIcons.circle_check,
                    title: 'Tudo em dia',
                    subtitle:
                        'Nenhuma parcela pendente no momento. '
                        'Novas cobranças aparecem aqui automaticamente.',
                  ),
                ),
              ),
            ),
          );
        }

        if (cards.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppSpacing.maxContentWidth,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: AppEmptyState(
                    icon: query.trim().isNotEmpty
                        ? LucideIcons.search
                        : _emptyIcon(filter),
                    title: query.trim().isNotEmpty
                        ? 'Nenhum resultado'
                        : _emptyTitle(filter),
                    subtitle: query.trim().isNotEmpty
                        ? 'Tente outro nome ou valor.'
                        : _emptySubtitle(filter),
                  ),
                ),
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            kBottomNavReservedHeight + AppSpacing.lg,
          ),
          sliver: SliverList.separated(
            itemCount: cards.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final item = cards[index];
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppSpacing.maxContentWidth,
                  ),
                  child: PaymentListCard(
                    item: item,
                    onWhatsApp: () => _openWhatsApp(context, item),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  static IconData _emptyIcon(PaymentListFilter filter) => switch (filter) {
        PaymentListFilter.atrasados => LucideIcons.circle_check,
        PaymentListFilter.aVencer => LucideIcons.calendar,
        PaymentListFilter.todos => LucideIcons.wallet,
      };

  static String _emptyTitle(PaymentListFilter filter) => switch (filter) {
        PaymentListFilter.atrasados => 'Nenhum empréstimo em atraso',
        PaymentListFilter.aVencer => 'Nenhuma parcela a vencer',
        PaymentListFilter.todos => 'Nenhuma cobrança',
      };

  static String _emptySubtitle(PaymentListFilter filter) => switch (filter) {
        PaymentListFilter.atrasados =>
          'Ótimo! Nenhuma parcela vencida pendente.',
        PaymentListFilter.aVencer =>
          'Nenhum empréstimo com a próxima parcela em dia.',
        PaymentListFilter.todos =>
          'Empréstimos quitados ou sem saldo em aberto.',
      };

  Future<void> _openWhatsApp(
    BuildContext context,
    PaymentLoanCardItem item,
  ) async {
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
}

class _PaymentsSummaryCard extends StatelessWidget {
  const _PaymentsSummaryCard({required this.overview});

  final PaymentsOverview overview;

  @override
  Widget build(BuildContext context) {
    final hasOverdue = overview.totalOverdue > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: context.appTheme.border),
        boxShadow: context.appTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Total a receber',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: context.appTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            LoanSimulator.formatMoney(overview.totalToReceive),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.accent,
                  height: 1.1,
                ),
          ),
          if (hasOverdue) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration:
                        AppDecorations.iconBadge(color: AppColors.error),
                    child: const AttentionLucideIcon(
                      icon: LucideIcons.triangle_alert,
                      size: 20,
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Em atraso',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppColors.error,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        Text(
                          LoanSimulator.formatMoney(overview.totalOverdue),
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.error,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${overview.clientsOverdueCount}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.error,
                            ),
                      ),
                      Text(
                        overview.clientsOverdueCount == 1
                            ? 'cliente'
                            : 'clientes',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: context.appTheme.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PaymentsPortfolioCard extends StatelessWidget {
  const _PaymentsPortfolioCard({
    required this.counts,
    required this.selected,
    required this.onFilterTap,
  });

  final PaymentPortfolioCounts counts;
  final PaymentListFilter selected;
  final ValueChanged<PaymentListFilter> onFilterTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: context.appTheme.border),
        boxShadow: context.appTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Toque para filtrar · toque de novo no mesmo para ver todos',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: context.appTheme.textSecondary,
                  fontSize: 11,
                  height: 1.35,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _PaymentFilterStat(
                    icon: LucideIcons.triangle_alert,
                    label: 'Atrasados',
                    count: counts.atrasados,
                    color: AppColors.error,
                    selected: selected == PaymentListFilter.atrasados,
                    onTap: () => onFilterTap(PaymentListFilter.atrasados),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _PaymentFilterStat(
                    icon: LucideIcons.calendar_clock,
                    label: 'A vencer',
                    count: counts.aVencer,
                    color: AppColors.info,
                    selected: selected == PaymentListFilter.aVencer,
                    onTap: () => onFilterTap(PaymentListFilter.aVencer),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _PaymentFilterStat(
                    icon: LucideIcons.layers,
                    label: 'Todos',
                    count: counts.total,
                    color: AppColors.accent,
                    selected: selected == PaymentListFilter.todos,
                    onTap: () => onFilterTap(PaymentListFilter.todos),
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

class _PaymentFilterStat extends StatelessWidget {
  const _PaymentFilterStat({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final int count;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.14)
                : context.appTheme.border.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: selected
                  ? color.withValues(alpha: 0.55)
                  : context.appTheme.border,
              width: selected ? 1.5 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? color : context.appTheme.textSecondary,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: selected
                          ? color
                          : context.appTheme.textSecondary,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '$count',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: selected ? color : null,
                      height: 1,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentsSearchField extends StatefulWidget {
  const _PaymentsSearchField({
    required this.controller,
    super.key,
  });

  final TextEditingController controller;

  @override
  State<_PaymentsSearchField> createState() => _PaymentsSearchFieldState();
}

class _PaymentsSearchFieldState extends State<_PaymentsSearchField> {
  late final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() => setState(() {});

  void _clear() {
    widget.controller.clear();
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final showClear = widget.controller.text.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: context.appTheme.border),
        boxShadow: context.appTheme.cardShadow,
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        autofocus: false,
        enableSuggestions: false,
        autocorrect: false,
        textInputAction: TextInputAction.search,
        style: Theme.of(context).textTheme.bodyMedium,
        decoration: InputDecoration(
          hintText: 'Buscar por cliente ou valor',
          prefixIcon: Icon(
            LucideIcons.search,
            size: 20,
            color: context.appTheme.textSecondary,
          ),
          suffixIcon: showClear
              ? IconButton(
                  tooltip: 'Limpar busca',
                  icon: Icon(
                    LucideIcons.circle_x,
                    size: 20,
                    color: context.appTheme.textSecondary,
                  ),
                  onPressed: _clear,
                )
              : null,
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md + 2,
          ),
        ),
      ),
    );
  }
}
