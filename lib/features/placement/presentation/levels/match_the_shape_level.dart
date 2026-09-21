import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/widgets/maza_speech_bubble.dart';
import '../../domain/placement_result.dart';
import 'tap_choice_game.dart';

const _shapes = ['Circle', 'Square', 'Triangle'];

/// Level 6 — Match the Shape (PROJECT_V4.md §6): a forward probe, not a
/// core placement signal — shapes live in Unit 2, not Unit 1, so this only
/// feeds the supplementary `shapeAwareness` signal (PROJECT_V4.md §7.1),
/// never the starting-lesson math.
class MatchTheShapeLevel extends StatelessWidget {
  final int seed;
  final PlaygroundLevelComplete onComplete;

  const MatchTheShapeLevel({
    super.key,
    required this.seed,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final rng = Random(seed ^ 'match_the_shape'.hashCode);
    final correctIndex = rng.nextInt(_shapes.length);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MazaSpeechBubble(text: 'Find the ${_shapes[correctIndex]}!'),
        const SizedBox(height: 24),
        Expanded(
          child: TapChoiceGame(
            choices: _shapes,
            correctIndex: correctIndex,
            onComplete: onComplete,
          ),
        ),
      ],
    );
  }
}
