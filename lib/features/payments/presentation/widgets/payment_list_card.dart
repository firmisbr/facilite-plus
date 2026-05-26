import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/utils/whatsapp_utils.dart';
import '../../../../shared/widgets/attention_lucide_icon.dart';
import '../../../loans/domain/loan_installment_status.dart';
import '../../../loans/domain/loan_simulator.dart';
import '../../../loans/presentation/widgets/installment_card_style.dart';
import '../../../loans/presentation/widgets/loan_installment_status_strip.dart';
import '../../domain/payment_loan_card_display.dart';
import '../../domain/payments_overview.dart';

class PaymentListCard extends StatelessWidget {
  const PaymentListCard({
    required this.item,
    required this.onWhatsApp,
    super.key,
  });

  final PaymentLoanCardItem item;
  final VoidCallback onWhatsApp;

  @override
  Widget build(BuildContext context) {
    final loan = item.loanItem.loan;
    final isQuitado = item.totalInstallments > 0 &&
        item.paidInstallments >= item.totalInstallments;
    final style = InstallmentCardStyle.forLoanCard(
      installments: item.installments,
      isQuitado: isQuitado,
    );
    final accent = style.color;
    final progress = item.totalInstallments > 0
        ? item.paidInstallments / item.totalInstallments
        : 0.0;

    final canWhatsApp = item.hasOverdue &&
        WhatsAppUtils.normalizeBrazilPhone(item.clientPhone) != null;

    final borderColor = item.hasOverdue || style.isDueToday
        ? style.border.withValues(alpha: 0.55)
        : context.appTheme.border;

    final amountLine =
        '${item.installmentsProgressLabel} · '
        '${LoanSimulator.formatMoney(item.remainingAmount)}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push(
          AppRoutes.loanDetail(
            loan.id,
            highlightInstallment: item.nextInstallmentNumber,
          ),
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        child: Ink(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            border: Border.all(color: borderColor),
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
                    child: _StatusIcon(style: style),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                item.clientName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: Text(
                                  amountLine,
                                  textAlign: TextAlign.end,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: accent,
                                      ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (item.dueDatesLabel != null) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            item.dueDatesLabel!,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: context.appTheme.textSecondary,
                                ),
                          ),
                          if (item.isNextDueToday) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Vence hoje',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: accent,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (item.hasOverdue) ...[
                const SizedBox(height: AppSpacing.sm),
                _PaymentStatusChip(
                  label: item.overdueChipLabel,
                  color: AppColors.error,
                ),
                if (canWhatsApp) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _WhatsAppButton(onPressed: onWhatsApp),
                ] else ...[
                  const SizedBox(height: AppSpacing.xs),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Icon(
                      LucideIcons.phone_off,
                      size: 20,
                      color: context.appTheme.textSecondary,
                    ),
                  ),
                ],
              ],
              if (item.totalInstallments > 0) ...[
                const SizedBox(height: AppSpacing.sm),
                LoanInstallmentStatusStrip(
                  installments: item.installments,
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

class _WhatsAppButton extends StatefulWidget {
  const _WhatsAppButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_WhatsAppButton> createState() => _WhatsAppButtonState();
}

class _WhatsAppButtonState extends State<_WhatsAppButton>
    with SingleTickerProviderStateMixin {
  static const _green = Color(0xFF25D366);

  late final AnimationController _pulseController;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _pulse = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final t = _pulse.value;
        final fillAlpha = 0.14 + t * 0.22;
        final borderAlpha = 0.4 + t * 0.5;
        final glowAlpha = 0.12 + t * 0.28;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onPressed,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: Ink(
              decoration: BoxDecoration(
                color: _green.withValues(alpha: fillAlpha),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: _green.withValues(alpha: borderAlpha),
                  width: 1 + t * 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _green.withValues(alpha: glowAlpha),
                    blurRadius: 6 + t * 10,
                    spreadRadius: t * 1.5,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.message_circle,
                      size: 18,
                      color: Color.lerp(
                        _green.withValues(alpha: 0.85),
                        _green,
                        t,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Chamar no WhatsApp',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Color.lerp(
                              _green.withValues(alpha: 0.9),
                              _green,
                              t,
                            ),
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.style});

  final InstallmentCardStyle style;

  @override
  Widget build(BuildContext context) {
    if (style.isDueToday) {
      return Icon(LucideIcons.bell, size: 20, color: style.color);
    }
    return switch (style.status) {
      LoanInstallmentStatus.overdue => AttentionLucideIcon(
          icon: LucideIcons.triangle_alert,
          size: 20,
          color: style.color,
        ),
      LoanInstallmentStatus.paid => Icon(
          LucideIcons.circle_check,
          size: 20,
          color: style.color,
        ),
      LoanInstallmentStatus.pending => Icon(
          LucideIcons.clock,
          size: 20,
          color: style.color,
        ),
    };
  }
}

class _PaymentStatusChip extends StatelessWidget {
  const _PaymentStatusChip({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        label,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
