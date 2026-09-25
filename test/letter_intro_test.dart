import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazatalk/core/services/speech_input_service.dart';
import 'package:mazatalk/features/letters/domain/letter_glyph.dart';
import 'package:mazatalk/features/letters/domain/stroke_tracker.dart';
import 'package:mazatalk/features/letters/presentation/letter_intro_flow.dart';
import 'package:mazatalk/features/letters/presentation/letter_trace_canvas.dart';
import 'helpers/letter_flow.dart';

class _NoSpeech extends SpeechInputService {
  @override
  Future<SpeechAttempt> listenFor(
    String targetWord, {
    Duration? timeout,
  }) async => const SpeechAttempt(SpeechAttemptResult.unavailable);
}

void main() {
  group('StrokeTracker (forgiving by design)', () {
    StrokeTracker tracker() => StrokeTracker(
      const [Offset(0, 0), Offset(0, 300)],
      tolerance: 40,
      startRadius: 50,
    );

    test('a touch away from the start dot does not begin the stroke', () {
      final t = tracker()..down(const Offset(0, 200));
      expect(t.active, isFalse);
    });

    test('following the path advances progress and completes the stroke', () {
      final t = tracker()..down(const Offset(5, 0));
      for (var y = 20.0; y <= 300; y += 20) {
        t.move(Offset(5, y));
      }
      expect(t.complete, isTrue);
    });

    test(
      'wandering off flags offPath but keeps progress; returning resumes',
      () {
        final t = tracker()..down(const Offset(0, 0));
        t.move(const Offset(0, 100));
        final kept = t.along;
        t.move(const Offset(120, 110)); // far from the path
        expect(t.offPath, isTrue);
        expect(t.along, kept);
        t.move(const Offset(10, 130)); // back on the path
        expect(t.offPath, isFalse);
        expect(t.along, greaterThan(kept));
      },
    );

    test('lifting mid-stroke: resume at the halo or restart from the top', () {
      final t = tracker()..down(const Offset(0, 0));
      for (var y = 30.0; y <= 150; y += 30) {
        t.move(Offset(0, y));
      }
      t.up();
      final kept = t.along;

      t.down(const Offset(0, 150)); // right where they stopped
      expect(t.active, isTrue);
      expect(t.along, kept);
      t.up();

      t.down(const Offset(0, 10)); // back on the start dot: do it again
      expect(t.active, isTrue);
      expect(t.along, 0);
    });

    test('jumping far ahead is not tracing', () {
      final t = tracker()..down(const Offset(0, 0));
      t.move(const Offset(0, 290));
      expect(t.along, 0);
      expect(t.offPath, isTrue);
    });
  });

  group('LetterIntroFlow (A: see → say → trace → complete)', () {
    Future<void> pump(WidgetTester tester, {VoidCallback? onDone}) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            speechInputServiceProvider.overrideWithValue(_NoSpeech()),
          ],
          child: MaterialApp(
            home: LetterIntroFlow(
              glyph: LetterCatalog.a,
              onDone: onDone ?? () {},
              onExit: () {},
            ),
          ),
        ),
      );
      await tester.pump();
    }

    String step(WidgetTester tester) =>
        tester.widget<Text>(find.byKey(const Key('letter_step_count'))).data!;

    testWidgets('the six progress steps line up with see/say/3 strokes/done', (
      tester,
    ) async {
      expect(LetterCatalog.a.totalSteps, 6);
      await pump(tester);
      expect(step(tester), '1/6');
      expect(find.text('Энэ бол А.'), findsOneWidget);

      await tester.tap(find.byKey(const Key('letter_next')));
      await tester.pump();
      expect(step(tester), '2/6');
      expect(find.byKey(const Key('letter_mic')), findsOneWidget);

      await tester.tap(find.byKey(const Key('letter_skip')));
      await tester.pump();
      expect(step(tester), '3/6');
      expect(find.text('Одоо хамтдаа А үсгийг зурья!'), findsOneWidget);
      expect(find.text('Дээрх цэгээс эхлээрэй.'), findsOneWidget);

      await traceStroke(tester, LetterCatalog.a, 0);
      expect(step(tester), '4/6');
      expect(
        find.text('Маш сайн! Одоо дараагийн зураасаа зурья!'),
        findsOneWidget,
      );

      await traceStroke(tester, LetterCatalog.a, 1);
      expect(step(tester), '5/6');
      await traceStroke(tester, LetterCatalog.a, 2);
      await tester.pump(const Duration(seconds: 1));

      expect(step(tester), '6/6');
      expect(find.text('Гайхалтай! Чи А үсгийг зурлаа!'), findsOneWidget);
      expect(find.byKey(const Key('letter_continue')), findsOneWidget);
    });

    testWidgets('the mic step listens, then moves on whatever it heard', (
      tester,
    ) async {
      await pump(tester);
      await tester.tap(find.byKey(const Key('letter_next')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('letter_mic')));
      await tester.pump();
      expect(step(tester), '3/6');
    });

    testWidgets('stepping off the path shows a gentle nudge, never a failure', (
      tester,
    ) async {
      await pump(tester);
      await tester.tap(find.byKey(const Key('letter_next')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('letter_skip')));
      await tester.pump();

      final rect = tester.getRect(find.byKey(const Key('trace_canvas')));
      final pts = [
        for (final p in LetterCatalog.a.strokes[0].points)
          rect.topLeft + glyphPoint(rect.size, p),
      ];
      final g = await tester.startGesture(pts.first);
      await g.moveTo(Offset.lerp(pts.first, pts.last, .3)!);
      await tester.pump();
      await g.moveTo(
        Offset.lerp(pts.first, pts.last, .3)! + const Offset(140, 0),
      );
      await tester.pump();

      expect(find.text('Зүгээр ээ! Дахин оролдоод үзье.'), findsOneWidget);
      expect(
        find.text('Зөв зам руу буцаад орвол үргэлжлүүлж болно.'),
        findsOneWidget,
      );

      // Back onto the path: the nudge goes away and tracing carries on.
      await g.moveTo(Offset.lerp(pts.first, pts.last, .45)!);
      await tester.pump();
      expect(find.text('Зүгээр ээ! Дахин оролдоод үзье.'), findsNothing);
      await g.up();
      await tester.pump();
      expect(step(tester), '3/6'); // still on stroke one — nothing was lost
    });

    testWidgets('nothing advances by itself; continue calls onDone', (
      tester,
    ) async {
      var done = false;
      await pump(tester, onDone: () => done = true);
      await tester.pump(const Duration(minutes: 3));
      expect(step(tester), '1/6');

      await playLetterIntro(tester, LetterCatalog.a);
      expect(done, isTrue);
    });
  });
}
