import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_spacing.dart';

/// Tela cheia de exclusão: animação → ação → callback (navegar para lista).
class LoanDeleteProgressView extends StatefulWidget {
  const LoanDeleteProgressView({
    super.key,
    required this.deleteAction,
    required this.onComplete,
    this.onFailed,
    this.subtitle,
  });

  final Future<void> Function() deleteAction;
  final VoidCallback onComplete;
  final void Function(Object error)? onFailed;
  final String? subtitle;

  @override
  State<LoanDeleteProgressView> createState() => _LoanDeleteProgressViewState();
}

class _LoanDeleteProgressViewState extends State<LoanDeleteProgressView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _fade;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _scale = Tween<double>(begin: 0.6, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0, 0.45, curve: Curves.easeOut),
      ),
    );
    unawaited(_run());
  }

  Future<void> _run() async {
    _ctrl.forward();
    try {
      await widget.deleteAction();
      if (!mounted) return;
      await Future<void>.delayed(const Duration(milliseconds: 650));
      if (!mounted) return;
      widget.onComplete();
    } catch (e) {
      if (!mounted) return;
      if (widget.onFailed != null) {
        widget.onFailed!(e);
        return;
      }
      setState(() => _error = e.toString());
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppDecorations.screenBackground(brightness),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: FadeTransition(
                opacity: _fade,
                child: ScaleTransition(
                  scale: _scale,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_error != null) ...[
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            LucideIcons.circle_alert,
                            size: 48,
                            color: AppColors.error,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'Não foi possível excluir',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        FilledButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Voltar'),
                        ),
                      ] else ...[
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.error.withValues(alpha: 0.2),
                                AppColors.accent.withValues(alpha: 0.12),
                              ],
                            ),
                            border: Border.all(
                              color: AppColors.error.withValues(alpha: 0.35),
                            ),
                          ),
                          child: const Center(
                            child: SizedBox(
                              width: 36,
                              height: 36,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'Excluindo empréstimo…',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        if (widget.subtitle != null) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            widget.subtitle!,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: context.appTheme.textSecondary,
                                ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
