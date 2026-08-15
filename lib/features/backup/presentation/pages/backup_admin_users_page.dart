import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../services/supabase/supabase_providers.dart';
import '../../../../services/sync/sync_coordinator.dart';
import '../../../admin/domain/admin_user.dart';
import '../../domain/backup_snapshot.dart';
import '../providers/backup_providers.dart';

class BackupAdminUsersPage extends ConsumerStatefulWidget {
  const BackupAdminUsersPage({required this.supportPin, super.key});

  final String supportPin;

  @override
  ConsumerState<BackupAdminUsersPage> createState() =>
      _BackupAdminUsersPageState();
}

class _BackupAdminUsersPageState extends ConsumerState<BackupAdminUsersPage> {
  final _searchController = TextEditingController();
  bool _busy = false;
  late Future<List<AdminUser>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _usersFuture = _loadUsers();
  }

  Future<List<AdminUser>> _loadUsers() {
    return ref.read(supportImportRepositoryProvider).fetchProfiles(
          widget.supportPin,
        );
  }

  Future<void> _refreshUsers() async {
    setState(() {
      _usersFuture = _loadUsers();
    });
    await _usersFuture;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Importar da nuvem'),
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppDecorations.screenBackground(brightness),
        ),
        child: Stack(
          children: [
            SafeArea(
              child: FutureBuilder<List<AdminUser>>(
                future: _usersFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Text(
                          _mapLoadError(snapshot.error!),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  final users = snapshot.data ?? [];
                  final filtered = query.isEmpty
                      ? users
                      : users
                          .where(
                            (u) =>
                                u.displayName.toLowerCase().contains(query) ||
                                u.email.toLowerCase().contains(query),
                          )
                          .toList();

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.md,
                          AppSpacing.lg,
                          AppSpacing.sm,
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: 'Buscar usuário…',
                            prefixIcon:
                                const Icon(LucideIcons.search, size: 20),
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surface,
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusLg),
                              borderSide: BorderSide(
                                color: context.appTheme.border,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: filtered.isEmpty
                            ? const Center(
                                child: Text('Nenhum usuário encontrado.'),
                              )
                            : RefreshIndicator(
                                onRefresh: _refreshUsers,
                                child: ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(
                                    AppSpacing.lg,
                                    AppSpacing.sm,
                                    AppSpacing.lg,
                                    AppSpacing.lg,
                                  ),
                                  itemCount: filtered.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(height: AppSpacing.sm),
                                  itemBuilder: (context, index) {
                                    final user = filtered[index];
                                    return _UserImportTile(
                                      user: user,
                                      onTap: _busy
                                          ? null
                                          : () => _confirmAndImport(user),
                                    );
                                  },
                                ),
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
            if (_busy)
              const Positioned.fill(
                child: ColoredBox(
                  color: Color(0x66000000),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _mapLoadError(Object error) {
    if (error is PostgrestException) {
      final msg = error.message.toLowerCase();
      if (msg.contains('pin')) {
        return 'PIN inválido ou função de suporte não disponível no Supabase. '
            'Aplique a migration support_import_rpc.';
      }
      return 'Erro ao carregar usuários: ${error.message}';
    }
    return 'Erro ao carregar usuários: $error';
  }

  Future<void> _confirmAndImport(AdminUser user) async {
    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId == null) return;

    final isSameAccount = user.id == currentUserId;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Importar dados?'),
        content: Text(
          isSameAccount
              ? 'Deseja recarregar todos os dados de ${user.displayName} '
                  'da nuvem para este aparelho?\n\n'
                  'Os dados locais atuais serão substituídos e depois '
                  'sincronizados.'
              : 'Deseja importar todos os dados de ${user.displayName} '
                  '(${user.email}) para a conta atual neste aparelho?\n\n'
                  'Clientes, empréstimos e pagamentos serão copiados da nuvem '
                  'e associados à sua conta logada.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sim, importar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    await _runImport(user, currentUserId);
  }

  Future<void> _runImport(AdminUser user, String currentUserId) async {
    setState(() => _busy = true);
    try {
      final repo = ref.read(supportImportRepositoryProvider);
      final clients = await repo.fetchClients(
        pin: widget.supportPin,
        userId: user.id,
      );
      final loans = await repo.fetchLoans(
        pin: widget.supportPin,
        userId: user.id,
      );
      final payments = await repo.fetchPayments(
        pin: widget.supportPin,
        userId: user.id,
      );

      final summary = await ref.read(backupServiceProvider).importCloudUserData(
            clients: clients,
            loans: loans,
            payments: payments,
            sourceUserId: user.id,
            currentUserId: currentUserId,
            sourceEmail: user.email,
          );

      invalidateDataAfterBackupRestore(ref);
      ref.invalidate(backupPreviewProvider);
      unawaited(ref.read(syncCoordinatorProvider).requestSync(force: true));

      if (!mounted) return;
      final prefix = summary.importedFromOtherAccount
          ? 'Importado de ${user.displayName}'
          : 'Dados recarregados';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$prefix: ${summary.clients} clientes, ${summary.loans} empréstimos, '
            '${summary.payments} pagamentos. Enviando para a nuvem…',
          ),
          duration: const Duration(seconds: 6),
        ),
      );
      Navigator.pop(context);
    } on BackupException catch (e) {
      _showError(e.message);
    } on PostgrestException catch (e) {
      _showError(
        e.message.toLowerCase().contains('pin')
            ? 'PIN inválido ou função de suporte indisponível.'
            : 'Erro ao ler dados na nuvem: ${e.message}',
      );
    } catch (e) {
      _showError('Falha ao importar: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }
}

class _UserImportTile extends StatelessWidget {
  const _UserImportTile({
    required this.user,
    required this.onTap,
  });

  final AdminUser user;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final created = user.createdAt;
    final parsedCreated = created == null ? null : DateTime.tryParse(created);
    final createdLabel = parsedCreated == null
        ? null
        : DateFormat('dd/MM/yyyy').format(parsedCreated.toLocal());

    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            border: Border.all(color: context.appTheme.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: AppDecorations.iconBadge(color: AppColors.accent),
                child: const Icon(
                  LucideIcons.user,
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
                      user.displayName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: context.appTheme.textSecondary,
                          ),
                    ),
                    if (createdLabel != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Desde $createdLabel',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: context.appTheme.textSecondary,
                              fontSize: 10,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                LucideIcons.download,
                size: 18,
                color: context.appTheme.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
