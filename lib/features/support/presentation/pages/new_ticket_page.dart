import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../services/supabase/supabase_providers.dart';
import '../../../../services/sync/sync_providers.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/sync_feedback.dart';
import '../../domain/support_ticket_type.dart';
import '../providers/support_providers.dart';

class NewTicketPage extends ConsumerStatefulWidget {
  const NewTicketPage({super.key, required this.type});

  final SupportTicketType type;

  @override
  ConsumerState<NewTicketPage> createState() => _NewTicketPageState();
}

class _NewTicketPageState extends ConsumerState<NewTicketPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _extraController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _extraController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    setState(() => _loading = true);
    try {
      final repo = ref.read(supportRepositoryProvider);
      final ticket = await repo.createTicket(
        userId: userId,
        type: widget.type,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        extraField: _extraController.text.trim().isEmpty
            ? null
            : _extraController.text.trim(),
      );

      if (!mounted) return;
      final container = ProviderScope.containerOf(context);
      final syncResult = await container.read(syncServiceProvider).processQueue();
      if (!mounted) return;
      showSyncSnackBar(context, syncResult);
      context.pop(ticket.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível enviar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final extraLabel = switch (widget.type) {
      SupportTicketType.bug => 'Passos para reproduzir',
      SupportTicketType.sugestao => 'Qual problema isso resolve?',
      SupportTicketType.suporte => null,
    };

    return Scaffold(
      appBar: AppBar(title: Text(widget.type.newPageTitle)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            AppTextField(
              controller: _titleController,
              label: 'Título',
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Informe o título' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _descriptionController,
              label: 'Descrição detalhada',
              maxLines: 6,
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Informe a descrição'
                  : null,
            ),
            if (extraLabel != null) ...[
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _extraController,
                label: extraLabel,
                maxLines: widget.type == SupportTicketType.bug ? 4 : 3,
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            AppPrimaryButton(
              label: 'Enviar',
              isLoading: _loading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
