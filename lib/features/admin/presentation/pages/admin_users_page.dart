import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_page_header.dart';
import '../../domain/admin_user.dart';
import '../admin_routes.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_app_bar_actions.dart';

class AdminUsersPage extends ConsumerStatefulWidget {
  const AdminUsersPage({super.key});

  @override
  ConsumerState<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends ConsumerState<AdminUsersPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminUsersProvider);
    final query = _searchController.text.trim().toLowerCase();
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel Admin'),
        actions: const [AdminAppBarActions()],
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppDecorations.screenBackground(brightness),
        ),
        child: SafeArea(
          child: usersAsync.when(
            data: (users) {
              final filtered = query.isEmpty
                  ? users
                  : users
                      .where(
                        (u) =>
                            u.displayName.toLowerCase().contains(query) ||
                            u.email.toLowerCase().contains(query),
                      )
                      .toList();

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(adminUsersProvider);
                  await ref.read(adminUsersProvider.future);
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
                              title: 'Usuários',
                              subtitle:
                                  'Selecione um gerente para ver clientes, '
                                  'parcelas e relatórios na nuvem.',
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
                              decoration: InputDecoration(
                                hintText: 'Buscar por nome ou e-mail',
                                prefixIcon: const Icon(LucideIcons.search),
                                suffixIcon: query.isEmpty
                                    ? null
                                    : IconButton(
                                        icon: const Icon(LucideIcons.x),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() {});
                                        },
                                      ),
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
                            title: query.isEmpty
                                ? 'Nenhum usuário'
                                : 'Nada encontrado',
                            subtitle: query.isEmpty
                                ? 'Contas de gerente aparecem aqui após cadastro.'
                                : 'Tente outro termo de busca.',
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
                            final user = filtered[index];
                            return Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: AppSpacing.maxContentWidth,
                                ),
                                child: _AdminUserTile(
                                  user: user,
                                  onTap: () => context.push(
                                    AdminRoutes.userOverview(user.id),
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
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: AppEmptyState(
                  icon: LucideIcons.circle_alert,
                  title: 'Erro ao carregar usuários',
                  subtitle: e.toString(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminUserTile extends StatelessWidget {
  const _AdminUserTile({required this.user, required this.onTap});

  final AdminUser user;
  final VoidCallback onTap;

  static final _dateFmt = DateFormat('dd/MM/yyyy', 'pt_BR');

  @override
  Widget build(BuildContext context) {
    final created = user.createdAt;
    final createdLabel = created == null
        ? null
        : _dateFmt.format(DateTime.tryParse(created) ?? DateTime.now());

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
              CircleAvatar(
                child: Text(
                  user.displayName.isNotEmpty
                      ? user.displayName[0].toUpperCase()
                      : '?',
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      user.email,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (createdLabel != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Cadastro: $createdLabel',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
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
