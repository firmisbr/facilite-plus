import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../services/supabase/supabase_providers.dart';
import '../../../../services/sync/sync_providers.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../domain/entities/ticket_message.dart';
import '../../domain/support_ticket_type.dart';
import '../providers/support_providers.dart';
import '../utils/support_date_format.dart';
import '../widgets/support_chips.dart';

class TicketDetailPage extends ConsumerStatefulWidget {
  const TicketDetailPage({super.key, required this.ticketId});

  final String ticketId;

  @override
  ConsumerState<TicketDetailPage> createState() => _TicketDetailPageState();
}

class _TicketDetailPageState extends ConsumerState<TicketDetailPage> {
  final _messageController = TextEditingController();
  bool _sending = false;
  bool _markedSeen = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final body = _messageController.text.trim();
    if (body.isEmpty) return;
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    setState(() => _sending = true);
    try {
      await ref.read(supportRepositoryProvider).sendMessage(
            ticketId: widget.ticketId,
            authorId: userId,
            body: body,
          );
      _messageController.clear();
      if (!mounted) return;
      final container = ProviderScope.containerOf(context);
      await container.read(syncServiceProvider).processQueue();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar mensagem: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(ticketRealtimeProvider(widget.ticketId));

    final ticketAsync = ref.watch(supportTicketProvider(widget.ticketId));
    final messagesAsync = ref.watch(ticketMessagesProvider(widget.ticketId));

    return Scaffold(
      appBar: AppBar(title: const Text('Chamado')),
      body: ticketAsync.when(
        data: (ticket) {
          if (ticket == null) {
            return const Center(child: Text('Chamado não encontrado'));
          }

          if (!_markedSeen) {
            _markedSeen = true;
            markSupportTicketSeen(ref, ticket);
          }

          final extraLabel = switch (ticket.type) {
            SupportTicketType.bug => 'Passos para reproduzir',
            SupportTicketType.sugestao => 'Problema que resolve',
            SupportTicketType.suporte => null,
          };

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    Text(
                      ticket.title,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      children: [
                        SupportTypeChip(type: ticket.type),
                        SupportStatusChip(status: ticket.status),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Aberto em ${formatSupportDate(ticket.createdAt)}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: context.appTheme.textSecondary,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _Section(title: 'Descrição', body: ticket.description),
                    if (ticket.extraField != null &&
                        ticket.extraField!.isNotEmpty &&
                        extraLabel != null)
                      _Section(title: extraLabel, body: ticket.extraField!),
                    if (ticket.devResponse != null &&
                        ticket.devResponse!.trim().isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.lg),
                      _DevResponseCard(text: ticket.devResponse!),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Mensagens',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    messagesAsync.when(
                      data: (messages) {
                        if (messages.isEmpty) {
                          return Text(
                            'Nenhuma mensagem ainda. Envie uma abaixo.',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: context.appTheme.textSecondary,
                                ),
                          );
                        }
                        return Column(
                          children: [
                            for (final msg in messages)
                              _MessageBubble(message: msg),
                          ],
                        );
                      },
                      loading: () => const Padding(
                        padding: EdgeInsets.all(AppSpacing.lg),
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      error: (e, _) => Text('Erro: $e'),
                    ),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border(top: BorderSide(color: context.appTheme.border)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppTextField(
                        controller: _messageController,
                        label: 'Nova mensagem',
                        maxLines: 3,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppPrimaryButton(
                        label: 'Enviar',
                        isLoading: _sending,
                        onPressed: _sendMessage,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(body, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _DevResponseCard extends StatelessWidget {
  const _DevResponseCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accent.withValues(alpha: 0.12),
            AppColors.premium.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: AppDecorations.iconBadge(color: AppColors.accent),
            child: const Icon(
              LucideIcons.code_xml,
              size: 20,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resposta da equipe',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.accent,
                      ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(text, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final TicketMessage message;

  @override
  Widget build(BuildContext context) {
    final isAdmin = message.isFromAdmin;
    final align = isAdmin ? CrossAxisAlignment.start : CrossAxisAlignment.end;
    final bg = isAdmin
        ? AppColors.accent.withValues(alpha: 0.12)
        : Theme.of(context).colorScheme.surfaceContainerHighest;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.85,
            ),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: isAdmin
                  ? Border.all(color: AppColors.accent.withValues(alpha: 0.3))
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isAdmin)
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.shield,
                        size: 14,
                        color: AppColors.accent,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Equipe',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.accent,
                            ),
                      ),
                    ],
                  ),
                if (isAdmin) const SizedBox(height: 4),
                Text(message.body),
                const SizedBox(height: 4),
                Text(
                  formatSupportDate(message.createdAt),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: context.appTheme.textSecondary,
                        fontSize: 10,
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
