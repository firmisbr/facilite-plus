import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/routes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_decorations.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../admin/presentation/widgets/admin_app_bar_actions.dart';
import '../../../../../shared/widgets/app_empty_state.dart';
import '../../../../../shared/widgets/app_page_header.dart';
import '../../providers/admin_support_providers.dart';
import '../../utils/support_date_format.dart';
import '../../widgets/support_chips.dart';

class AdminSupportTicketsPage extends ConsumerWidget {
  const AdminSupportTicketsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(adminSupportRealtimeProvider);
    final ticketsAsync = ref.watch(adminSupportTicketsProvider);
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chamados de suporte'),
        actions: const [AdminAppBarActions()],
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppDecorations.screenBackground(brightness),
        ),
        child: SafeArea(
          child: ticketsAsync.when(
            data: (items) {
              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(adminSupportTicketsProvider);
                  await ref.read(adminSupportTicketsProvider.future);
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
                              title: 'Suporte',
                              subtitle:
                                  'Todos os chamados dos usuários. Toque para '
                                  'responder ou alterar status.',
                              centered: true,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (items.isEmpty)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: AppEmptyState(
                            icon: LucideIcons.inbox,
                            title: 'Nenhum chamado',
                            subtitle:
                                'Quando usuários abrirem tickets, aparecem aqui.',
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
                          itemCount: items.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (context, index) {
                            final item = items[index];
                            final ticket = item.ticket;
                            return Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: AppSpacing.maxContentWidth,
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => context.push(
                                      AppRoutes.adminSupportTicket(ticket.id),
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusXl,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.all(
                                        AppSpacing.md,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surface,
                                        borderRadius: BorderRadius.circular(
                                          AppSpacing.radiusXl,
                                        ),
                                        border: Border.all(
                                          color: context.appTheme.border,
                                        ),
                                        boxShadow: context.appTheme.cardShadow,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            ticket.title,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${item.userName} · ${item.userEmail}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: context
                                                      .appTheme
                                                      .textSecondary,
                                                ),
                                          ),
                                          const SizedBox(
                                            height: AppSpacing.sm,
                                          ),
                                          Wrap(
                                            spacing: AppSpacing.sm,
                                            runSpacing: AppSpacing.xs,
                                            children: [
                                              SupportTypeChip(type: ticket.type),
                                              SupportStatusChip(
                                                status: ticket.status,
                                              ),
                                              Text(
                                                formatSupportDate(
                                                  ticket.updatedAt,
                                                ),
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelSmall
                                                    ?.copyWith(
                                                      color: context.appTheme
                                                          .textSecondary,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
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
            error: (e, _) => Center(child: Text('Erro: $e')),
          ),
        ),
      ),
    );
  }
}
