import 'dart:math';
import 'dart:ui';

/// Follows a finger along one stroke (a polyline in pixels). Deliberately
/// forgiving: it never "fails" — leaving the path only flags [offPath], and
/// progress is kept, so the child can step back onto the path and carry on.
class StrokeTracker {
  final List<Offset> points;

  /// How far from the centre line the finger may wander and still count.
  final double tolerance;

  /// How close to the current progress point a touch must begin.
  final double startRadius;

  late final List<double> _cumulative;
  late final double length;

  /// Distance traced so far along the stroke.
  double along;
  bool active = false;
  bool offPath = false;

  StrokeTracker(
    this.points, {
    required this.tolerance,
    required this.startRadius,
    this.along = 0,
  }) {
    _cumulative = [0];
    for (var i = 1; i < points.length; i++) {
      _cumulative.add(_cumulative.last + (points[i] - points[i - 1]).distance);
    }
    length = _cumulative.last;
  }

  bool get complete => along >= length * .93;
  double get fraction => length == 0 ? 0 : (along / length).clamp(0.0, 1.0);

  Offset pointAt(double distance) {
    final d = distance.clamp(0.0, length);
    for (var i = 1; i < points.length; i++) {
      if (d <= _cumulative[i]) {
        final seg = _cumulative[i] - _cumulative[i - 1];
        final t = seg == 0 ? 0.0 : (d - _cumulative[i - 1]) / seg;
        return Offset.lerp(points[i - 1], points[i], t)!;
      }
    }
    return points.last;
  }

  /// Nearest point on the stroke to [p]: its distance along the stroke and
  /// how far [p] is from it.
  ({double along, double distance}) project(Offset p) {
    var bestAlong = 0.0;
    var bestDist = double.infinity;
    for (var i = 1; i < points.length; i++) {
      final a = points[i - 1];
      final b = points[i];
      final ab = b - a;
      final len2 = ab.dx * ab.dx + ab.dy * ab.dy;
      final t = len2 == 0
          ? 0.0
          : (((p - a).dx * ab.dx + (p - a).dy * ab.dy) / len2).clamp(0.0, 1.0);
      final nearest = a + ab * t;
      final dist = (p - nearest).distance;
      if (dist < bestDist) {
        bestDist = dist;
        bestAlong = _cumulative[i - 1] + (nearest - a).distance;
      }
    }
    return (along: bestAlong, distance: bestDist);
  }

  /// A touch begins. It counts when it lands on the current progress point
  /// (carry on where you left off) or back on the start dot (do the stroke
  /// again from the top); anywhere else it is ignored.
  void down(Offset p) {
    if (complete) return;
    offPath = false;
    if ((p - pointAt(along)).distance <= startRadius) {
      active = true;
    } else if ((p - points.first).distance <= startRadius) {
      along = 0;
      active = true;
    } else {
      active = false;
    }
  }

  void move(Offset p) {
    if (!active || complete) return;
    final hit = project(p);
    if (hit.distance > tolerance) {
      offPath = true;
      return;
    }
    // Jumping far ahead of where the finger has been isn't tracing.
    if (hit.along > along + max(length * .35, tolerance * 2)) {
      offPath = true;
      return;
    }
    offPath = false;
    if (hit.along > along) along = hit.along;
  }

  void up() {
    active = false;
    offPath = false;
  }
}
