import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/providers/app_data_invalidation.dart';
import '../../../../shared/widgets/attention_lucide_icon.dart';
import '../../../../services/sync/sync_providers.dart';
import '../../../payments/presentation/providers/payments_providers.dart';
import '../../domain/loan_installment_status.dart';
import '../../domain/loan_schedule_builder.dart';
import '../../domain/loan_status_sync.dart';
import '../../domain/loan_simulator.dart';
import '../../../notifications/notification_reschedule.dart';
import '../providers/loans_providers.dart';
import 'installment_card_style.dart';
import 'pay_installment_dialog.dart';

class LoanInstallmentCard extends ConsumerStatefulWidget {
  const LoanInstallmentCard({
    super.key,
    required this.loanId,
    required this.item,
  });

  final String loanId;
  final LoanInstallmentItem item;

  @override
  ConsumerState<LoanInstallmentCard> createState() =>
      _LoanInstallmentCardState();
}

class _LoanInstallmentCardState extends ConsumerState<LoanInstallmentCard> {
  bool _busy = false;

  static String _formatIsoDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> _pay() async {
    final paidOn = await PayInstallmentDialog.show(context, widget.item);
    if (paidOn == null || !mounted) return;

    setState(() => _busy = true);
    try {
      final paymentsRepo = ref.read(paymentsRepositoryProvider);
      final loansRepo = ref.read(loansRepositoryProvider);

      await paymentsRepo.payInstallment(
        loanId: widget.loanId,
        installmentNumber: widget.item.number,
        amount: LoanScheduleBuilder.amountToStorage(widget.item.amount),
        paymentDate: _formatIsoDate(paidOn),
      );
      await LoanStatusSync.refresh(
        loansRepo: loansRepo,
        paymentsRepo: paymentsRepo,
        loanId: widget.loanId,
      );
      invalidateAppDataCacheWidgetRef(ref);
      await ref.read(syncServiceProvider).processQueue();
      await rescheduleLoanNotifications(ref);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Parcela ${widget.item.number} registrada como paga'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _undo() async {
    final confirm = await UndoInstallmentPaymentDialog.show(
      context,
      widget.item,
    );

    if (!confirm || !mounted) return;

    setState(() => _busy = true);
    try {
      final paymentsRepo = ref.read(paymentsRepositoryProvider);
      final loansRepo = ref.read(loansRepositoryProvider);

      await paymentsRepo.undoInstallment(widget.loanId, widget.item.number);
      await LoanStatusSync.refresh(
        loansRepo: loansRepo,
        paymentsRepo: paymentsRepo,
        loanId: widget.loanId,
      );
      invalidateAppDataCacheWidgetRef(ref);
      await ref.read(syncServiceProvider).processQueue();
      await rescheduleLoanNotifications(ref);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Pagamento desfeito')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final style = InstallmentCardStyle.resolve(item);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: style.fill,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: style.border, width: style.borderWidth),
        boxShadow: style.shadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _InstallmentStatusBadge(
            number: item.number,
            status: item.status,
            isDueToday: item.isDueToday,
            color: style.color,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _StatusChip(style: style),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  LoanSimulator.formatMoney(item.amount),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  LoanSimulator.formatDate(item.dueDate),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                if (item.isPaid && item.paidDate != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Pago ${LoanSimulator.formatDate(item.paidDate!)}'
                    '${item.paymentTimingLabel != null ? ' · ${item.paymentTimingLabel}' : ''}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: _timingColor(context, item),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(
            width: 48,
            child: Center(
              child: _busy
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : item.canPay
                  ? IconButton(
                      tooltip: 'Registrar pagamento',
                      onPressed: _pay,
                      icon: const Icon(Icons.payments_outlined),
                      color: style.color,
                    )
                  : item.canUndo
                  ? IconButton(
                      tooltip: 'Desfazer pagamento',
                      onPressed: _undo,
                      icon: const Icon(Icons.undo_rounded),
                      color: AppColors.warning,
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

Color _timingColor(BuildContext context, LoanInstallmentItem item) {
  if (item.paidDate == null) {
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }
  final due = DateTime(item.dueDate.year, item.dueDate.month, item.dueDate.day);
  final paid = DateTime(
    item.paidDate!.year,
    item.paidDate!.month,
    item.paidDate!.day,
  );
  if (paid.isAfter(due)) return AppColors.error;
  if (paid.isBefore(due)) return AppColors.info;
  return AppColors.success;
}

class _InstallmentStatusBadge extends StatelessWidget {
  const _InstallmentStatusBadge({
    required this.number,
    required this.status,
    required this.isDueToday,
    required this.color,
  });

  final int number;
  final LoanInstallmentStatus status;
  final bool isDueToday;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _statusIcon(status, isDueToday, color),
          const SizedBox(height: 2),
          Text(
            '$number',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: color,
                  fontSize: 10,
                  height: 1,
                ),
          ),
        ],
      ),
    );
  }

  Widget _statusIcon(
    LoanInstallmentStatus status,
    bool isDueToday,
    Color color,
  ) {
    if (isDueToday) {
      return AttentionLucideIcon(
        icon: LucideIcons.bell,
        color: color,
        size: 22,
      );
    }
    return switch (status) {
      LoanInstallmentStatus.paid => Icon(
          LucideIcons.circle_check,
          size: 22,
          color: color,
        ),
      LoanInstallmentStatus.overdue => AttentionLucideIcon(
          icon: LucideIcons.triangle_alert,
          color: color,
          size: 22,
        ),
      LoanInstallmentStatus.pending => Icon(
          LucideIcons.clock,
          size: 22,
          color: color,
        ),
    };
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.style});

  final InstallmentCardStyle style;

  @override
  Widget build(BuildContext context) {
    final icon = switch (style.status) {
      LoanInstallmentStatus.paid => LucideIcons.circle_check,
      LoanInstallmentStatus.overdue => LucideIcons.triangle_alert,
      LoanInstallmentStatus.pending when style.isDueToday => LucideIcons.bell,
      LoanInstallmentStatus.pending => LucideIcons.clock,
    };

    final label = style.isDueToday ? 'Vence hoje' : style.status.label;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: style.color.withValues(alpha: style.isDueToday ? 0.22 : 0.18),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: style.color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: style.color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: style.color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
