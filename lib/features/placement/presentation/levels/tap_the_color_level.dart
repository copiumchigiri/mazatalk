import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/widgets/maza_speech_bubble.dart';
import '../../../curriculum/data/activity_factories.dart' show colorNames;
import '../../domain/placement_result.dart';
import 'tap_choice_game.dart';

/// Level 3 — Tap the Color (PROJECT_V4.md §6): listening vocabulary, using
/// the same 4 colors as Unit 1 Lesson 5 so the probe measures a skill the
/// curriculum actually teaches next. Colors are named as text, not shown as
/// literal color swatches — matching the rest of the app's "designless"
/// black/white convention (see `lesson_player_screen.dart`).
class TapTheColorLevel extends StatelessWidget {
  final int seed;
  final PlaygroundLevelComplete onComplete;

  const TapTheColorLevel({
    super.key,
    required this.seed,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final rng = Random(seed ^ 'tap_the_color'.hashCode);
    final correctIndex = rng.nextInt(colorNames.length);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MazaSpeechBubble(text: 'Tap the color ${colorNames[correctIndex]}!'),
        const SizedBox(height: 24),
        Expanded(
          child: TapChoiceGame(
            choices: colorNames,
            correctIndex: correctIndex,
            onComplete: onComplete,
          ),
        ),
      ],
    );
  }
}
