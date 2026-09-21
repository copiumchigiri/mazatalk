import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazatalk/features/curriculum/data/activity_factories.dart';
import 'package:mazatalk/features/lesson/presentation/activities/multi_step_boards.dart';

Widget _host(Widget board) => MaterialApp(
      home: Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: board)),
    );

void main() {
  testWidgets('MatchPairsBoard: solving cleanly reports clean=true',
      (tester) async {
    final activity = matchPairs(
      'Match',
      const [('cat', '🐱'), ('dog', '🐶'), ('sun', '☀️')],
      Random(1),
    );
    bool? result;
    await tester.pumpWidget(_host(
      MatchPairsBoard(activity: activity, onFinished: (clean) => result = clean),
    ));

    for (var left = 0; left < activity.choices.length; left++) {
      await tester.tap(find.text(activity.choices[left]));
      await tester.pump();
      final right = activity.rightColumn[activity.correctOrder[left]];
      await tester.tap(find.text(right));
      await tester.pump();
    }
    expect(result, isTrue);
  });

  testWidgets('MatchPairsBoard: a wrong match flashes and reports clean=false',
      (tester) async {
    final activity = matchPairs(
      'Match',
      const [('cat', '🐱'), ('dog', '🐶'), ('sun', '☀️')],
      Random(1),
    );
    bool? result;
    await tester.pumpWidget(_host(
      MatchPairsBoard(activity: activity, onFinished: (clean) => result = clean),
    ));

    // Select left 0, tap a wrong right tile.
    final wrongRight = activity.rightColumn[
        activity.correctOrder[0] == 0 ? 1 : 0];
    await tester.tap(find.text(activity.choices[0]));
    await tester.pump();
    await tester.tap(find.text(wrongRight));
    await tester.pump();
    expect(result, isNull, reason: 'board not finished after a wrong tap');
    await tester.pump(const Duration(milliseconds: 500));

    for (var left = 0; left < activity.choices.length; left++) {
      await tester.tap(find.text(activity.choices[left]));
      await tester.pump();
      final right = activity.rightColumn[activity.correctOrder[left]];
      await tester.tap(find.text(right));
      await tester.pump();
    }
    expect(result, isFalse);
  });

  testWidgets('FillBlankBoard: wrong letter retries, right letter finishes',
      (tester) async {
    final activity = fillBlankWord('cat', '🐱', 1, Random(2));
    bool? result;
    await tester.pumpWidget(_host(
      FillBlankBoard(activity: activity, onFinished: (clean) => result = clean),
    ));

    final wrongIndex = activity.correctIndex == 0 ? 1 : 0;
    await tester.tap(find.text(activity.choices[wrongIndex]));
    await tester.pump();
    expect(result, isNull);
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text(activity.choices[activity.correctIndex]));
    await tester.pump();
    expect(result, isFalse, reason: 'had a mistake → clean=false');
  });

  testWidgets('SequenceBoard: tiles lock in order; out-of-order taps flash',
      (tester) async {
    final activity = sequenceTap(
      'Tap in order',
      const ['1', '2', '3'],
      Random(3),
      skillId: 'counting',
    );
    bool? result;
    await tester.pumpWidget(_host(
      SequenceBoard(activity: activity, onFinished: (clean) => result = clean),
    ));

    // Tap '3' first — wrong unless it's genuinely the first in order.
    // correctOrder holds choice-indices in tap order; taps go by tile text.
    await tester.tap(find.text('2'));
    await tester.pump();
    expect(result, isNull);
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('1'));
    await tester.pump();
    await tester.tap(find.text('2'));
    await tester.pump();
    await tester.tap(find.text('3'));
    await tester.pump();
    expect(result, isFalse, reason: 'out-of-order tap earlier → clean=false');
  });

  testWidgets('SequenceBoard: clean solve reports clean=true', (tester) async {
    final activity = sequenceTap(
      'Tap in order',
      const ['1', '2', '3'],
      Random(3),
      skillId: 'counting',
    );
    bool? result;
    await tester.pumpWidget(_host(
      SequenceBoard(activity: activity, onFinished: (clean) => result = clean),
    ));
    await tester.tap(find.text('1'));
    await tester.pump();
    await tester.tap(find.text('2'));
    await tester.pump();
    await tester.tap(find.text('3'));
    await tester.pump();
    expect(result, isTrue);
  });
}
