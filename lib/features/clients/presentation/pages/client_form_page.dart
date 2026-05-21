import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../services/supabase/supabase_providers.dart';
import '../../../../services/sync/sync_providers.dart';
import '../../../../shared/widgets/app_bar_actions.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../providers/clients_providers.dart';

class ClientFormPage extends ConsumerStatefulWidget {
  const ClientFormPage({super.key, this.clientId});

  final String? clientId;

  bool get isEditing => clientId != null;

  @override
  ConsumerState<ClientFormPage> createState() => _ClientFormPageState();
}

class _ClientFormPageState extends ConsumerState<ClientFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _documentController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  bool _loading = false;
  bool _initialLoad = true;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _loadClient();
    } else {
      _initialLoad = false;
    }
  }

  Future<void> _loadClient() async {
    final client =
        await ref.read(clientsRepositoryProvider).getById(widget.clientId!);
    if (client == null || !mounted) return;
    _nameController.text = client.name;
    _phoneController.text = client.phone ?? '';
    _documentController.text = client.document ?? '';
    _addressController.text = client.address ?? '';
    _notesController.text = client.notes ?? '';
    setState(() => _initialLoad = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _documentController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    setState(() => _loading = true);
    final repo = ref.read(clientsRepositoryProvider);

    try {
      if (widget.isEditing) {
        final existing = await repo.getById(widget.clientId!);
        if (existing == null) throw StateError('Cliente não encontrado');
        await repo.update(
          existing.copyWith(
            name: _nameController.text.trim(),
            phone: _emptyToNull(_phoneController.text),
            document: _emptyToNull(_documentController.text),
            address: _emptyToNull(_addressController.text),
            notes: _emptyToNull(_notesController.text),
          ),
        );
      } else {
        await repo.create(
          userId: userId,
          name: _nameController.text.trim(),
          phone: _emptyToNull(_phoneController.text),
          document: _emptyToNull(_documentController.text),
          address: _emptyToNull(_addressController.text),
          notes: _emptyToNull(_notesController.text),
        );
      }

      final sync = ref.read(syncServiceProvider);
      await sync.processQueue();

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _emptyToNull(String value) {
    final t = value.trim();
    return t.isEmpty ? null : t;
  }

  @override
  Widget build(BuildContext context) {
    if (_initialLoad) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Editar cliente' : 'Novo cliente'),
        actions: const [
          AppBarActions(showSync: false, showLogout: false),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Dados do cliente',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Salvo no dispositivo e enviado ao Supabase quando online.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    controller: _nameController,
                    label: 'Nome *',
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Obrigatório' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _phoneController,
                    label: 'Telefone',
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _documentController,
                    label: 'Documento',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _addressController,
                    label: 'Endereço',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _notesController,
                    label: 'Observações',
                    maxLines: 3,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppPrimaryButton(
                    label: 'Salvar',
                    isLoading: _loading,
                    onPressed: _save,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
