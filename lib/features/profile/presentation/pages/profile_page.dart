import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../services/supabase/supabase_providers.dart';
import '../providers/profile_providers.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _nameController = TextEditingController();
  bool _nameEdited = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);
    final ctrlState = ref.watch(profileControllerProvider);
    final ctrl = ref.read(profileControllerProvider.notifier);
    final session = ref.watch(sessionProvider).valueOrNull;
    final email = session?.user.email ?? '';
    final brightness = Theme.of(context).brightness;

    ref.listen(profileControllerProvider, (_, next) {
      final msg = next.successMessage ?? next.error;
      if (msg != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor:
                next.successMessage != null ? AppColors.success : AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ctrl.clearMessages();
      }
    });

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: const Text('Meu perfil'),
        centerTitle: false,
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppDecorations.screenBackground(brightness),
        ),
        child: profileAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(
            child: Text('Não foi possível carregar o perfil.'),
          ),
          data: (profile) {
            // Preenche o campo de nome apenas uma vez quando o perfil carrega.
            if (!_nameEdited && profile != null && profile.name != null) {
              _nameController.text = profile.name!;
            }

            final displayEmail = email.isEmpty ? 'Sem e-mail' : email;
            final createdLabel = profile?.createdAt != null
                ? DateFormat("dd 'de' MMMM 'de' yyyy", 'pt_BR')
                    .format(profile!.createdAt!)
                : '—';

            return ListView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                MediaQuery.of(context).padding.bottom + AppSpacing.xl,
              ),
              children: [
                // ── Avatar + e-mail ─────────────────────────────────────
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor:
                            AppColors.accent.withValues(alpha: 0.15),
                        child: Text(
                          _initials(
                            profile?.name,
                            email,
                          ),
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.accent,
                              ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        displayEmail,
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: context.appTheme.textSecondary,
                                ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // ── Nome de exibição ─────────────────────────────────────
                _SectionLabel(label: 'Nome de exibição'),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _nameController,
                  onChanged: (_) => setState(() => _nameEdited = true),
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    hintText: 'Ex.: Victor Cruz',
                    prefixIcon: const Icon(LucideIcons.user, size: 18),
                    suffixIcon: ctrlState.isSaving
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Aparece como saudação no painel principal.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.appTheme.textSecondary,
                      ),
                ),
                const SizedBox(height: AppSpacing.md),
                FilledButton.icon(
                  onPressed: ctrlState.isSaving
                      ? null
                      : () => ctrl.saveName(_nameController.text),
                  icon: const Icon(LucideIcons.save, size: 18),
                  label: const Text('Salvar nome'),
                ),

                const SizedBox(height: AppSpacing.xl),

                // ── Informações da conta ─────────────────────────────────
                _SectionLabel(label: 'Informações da conta'),
                const SizedBox(height: AppSpacing.sm),
                _InfoRow(
                  icon: LucideIcons.mail,
                  label: 'E-mail',
                  value: displayEmail,
                ),
                const SizedBox(height: AppSpacing.sm),
                _InfoRow(
                  icon: LucideIcons.calendar,
                  label: 'Membro desde',
                  value: createdLabel,
                ),

                const SizedBox(height: AppSpacing.xl),

                // ── Segurança ────────────────────────────────────────────
                _SectionLabel(label: 'Segurança'),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: ctrlState.isSaving || email.isEmpty
                      ? null
                      : () => ctrl.sendPasswordReset(email),
                  icon: const Icon(LucideIcons.key_round, size: 18),
                  label: const Text('Alterar senha por e-mail'),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Enviaremos um link de redefinição para $displayEmail.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.appTheme.textSecondary,
                      ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _initials(String? name, String email) {
    if (name != null && name.trim().isNotEmpty) {
      final parts = name.trim().split(RegExp(r'\s+'));
      if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
      return parts.first[0].toUpperCase();
    }
    return email.isNotEmpty ? email[0].toUpperCase() : '?';
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: context.appTheme.textSecondary,
          ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: context.appTheme.border),
        boxShadow: context.appTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: AppDecorations.iconBadge(
                color: context.appTheme.textSecondary),
            child: Icon(icon, size: 18,
                color: context.appTheme.textSecondary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: context.appTheme.textSecondary,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
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
