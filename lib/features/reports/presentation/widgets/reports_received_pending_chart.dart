import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../loans/domain/loan_simulator.dart';

/// Rosca Recebido vs. pendente / a receber.
class ReportsReceivedPendingChart extends StatelessWidget {
  const ReportsReceivedPendingChart({
    required this.received,
    required this.pending,
    this.centerLabel = 'Total',
    this.centerSubtitle,
    this.pendingLegendLabel = 'Pendente',
    this.emptyMessage = 'Sem valores na carteira.',
    super.key,
  });

  final double received;
  final double pending;
  final String centerLabel;
  final String? centerSubtitle;
  final String pendingLegendLabel;
  final String emptyMessage;

  static const _pendingColor = Color(0xFFE8A04A);

  double get _total => received + pending;

  double get _receivedShare => _total > 0 ? received / _total : 0;

  double get _pendingShare => _total > 0 ? pending / _total : 0;

  @override
  Widget build(BuildContext context) {
    if (_total <= 0) {
      return Text(
        emptyMessage,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: context.appTheme.textSecondary,
            ),
      );
    }

    final receivedPct = (_receivedShare * 100).toStringAsFixed(1);
    final pendingPct = (_pendingShare * 100).toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(double.infinity, 220),
                painter: _DonutChartPainter(
                  receivedShare: _receivedShare,
                  receivedColor: AppColors.success,
                  pendingColor: _pendingColor,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    centerLabel,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: context.appTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  if (centerSubtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      centerSubtitle!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: context.appTheme.textSecondary,
                            fontSize: 10,
                          ),
                    ),
                  ],
                  const SizedBox(height: 2),
                  Text(
                    LoanSimulator.formatMoney(_total),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
              if (_receivedShare >= 0.08)
                _SegmentPercentLabel(
                  share: _receivedShare,
                  startShare: 0,
                  text: '$receivedPct%',
                ),
              if (_pendingShare >= 0.08)
                _SegmentPercentLabel(
                  share: _pendingShare,
                  startShare: _receivedShare,
                  text: '$pendingPct%',
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: _LegendColumn(
                  color: AppColors.success,
                  label: 'Recebido',
                  value: LoanSimulator.formatMoney(received),
                  percent: '$receivedPct%',
                ),
              ),
              VerticalDivider(
                width: 1,
                thickness: 1,
                color: context.appTheme.border.withValues(alpha: 0.8),
              ),
              Expanded(
                child: _LegendColumn(
                  color: _pendingColor,
                  label: pendingLegendLabel,
                  value: LoanSimulator.formatMoney(pending),
                  percent: '$pendingPct%',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SegmentPercentLabel extends StatelessWidget {
  const _SegmentPercentLabel({
    required this.share,
    required this.startShare,
    required this.text,
  });

  final double share;
  final double startShare;
  final String text;

  @override
  Widget build(BuildContext context) {
    const chartSize = 220.0;
    const stroke = 32.0;
    final radius = (chartSize / 2) - stroke / 2 - 6;
    final midAngle =
        -math.pi / 2 + (startShare + share / 2) * 2 * math.pi;
    final dx = math.cos(midAngle) * radius;
    final dy = math.sin(midAngle) * radius;

    return Transform.translate(
      offset: Offset(dx, dy),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 11,
              shadows: const [
                Shadow(
                  color: Color(0x99000000),
                  blurRadius: 4,
                ),
              ],
            ),
      ),
    );
  }
}

class _LegendColumn extends StatelessWidget {
  const _LegendColumn({
    required this.color,
    required this.label,
    required this.value,
    required this.percent,
  });

  final Color color;
  final String label;
  final String value;
  final String percent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
          ),
          Text(
            percent,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: context.appTheme.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  _DonutChartPainter({
    required this.receivedShare,
    required this.receivedColor,
    required this.pendingColor,
  });

  final double receivedShare;
  final Color receivedColor;
  final Color pendingColor;
  static const double _strokeWidth = 32;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - _strokeWidth / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const startAngle = -math.pi / 2;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.butt;

    final receivedSweep = 2 * math.pi * receivedShare.clamp(0.0, 1.0);
    final pendingSweep = 2 * math.pi - receivedSweep;

    if (receivedSweep > 0) {
      paint.color = receivedColor;
      canvas.drawArc(rect, startAngle, receivedSweep, false, paint);
    }
    if (pendingSweep > 0) {
      paint.color = pendingColor;
      canvas.drawArc(
        rect,
        startAngle + receivedSweep,
        pendingSweep,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.receivedShare != receivedShare ||
        oldDelegate.receivedColor != receivedColor ||
        oldDelegate.pendingColor != pendingColor;
  }
}
