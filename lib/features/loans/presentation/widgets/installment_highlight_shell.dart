import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Pulso ao redor da parcela por [duration] (ex.: após navegação do dashboard).
class InstallmentHighlightShell extends StatefulWidget {
  const InstallmentHighlightShell({
    super.key,
    required this.active,
    required this.child,
  });

  final bool active;
  final Widget child;

  @override
  State<InstallmentHighlightShell> createState() =>
      _InstallmentHighlightShellState();
}

class _InstallmentHighlightShellState extends State<InstallmentHighlightShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulse = Tween<double>(begin: 0.25, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.active) _startPulse();
  }

  @override
  void didUpdateWidget(InstallmentHighlightShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _startPulse();
    } else if (!widget.active && oldWidget.active) {
      _stopPulse();
    }
  }

  void _startPulse() {
    _controller.repeat(reverse: true);
  }

  void _stopPulse() {
    if (_controller.isAnimating) {
      _controller.stop();
    }
    _controller.value = 0;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return widget.child;

    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final t = _pulse.value;
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl + 2),
            border: Border.all(
              color: AppColors.accent.withValues(alpha: 0.35 + 0.55 * t),
              width: 2 + t,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.18 * t),
                blurRadius: 8 + 14 * t,
                spreadRadius: 1 * t,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
