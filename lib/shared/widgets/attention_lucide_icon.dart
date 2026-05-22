import 'package:flutter/material.dart';

/// Ícone com bounce e leve balanço contínuo (alertas de atraso).
class AttentionLucideIcon extends StatefulWidget {
  const AttentionLucideIcon({
    super.key,
    required this.icon,
    required this.color,
    this.size = 22,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  State<AttentionLucideIcon> createState() => _AttentionLucideIconState();
}

class _AttentionLucideIconState extends State<AttentionLucideIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _bounce;
  late final Animation<double> _wiggle;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _bounce = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -6), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -6, end: 0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0, end: -3), weight: 15),
      TweenSequenceItem(tween: Tween(begin: -3, end: 0), weight: 45),
    ]).animate(_controller);

    _wiggle = Tween<double>(begin: -0.07, end: 0.07).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _bounce.value),
          child: Transform.rotate(
            angle: _wiggle.value,
            child: child,
          ),
        );
      },
      child: Icon(widget.icon, size: widget.size, color: widget.color),
    );
  }
}
