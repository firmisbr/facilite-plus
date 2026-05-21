import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../services/sync/sync_providers.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../payments/presentation/providers/payments_providers.dart';
import '../../domain/loan_installment_status.dart';
import '../../domain/loan_schedule_builder.dart';
import '../../domain/loan_simulator.dart';

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

  Future<void> _pay() async {
    setState(() => _busy = true);
    try {
      await ref.read(paymentsRepositoryProvider).payInstallment(
            loanId: widget.loanId,
            installmentNumber: widget.item.number,
            amount: LoanScheduleBuilder.amountToStorage(widget.item.amount),
          );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
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
      await ref.read(paymentsRepositoryProvider).undoInstallment(
            widget.loanId,
            widget.item.number,
          );
      await ref.read(syncServiceProvider).processQueue();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pagamento desfeito')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
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
      LoanInstallmentStatus.paid => AppColors.lightTextSecondary,
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
