import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/floating_notched_nav_bar.dart';
import '../../../../shared/widgets/sync_feedback.dart';
import '../../domain/support_ticket_status.dart';
import '../../domain/support_ticket_type.dart';
import '../providers/support_providers.dart';
import '../utils/support_date_format.dart';
import '../widgets/support_chips.dart';

class SupportHomePage extends ConsumerWidget {
  const SupportHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketsAsync = ref.watch(supportTicketsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Suporte')),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppDecorations.screenBackground(
            Theme.of(context).brightness,
          ),
        ),
        child: RefreshIndicator(
          onRefresh: () async {
            final container = ProviderScope.containerOf(context);
            await runFullSync(container);
          },
          child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            kBottomNavReservedHeight,
          ),
          children: [
            _ActionCard(
              emoji: SupportTicketType.bug.emoji,
              title: 'Reportar Bug',
              subtitle: 'Algo não funciona como esperado',
              onTap: () => context.push(
                AppRoutes.supportNew(SupportTicketType.bug.value),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _ActionCard(
              emoji: SupportTicketType.sugestao.emoji,
              title: 'Enviar Sugestão',
              subtitle: 'Ideias para melhorar o app',
              onTap: () => context.push(
                AppRoutes.supportNew(SupportTicketType.sugestao.value),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _ActionCard(
              emoji: SupportTicketType.suporte.emoji,
              title: 'Abrir Chamado de Suporte',
              subtitle: 'Dúvidas ou ajuda geral',
              onTap: () => context.push(
                AppRoutes.supportNew(SupportTicketType.suporte.value),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Meus Chamados',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            ticketsAsync.when(
              data: (tickets) {
                if (tickets.isEmpty) {
                  return const AppEmptyState(
                    icon: LucideIcons.inbox,
                    title: 'Nenhum chamado ainda',
                    subtitle: 'Abra um bug, sugestão ou chamado acima.',
                  );
                }
                return Column(
                  children: [
                    for (final ticket in tickets) ...[
                      _TicketListTile(
                        title: ticket.title,
                        type: ticket.type,
                        status: ticket.status,
                        dateLabel: formatSupportDate(ticket.updatedAt),
                        onTap: () =>
                            context.push(AppRoutes.supportTicket(ticket.id)),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                  ],
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (e, _) => Text('Erro ao carregar: $e'),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            border: Border.all(color: context.appTheme.border),
            boxShadow: context.appTheme.cardShadow,
          ),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: context.appTheme.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                LucideIcons.chevron_right,
                color: context.appTheme.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TicketListTile extends StatelessWidget {
  const _TicketListTile({
    required this.title,
    required this.type,
    required this.status,
    required this.dateLabel,
    required this.onTap,
  });

  final String title;
  final SupportTicketType type;
  final SupportTicketStatus status;
  final String dateLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            border: Border.all(color: context.appTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SupportTypeChip(type: type),
                  SupportStatusChip(status: status),
                  Text(
                    dateLabel,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: context.appTheme.textSecondary,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
