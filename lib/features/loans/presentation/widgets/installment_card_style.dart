import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/loan_installment_status.dart';

/// Cores por status: azul a vencer, verde paga, vermelho atrasada, amarelo hoje.
class InstallmentCardStyle {
  const InstallmentCardStyle({
    required this.color,
    required this.fill,
    required this.border,
    required this.borderWidth,
    required this.status,
    required this.isDueToday,
    this.shadow,
  });

  final Color color;
  final Color fill;
  final Color border;
  final double borderWidth;
  final LoanInstallmentStatus status;
  final bool isDueToday;
  final List<BoxShadow>? shadow;

  static InstallmentCardStyle resolve(LoanInstallmentItem item) =>
      resolveFor(status: item.status, isDueToday: item.isDueToday);

  static InstallmentCardStyle resolveFor({
    required LoanInstallmentStatus status,
    bool isDueToday = false,
  }) {
    return switch (status) {
      LoanInstallmentStatus.paid => InstallmentCardStyle(
          color: AppColors.success,
          fill: AppColors.success.withValues(alpha: 0.1),
          border: AppColors.success.withValues(alpha: 0.38),
          borderWidth: 1,
          status: status,
          isDueToday: false,
        ),
      LoanInstallmentStatus.overdue => InstallmentCardStyle(
          color: AppColors.error,
          fill: AppColors.error.withValues(alpha: 0.12),
          border: AppColors.error.withValues(alpha: 0.45),
          borderWidth: 1.25,
          status: status,
          isDueToday: false,
        ),
      LoanInstallmentStatus.pending when isDueToday => InstallmentCardStyle(
          color: AppColors.warning,
          fill: AppColors.warning.withValues(alpha: 0.16),
          border: AppColors.warning.withValues(alpha: 0.55),
          borderWidth: 1.5,
          status: status,
          isDueToday: true,
          shadow: [
            BoxShadow(
              color: AppColors.warning.withValues(alpha: 0.22),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
      LoanInstallmentStatus.pending => InstallmentCardStyle(
          color: AppColors.info,
          fill: AppColors.info.withValues(alpha: 0.1),
          border: AppColors.info.withValues(alpha: 0.4),
          borderWidth: 1,
          status: status,
          isDueToday: false,
        ),
    };
  }

  /// Próxima parcela em aberto (vencimento mais próximo).
  static LoanInstallmentItem? nextOpenInstallment(
    List<LoanInstallmentItem> installments,
  ) {
    LoanInstallmentItem? next;
    for (final installment in installments) {
      if (installment.isPaid) continue;
      if (next == null || installment.dueDate.isBefore(next.dueDate)) {
        next = installment;
      }
    }
    return next;
  }

  /// Destaque do card conforme a próxima parcela ou quitado.
  static InstallmentCardStyle forLoanCard({
    required List<LoanInstallmentItem> installments,
    required bool isQuitado,
  }) {
    if (isQuitado) {
      return resolveFor(status: LoanInstallmentStatus.paid);
    }
    final next = nextOpenInstallment(installments);
    if (next != null) return resolve(next);
    return resolveFor(status: LoanInstallmentStatus.pending);
  }
}
