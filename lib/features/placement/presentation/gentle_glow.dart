import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// A slow breathing glow behind a circular [child] (the mic) — the
/// playground's gentle "I'm waiting for you". Only the glow's opacity
/// animates: the child and everything around it never change size or move.
/// Levels never auto-answer or auto-advance; this is purely visual.
class GentleGlow extends StatefulWidget {
  final Widget child;
  const GentleGlow({super.key, required this.child});

  @override
  State<GentleGlow> createState() => _GentleGlowState();
}

class _GentleGlowState extends State<GentleGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(
                alpha: .12 + .33 * _controller.value,
              ),
              blurRadius: 26,
              spreadRadius: 6,
            ),
          ],
        ),
        child: child,
      ),
      child: widget.child,
    );
  }
}
