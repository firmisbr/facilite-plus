import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/attention_lucide_icon.dart';
import '../../domain/entities/loan_with_client.dart';
import '../../domain/loan_simulator.dart';
import '../../domain/loan_installment_status.dart';
import '../providers/loan_detail_providers.dart';
import 'installment_card_style.dart';
import 'loan_installment_status_strip.dart';

class LoanListCard extends ConsumerWidget {
  const LoanListCard({
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

    final principal =
        LoanSimulator.parseAmount(loan.amount) ?? 0;
    final principalText = LoanSimulator.formatMoney(principal);

    final nextDue = summary?.nextDueDate;
    final nextDueText = nextDue != null
        ? LoanSimulator.formatDate(nextDue)
        : (loan.firstDueDate != null
            ? LoanSimulator.formatDate(
                DateTime.tryParse(loan.firstDueDate!) ?? DateTime.now(),
              )
            : '—');

    final installments = summary?.installments ?? const <LoanInstallmentItem>[];
    final overdueCount = summary?.overdueInstallments ?? 0;
    final paid = summary?.paidInstallments ?? 0;
    final total = summary?.totalInstallments ?? loan.installments ?? 0;
    final progress = total > 0 ? paid / total : 0.0;
    final isQuitado = total > 0 && paid >= total;
    final isOverdue = summary?.isNextDueOverdue ?? false;
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap ?? () => context.push(AppRoutes.loanDetail(loan.id)),
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        child: Ink(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            border: Border.all(
              color: borderColor,
              width: selected ? 2 : 1,
            ),
            boxShadow: context.appTheme.cardShadow,
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: AppDecorations.iconBadge(color: accent),
                    child: _LoanCardStatusIcon(
                      style: style,
                      isQuitado: isQuitado,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.clientName,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '$paid/$total · $principalText',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: accent,
                                height: 1.05,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    LucideIcons.chevron_right,
                    size: 18,
                    color: context.appTheme.textSecondary,
                  ),
                ],
              ),
              if (overdueCount > 0) ...[
                const SizedBox(height: AppSpacing.sm),
                _StatusChip(
                  label: overdueCount == 1
                      ? '1 parcela em atraso'
                      : '$overdueCount parcelas em atraso',
                  color: AppColors.error,
                ),
              ] else if (isQuitado) ...[
                const SizedBox(height: AppSpacing.sm),
                _StatusChip(
                  label: 'Quitado',
                  color: accent,
                ),
              ] else if (isNextDueToday) ...[
                const SizedBox(height: AppSpacing.sm),
                _StatusChip(
                  label: 'Vence hoje',
                  color: accent,
                ),
              ],
              if (!isQuitado && nextDue != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '${isOverdue ? 'Venceu em' : 'Próximo venc.'} $nextDueText',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isOverdue || isNextDueToday
                            ? accent
                            : context.appTheme.textSecondary,
                        fontWeight: isOverdue || isNextDueToday
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                ),
              ],
              if (total > 0) ...[
                const SizedBox(height: AppSpacing.sm),
                LoanInstallmentStatusStrip(
                  installments: installments,
                  fallbackProgress: progress,
                  fallbackColor: accent,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LoanCardStatusIcon extends StatelessWidget {
  const _LoanCardStatusIcon({
    required this.style,
    required this.isQuitado,
  });

  final InstallmentCardStyle style;
  final bool isQuitado;

  @override
  Widget build(BuildContext context) {
    if (isQuitado) {
      return Icon(LucideIcons.circle_check, size: 20, color: style.color);
    }
    if (style.isDueToday) {
      return Icon(LucideIcons.bell, size: 20, color: style.color);
    }
    return switch (style.status) {
      LoanInstallmentStatus.overdue => AttentionLucideIcon(
          icon: LucideIcons.triangle_alert,
          size: 20,
          color: style.color,
        ),
      LoanInstallmentStatus.pending => Icon(
          LucideIcons.clock,
          size: 20,
          color: style.color,
        ),
      LoanInstallmentStatus.paid => Icon(
          LucideIcons.circle_check,
          size: 20,
          color: style.color,
        ),
    };
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }
}
