import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/letter_glyph.dart';
import '../domain/stroke_tracker.dart';

const _track = Color(0xFFE6EBF0);

/// Where a normalised glyph point lands inside a canvas of [size]: a centred
/// square with room for the fat stroke. Shared by the painter, the gesture
/// code and the tests so they always agree.
Offset glyphPoint(Size size, Offset normalized) {
  final side = size.shortestSide;
  final pad = side * .13;
  final area = side - pad * 2;
  final origin = Offset((size.width - side) / 2, (size.height - side) / 2);
  return origin +
      Offset(pad + normalized.dx * area, pad + normalized.dy * area);
}

double glyphStrokeWidth(Size size) => size.shortestSide * .15;

List<Offset> _pixels(GlyphStroke s, Size size) => [
  for (final p in s.points) glyphPoint(size, p),
];

Path _path(List<Offset> pts) {
  final path = Path()..moveTo(pts.first.dx, pts.first.dy);
  for (final p in pts.skip(1)) {
    path.lineTo(p.dx, p.dy);
  }
  return path;
}

/// The letter as a solid shape in one [color] — the big letter on the "see"
/// and "complete" steps.
class GlyphView extends StatelessWidget {
  final LetterGlyph glyph;
  final Color color;
  const GlyphView({super.key, required this.glyph, required this.color});

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _SolidPainter(glyph, color),
    child: const SizedBox.expand(),
  );
}

class _SolidPainter extends CustomPainter {
  final LetterGlyph glyph;
  final Color color;
  _SolidPainter(this.glyph, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = glyphStrokeWidth(size)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final s in glyph.strokes) {
      canvas.drawPath(_path(_pixels(s, size)), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SolidPainter old) =>
      old.glyph != glyph || old.color != color;
}

/// The tracing surface: a pale letter to follow, a numbered start dot, a
/// dashed guide with an arrow, and a fill that grows under the finger.
/// Leaving the path never fails anything — [onOffPath] just lets Maza offer
/// a gentle "step back onto the path", and progress is kept.
class LetterTraceCanvas extends StatefulWidget {
  final LetterGlyph glyph;

  /// The finger just started the current stroke from its start dot.
  final VoidCallback? onStrokeStarted;

  /// Stroke [index] (0-based) is finished.
  final ValueChanged<int>? onStrokeDone;
  final VoidCallback? onAllDone;

  /// The finger wandered off (true) or came back to the path (false).
  final ValueChanged<bool>? onOffPath;

  const LetterTraceCanvas({
    super.key,
    required this.glyph,
    this.onStrokeStarted,
    this.onStrokeDone,
    this.onAllDone,
    this.onOffPath,
  });

  @override
  State<LetterTraceCanvas> createState() => _LetterTraceCanvasState();
}

class _LetterTraceCanvasState extends State<LetterTraceCanvas> {
  int _done = 0;
  double _fraction = 0;
  bool _active = false;
  bool _off = false;
  bool _startedReported = false;
  Offset? _finger;

  StrokeTracker _tracker(Size size) {
    final pts = _pixels(widget.glyph.strokes[_done], size);
    final w = glyphStrokeWidth(size);
    final t = StrokeTracker(pts, tolerance: w * 1.05, startRadius: w * 1.25);
    t.along = _fraction * t.length;
    return t;
  }

  void _apply(StrokeTracker t, Offset p) {
    final wasOff = _off;
    _fraction = t.fraction;
    _active = t.active;
    _off = t.active && t.offPath;
    _finger = t.active ? p : null;
    if (_active && !_startedReported) {
      _startedReported = true;
      widget.onStrokeStarted?.call();
    }
    if (wasOff != _off) widget.onOffPath?.call(_off);
    if (t.complete) {
      final index = _done;
      _done++;
      _fraction = 0;
      _active = false;
      _off = false;
      _finger = null;
      _startedReported = false;
      widget.onStrokeDone?.call(index);
      if (_done >= widget.glyph.strokes.length) widget.onAllDone?.call();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        bool finished() => _done >= widget.glyph.strokes.length;
        return Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (e) {
            if (finished()) return;
            final t = _tracker(size)..down(e.localPosition);
            _apply(t, e.localPosition);
          },
          onPointerMove: (e) {
            if (finished() || !_active) return;
            final t = _tracker(size)
              ..active = true
              ..move(e.localPosition);
            _apply(t, e.localPosition);
          },
          onPointerUp: (_) => _release(),
          onPointerCancel: (_) => _release(),
          child: CustomPaint(
            painter: _TracePainter(
              glyph: widget.glyph,
              done: _done,
              fraction: _fraction,
              finger: _finger,
              off: _off,
            ),
            child: const SizedBox.expand(),
          ),
        );
      },
    );
  }

  void _release() {
    if (_off) widget.onOffPath?.call(false);
    setState(() {
      _active = false;
      _off = false;
      _finger = null;
      _startedReported = false;
    });
  }
}

class _TracePainter extends CustomPainter {
  final LetterGlyph glyph;
  final int done;
  final double fraction;
  final Offset? finger;
  final bool off;

  _TracePainter({
    required this.glyph,
    required this.done,
    required this.fraction,
    required this.finger,
    required this.off,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = glyphStrokeWidth(size);
    Paint fat(Color c) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final strokes = [for (final s in glyph.strokes) _pixels(s, size)];

    // The pale letter to follow.
    for (final pts in strokes) {
      canvas.drawPath(_path(pts), fat(_track));
    }
    // Finished strokes, solid.
    for (var i = 0; i < done && i < strokes.length; i++) {
      canvas.drawPath(_path(strokes[i]), fat(AppColors.primary));
    }
    if (done >= strokes.length) return;

    // The stroke being traced: dashed guide, growing fill, arrow, start dot.
    final pts = strokes[done];
    final tracker = StrokeTracker(pts, tolerance: w, startRadius: w);
    final metric = _path(pts).computeMetrics().first;
    if (fraction > 0) {
      canvas.drawPath(
        metric.extractPath(0, metric.length * fraction),
        fat(AppColors.primary),
      );
    }
    _dashed(
      canvas,
      metric,
      Paint()
        ..color = AppColors.textLight
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    _arrow(canvas, pts, tracker);

    if (fraction < .02) {
      final start = pts.first;
      canvas.drawCircle(start, w * .42, Paint()..color = AppColors.primary);
      canvas.drawCircle(
        start,
        w * .42,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
      final tp = TextPainter(
        text: TextSpan(
          text: '${done + 1}',
          style: TextStyle(
            color: Colors.white,
            fontSize: w * .48,
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, start - Offset(tp.width / 2, tp.height / 2));
    }

    if (fraction >= .02 && finger == null) {
      // Finger lifted mid-stroke: mark where to pick it up again.
      final resume = tracker.pointAt(tracker.length * fraction);
      canvas.drawCircle(
        resume,
        w * .36,
        Paint()
          ..color = AppColors.primary
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5,
      );
    }

    if (finger != null) {
      // Amber (never red) halo while off the path, cyan while on it.
      final color = off ? const Color(0xFFFFB74D) : AppColors.primary;
      canvas.drawCircle(
        finger!,
        w * .55,
        Paint()..color = color.withValues(alpha: .28),
      );
      canvas.drawCircle(finger!, w * .28, Paint()..color = color);
    }
  }

  void _dashed(Canvas canvas, ui.PathMetric metric, Paint paint) {
    const dash = 12.0, gap = 9.0;
    var d = 0.0;
    while (d < metric.length) {
      canvas.drawPath(
        metric.extractPath(d, (d + dash).clamp(0, metric.length)),
        paint,
      );
      d += dash + gap;
    }
  }

  void _arrow(Canvas canvas, List<Offset> pts, StrokeTracker t) {
    final end = pts.last;
    final dir = (pts.last - pts[pts.length - 2]);
    final unit = dir / dir.distance;
    final normal = Offset(-unit.dy, unit.dx);
    final tip = end - unit * 6;
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(
        (tip - unit * 20 + normal * 11).dx,
        (tip - unit * 20 + normal * 11).dy,
      )
      ..lineTo(
        (tip - unit * 20 - normal * 11).dx,
        (tip - unit * 20 - normal * 11).dy,
      )
      ..close();
    canvas.drawPath(path, Paint()..color = AppColors.textLight);
  }

  @override
  bool shouldRepaint(covariant _TracePainter old) =>
      old.done != done ||
      old.fraction != fraction ||
      old.finger != finger ||
      old.off != off;
}
