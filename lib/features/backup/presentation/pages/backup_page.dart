import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../services/supabase/supabase_providers.dart';
import '../../../../shared/widgets/floating_notched_nav_bar.dart';
import '../../domain/backup_snapshot.dart';
import '../../../../services/sync/sync_coordinator.dart';
import '../backup_native_io.dart';
import '../providers/backup_providers.dart';
import '../widgets/backup_pin_dialog.dart';

class BackupPage extends ConsumerStatefulWidget {
  const BackupPage({super.key});

  @override
  ConsumerState<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends ConsumerState<BackupPage> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(backupPreviewProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final preview = ref.watch(backupPreviewProvider);
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: const Text('Backup'),
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppDecorations.screenBackground(brightness),
        ),
        child: Stack(
          children: [
            SafeArea(
              bottom: false,
              child: preview.when(
                data: (snapshot) => _BackupContent(
                  snapshot: snapshot,
                  busy: _busy,
                  onExport: _exportBackup,
                  onRestoreSameAccount: _restoreSameAccount,
                  onImportOtherAccount: _importOtherAccount,
                ),
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Text('Erro ao carregar: $e'),
                  ),
                ),
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

  Future<void> _exportBackup() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    final pin = await showBackupTransferPinDialog(
      context,
      mode: BackupPinDialogMode.createForExport,
    );
    if (pin == null || !mounted) return;

    setState(() => _busy = true);
    BackupExportFile? exported;
    try {
      final session = ref.read(sessionProvider).valueOrNull;
      exported = await ref.read(backupServiceProvider).exportToFile(
            userId: userId,
            userEmail: session?.user.email,
            transferPin: pin,
          );
      await shareBackupFile(
        filePath: exported.filePath,
        fileName: exported.fileName,
        shareText:
            'Backup Facilite Plus — ${exported.snapshot.totalRecords} registro(s). '
            'PIN necessário para importar em outra conta.',
      );
      if (mounted) {
        final savedDownloads = exported.downloadsPath != null;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Backup criado (${exported.snapshot.totalRecords} registros). '
              '${savedDownloads ? 'Salvo em Downloads como ${exported.fileName}. ' : 'Não foi possível salvar em Downloads. '}'
              'Anote o PIN para importar em outra conta.',
            ),
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } on BackupException catch (e) {
      _showError(e.message);
    } on BackupNativeIoException catch (e) {
      final downloads = exported?.downloadsPath;
      final temp = exported?.filePath;
      _showError(
        downloads != null
            ? '${e.message}\n\nO backup está em Downloads/${exported!.fileName}.'
            : temp != null
                ? '${e.message}\n\nO JSON foi gerado em:\n$temp'
                : e.message,
      );
    } catch (e) {
      _showError('Não foi possível exportar: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<BackupSnapshot?> _pickAndParseSnapshot() async {
    try {
      final bytes = await pickBackupJsonBytes();
      if (bytes == null) return null;

      final snapshot =
          await ref.read(backupServiceProvider).parseFileBytes(bytes);
      snapshot.validateIntegrity();
      return snapshot;
    } on BackupNativeIoException catch (e) {
      _showError(e.message);
      return null;
    } on BackupException catch (e) {
      _showError(e.message);
      return null;
    } catch (e) {
      _showError('Arquivo inválido: $e');
      return null;
    }
  }

  Future<void> _restoreSameAccount() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    final snapshot = await _pickAndParseSnapshot();
    if (snapshot == null || !mounted) return;

    if (!snapshot.isSameAccount(userId)) {
      _showError(
        'Este backup é de outra conta. Use "Importar em outra conta" '
        'e informe o PIN.',
      );
      return;
    }

    final confirmed = await _confirmRestoreDialog(
      snapshot: snapshot,
      title: 'Restaurar backup?',
      extraLines: 'Depois use Sincronizar para enviar à nuvem.',
    );
    if (confirmed != true || !mounted) return;

    await _runRestore(
      snapshot: snapshot,
      userId: userId,
      importToCurrentAccount: false,
    );
  }

  Future<void> _importOtherAccount() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    final snapshot = await _pickAndParseSnapshot();
    if (snapshot == null || !mounted) return;

    if (snapshot.isSameAccount(userId)) {
      _showError(
        'Este backup já é desta conta. Use "Restaurar (mesma conta)".',
      );
      return;
    }

    if (!snapshot.hasTransferPin) {
      _showError(
        'Backup antigo sem PIN. Exporte novamente na conta original '
        'com PIN de 4 dígitos.',
      );
      return;
    }

    final pin = await showBackupTransferPinDialog(
      context,
      mode: BackupPinDialogMode.verifyForImport,
    );
    if (pin == null || !mounted) return;

    try {
      snapshot.validateForCrossAccountImport(pin: pin);
    } on BackupException catch (e) {
      _showError(e.message);
      return;
    }

    final sourceLabel = snapshot.userEmail?.isNotEmpty == true
        ? snapshot.userEmail!
        : 'outra conta';
    final confirmed = await _confirmRestoreDialog(
      snapshot: snapshot,
      title: 'Importar em outra conta?',
      extraLines:
          'Origem: $sourceLabel\n\n'
          'Os dados atuais desta conta neste aparelho serão '
          'substituídos. Depois sincronize para enviar à nuvem.',
    );
    if (confirmed != true || !mounted) return;

    await _runRestore(
      snapshot: snapshot,
      userId: userId,
      importToCurrentAccount: true,
      transferPin: pin,
    );
  }

  Future<bool?> _confirmRestoreDialog({
    required BackupSnapshot snapshot,
    required String title,
    required String extraLines,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(
          'Os dados atuais neste aparelho serão substituídos por:\n\n'
          '• ${snapshot.clients.length} clientes\n'
          '• ${snapshot.loans.length} empréstimos\n'
          '• ${snapshot.payments.length} pagamentos\n\n'
          'Exportado em ${_formatExportedAt(snapshot.exportedAt)}.\n\n'
          '$extraLines',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  Future<void> _runRestore({
    required BackupSnapshot snapshot,
    required String userId,
    required bool importToCurrentAccount,
    String? transferPin,
  }) async {
    setState(() => _busy = true);
    try {
      final summary = await ref.read(backupServiceProvider).restoreSnapshot(
            snapshot: snapshot,
            currentUserId: userId,
            importToCurrentAccount: importToCurrentAccount,
            transferPin: transferPin,
          );
      invalidateDataAfterBackupRestore(ref);
      unawaited(ref.read(syncCoordinatorProvider).requestSync(force: true));
      if (!mounted) return;
      final prefix = summary.importedFromOtherAccount
          ? 'Importado de outra conta'
          : 'Restaurado';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$prefix: ${summary.total} registro(s). '
            'Enviando para a nuvem…',
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    } on BackupException catch (e) {
      _showError(e.message);
    } on BackupNativeIoException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('Falha ao restaurar: $e');
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

  static String _formatExportedAt(String iso) {
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return iso;
    return DateFormat('dd/MM/yyyy HH:mm').format(parsed.toLocal());
  }
}

class _BackupContent extends StatelessWidget {
  const _BackupContent({
    required this.snapshot,
    required this.busy,
    required this.onExport,
    required this.onRestoreSameAccount,
    required this.onImportOtherAccount,
  });

  final BackupSnapshot snapshot;
  final bool busy;
  final VoidCallback onExport;
  final VoidCallback onRestoreSameAccount;
  final VoidCallback onImportOtherAccount;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        kBottomNavReservedHeight + AppSpacing.lg,
      ),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSpacing.maxContentWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _BackupSurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            decoration:
                                AppDecorations.iconBadge(color: AppColors.accent),
                            child: const Icon(
                              LucideIcons.hard_drive,
                              size: 22,
                              color: AppColors.accent,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              'Cópia de segurança',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Salve um arquivo JSON com clientes, empréstimos e '
                        'pagamentos. O backup é salvo em Downloads e você '
                        'pode compartilhar. PIN de 4 dígitos para importar '
                        'em outra conta.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: context.appTheme.textSecondary,
                              height: 1.45,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _BackupSurfaceCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      _CountChip(
                        label: 'Clientes',
                        count: snapshot.clients.length,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _CountChip(
                        label: 'Empréstimos',
                        count: snapshot.loans.length,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _CountChip(
                        label: 'Pagamentos',
                        count: snapshot.payments.length,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton.icon(
                  onPressed: busy ? null : onExport,
                  icon: const Icon(LucideIcons.share_2, size: 20),
                  label: const Text('Criar backup e compartilhar'),
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: busy ? null : onRestoreSameAccount,
                  icon: const Icon(LucideIcons.upload, size: 20),
                  label: const Text('Restaurar (mesma conta)'),
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: busy ? null : onImportOtherAccount,
                  icon: const Icon(LucideIcons.key_round, size: 20),
                  label: const Text('Importar em outra conta'),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Mesma conta: login igual ao da exportação, sem PIN. '
                  'Outra conta: PIN obrigatório; substitui os dados locais '
                  'desta conta e depois sincronize.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: context.appTheme.textSecondary,
                        height: 1.35,
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.sm,
          horizontal: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: context.appTheme.border.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    color: context.appTheme.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackupSurfaceCard extends StatelessWidget {
  const _BackupSurfaceCard({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: context.appTheme.border),
        boxShadow: context.appTheme.cardShadow,
      ),
      child: child,
    );
  }
}
