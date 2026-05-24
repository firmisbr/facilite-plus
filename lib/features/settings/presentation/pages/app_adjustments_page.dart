import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/floating_notched_nav_bar.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../../loans/domain/loan_periodicity.dart';
import '../../../loans/domain/loan_status_sync.dart';
import '../../../loans/presentation/providers/loans_providers.dart';
import '../../../notifications/notification_reschedule.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';
import '../../../payments/presentation/providers/payments_providers.dart';
import '../providers/daily_loan_skip_sunday_provider.dart';

class AppAdjustmentsPage extends ConsumerWidget {
  const AppAdjustmentsPage({super.key});

  Future<void> _onSkipSundayChanged(WidgetRef ref, bool enabled) async {
    await ref.read(dailyLoanSkipSundayProvider.notifier).setEnabled(enabled);

    final loansRepo = ref.read(loansRepositoryProvider);
    final paymentsRepo = ref.read(paymentsRepositoryProvider);
    final loans = ref.read(allLoansProvider).valueOrNull ?? [];

    final dailyIds = loans
        .where(
          (item) =>
              LoanPeriodicity.fromValue(item.loan.periodicity) ==
              LoanPeriodicity.diaria,
        )
        .map((item) => item.loan.id)
        .toList();

    if (dailyIds.isNotEmpty) {
      await LoanStatusSync.reconcileOpenLoans(
        loansRepo: loansRepo,
        paymentsRepo: paymentsRepo,
        loanIds: dailyIds,
      );
    }

    ref.invalidate(dashboardStatsProvider);
    ref.invalidate(notificationPreviewProvider);
    await rescheduleLoanNotifications(ref);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skipSunday = ref.watch(dailyLoanSkipSundayProvider);
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppDecorations.screenBackground(brightness),
        ),
        child: SafeArea(
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
                          'Vale só para empréstimos com periodicidade diária. '
                          'Com a opção ativa, não há parcela aos domingos: '
                          'cobrança de segunda a sábado. Empréstimos já '
                          'cadastrados são recalculados na hora.',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(height: 1.35),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _SectionLabel(title: 'Empréstimos diários'),
                      const SizedBox(height: AppSpacing.sm),
                      _SwitchTile(
                        icon: LucideIcons.calendar_off,
                        title: 'Folga aos domingos',
                        subtitle:
                            'Sem parcela no domingo; atraso e lembretes '
                            'seguem seg–sáb',
                        value: skipSunday,
                        onChanged: (v) => _onSkipSundayChanged(ref, v),
                      ),
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
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: SwitchListTile(
        secondary: Icon(icon, color: AppColors.accent),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
