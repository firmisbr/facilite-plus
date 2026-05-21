import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../services/sync/sync_providers.dart';
import '../../../../shared/widgets/app_card.dart';
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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Desfazer pagamento?'),
        content: Text(
          'A parcela ${widget.item.number} voltará a ficar em aberto.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Desfazer'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

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

    return AppCard(
      child: Row(
        children: [
          _InstallmentBadge(number: item.number),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _StatusChip(status: item.status),
                    const Spacer(),
                    Text(
                      LoanSimulator.formatMoney(item.amount),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Vencimento: ${LoanSimulator.formatDate(item.dueDate)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (item.isPaid && item.paidDate != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Pago em: ${LoanSimulator.formatDate(item.paidDate!)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (item.paymentTimingLabel != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.paymentTimingLabel!,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: _timingColor(context, item),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
          if (_busy)
            const Padding(
              padding: EdgeInsets.only(left: AppSpacing.sm),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (item.canPay)
            IconButton(
              tooltip: 'Registrar pagamento',
              onPressed: _pay,
              icon: const Icon(Icons.payments_outlined),
              color: AppColors.accent,
            )
          else if (item.canUndo)
            IconButton(
              tooltip: 'Desfazer pagamento',
              onPressed: _undo,
              icon: const Icon(Icons.undo_rounded),
              color: Theme.of(context).colorScheme.onSurfaceVariant,
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

class _InstallmentBadge extends StatelessWidget {
  const _InstallmentBadge({required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 18,
      backgroundColor: AppColors.accent.withValues(alpha: 0.15),
      child: Text(
        '$number',
        style: const TextStyle(
          color: AppColors.accent,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
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
