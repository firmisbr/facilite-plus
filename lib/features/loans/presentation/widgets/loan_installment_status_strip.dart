import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/loan_installment_status.dart';
import 'installment_card_style.dart';

/// Barra segmentada: uma cor por parcela (mesma lógica do detalhe do empréstimo).
class LoanInstallmentStatusStrip extends StatelessWidget {
  const LoanInstallmentStatusStrip({
    super.key,
    required this.installments,
    this.height = 5,
    this.fallbackProgress,
    this.fallbackColor,
  });

  final List<LoanInstallmentItem> installments;
  final double height;

  /// Usado quando o cronograma ainda não está disponível (só total conhecido).
  final double? fallbackProgress;
  final Color? fallbackColor;

  @override
  Widget build(BuildContext context) {
    if (installments.isEmpty) {
      final progress = fallbackProgress;
      if (progress == null) return const SizedBox.shrink();

      final color = fallbackColor ?? Theme.of(context).colorScheme.primary;
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0),
          minHeight: height,
          backgroundColor: color.withValues(alpha: 0.12),
          color: color,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: SizedBox(
        height: height,
        child: Row(
          children: [
            for (var i = 0; i < installments.length; i++) ...[
              if (i > 0) const SizedBox(width: 2),
              Expanded(
                child: ColoredBox(
                  color: InstallmentCardStyle.resolve(installments[i]).color,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
