import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../services/supabase/supabase_providers.dart';
import '../../../../shared/widgets/floating_notched_nav_bar.dart';
import '../../domain/backup_snapshot.dart';
import '../providers/backup_providers.dart';

class BackupPage extends ConsumerStatefulWidget {
  const BackupPage({super.key});

  @override
  ConsumerState<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends ConsumerState<BackupPage> {
  bool _busy = false;

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
                  onRestore: _restoreBackup,
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

    setState(() => _busy = true);
    try {
      final session = ref.read(sessionProvider).valueOrNull;
      final file = await ref.read(backupServiceProvider).exportToFile(
            userId: userId,
            userEmail: session?.user.email,
          );
      await Share.shareXFiles(
        [XFile(file.filePath, name: file.fileName)],
        text:
            'Backup Facilite Plus — ${file.snapshot.totalRecords} registro(s)',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Backup criado (${file.snapshot.totalRecords} registros).',
            ),
          ),
        );
      }
    } on BackupException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('Não foi possível exportar: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restoreBackup() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return;
    final bytes = picked.files.single.bytes;
    if (bytes == null || bytes.isEmpty) {
      _showError('Arquivo vazio ou inacessível.');
      return;
    }

    BackupSnapshot snapshot;
    try {
      snapshot = await ref.read(backupServiceProvider).parseFileBytes(bytes);
      snapshot.validateForRestore(currentUserId: userId);
    } on BackupException catch (e) {
      _showError(e.message);
      return;
    } catch (e) {
      _showError('Arquivo inválido: $e');
      return;
    }

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restaurar backup?'),
        content: Text(
          'Os dados atuais neste aparelho serão substituídos por:\n\n'
          '• ${snapshot.clients.length} clientes\n'
          '• ${snapshot.loans.length} empréstimos\n'
          '• ${snapshot.payments.length} pagamentos\n\n'
          'Exportado em ${_formatExportedAt(snapshot.exportedAt)}.\n\n'
          'Depois use Sincronizar para enviar à nuvem.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      final summary = await ref.read(backupServiceProvider).restoreSnapshot(
            snapshot: snapshot,
            currentUserId: userId,
          );
      invalidateDataAfterBackupRestore(ref);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Restaurado: ${summary.total} registro(s). '
            'Sincronize para atualizar a nuvem.',
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    } on BackupException catch (e) {
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
    required this.onRestore,
  });

  final BackupSnapshot snapshot;
  final bool busy;
  final VoidCallback onExport;
  final VoidCallback onRestore;

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
                        'pagamentos. No outro celular, entre na mesma conta, '
                        'restaure o arquivo e sincronize.',
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
                  onPressed: busy ? null : onRestore,
                  icon: const Icon(LucideIcons.upload, size: 20),
                  label: const Text('Restaurar de arquivo'),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'A restauração substitui os dados deste aparelho. '
                  'Use apenas backups da sua conta.',
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
