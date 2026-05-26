import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../admin/presentation/widgets/admin_app_bar_actions.dart';
import '../../../../../services/supabase/supabase_providers.dart';
import '../../../../../shared/widgets/app_primary_button.dart';
import '../../../../../shared/widgets/app_text_field.dart';
import '../../../domain/entities/ticket_message.dart';
import '../../../domain/support_ticket_status.dart';
import '../../../domain/support_ticket_type.dart';
import '../../providers/admin_support_providers.dart';
import '../../utils/support_date_format.dart';
import '../../widgets/support_chips.dart';

class AdminTicketDetailPage extends ConsumerStatefulWidget {
  const AdminTicketDetailPage({super.key, required this.ticketId});

  final String ticketId;

  @override
  ConsumerState<AdminTicketDetailPage> createState() =>
      _AdminTicketDetailPageState();
}

class _AdminTicketDetailPageState extends ConsumerState<AdminTicketDetailPage> {
  final _devResponseController = TextEditingController();
  final _messageController = TextEditingController();
  SupportTicketStatus? _selectedStatus;
  bool _saving = false;
  bool _sending = false;
  bool _devLoaded = false;

  @override
  void dispose() {
    _devResponseController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _saveTicket() async {
    setState(() => _saving = true);
    try {
      await ref.read(adminSupportRepositoryProvider).updateTicket(
            ticketId: widget.ticketId,
            status: _selectedStatus,
            devResponse: _devResponseController.text,
          );
      ref.invalidate(adminSupportTicketProvider(widget.ticketId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chamado atualizado')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _sendMessage() async {
    final body = _messageController.text.trim();
    if (body.isEmpty) return;
    final authorId = ref.read(currentUserIdProvider);
    if (authorId == null) return;

    setState(() => _sending = true);
    try {
      await ref.read(adminSupportRepositoryProvider).sendAdminMessage(
            ticketId: widget.ticketId,
            authorId: authorId,
            body: body,
          );
      _messageController.clear();
      ref.invalidate(adminTicketMessagesProvider(widget.ticketId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(adminTicketDetailRealtimeProvider(widget.ticketId));

    final ticketAsync = ref.watch(adminSupportTicketProvider(widget.ticketId));
    final messagesAsync =
        ref.watch(adminTicketMessagesProvider(widget.ticketId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chamado'),
        actions: const [AdminAppBarActions()],
      ),
      body: ticketAsync.when(
        data: (item) {
          if (item == null) {
            return const Center(child: Text('Chamado não encontrado'));
          }

          final ticket = item.ticket;
          if (!_devLoaded) {
            _devLoaded = true;
            _devResponseController.text = ticket.devResponse ?? '';
            _selectedStatus = ticket.status;
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
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '${item.userName} · ${item.userEmail}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: context.appTheme.textSecondary,
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
                    const SizedBox(height: AppSpacing.lg),
                    _Section(title: 'Descrição', body: ticket.description),
                    if (ticket.extraField != null &&
                        ticket.extraField!.isNotEmpty &&
                        extraLabel != null)
                      _Section(title: extraLabel, body: ticket.extraField!),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Gerenciar',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    DropdownButtonFormField<SupportTicketStatus>(
                      initialValue: _selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                      ),
                      items: SupportTicketStatus.values
                          .map(
                            (s) => DropdownMenuItem(
                              value: s,
                              child: Text(s.label),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _selectedStatus = v),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      controller: _devResponseController,
                      label: 'Resposta da equipe (visível ao usuário)',
                      maxLines: 4,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppPrimaryButton(
                      label: 'Salvar status e resposta',
                      isLoading: _saving,
                      onPressed: _saveTicket,
                    ),
                    const SizedBox(height: AppSpacing.xl),
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
                            'Sem mensagens no thread.',
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
                              _AdminMessageBubble(message: msg),
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
                    border:
                        Border(top: BorderSide(color: context.appTheme.border)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppTextField(
                        controller: _messageController,
                        label: 'Responder como equipe',
                        maxLines: 3,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppPrimaryButton(
                        label: 'Enviar mensagem',
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
        Text(body),
      ],
    );
  }
}

class _AdminMessageBubble extends StatelessWidget {
  const _AdminMessageBubble({required this.message});

  final TicketMessage message;

  @override
  Widget build(BuildContext context) {
    final isAdmin = message.isFromAdmin;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Align(
        alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.85,
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isAdmin
                ? AppColors.accent.withValues(alpha: 0.12)
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: isAdmin
                ? Border.all(color: AppColors.accent.withValues(alpha: 0.3))
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isAdmin ? 'Equipe' : 'Usuário',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isAdmin ? AppColors.accent : null,
                    ),
              ),
              const SizedBox(height: 4),
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
      ),
    );
  }
}
