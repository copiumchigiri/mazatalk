import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/widgets/maza_speech_bubble.dart';
import '../../domain/placement_result.dart';
import '../art/painters.dart';
import '../art/play_art.dart';
import 'tap_choice_game.dart';

const _colorNames = ['Улаан', 'Хөх', 'Ногоон', 'Шар'];
const _colorArt = ['pot_red', 'pot_blue', 'pot_green', 'pot_yellow'];
const _colors = [
  Color(0xFFEF5350),
  Color(0xFF42A5F5),
  Color(0xFF66BB6A),
  Color(0xFFFFCA28),
];

/// Act 1, level 3 — Tap the Color (PROJECT_V4.md §6): listening vocabulary
/// with the same 4 colors as Unit 1 Lesson 5. The child never has to read:
/// Maza names a color and the choices are real paint pots.
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
    final correctIndex = rng.nextInt(_colorNames.length);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MazaSpeechBubble(text: '${_colorNames[correctIndex]} өнгийг дар!'),
        const SizedBox(height: 24),
        Expanded(
          child: TapChoiceGame(
            choices: _colorNames,
            correctIndex: correctIndex,
            onComplete: onComplete,
            faceBuilder: (i) => Semantics(
              label: _colorNames[i],
              child: PlayArt(
                name: _colorArt[i],
                placeholder: PotPainter(_colors[i]),
                width: 96,
                height: 96,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
