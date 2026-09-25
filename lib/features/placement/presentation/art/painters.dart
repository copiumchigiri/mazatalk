import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

// Placeholder illustrations, drawn in code so the playground is fully
// playable before real art exists. Each is replaced by a PNG of the same
// name in assets/art/ (see ART_BRIEF.md) without touching the levels.

const _grassLight = Color(0xFF8ED15B);
const _grassDark = Color(0xFF5DB33A);
const _wool = Color(0xFFFFFFFF);
const _skin = Color(0xFFFFD166);
const _ink = Color(0xFF3B2F2F);

class BushPainter extends CustomPainter {
  const BushPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final dark = Paint()..color = _grassDark;
    final light = Paint()..color = _grassLight;
    canvas.drawCircle(Offset(w * .3, h * .62), w * .26, dark);
    canvas.drawCircle(Offset(w * .7, h * .62), w * .26, dark);
    canvas.drawCircle(Offset(w * .5, h * .45), w * .32, light);
    canvas.drawCircle(
      Offset(w * .38, h * .5),
      w * .08,
      Paint()..color = Colors.white24,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// A classic football: white leather, black pentagon patches with seams,
/// soft shading and a highlight so it reads as a round object at any size.
class BallPainter extends CustomPainter {
  const BallPainter();

  Path _pentagon(Offset c, double r, double rotation) {
    final path = Path();
    for (var i = 0; i < 5; i++) {
      final a = rotation + i * 2 * pi / 5;
      final p = c + Offset(cos(a), sin(a)) * r;
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 * .94;
    const ink = Color(0xFF2B2B33);

    // Ground shadow.
    canvas.drawOval(
      Rect.fromCenter(
        center: c + Offset(0, r * .98),
        width: r * 1.5,
        height: r * .26,
      ),
      Paint()..color = Colors.black.withValues(alpha: .14),
    );

    final ball = Rect.fromCircle(center: c, radius: r);
    canvas.save();
    canvas.clipPath(Path()..addOval(ball));

    // Leather with a light source top-left.
    canvas.drawRect(
      ball,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-.4, -.45),
          radius: 1.05,
          colors: [Colors.white, Color(0xFFE9EDF2), Color(0xFFB9C2CE)],
          stops: [0, .6, 1],
        ).createShader(ball),
    );

    final seam = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * .04
      ..strokeCap = StrokeCap.round;

    // Centre patch with a spoke from each corner. Every spoke forks into a
    // "V" whose arms end at the inner corners of the two edge patches on
    // either side (patches sit between spokes, cut off by the rim).
    Offset at(double angle, double dist) =>
        c + Offset(cos(angle), sin(angle)) * dist;
    for (var i = 0; i < 5; i++) {
      final a = -pi / 2 + i * 2 * pi / 5;
      final junction = at(a, r * .58);
      canvas.drawLine(at(a, r * .3), junction, seam);
      for (final side in [-1, 1]) {
        final b = a + side * pi / 5;
        canvas.drawLine(junction, at(b, r * .7), seam);
      }
      final patchAngle = a + pi / 5;
      canvas.drawPath(
        _pentagon(at(patchAngle, r), r * .3, patchAngle + pi),
        Paint()..color = ink,
      );
    }
    canvas.drawPath(_pentagon(c, r * .3, -pi / 2), Paint()..color = ink);

    // Soft rim shade and a glossy highlight.
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [Colors.transparent, Colors.black.withValues(alpha: .22)],
          stops: const [.72, 1],
        ).createShader(ball),
    );
    canvas.restore();
    canvas.drawOval(
      Rect.fromCenter(
        center: c + Offset(-r * .38, -r * .46),
        width: r * .42,
        height: r * .24,
      ),
      Paint()..color = Colors.white.withValues(alpha: .75),
    );
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * .045,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class SheepPainter extends CustomPainter {
  const SheepPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final leg = Paint()
      ..color = _ink
      ..strokeWidth = w * .07
      ..strokeCap = StrokeCap.round;
    for (final x in [.32, .44, .6, .72]) {
      canvas.drawLine(Offset(w * x, h * .68), Offset(w * x, h * .88), leg);
    }
    final wool = Paint()..color = _wool;
    final edge = Paint()
      ..color = AppColors.borderSubtle
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final o in [
      Offset(.3, .5),
      Offset(.5, .42),
      Offset(.7, .5),
      Offset(.4, .58),
      Offset(.62, .6),
    ]) {
      canvas.drawCircle(Offset(w * o.dx, h * o.dy), w * .17, wool);
      canvas.drawCircle(Offset(w * o.dx, h * o.dy), w * .17, edge);
    }
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * .86, h * .5),
        width: w * .2,
        height: h * .26,
      ),
      Paint()..color = _ink,
    );
    canvas.drawCircle(
      Offset(w * .88, h * .46),
      w * .018,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// A paint pot filled with [color] (Tap the Color).
class PotPainter extends CustomPainter {
  final Color color;
  const PotPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final body = Path()
      ..moveTo(w * .15, h * .3)
      ..lineTo(w * .85, h * .3)
      ..lineTo(w * .75, h * .9)
      ..lineTo(w * .25, h * .9)
      ..close();
    canvas.drawPath(body, Paint()..color = color);
    canvas.drawPath(
      body,
      Paint()
        ..color = Colors.black12
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawOval(
      Rect.fromLTRB(w * .15, h * .2, w * .85, h * .4),
      Paint()..color = color,
    );
    canvas.drawOval(
      Rect.fromLTRB(w * .15, h * .2, w * .85, h * .4),
      Paint()
        ..color = Colors.white38
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(covariant PotPainter old) => old.color != color;
}

/// Fallback for art that is just "a Material icon on a soft disc" — used by
/// the interest tiles until real illustrations arrive.
class IconArtPainter extends CustomPainter {
  final IconData icon;
  final Color color;
  const IconArtPainter(this.icon, {this.color = AppColors.primary});

  @override
  void paint(Canvas canvas, Size size) {
    final tp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: size.shortestSide * .9,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      size.center(Offset.zero) - Offset(tp.width / 2, tp.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant IconArtPainter old) =>
      old.icon != icon || old.color != color;
}

enum PlayShape { circle, square, triangle }

/// A solid [shape] (draggable piece) or, with [hole], its cut-out outline.
class ShapePainter extends CustomPainter {
  final PlayShape shape;
  final bool hole;
  final Color color;
  const ShapePainter(
    this.shape, {
    this.hole = false,
    this.color = AppColors.secondary,
  });

  Path _path(Size s) {
    final w = s.width, h = s.height;
    return switch (shape) {
      PlayShape.circle =>
        (Path()..addOval(Rect.fromLTWH(w * .1, h * .1, w * .8, h * .8))),
      PlayShape.square =>
        (Path()..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * .12, h * .12, w * .76, h * .76),
            Radius.circular(w * .08),
          ),
        )),
      PlayShape.triangle =>
        (Path()
          ..moveTo(w * .5, h * .1)
          ..lineTo(w * .92, h * .86)
          ..lineTo(w * .08, h * .86)
          ..close()),
    };
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _path(size);
    if (hole) {
      canvas.drawPath(path, Paint()..color = AppColors.background);
      canvas.drawPath(
        path,
        Paint()
          ..color = AppColors.primary
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeJoin = StrokeJoin.round,
      );
    } else {
      canvas.drawPath(path, Paint()..color = color);
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.black12
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ShapePainter old) =>
      old.shape != shape || old.hole != hole || old.color != color;
}

enum Feeling { happy, sad, angry, scared }

class FacePainter extends CustomPainter {
  final Feeling feeling;
  const FacePainter(this.feeling);
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    canvas.drawCircle(c, r * .92, Paint()..color = _skin);
    canvas.drawCircle(
      c,
      r * .92,
      Paint()
        ..color = Colors.black12
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    final ink = Paint()..color = _ink;
    final line = Paint()
      ..color = _ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * .09
      ..strokeCap = StrokeCap.round;
    final eyeY = c.dy - r * .18;
    for (final dx in [-.32, .32]) {
      canvas.drawCircle(
        Offset(c.dx + r * dx, eyeY),
        r * (feeling == Feeling.scared ? .13 : .09),
        ink,
      );
    }
    final mouth = Rect.fromCenter(
      center: Offset(c.dx, c.dy + r * .28),
      width: r * .7,
      height: r * .5,
    );
    switch (feeling) {
      case Feeling.happy:
        canvas.drawArc(mouth, .2, pi - .4, false, line);
      case Feeling.sad:
        canvas.drawArc(
          mouth.translate(0, r * .22),
          pi + .3,
          pi - .6,
          false,
          line,
        );
        canvas.drawCircle(
          Offset(c.dx - r * .36, eyeY + r * .28),
          r * .06,
          Paint()..color = const Color(0xFF6EC6FF),
        );
      case Feeling.angry:
        canvas.drawArc(
          mouth.translate(0, r * .2),
          pi + .4,
          pi - .8,
          false,
          line,
        );
        canvas.drawLine(
          Offset(c.dx - r * .5, eyeY - r * .22),
          Offset(c.dx - r * .12, eyeY - r * .08),
          line,
        );
        canvas.drawLine(
          Offset(c.dx + r * .5, eyeY - r * .22),
          Offset(c.dx + r * .12, eyeY - r * .08),
          line,
        );
      case Feeling.scared:
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(c.dx, c.dy + r * .38),
            width: r * .3,
            height: r * .36,
          ),
          ink,
        );
    }
  }

  @override
  bool shouldRepaint(covariant FacePainter old) => old.feeling != feeling;
}

class BackpackPainter extends CustomPainter {
  const BackpackPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * .1, h * .2, w * .8, h * .75),
      Radius.circular(w * .2),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * .3, h * .04, w * .4, h * .3),
        Radius.circular(w * .12),
      ),
      Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * .07,
    );
    canvas.drawRRect(body, Paint()..color = AppColors.primary);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * .25, h * .55, w * .5, h * .3),
        Radius.circular(w * .1),
      ),
      Paint()..color = Colors.white30,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// Soft act backdrop: hills (meadow), water bands (riverside) or a ger on a
/// warm horizon (home). Kept pale so tiles stay the loudest thing on screen.
class ActScenePainter extends CustomPainter {
  final int act;
  const ActScenePainter(this.act);
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final sky = switch (act) {
      1 => const [Color(0xFFE6F7FF), Colors.white],
      2 => const [Color(0xFFFFF3D6), Colors.white],
      _ => const [Color(0xFFD3F5F8), Colors.white],
    };
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: sky,
        ).createShader(Offset.zero & size),
    );
    switch (act) {
      case 1:
        for (var i = 0; i < 3; i++) {
          final y = h * (.88 + i * .04);
          final p = Path()..moveTo(0, y);
          for (var x = 0.0; x <= w; x += w / 8) {
            p.quadraticBezierTo(x + w / 16, y - 10, x + w / 8, y);
          }
          p.lineTo(w, h);
          p.lineTo(0, h);
          p.close();
          canvas.drawPath(
            p,
            Paint()
              ..color = const Color(
                0xFF9AD8FF,
              ).withValues(alpha: .35 + i * .15),
          );
        }
      case 2:
        canvas.drawCircle(
          Offset(w * .82, h * .1),
          w * .09,
          Paint()..color = const Color(0xFFFFD166).withValues(alpha: .6),
        );
        canvas.drawPath(
          Path()
            ..moveTo(w * .05, h)
            ..lineTo(w * .05, h * .93)
            ..quadraticBezierTo(w * .17, h * .84, w * .29, h * .93)
            ..lineTo(w * .29, h)
            ..close(),
          Paint()..color = Colors.white,
        );
        canvas.drawPath(
          Path()
            ..moveTo(w * .03, h * .93)
            ..lineTo(w * .17, h * .86)
            ..lineTo(w * .31, h * .93)
            ..close(),
          Paint()..color = AppColors.primary.withValues(alpha: .5),
        );
        canvas.drawRect(
          Rect.fromLTWH(0, h * .96, w, h * .04),
          Paint()..color = _grassLight.withValues(alpha: .5),
        );
      default:
        canvas.drawPath(
          Path()
            ..moveTo(0, h)
            ..lineTo(0, h * .92)
            ..quadraticBezierTo(w * .25, h * .84, w * .5, h * .92)
            ..quadraticBezierTo(w * .75, h * 1.0, w, h * .9)
            ..lineTo(w, h)
            ..close(),
          Paint()..color = _grassLight.withValues(alpha: .5),
        );
    }
  }

  @override
  bool shouldRepaint(covariant ActScenePainter old) => old.act != act;
}
