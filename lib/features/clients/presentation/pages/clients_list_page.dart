import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_page_header.dart';
import '../../../../shared/widgets/floating_notched_nav_bar.dart';
import '../../../loans/presentation/providers/loans_providers.dart';
import '../../../payments/presentation/providers/payments_providers.dart';
import '../../domain/client_list_entry.dart';
import '../../domain/client_list_filter.dart';
import '../providers/clients_list_providers.dart';
import '../providers/clients_providers.dart';

class ClientsListPage extends ConsumerStatefulWidget {
  const ClientsListPage({super.key});

  @override
  ConsumerState<ClientsListPage> createState() => _ClientsListPageState();
}

class _ClientsListPageState extends ConsumerState<ClientsListPage> {
  ClientListFilter _filter = ClientListFilter.todos;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleFilter(ClientListFilter filter) {
    setState(() {
      _filter = _filter == filter ? ClientListFilter.todos : filter;
    });
  }

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(clientListEntriesProvider);
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        leading: const BackButton(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.clientNew),
        icon: const Icon(LucideIcons.user_plus),
        label: const Text('Novo cliente'),
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppDecorations.screenBackground(brightness),
        ),
        child: SafeArea(
          bottom: false,
          child: entriesAsync.when(
            data: (entries) => RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(clientsStreamProvider);
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
                          title: 'Clientes',
                          subtitle:
                              'Cadastro local sincronizado na nuvem.',
                          centered: true,
                        ),
                      ),
                    ),
                  ),
                  if (entries.isNotEmpty)
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
                            child: _ClientsPortfolioCard(
                              counts: ClientPortfolioCounts.compute(entries),
                              selected: _filter,
                              onFilterTap: _toggleFilter,
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (entries.isNotEmpty)
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
                            child: _ClientsSearchField(
                              key: const ValueKey('clients-search-field'),
                              controller: _searchController,
                            ),
                          ),
                        ),
                      ),
                    ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.md),
                  ),
                  _buildListSliver(entries: entries),
                ],
              ),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
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
      ),
    );
  }

  Widget _buildListSliver({required List<ClientListEntry> entries}) {
    if (entries.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: AppEmptyState(
              icon: LucideIcons.users,
              title: 'Nenhum cliente ainda',
              subtitle:
                  'Use o botão abaixo para cadastrar seu primeiro cliente.',
            ),
          ),
        ),
      );
    }

    return ListenableBuilder(
      listenable: _searchController,
      builder: (context, _) {
        final query = _searchController.text;
        final filteredByStatus = ClientListFilterHelper.apply(
          items: entries,
          filter: _filter,
        );
        final filtered = filterClientEntries(filteredByStatus, query);

        if (filtered.isEmpty) {
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
                        : LucideIcons.users,
                    title: query.trim().isNotEmpty
                        ? 'Nenhum resultado'
                        : _emptyTitle(_filter),
                    subtitle: query.trim().isNotEmpty
                        ? 'Tente outro nome, telefone ou CPF.'
                        : _emptySubtitle(_filter),
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
            kBottomNavReservedHeight + AppSpacing.xxl + 48,
          ),
          sliver: SliverList.separated(
            itemCount: filtered.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppSpacing.maxContentWidth,
                  ),
                  child: _ClientListTile(entry: filtered[index]),
                ),
              );
            },
          ),
        );
      },
    );
  }

  static String _emptyTitle(ClientListFilter filter) => switch (filter) {
        ClientListFilter.todos => 'Nenhum cliente',
        ClientListFilter.comEmprestimo => 'Nenhum com empréstimo ativo',
        ClientListFilter.emAtraso => 'Nenhum cliente em atraso',
      };

  static String _emptySubtitle(ClientListFilter filter) => switch (filter) {
        ClientListFilter.todos => 'Cadastre clientes para vincular empréstimos.',
        ClientListFilter.comEmprestimo =>
          'Nenhum cliente com empréstimo em aberto no momento.',
        ClientListFilter.emAtraso =>
          'Ótimo! Nenhum cliente com parcela vencida.',
      };
}

class _ClientsSearchField extends StatefulWidget {
  const _ClientsSearchField({
    required this.controller,
    super.key,
  });

  final TextEditingController controller;

  @override
  State<_ClientsSearchField> createState() => _ClientsSearchFieldState();
}

class _ClientsSearchFieldState extends State<_ClientsSearchField> {
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
          hintText: 'Buscar por nome, WhatsApp ou CPF',
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

class _ClientsPortfolioCard extends StatelessWidget {
  const _ClientsPortfolioCard({
    required this.counts,
    required this.selected,
    required this.onFilterTap,
  });

  final ClientPortfolioCounts counts;
  final ClientListFilter selected;
  final ValueChanged<ClientListFilter> onFilterTap;

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
                  child: _ClientFilterStat(
                    icon: LucideIcons.users,
                    label: 'Total',
                    count: counts.total,
                    color: AppColors.accent,
                    selected: selected == ClientListFilter.todos,
                    onTap: () => onFilterTap(ClientListFilter.todos),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _ClientFilterStat(
                    icon: LucideIcons.wallet,
                    label: 'Ativos',
                    count: counts.comEmprestimo,
                    color: AppColors.accentSecondary,
                    selected: selected == ClientListFilter.comEmprestimo,
                    onTap: () => onFilterTap(ClientListFilter.comEmprestimo),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _ClientFilterStat(
                    icon: LucideIcons.triangle_alert,
                    label: 'Atraso',
                    count: counts.emAtraso,
                    color: AppColors.error,
                    selected: selected == ClientListFilter.emAtraso,
                    onTap: () => onFilterTap(ClientListFilter.emAtraso),
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

class _ClientFilterStat extends StatelessWidget {
  const _ClientFilterStat({
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
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: selected
                          ? color
                          : context.appTheme.textSecondary,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 10,
                      height: 1.2,
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

class _ClientListTile extends StatelessWidget {
  const _ClientListTile({required this.entry});

  final ClientListEntry entry;

  @override
  Widget build(BuildContext context) {
    final client = entry.client;
    final subtitle = [
      if (client.phone != null) client.phone,
      if (client.document != null) client.document,
    ].whereType<String>().join(' · ');

    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(AppRoutes.clientEdit(client.id)),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            border: Border.all(color: context.appTheme.border),
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            boxShadow: context.appTheme.cardShadow,
          ),
          child: Row(
            children: [
              _ClientAvatar(name: client.name),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: context.appTheme.textSecondary,
                            ),
                      ),
                    ],
                    if (entry.hasDelinquency) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _DelinquencyBadge(count: entry.overdueInstallments),
                    ] else if (entry.activeLoansCount > 0) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        '${entry.activeLoansCount} empréstimo(s) ativo(s)',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Empréstimos',
                onPressed: () => context.push(AppRoutes.clientLoans(client.id)),
                icon: const Icon(LucideIcons.wallet, size: 22),
                color: AppColors.accent,
              ),
              Icon(
                LucideIcons.chevron_right,
                size: 20,
                color: context.appTheme.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DelinquencyBadge extends StatelessWidget {
  const _DelinquencyBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        '$count parcela(s) em atraso',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _ClientAvatar extends StatelessWidget {
  const _ClientAvatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final initial =
        name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';

    return CircleAvatar(
      radius: 24,
      backgroundColor: AppColors.accent.withValues(alpha: 0.18),
      child: Text(
        initial,
        style: const TextStyle(
          color: AppColors.accent,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
      ),
    );
  }
}
