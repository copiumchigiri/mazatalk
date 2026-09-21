import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazatalk/core/services/speech_input_service.dart';
import 'package:mazatalk/features/placement/domain/placement_result.dart';
import 'package:mazatalk/features/placement/presentation/levels/copy_the_pattern_level.dart';
import 'package:mazatalk/features/placement/presentation/levels/find_the_ball_level.dart';
import 'package:mazatalk/features/placement/presentation/levels/memory_match_level.dart';
import 'package:mazatalk/features/placement/presentation/levels/pick_favorites_level.dart';
import 'package:mazatalk/features/placement/presentation/levels/repeat_after_me_level.dart';
import 'package:mazatalk/features/placement/presentation/levels/tap_choice_game.dart';

/// Direct widget tests for the playground's trickier interaction paths —
/// `full_journey_test.dart` and `auth_flow_test.dart` only ever exercise
/// these levels via their timeout path, so the actual "child answers
/// correctly" and "child answers wrong then retries" branches need their
/// own coverage.
Widget _host(Widget child, {List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      home: Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: child)),
    ),
  );
}

class _ScriptedSpeechInputService extends SpeechInputService {
  final SpeechAttempt attempt;
  _ScriptedSpeechInputService(this.attempt);

  @override
  Future<SpeechAttempt> listenFor(String targetWord, {Duration? timeout}) async {
    return attempt;
  }
}

void main() {
  group('TapChoiceGame (shared mechanic behind Levels 3/4/5/6)', () {
    testWidgets('correct tap on first try scores 10', (tester) async {
      PlaygroundLevelOutcome? outcome;
      await tester.pumpWidget(_host(TapChoiceGame(
        choices: const ['Red', 'Blue', 'Green'],
        correctIndex: 1,
        onComplete: (o) => outcome = o,
      )));

      await tester.tap(find.text('Blue'));
      await tester.pump(const Duration(milliseconds: 950));

      expect(outcome?.points, 10);
      expect(outcome?.timedOut, isFalse);
    });

    testWidgets('a miss then the correct tile scores 6', (tester) async {
      PlaygroundLevelOutcome? outcome;
      await tester.pumpWidget(_host(TapChoiceGame(
        choices: const ['Red', 'Blue', 'Green'],
        correctIndex: 1,
        onComplete: (o) => outcome = o,
      )));

      await tester.tap(find.text('Red')); // miss — no red styling, just a flash
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('Blue'));
      await tester.pump(const Duration(milliseconds: 950));

      expect(outcome?.points, 6);
    });

    testWidgets('timing out never answers scores the floor (2), never 0',
        (tester) async {
      PlaygroundLevelOutcome? outcome;
      await tester.pumpWidget(_host(TapChoiceGame(
        choices: const ['Red', 'Blue', 'Green'],
        correctIndex: 1,
        onComplete: (o) => outcome = o,
        timeout: const Duration(seconds: 1),
      )));

      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 950));

      expect(outcome?.points, 2);
      expect(outcome?.timedOut, isTrue);
    });

    testWidgets('a tap after the level already finished is ignored',
        (tester) async {
      var completions = 0;
      await tester.pumpWidget(_host(TapChoiceGame(
        choices: const ['Red', 'Blue', 'Green'],
        correctIndex: 1,
        onComplete: (_) => completions++,
      )));

      await tester.tap(find.text('Blue'));
      await tester.pump(const Duration(milliseconds: 950));
      expect(completions, 1);

      // The tile is still in the tree for a moment; a stray extra tap must
      // not double-fire onComplete.
      await tester.tap(find.text('Blue'));
      await tester.pump();
      expect(completions, 1);
    });
  });

  group('FindTheBallLevel', () {
    testWidgets('tapping the ball straight away scores 10', (tester) async {
      PlaygroundLevelOutcome? outcome;
      await tester.pumpWidget(_host(
        FindTheBallLevel(seed: 1, onComplete: (o) => outcome = o),
      ));

      await tester.tap(find.byKey(const Key('placement_ball')));
      await tester.pump(const Duration(milliseconds: 750));

      expect(outcome?.points, 10);
    });

    testWidgets('two misses trigger the hint and cap the score at 6',
        (tester) async {
      PlaygroundLevelOutcome? outcome;
      await tester.pumpWidget(_host(
        FindTheBallLevel(seed: 1, onComplete: (o) => outcome = o),
      ));

      // Any two non-ball taps (decoys) push past the hint threshold.
      await tester.tap(find.byKey(const Key('placement_decoy_0')));
      await tester.tap(find.byKey(const Key('placement_decoy_1')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('placement_ball')));
      await tester.pump(const Duration(milliseconds: 750));

      expect(outcome?.points, 6);
    });
  });

  group('MemoryMatchLevel', () {
    testWidgets('matching all 3 pairs scores 10 and signals readyForMultiStep',
        (tester) async {
      PlaygroundLevelOutcome? outcome;
      await tester.pumpWidget(_host(
        MemoryMatchLevel(seed: 7, onComplete: (o) => outcome = o),
      ));

      Finder tileAt(int index) => find.byKey(Key('memory_tile_$index'));
      for (var i = 0; i < 6; i++) {
        expect(tileAt(i), findsOneWidget);
      }

      // A face-down tile still shows '❓'; a tile that stayed face up after
      // the mismatch-flip-back window is a real match. Brute-force every
      // unmatched tile against the others — this only trusts what the
      // widget actually renders, not a side-channel guess at the shuffle.
      bool isFaceUp(int index) => find
          .descendant(of: tileAt(index), matching: find.text('❓'))
          .evaluate()
          .isEmpty;

      final remaining = List.generate(6, (i) => i);
      while (remaining.length > 1) {
        final anchor = remaining.first;
        var foundMatch = false;
        for (final candidate in remaining.skip(1).toList()) {
          await tester.tap(tileAt(anchor));
          await tester.pump();
          await tester.tap(tileAt(candidate));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 900)); // flip-back window
          if (isFaceUp(anchor) && isFaceUp(candidate)) {
            remaining.remove(anchor);
            remaining.remove(candidate);
            foundMatch = true;
            break;
          }
        }
        expect(foundMatch, isTrue, reason: 'every tile has exactly one partner');
      }
      await tester.pump(const Duration(milliseconds: 750));

      expect(outcome?.points, 10);
      expect(outcome?.payload, isTrue);
    });
  });

  group('CopyThePatternLevel', () {
    // The 3 tiles render in a fixed visual order (⚽🎈🌟); `_pattern` only
    // decides the tap order the demo teaches, computed the same way the
    // widget computes it internally. Replicating that formula here is more
    // robust than trying to poll the demo animation to infer it, and each
    // tile carries a stable key (`pattern_tile_<index>`) so tapping doesn't
    // depend on animation timing either.
    List<int> expectedPattern(int seed) {
      final rng = Random(seed ^ 'copy_the_pattern'.hashCode);
      return List.generate(3, (i) => i)..shuffle(rng);
    }

    Finder tileAt(int index) => find.byKey(Key('pattern_tile_$index'));

    Future<void> tapPattern(WidgetTester tester, List<int> order) async {
      for (final index in order) {
        await tester.tap(tileAt(index));
        await tester.pump();
      }
    }

    // 3 steps x (550ms highlight + 200ms gap) = 2250ms; comfortably covered
    // by a single 3s pump, which also flushes the chained `Future.delayed`
    // calls that make up the demo (see full_journey_test.dart for the same
    // technique used against this level's extended timeout).
    const demoDuration = Duration(seconds: 3);

    testWidgets('repeating the demo pattern correctly on the first try scores 10',
        (tester) async {
      const seed = 3;
      PlaygroundLevelOutcome? outcome;
      await tester.pumpWidget(_host(
        CopyThePatternLevel(seed: seed, onComplete: (o) => outcome = o),
      ));
      await tester.pump(demoDuration);

      await tapPattern(tester, expectedPattern(seed));
      await tester.pump(const Duration(milliseconds: 950));

      expect(outcome?.points, 10);
    });

    testWidgets('a mismatch triggers one retry demo; correct on the retry scores 6',
        (tester) async {
      const seed = 3;
      PlaygroundLevelOutcome? outcome;
      await tester.pumpWidget(_host(
        CopyThePatternLevel(seed: seed, onComplete: (o) => outcome = o),
      ));
      await tester.pump(demoDuration);

      final correct = expectedPattern(seed);
      final wrong = correct.reversed.toList(); // guaranteed to differ at [0]
      await tapPattern(tester, wrong); // first tap already mismatches
      await tester.pump(demoDuration); // the one allowed retry demo plays

      await tapPattern(tester, correct);
      await tester.pump(const Duration(milliseconds: 950));

      expect(outcome?.points, 6);
    });

    testWidgets('still wrong after the retry scores the floor (2), never 0',
        (tester) async {
      const seed = 3;
      PlaygroundLevelOutcome? outcome;
      await tester.pumpWidget(_host(
        CopyThePatternLevel(seed: seed, onComplete: (o) => outcome = o),
      ));
      await tester.pump(demoDuration);

      final wrong = expectedPattern(seed).reversed.toList();
      await tapPattern(tester, wrong); // mismatch -> retry demo
      await tester.pump(demoDuration);
      // The second mismatch finalizes the level immediately (no more
      // retries), swapping the tiles out for the celebration widget — only
      // the first tap of this attempt is reachable.
      await tester.tap(tileAt(wrong.first));
      await tester.pump(const Duration(milliseconds: 950));

      expect(outcome?.points, 2);
    });
  });

  group('RepeatAfterMeLevel (speech is diagnostic only, never gating)', () {
    Future<int?> runWithAttempt(WidgetTester tester, SpeechAttempt attempt) async {
      PlaygroundLevelOutcome? outcome;
      await tester.pumpWidget(_host(
        RepeatAfterMeLevel(onComplete: (o) => outcome = o),
        overrides: [
          speechInputServiceProvider
              .overrideWithValue(_ScriptedSpeechInputService(attempt)),
        ],
      ));
      await tester.tap(find.text('🎤'));
      await tester.pump(const Duration(milliseconds: 900));
      return outcome?.points;
    }

    testWidgets('a matched word scores 10', (tester) async {
      final points = await runWithAttempt(tester,
          const SpeechAttempt(SpeechAttemptResult.matched, recognizedWords: 'ball'));
      expect(points, 10);
    });

    testWidgets('any vocalization without a match scores 6', (tester) async {
      final points = await runWithAttempt(
          tester, const SpeechAttempt(SpeechAttemptResult.vocalized));
      expect(points, 6);
    });

    testWidgets('a permission-denied / unavailable recognizer never blocks',
        (tester) async {
      final points = await runWithAttempt(
          tester, const SpeechAttempt(SpeechAttemptResult.unavailable));
      expect(points, isNotNull); // completed, not stuck
      expect(points, greaterThan(0)); // never shamed with a 0
    });
  });

  group('PickFavoritesLevel', () {
    testWidgets('tap order becomes interestIds order, always full credit',
        (tester) async {
      PlaygroundLevelOutcome? outcome;
      await tester.pumpWidget(_host(
        PickFavoritesLevel(seed: 5, onComplete: (o) => outcome = o),
      ));

      await tester.tap(find.text('🚀')); // space
      await tester.tap(find.text('🦖')); // dinosaurs
      await tester.tap(find.text('🐠')); // ocean
      await tester.pump(const Duration(milliseconds: 550));

      expect(outcome?.points, 10);
      expect(outcome?.payload, ['space', 'dinosaurs', 'ocean']);
    });

    testWidgets('tapping the same tile twice deselects it', (tester) async {
      PlaygroundLevelOutcome? outcome;
      await tester.pumpWidget(_host(
        PickFavoritesLevel(seed: 5, onComplete: (o) => outcome = o),
      ));

      await tester.tap(find.text('🚀'));
      await tester.pump();
      await tester.tap(find.text('🚀')); // deselect
      await tester.pump();
      await tester.tap(find.text('🦖'));
      await tester.tap(find.text('🐠'));
      await tester.tap(find.text('🐶'));
      await tester.pump(const Duration(milliseconds: 550));

      expect(outcome?.payload, isNot(contains('space')));
      expect(outcome?.payload, ['dinosaurs', 'ocean', 'animals']);
    });
  });
}
