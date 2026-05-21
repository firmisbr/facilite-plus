import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Altura total reservada (barra flutuante + FAB).
const double kBottomNavReservedHeight = 108;

const double _barHeight = 62;
const double _fabSize = 58;
const double _fabLift = 26;
const double _horizontalInset = 22;
const double _bottomInset = 22;
const double _cornerRadius = 30;

/// Barra inferior flutuante com entalhe central (estilo referência).
class FloatingNotchedNavBar extends StatelessWidget {
  const FloatingNotchedNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.onCreateLoan,
  });

  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onCreateLoan;

  static const _tabs = [
    _TabSpec(LucideIcons.layout_grid, 'Início'),
    _TabSpec(LucideIcons.banknote, 'Cobranças'),
    _TabSpec(LucideIcons.wallet, 'Empréstimos'),
    _TabSpec(LucideIcons.settings, 'Config'),
  ];

  @override
  Widget build(BuildContext context) {
    final notchRadius = _fabSize / 2 + 10;

    return SizedBox(
      height: kBottomNavReservedHeight,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            left: _horizontalInset,
            right: _horizontalInset,
            bottom: _bottomInset,
            height: _barHeight,
            child: CustomPaint(
              painter: _NotchedBarPainter(
                notchRadius: notchRadius,
                barColor: const Color(0xFF2C2C2A),
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  top: notchRadius * 0.15,
                  bottom: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _NavIconButton(
                            icon: _tabs[0].icon,
                            selected: currentIndex == 0,
                            onTap: () => onTabSelected(0),
                          ),
                          _NavIconButton(
                            icon: _tabs[1].icon,
                            selected: currentIndex == 1,
                            onTap: () => onTabSelected(1),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: notchRadius * 2 + 8),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _NavIconButton(
                            icon: _tabs[2].icon,
                            selected: currentIndex == 2,
                            onTap: () => onTabSelected(2),
                          ),
                          _NavIconButton(
                            icon: _tabs[3].icon,
                            selected: currentIndex == 3,
                            onTap: () => onTabSelected(3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: _bottomInset + _barHeight - _fabLift,
            child: _CenterFab(onTap: onCreateLoan),
          ),
        ],
      ),
    );
  }
}

class _TabSpec {
  const _TabSpec(this.icon, this.semanticLabel);
  final IconData icon;
  final String semanticLabel;
}

class _NavIconButton extends StatelessWidget {
  const _NavIconButton({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const idleColor = Color(0xFF8E8E8A);
    const activeColor = Color(0xFFF4F1EA);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.transparent,
          ),
          child: Icon(
            icon,
            size: 24,
            color: selected ? activeColor : idleColor,
          ),
        ),
      ),
    );
  }
}

class _CenterFab extends StatefulWidget {
  const _CenterFab({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_CenterFab> createState() => _CenterFabState();
}

class _CenterFabState extends State<_CenterFab> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: _fabSize,
          height: _fabSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.accent,
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.45),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            LucideIcons.plus,
            size: 28,
            color: Color(0xFF1A221C),
          ),
        ),
      ),
    );
  }
}

class _NotchedBarPainter extends CustomPainter {
  _NotchedBarPainter({
    required this.notchRadius,
    required this.barColor,
  });

  final double notchRadius;
  final Color barColor;

  @override
  void paint(Canvas canvas, Size size) {
    final path = _buildPath(size);
    canvas.drawShadow(path, Colors.black.withValues(alpha: 0.45), 14, false);
    canvas.drawPath(path, Paint()..color = barColor);
  }

  Path _buildPath(Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final r = _cornerRadius;
    final nr = notchRadius;
    final notchDepth = nr * 0.62;

    final path = Path();

    path.moveTo(r, 0);

    final gap = nr + 16;
    path.lineTo(cx - gap, 0);
    path.cubicTo(
      cx - gap * 0.72,
      0,
      cx - nr * 0.85,
      notchDepth * 0.35,
      cx - nr * 0.42,
      notchDepth * 0.92,
    );
    path.arcToPoint(
      Offset(cx + nr * 0.42, notchDepth * 0.92),
      radius: Radius.circular(nr * 0.95),
      clockwise: false,
    );
    path.cubicTo(
      cx + nr * 0.85,
      notchDepth * 0.35,
      cx + gap * 0.72,
      0,
      cx + gap,
      0,
    );

    path.lineTo(w - r, 0);
    path.quadraticBezierTo(w, 0, w, r);
    path.lineTo(w, h - r);
    path.quadraticBezierTo(w, h, w - r, h);
    path.lineTo(r, h);
    path.quadraticBezierTo(0, h, 0, h - r);
    path.lineTo(0, r);
    path.quadraticBezierTo(0, 0, r, 0);
    path.close();

    return path;
  }

  @override
  bool shouldRepaint(covariant _NotchedBarPainter oldDelegate) {
    return oldDelegate.notchRadius != notchRadius ||
        oldDelegate.barColor != barColor;
  }
}
