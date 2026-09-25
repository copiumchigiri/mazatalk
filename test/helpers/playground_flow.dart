import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazatalk/features/placement/presentation/levels/tap_choice_game.dart';

/// Plays the whole 9-level "Maza's trip" playground for real (no timeouts to
/// lean on), for the journey tests. The screen's seed is time-based, so
/// every level is answered by trying options until it advances.
///
/// Needs a tall surface (see the journey tests) so every tile is on screen.
Future<void> playPlayground(
  WidgetTester tester, {
  List<String> favorites = const ['dinosaurs', 'space', 'ocean'],
}) async {
  Future<void> startAct() async {
    await tester.tap(find.byKey(const Key('act_intro_go')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  int tapChoiceTileCount() => find
      .descendant(
        of: find.byType(TapChoiceGame),
        matching: find.byType(InkWell),
      )
      .evaluate()
      .length;

  // Cycles through the tiles until the tile count changes (the level
  // advanced); a wrong tap just wiggles, so bounded retries always converge.
  Future<void> answerTapChoiceLevel() async {
    final initialCount = tapChoiceTileCount();
    for (var attempt = 0; attempt < initialCount * 3; attempt++) {
      if (tapChoiceTileCount() != initialCount) return;
      final tiles = find.descendant(
        of: find.byType(TapChoiceGame),
        matching: find.byType(InkWell),
      );
      await tester.tap(tiles.at(attempt % initialCount), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 950));
    }
  }

  Future<void> answerTapChoiceLevels() async {
    var guard = 0;
    while (tapChoiceTileCount() > 0 && guard < 20) {
      await answerTapChoiceLevel();
      guard++;
    }
  }

  // ---- Act 1: Тал нутаг ----
  await startAct();
  // Find the Ball.
  await tester.tap(find.byKey(const Key('placement_ball')));
  await tester.pump(const Duration(milliseconds: 750));
  // Repeat After Me: the scripted speech service resolves instantly to
  // "unavailable", which still completes the level.
  await tester.tap(find.byIcon(Icons.mic));
  await tester.pump(const Duration(milliseconds: 700));
  // Tap the Color.
  await answerTapChoiceLevels();

  // ---- Act 2: Голын эрэг ----
  await startAct();
  // Count the Friends + Find the Letter.
  await answerTapChoiceLevels();
  // Match the Shape: drag the piece to each hole until it lands.
  for (var hole = 0; hole < 3; hole++) {
    final piece = find.byKey(const Key('shape_drag'));
    if (piece.evaluate().isEmpty) break;
    await tester.drag(
      piece,
      tester.getCenter(find.byKey(Key('shape_hole_$hole'))) -
          tester.getCenter(piece),
    );
    await tester.pump(const Duration(milliseconds: 500));
  }
  await tester.pump(const Duration(milliseconds: 950));

  // ---- Act 3: Гэрийн дэргэд ----
  await startAct();
  // Pick Favorites: tap order becomes `interestIds` order.
  for (final id in favorites) {
    await tester.tap(find.byKey(Key('interest_$id')));
  }
  await tester.pump(const Duration(milliseconds: 550));
  // How Do They Feel: no wrong answer, tap any face.
  await tester.tap(find.byKey(const Key('feeling_0')));
  await tester.pump(const Duration(milliseconds: 750));
  // Copy the Pattern: only one retry is ever allowed, so tap one pad at a
  // time and bail the moment the prompt changes (that tap just resolved),
  // waiting out the demo phases in between.
  var guard = 0;
  while (find.byKey(const Key('pattern_tile_0')).evaluate().isNotEmpty &&
      guard < 30) {
    if (find.text('Одоо чи оролдоорой!').evaluate().isNotEmpty) {
      for (final i in [0, 1, 2]) {
        if (find.byKey(Key('pattern_tile_$i')).evaluate().isEmpty) break;
        if (find.text('Одоо чи оролдоорой!').evaluate().isEmpty) break;
        await tester.tap(find.byKey(Key('pattern_tile_$i')));
        await tester.pump(const Duration(milliseconds: 100));
      }
    } else {
      await tester.pump(const Duration(milliseconds: 300));
    }
    guard++;
  }
  await tester.pump(const Duration(milliseconds: 950));
  await tester.pumpAndSettle();
}
