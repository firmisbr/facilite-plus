import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../clients/domain/entities/client.dart';
import '../../../clients/presentation/providers/clients_providers.dart';
import '../../../../shared/utils/br_cpf_input_formatter.dart';
import '../../../../shared/utils/br_phone_input_formatter.dart';

/// Diálogo para escolher um cliente já cadastrado (ordem alfabética).
class SelectExistingClientDialog extends ConsumerStatefulWidget {
  const SelectExistingClientDialog({super.key});

  static Future<Client?> show(BuildContext context) {
    return showDialog<Client>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => const SelectExistingClientDialog(),
    );
  }

  @override
  ConsumerState<SelectExistingClientDialog> createState() =>
      _SelectExistingClientDialogState();
}

class _SelectExistingClientDialogState
    extends ConsumerState<SelectExistingClientDialog> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Client> _sorted(List<Client> clients) {
    final list = [...clients];
    list.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return list;
  }

  List<Client> _filtered(List<Client> clients) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _sorted(clients);
    final digits = q.replaceAll(RegExp(r'\D'), '');
    return _sorted(clients).where((c) {
      final hay = [
        c.name,
        c.phone,
        c.document,
        c.email,
      ].whereType<String>().join(' ').toLowerCase();
      if (hay.contains(q)) return true;
      if (digits.length >= 3) {
        final doc = (c.document ?? '').replaceAll(RegExp(r'\D'), '');
        final phone = (c.phone ?? '').replaceAll(RegExp(r'\D'), '');
        return doc.contains(digits) || phone.contains(digits);
      }
      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(clientsStreamProvider);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 440,
          maxHeight: MediaQuery.sizeOf(context).height * 0.78,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.12),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: const Icon(
                      LucideIcons.users,
                      color: AppColors.accent,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Cliente existente',
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(LucideIcons.x),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar por nome, CPF ou WhatsApp',
                  prefixIcon: const Icon(LucideIcons.search, size: 20),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Flexible(
              child: clientsAsync.when(
                data: (clients) {
                  final visible = _filtered(clients);
                  if (clients.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: Text(
                        'Nenhum cliente cadastrado.',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  if (visible.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: Text(
                        'Nenhum cliente encontrado.',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.lg,
                    ),
                    itemCount: visible.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.xs),
                    itemBuilder: (context, index) {
                      final client = visible[index];
                      return _ClientPickTile(
                        client: client,
                        onTap: () => Navigator.pop(context, client),
                      );
                    },
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(AppSpacing.xxl),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text('Erro: $e'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClientPickTile extends StatelessWidget {
  const _ClientPickTile({required this.client, required this.onTap});

  final Client client;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = <String>[
      if (client.phone != null && client.phone!.trim().isNotEmpty)
        BrPhoneInputFormatter.formatDisplay(client.phone),
      if (client.document != null && client.document!.trim().isNotEmpty)
        BrCpfInputFormatter.formatDisplay(client.document),
    ].join(' · ');

    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest
          .withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.accent.withValues(alpha: 0.15),
                child: Text(
                  client.name.isNotEmpty
                      ? client.name.trim()[0].toUpperCase()
                      : '?',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.labelSmall
                            ?.copyWith(
                          color: context.appTheme.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                LucideIcons.chevron_right,
                size: 18,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
