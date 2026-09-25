import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/tts_service.dart';
import '../../../../core/theme/app_colors.dart';

/// One-shot burst of stars from the centre. Replays whenever [trigger]
/// increases; ignores touches. Finite, so `pumpAndSettle` still settles.
class CheerBurst extends StatefulWidget {
  final int trigger;
  const CheerBurst({super.key, required this.trigger});

  @override
  State<CheerBurst> createState() => _CheerBurstState();
}

class _CheerBurstState extends State<CheerBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didUpdateWidget(covariant CheerBurst old) {
    super.didUpdateWidget(old);
    if (widget.trigger > old.trigger) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => _c.isDismissed
            ? const SizedBox.expand()
            : CustomPaint(
                painter: _BurstPainter(_c.value),
                child: const SizedBox.expand(),
              ),
      ),
    );
  }
}

class _BurstPainter extends CustomPainter {
  final double t;
  _BurstPainter(this.t);
  static const _colors = [
    AppColors.primary,
    AppColors.secondary,
    Color(0xFFFFC800),
    Color(0xFF58CC02),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final ease = Curves.easeOutCubic.transform(t);
    for (var i = 0; i < 14; i++) {
      final angle = i / 14 * 2 * pi;
      final dist = size.shortestSide * .42 * ease;
      final p = c + Offset(cos(angle), sin(angle)) * dist;
      final paint = Paint()
        ..color = _colors[i % _colors.length].withValues(
          alpha: (1 - t).clamp(0, 1),
        );
      _star(canvas, p, 10 + 8 * (1 - t), paint);
    }
  }

  void _star(Canvas canvas, Offset c, double r, Paint paint) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final rr = i.isEven ? r : r * .45;
      final a = -pi / 2 + i * pi / 5;
      final pt = c + Offset(cos(a), sin(a)) * rr;
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    canvas.drawPath(path, paint..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant _BurstPainter old) => old.t != t;
}

/// Shakes [child] side to side each time [trigger] increases — the gentle
/// "not that one" signal (never red, never a buzzer).
class Wiggle extends StatefulWidget {
  final int trigger;
  final Widget child;
  const Wiggle({super.key, required this.trigger, required this.child});

  @override
  State<Wiggle> createState() => _WiggleState();
}

class _WiggleState extends State<Wiggle> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void didUpdateWidget(covariant Wiggle old) {
    super.didUpdateWidget(old);
    if (widget.trigger > old.trigger) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) => Transform.translate(
        offset: Offset(sin(_c.value * pi * 4) * 8 * (1 - _c.value), 0),
        child: child,
      ),
      child: widget.child,
    );
  }
}

/// Shared reactions for every level: [cheer] (stars + Maza's praise) and
/// [tryAgain] (Maza's gentle nudge). Add [withCheer] around the level body.
mixin PlayFeedbackMixin<T extends StatefulWidget> on State<T> {
  int cheerTrigger = 0;
  int _praiseIndex = 0;

  static const _praise = ['Гоё байна!', 'Маш сайн!', 'Сайн байна!'];
  static const tryAgainLine = 'За, дахин оролдоод үзье!';

  void _say(String line) {
    try {
      ProviderScope.containerOf(
        context,
        listen: false,
      ).read(ttsServiceProvider).speak(line);
    } catch (_) {}
  }

  void cheer() {
    if (!mounted) return;
    setState(() => cheerTrigger++);
    _say(_praise[_praiseIndex++ % _praise.length]);
  }

  void tryAgain() => _say(tryAgainLine);

  Widget withCheer(Widget body) => Stack(
    children: [
      Positioned.fill(child: body),
      Positioned.fill(child: CheerBurst(trigger: cheerTrigger)),
    ],
  );
}
