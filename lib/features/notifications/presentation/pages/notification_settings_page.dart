import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/floating_notched_nav_bar.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../services/notifications/installment_due_scanner.dart';
import '../../../../services/notifications/local_notification_service.dart';
import '../../../../services/notifications/notification_prefs.dart';
import '../../notification_reschedule.dart';
import '../../../../services/notifications/notification_scheduler.dart';
import '../providers/notification_providers.dart';

class NotificationSettingsPage extends ConsumerStatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  ConsumerState<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState
    extends ConsumerState<NotificationSettingsPage> {
  NotificationPrefs? _prefs;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await NotificationPrefs.load();
    if (!mounted) return;
    setState(() {
      _prefs = prefs;
      _loading = false;
    });
  }

  Future<void> _persist(NotificationPrefs prefs) async {
    setState(() {
      _prefs = prefs;
      _saving = true;
    });
    await prefs.save();
    ref.invalidate(notificationPrefsProvider);
    ref.invalidate(notificationPreviewProvider);
    await rescheduleLoanNotifications(ref);
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _pickTime() async {
    final prefs = _prefs;
    if (prefs == null) return;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: prefs.hour, minute: prefs.minute),
      helpText: 'Horário do lembrete',
    );
    if (picked == null) return;
    await _persist(
      prefs.copyWith(hour: picked.hour, minute: picked.minute),
    );
  }

  Future<void> _requestPermissions() async {
    final ok = await LocalNotificationService.requestPermissions();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Permissão de notificações concedida'
              : 'Permissão negada — ative nas configurações do celular',
        ),
      ),
    );
  }

  Future<void> _testNotification() async {
    final ok = await LocalNotificationService.requestPermissions();
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ative as notificações para receber lembretes'),
        ),
      );
      return;
    }
    await NotificationScheduler.showTestNotification();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notificação de teste enviada')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = ref.watch(notificationPreviewProvider);
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificações'),
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppDecorations.screenBackground(brightness),
        ),
        child: _loading || _prefs == null
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
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
                            _HintCard(
                              child: Text(
                                'Os lembretes usam os dados do aparelho. '
                                'Ao abrir o app, o cronograma dos próximos '
                                '14 dias é atualizado.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(height: 1.35),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            preview.when(
                              data: (scan) => _PreviewCard(scan: scan),
                              loading: () => const SizedBox.shrink(),
                              error: (_, _) => const SizedBox.shrink(),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            _SectionLabel(title: 'Geral'),
                            const SizedBox(height: AppSpacing.sm),
                            _SwitchTile(
                              icon: LucideIcons.bell,
                              title: 'Ativar notificações',
                              subtitle: 'Lembretes de cobrança no horário escolhido',
                              value: _prefs!.enabled,
                              onChanged: (v) => _persist(
                                _prefs!.copyWith(enabled: v),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            _ActionTile(
                              icon: LucideIcons.clock,
                              title: 'Horário do lembrete',
                              subtitle: _prefs!.timeLabel,
                              onTap: _prefs!.enabled ? _pickTime : null,
                              enabled: _prefs!.enabled,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            _SectionLabel(title: 'O que avisar'),
                            const SizedBox(height: AppSpacing.sm),
                            _SwitchTile(
                              icon: LucideIcons.calendar_clock,
                              title: 'Parcelas que vencem hoje',
                              subtitle:
                                  'No dia do vencimento, no horário definido',
                              value: _prefs!.dueTodayEnabled,
                              onChanged: _prefs!.enabled
                                  ? (v) => _persist(
                                        _prefs!.copyWith(dueTodayEnabled: v),
                                      )
                                  : null,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            _SwitchTile(
                              icon: LucideIcons.triangle_alert,
                              title: 'Parcelas em atraso',
                              subtitle:
                                  'Lembrete diário se houver parcelas vencidas',
                              value: _prefs!.overdueEnabled,
                              onChanged: _prefs!.enabled
                                  ? (v) => _persist(
                                        _prefs!.copyWith(overdueEnabled: v),
                                      )
                                  : null,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            _SectionLabel(title: 'Permissões'),
                            const SizedBox(height: AppSpacing.sm),
                            _ActionTile(
                              icon: LucideIcons.shield_check,
                              title: 'Permitir notificações',
                              subtitle:
                                  'Necessário no Android 13+ e para alarmes exatos',
                              onTap: _requestPermissions,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            OutlinedButton.icon(
                              onPressed: _testNotification,
                              icon: const Icon(LucideIcons.bell_ring),
                              label: const Text('Enviar notificação de teste'),
                            ),
                            if (_saving) ...[
                              const SizedBox(height: AppSpacing.md),
                              const Center(
                                child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.accent,
          ),
    );
  }
}

class _HintCard extends StatelessWidget {
  const _HintCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
      ),
      child: child,
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.scan});

  final DueInstallmentScanResult scan;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: context.appTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Agora na carteira',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Hoje: ${scan.dueOnDayCount} parcela(s) a vencer',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (scan.dueOnDayCount > 0)
            Text(
              scan.dueOnDayCount == 1 && scan.dueOnDayLines.isNotEmpty
                  ? 'Ex.: ${scan.dueOnDayLines.first.clientName}'
                  : 'Próximo aviso no horário configurado',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.appTheme.textSecondary,
                  ),
            ),
          Text(
            'Em atraso: ${scan.overdueCount} parcela(s)',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Row(
        children: [
          Icon(icon, color: AppColors.accent),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.appTheme.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.accent,
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: Row(
          children: [
            Icon(icon, color: AppColors.accent),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.appTheme.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            if (enabled)
              Icon(
                LucideIcons.chevron_right,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: context.appTheme.border),
        boxShadow: context.appTheme.cardShadow,
      ),
      child: child,
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        child: content,
      ),
    );
  }
}
