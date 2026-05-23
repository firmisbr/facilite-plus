import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_page_header.dart';
import '../../../../shared/widgets/floating_notched_nav_bar.dart';
import '../../../payments/presentation/providers/payments_providers.dart';
import '../../domain/loan_list_filter.dart';
import '../providers/loan_list_layout_provider.dart';
import '../providers/loans_providers.dart';
import '../widgets/loan_list_tile.dart';

class AllLoansListPage extends ConsumerStatefulWidget {
  const AllLoansListPage({super.key});

  @override
  ConsumerState<AllLoansListPage> createState() => _AllLoansListPageState();
}

class _AllLoansListPageState extends ConsumerState<AllLoansListPage> {
  LoanListFilter _filter = LoanListFilter.ativos;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleFilter(LoanListFilter filter) {
    setState(() {
      _filter = _filter == filter ? LoanListFilter.todos : filter;
    });
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final layout = ref.watch(loanListLayoutProvider);

    return Scaffold(
      extendBody: true,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppDecorations.screenBackground(brightness),
        ),
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(allLoansProvider);
              ref.invalidate(allPaymentsForUserProvider);
              await Future<void>.delayed(const Duration(milliseconds: 400));
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
                      child: const AppPageHeader(
                        title: 'Empréstimos',
                        subtitle:
                            'Carteira completa: ativos, atrasados e quitados.',
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
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          0,
                          AppSpacing.lg,
                          AppSpacing.sm,
                        ),
                        child: _LoansPortfolioSection(
                          filter: _filter,
                          onFilterTap: _toggleFilter,
                          layout: layout,
                          onLayoutChanged: (next) => ref
                              .read(loanListLayoutProvider.notifier)
                              .setLayout(next),
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
                          AppSpacing.md,
                          AppSpacing.lg,
                          AppSpacing.sm,
                        ),
                        child: _LoansSearchField(
                          key: const ValueKey('loans-search-field'),
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
                  ref: ref,
                  filter: _filter,
                  searchController: _searchController,
                  layout: layout,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _emptyTitle(LoanListFilter filter) => switch (filter) {
        LoanListFilter.ativos => 'Nenhum empréstimo ativo',
        LoanListFilter.atrasados => 'Nenhum empréstimo em atraso',
        LoanListFilter.quitados => 'Nenhum empréstimo quitado',
        LoanListFilter.todos => 'Nenhum empréstimo',
      };

  static String _emptySubtitle(LoanListFilter filter) => switch (filter) {
        LoanListFilter.ativos =>
          'Use o botão + na barra inferior para criar um empréstimo.',
        LoanListFilter.atrasados =>
          'Ótimo! Nenhuma parcela pendente está vencida.',
        LoanListFilter.quitados =>
          'Empréstimos totalmente pagos aparecem aqui.',
        LoanListFilter.todos => 'Cadastre seu primeiro empréstimo.',
      };

  static Widget _buildFilteredListSliver({
    required WidgetRef ref,
    required LoanListFilter filter,
    required TextEditingController searchController,
    required LoanListCardLayout layout,
  }) {
    final loansAsync = ref.watch(allLoansProvider);
    final paymentsAsync = ref.watch(allPaymentsForUserProvider);

    return ListenableBuilder(
      listenable: searchController,
      builder: (context, _) {
        final query = searchController.text;

        return loansAsync.when(
          data: (allLoans) => paymentsAsync.when(
            data: (payments) {
              final filteredByStatus = LoanListFilterHelper.apply(
                items: allLoans,
                payments: payments,
                filter: filter,
              );
              final loans = LoanListFilterHelper.search(
                items: filteredByStatus,
                query: query,
              );

              if (loans.isEmpty) {
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
                              : LucideIcons.wallet,
                          title: query.trim().isNotEmpty
                              ? 'Nenhum resultado'
                              : _emptyTitle(filter),
                          subtitle: query.trim().isNotEmpty
                              ? 'Tente outro nome, valor ou parcelas.'
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
                  itemCount: loans.length,
                  separatorBuilder: (_, _) => SizedBox(
                    height: layout == LoanListCardLayout.compact
                        ? AppSpacing.xs
                        : AppSpacing.sm,
                  ),
                  itemBuilder: (context, index) {
                    return Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: AppSpacing.maxContentWidth,
                        ),
                        child: LoanListTile(item: loans[index]),
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: AppEmptyState(
                  icon: LucideIcons.circle_alert,
                  title: 'Erro ao carregar pagamentos',
                  subtitle: e.toString(),
                ),
              ),
            ),
          ),
          loading: () => const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: AppEmptyState(
                icon: LucideIcons.circle_alert,
                title: 'Erro ao carregar',
                subtitle: e.toString(),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Campo de busca isolado dos [StreamProvider]s da lista para não perder foco
/// nem reabrir o teclado a cada sincronização.
class _LoansSearchField extends StatefulWidget {
  const _LoansSearchField({
    required this.controller,
    super.key,
  });

  final TextEditingController controller;

  @override
  State<_LoansSearchField> createState() => _LoansSearchFieldState();
}

class _LoansSearchFieldState extends State<_LoansSearchField> {
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

class _LoansPortfolioSection extends ConsumerWidget {
  const _LoansPortfolioSection({
    required this.filter,
    required this.onFilterTap,
    required this.layout,
    required this.onLayoutChanged,
  });

  final LoanListFilter filter;
  final ValueChanged<LoanListFilter> onFilterTap;
  final LoanListCardLayout layout;
  final ValueChanged<LoanListCardLayout> onLayoutChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loansAsync = ref.watch(allLoansProvider);
    final paymentsAsync = ref.watch(allPaymentsForUserProvider);

    return loansAsync.when(
      data: (allLoans) => paymentsAsync.when(
        data: (payments) {
          final portfolio = LoanPortfolioCounts.compute(
            items: allLoans,
            payments: payments,
          );
          if (portfolio.total == 0) {
            return const SizedBox.shrink();
          }
          return _LoansPortfolioCard(
            counts: portfolio,
            selected: filter,
            onFilterTap: onFilterTap,
            layout: layout,
            onLayoutChanged: onLayoutChanged,
          );
        },
        loading: () => const _LoansPortfolioSkeleton(),
        error: (_, _) => const SizedBox.shrink(),
      ),
      loading: () => const _LoansPortfolioSkeleton(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _LoansPortfolioSkeleton extends StatelessWidget {
  const _LoansPortfolioSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 140,
      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }
}

class _LoanListLayoutToggle extends StatelessWidget {
  const _LoanListLayoutToggle({
    required this.layout,
    required this.onLayoutChanged,
  });

  final LoanListCardLayout layout;
  final ValueChanged<LoanListCardLayout> onLayoutChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: context.appTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LayoutIconButton(
            tooltip: 'Cards detalhados',
            icon: LucideIcons.layout_list,
            selected: layout == LoanListCardLayout.extended,
            onTap: () => onLayoutChanged(LoanListCardLayout.extended),
          ),
          Container(
            width: 1,
            height: 36,
            color: context.appTheme.border,
          ),
          _LayoutIconButton(
            tooltip: 'Lista compacta',
            icon: LucideIcons.list,
            selected: layout == LoanListCardLayout.compact,
            onTap: () => onLayoutChanged(LoanListCardLayout.compact),
          ),
        ],
      ),
    );
  }
}

class _LayoutIconButton extends StatelessWidget {
  const _LayoutIconButton({
    required this.tooltip,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(AppSpacing.sm + 2),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.accent.withValues(alpha: 0.14)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Icon(
            icon,
            size: 20,
            color: selected ? AppColors.accent : context.appTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _LoansPortfolioCard extends StatelessWidget {
  const _LoansPortfolioCard({
    required this.counts,
    required this.selected,
    required this.onFilterTap,
    required this.layout,
    required this.onLayoutChanged,
  });

  final LoanPortfolioCounts counts;
  final LoanListFilter selected;
  final ValueChanged<LoanListFilter> onFilterTap;
  final LoanListCardLayout layout;
  final ValueChanged<LoanListCardLayout> onLayoutChanged;

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
                  child: _PortfolioFilterStat(
                    icon: LucideIcons.layers,
                    label: 'Ativos',
                    count: counts.ativos,
                    color: AppColors.accent,
                    selected: selected == LoanListFilter.ativos,
                    onTap: () => onFilterTap(LoanListFilter.ativos),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _PortfolioFilterStat(
                    icon: LucideIcons.triangle_alert,
                    label: 'Atrasados',
                    count: counts.atrasados,
                    color: AppColors.error,
                    selected: selected == LoanListFilter.atrasados,
                    onTap: () => onFilterTap(LoanListFilter.atrasados),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _PortfolioFilterStat(
                    icon: LucideIcons.circle_check,
                    label: 'Quitados',
                    count: counts.quitados,
                    color: AppColors.success,
                    selected: selected == LoanListFilter.quitados,
                    onTap: () => onFilterTap(LoanListFilter.quitados),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Divider(height: 1, color: context.appTheme.border),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Visualização',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: context.appTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              _LoanListLayoutToggle(
                layout: layout,
                onLayoutChanged: onLayoutChanged,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PortfolioFilterStat extends StatelessWidget {
  const _PortfolioFilterStat({
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
