import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../services/sync/sync_providers.dart';
import '../../../payments/presentation/providers/payments_providers.dart';
import '../../domain/loan_installment_status.dart';
import '../../domain/loan_schedule_builder.dart';
import '../../domain/loan_status_sync.dart';
import '../../domain/loan_simulator.dart';
import '../providers/loans_providers.dart';
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
      ref.invalidate(allLoansProvider);
      await ref.read(syncServiceProvider).processQueue();
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
      ref.invalidate(allLoansProvider);
      await ref.read(syncServiceProvider).processQueue();
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

    final statusColor = switch (item.status) {
      LoanInstallmentStatus.paid => AppColors.success,
      LoanInstallmentStatus.overdue => AppColors.error,
      LoanInstallmentStatus.pending => AppColors.accent,
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: item.status == LoanInstallmentStatus.overdue
              ? AppColors.error.withValues(alpha: 0.35)
              : Theme.of(context).dividerColor.withValues(alpha: 0.85),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Text(
              '${item.number}',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: statusColor,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _StatusChip(status: item.status),
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
                      color: AppColors.accent,
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final LoanInstallmentStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      LoanInstallmentStatus.paid => AppColors.success,
      LoanInstallmentStatus.overdue => AppColors.error,
      LoanInstallmentStatus.pending => AppColors.accent,
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        status.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
