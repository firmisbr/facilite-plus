import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../services/supabase/supabase_providers.dart';
import '../../../../services/sync/sync_providers.dart';
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

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _loadClient();
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
    setState(() {});
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Editar cliente' : 'Novo cliente'),
      ),
      body: _loading && widget.isEditing && _nameController.text.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nome *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Obrigatório' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Telefone',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _documentController,
                      decoration: const InputDecoration(
                        labelText: 'Documento',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Endereço',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Observações',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _loading ? null : _save,
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Salvar'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
