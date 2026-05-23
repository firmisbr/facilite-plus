import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_page_header.dart';
import '../admin_routes.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_app_bar_actions.dart';

class AdminClientsPage extends ConsumerStatefulWidget {
  const AdminClientsPage({super.key, required this.userId});

  final String userId;

  @override
  ConsumerState<AdminClientsPage> createState() => _AdminClientsPageState();
}

class _AdminClientsPageState extends ConsumerState<AdminClientsPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(adminClientsProvider(widget.userId));
    final summariesAsync = ref.watch(adminLoansProvider(widget.userId));
    final query = _searchController.text.trim().toLowerCase();
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
        actions: const [AdminAppBarActions()],
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppDecorations.screenBackground(brightness),
        ),
        child: SafeArea(
          child: clientsAsync.when(
            data: (clients) {
              final filtered = query.isEmpty
                  ? clients
                  : clients
                      .where((c) => c.name.toLowerCase().contains(query))
                      .toList();

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(adminClientsProvider(widget.userId));
                  ref.invalidate(adminLoansProvider(widget.userId));
                  await ref.read(adminClientsProvider(widget.userId).future);
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
                          child: const Padding(
                            padding: EdgeInsets.fromLTRB(
                              AppSpacing.lg,
                              AppSpacing.md,
                              AppSpacing.lg,
                              AppSpacing.sm,
                            ),
                            child: AppPageHeader(
                              title: 'Clientes do usuário',
                              subtitle:
                                  'Toque em um cliente para ver empréstimos e parcelas.',
                              centered: true,
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
                              AppSpacing.md,
                            ),
                            child: TextField(
                              controller: _searchController,
                              onChanged: (_) => setState(() {}),
                              decoration: const InputDecoration(
                                hintText: 'Buscar cliente',
                                prefixIcon: Icon(LucideIcons.search),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (filtered.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: AppEmptyState(
                            icon: LucideIcons.users,
                            title: 'Nenhum cliente',
                            subtitle: query.isEmpty
                                ? 'Sem clientes sincronizados na nuvem.'
                                : 'Nenhum resultado para a busca.',
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          0,
                          AppSpacing.lg,
                          AppSpacing.xl,
                        ),
                        sliver: SliverList.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (context, index) {
                            final client = filtered[index];
                            final loanCount = summariesAsync.valueOrNull
                                    ?.where((l) => l.loan.clientId == client.id)
                                    .length ??
                                0;

                            return Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: AppSpacing.maxContentWidth,
                                ),
                                child: _ClientTile(
                                  name: client.name,
                                  phone: client.phone,
                                  loanCount: loanCount,
                                  onTap: () => context.push(
                                    AdminRoutes.clientLoans(
                                      widget.userId,
                                      client.id,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
          ),
        ),
      ),
    );
  }
}

class _ClientTile extends StatelessWidget {
  const _ClientTile({
    required this.name,
    required this.phone,
    required this.loanCount,
    required this.onTap,
  });

  final String name;
  final String? phone;
  final int loanCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              const Icon(LucideIcons.user_round),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    if (phone != null && phone!.trim().isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(phone!, style: Theme.of(context).textTheme.bodySmall),
                    ],
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '$loanCount empréstimo(s)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
