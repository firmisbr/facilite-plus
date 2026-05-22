import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_page_header.dart';
import '../../../../shared/widgets/app_page_scaffold.dart';
import '../../../../shared/widgets/floating_notched_nav_bar.dart';
import '../../domain/client_list_entry.dart';
import '../providers/clients_list_providers.dart';

class ClientsListPage extends ConsumerStatefulWidget {
  const ClientsListPage({super.key});

  @override
  ConsumerState<ClientsListPage> createState() => _ClientsListPageState();
}

class _ClientsListPageState extends ConsumerState<ClientsListPage> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(clientListEntriesProvider);

    return AppPageScaffold(
      title: 'Clientes',
      showBackButton: true,
      actions: [
        IconButton(
          tooltip: 'Novo cliente',
          icon: const Icon(LucideIcons.user_plus, size: 22),
          onPressed: () => context.push(AppRoutes.clientNew),
        ),
      ],
      body: entriesAsync.when(
        data: (entries) {
          final filtered = filterClientEntries(entries, _query);

          if (entries.isEmpty) {
            return const AppEmptyState(
              icon: Icons.people_outline,
              title: 'Nenhum cliente ainda',
              subtitle:
                  'Use o botão no topo da tela para cadastrar seu primeiro cliente.',
            );
          }

          return CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(
                child: AppPageHeader(
                  title: 'Seus clientes',
                  subtitle: 'Dados salvos localmente e sincronizados na nuvem.',
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.md,
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar por nome, WhatsApp ou CPF…',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                            )
                          : null,
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
              ),
              if (filtered.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: AppEmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'Nenhum resultado',
                    subtitle: 'Tente outro nome, telefone ou CPF.',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    kBottomNavReservedHeight + AppSpacing.lg,
                  ),
                  sliver: SliverList.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, index) {
                      return _ClientListTile(entry: filtered[index]);
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

    return AppCard(
      onTap: () => context.push(AppRoutes.clientEdit(client.id)),
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
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
                if (entry.hasDelinquency) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _DelinquencyBadge(count: entry.overdueInstallments),
                ] else if (entry.activeLoansCount > 0) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${entry.activeLoansCount} empréstimo(s) ativo(s)',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: 'Empréstimos',
            onPressed: () => context.push(AppRoutes.clientLoans(client.id)),
            icon: const Icon(Icons.payments_outlined),
            color: AppColors.accent,
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ],
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
        style: TextStyle(
          color: AppColors.accent,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
      ),
    );
  }
}
