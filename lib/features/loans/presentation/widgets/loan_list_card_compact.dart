import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/attention_lucide_icon.dart';
import '../../domain/entities/loan_with_client.dart';
import '../../domain/loan_installment_status.dart';
import '../../domain/loan_simulator.dart';
import '../providers/loan_detail_providers.dart';
import 'installment_card_style.dart';
import 'loan_installment_status_strip.dart';

/// Card enxuto para listas longas de empréstimos.
class LoanListCardCompact extends ConsumerWidget {
  const LoanListCardCompact({
    required this.item,
    super.key,
    this.selecting = false,
    this.selected = false,
    this.onTap,
    this.onLongPress,
  });

  final LoanWithClient item;
  final bool selecting;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loan = item.loan;
    final summary = ref.watch(loanCardSummaryProvider(loan.id));

    final principalText = LoanSimulator.formatMoney(
      LoanSimulator.parseAmount(loan.amount) ?? 0,
    );

    final installments = summary?.installments ?? const <LoanInstallmentItem>[];
    final nextDue = summary?.nextDueDate;
    final nextDueText = nextDue != null
        ? LoanSimulator.formatDate(nextDue)
        : '—';

    final isOverdue = summary?.isNextDueOverdue ?? false;
    final paid = summary?.paidInstallments ?? 0;
    final total = summary?.totalInstallments ?? loan.installments ?? 0;
    final progress = total > 0 ? paid / total : 0.0;
    final isQuitado = total > 0 && paid >= total;
    final isNextDueToday =
        InstallmentCardStyle.nextOpenInstallment(installments)?.isDueToday ??
            false;

    final style = InstallmentCardStyle.forLoanCard(
      installments: installments,
      isQuitado: isQuitado,
    );
    final accent = style.color;

    final borderColor = selected
        ? AppColors.accent.withValues(alpha: 0.65)
        : isOverdue || isNextDueToday
            ? style.border.withValues(alpha: 0.55)
            : context.appTheme.border;

    final subtitle = isQuitado
        ? '$principalText · $paid/$total · Quitado'
        : isNextDueToday
            ? '$paid/$total · $principalText · Vence hoje'
            : '$paid/$total · $principalText · $nextDueText';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap ?? () => context.push(AppRoutes.loanDetail(loan.id)),
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Ink(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: borderColor,
              width: selected ? 2 : 1,
            ),
            boxShadow: context.appTheme.cardShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm + 2,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: _CompactStatusIcon(
                        style: style,
                        isQuitado: isQuitado,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.clientName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: isOverdue || isNextDueToday
                                          ? accent
                                          : context.appTheme.textSecondary,
                                      fontWeight: isOverdue || isNextDueToday
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Icon(
                      LucideIcons.chevron_right,
                      size: 16,
                      color: context.appTheme.textSecondary,
                    ),
                  ],
                ),
              ),
              if (total > 0)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(AppSpacing.radiusLg),
                  ),
                  child: LoanInstallmentStatusStrip(
                    installments: installments,
                    height: 3,
                    fallbackProgress: progress,
                    fallbackColor: accent,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactStatusIcon extends StatelessWidget {
  const _CompactStatusIcon({
    required this.style,
    required this.isQuitado,
  });

  final InstallmentCardStyle style;
  final bool isQuitado;

  @override
  Widget build(BuildContext context) {
    if (isQuitado) {
      return Icon(LucideIcons.circle_check, size: 16, color: style.color);
    }
    if (style.isDueToday) {
      return Icon(LucideIcons.bell, size: 16, color: style.color);
    }
    return switch (style.status) {
      LoanInstallmentStatus.overdue => AttentionLucideIcon(
          icon: LucideIcons.triangle_alert,
          size: 16,
          color: style.color,
        ),
      LoanInstallmentStatus.pending => Icon(
          LucideIcons.clock,
          size: 16,
          color: style.color,
        ),
      LoanInstallmentStatus.paid => Icon(
          LucideIcons.circle_check,
          size: 16,
          color: style.color,
        ),
    };
  }
}
