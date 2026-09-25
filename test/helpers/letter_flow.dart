import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazatalk/features/letters/domain/letter_glyph.dart';
import 'package:mazatalk/features/letters/presentation/letter_trace_canvas.dart';

/// Drags a finger along stroke [strokeIndex] of [glyph] on the trace canvas,
/// like a child would: down on the start dot, then along the guide.
/// [endFraction] < 1 stops early (a half-finished stroke).
Future<void> traceStroke(
  WidgetTester tester,
  LetterGlyph glyph,
  int strokeIndex, {
  double endFraction = 1,
}) async {
  final rect = tester.getRect(find.byKey(const Key('trace_canvas')));
  final pts = [
    for (final p in glyph.strokes[strokeIndex].points)
      rect.topLeft + glyphPoint(rect.size, p),
  ];
  final gesture = await tester.startGesture(pts.first);
  const steps = 16;
  for (var i = 1; i <= steps; i++) {
    final t = i / steps * endFraction;
    await gesture.moveTo(Offset.lerp(pts.first, pts.last, t)!);
    await tester.pump(const Duration(milliseconds: 16));
  }
  await gesture.up();
  await tester.pump();
}

/// Plays a letter intro from "see" through "continue": next, skip the mic,
/// trace every stroke, wait out the celebration, tap continue.
Future<void> playLetterIntro(WidgetTester tester, LetterGlyph glyph) async {
  await tester.tap(find.byKey(const Key('letter_next')));
  await tester.pump();
  await tester.tap(find.byKey(const Key('letter_skip')));
  await tester.pump();
  for (var i = 0; i < glyph.strokes.length; i++) {
    await traceStroke(tester, glyph, i);
  }
  await tester.pump(const Duration(seconds: 1));
  await tester.tap(find.byKey(const Key('letter_continue')));
  await tester.pump();
}
