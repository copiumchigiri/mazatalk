import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/widgets/maza_speech_bubble.dart';
import '../../domain/placement_result.dart';
import 'tap_choice_game.dart';

const _letters = ['A', 'B', 'C', 'D', 'E'];

/// Level 5 — Find the Letter (PROJECT_V4.md §6): recognition of Unit 1's
/// first five letters, spoken by sound the same way `letterListen` prompts
/// do in the real curriculum (`activity_factories.dart`).
class FindTheLetterLevel extends StatelessWidget {
  final int seed;
  final PlaygroundLevelComplete onComplete;

  const FindTheLetterLevel({
    super.key,
    required this.seed,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final rng = Random(seed ^ 'find_the_letter'.hashCode);
    final choices = [..._letters]..shuffle(rng);
    final target = choices[rng.nextInt(choices.length)];
    final correctIndex = choices.indexOf(target);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MazaSpeechBubble(text: 'Find the letter... $target!'),
        const SizedBox(height: 24),
        Expanded(
          child: TapChoiceGame(
            choices: choices,
            correctIndex: correctIndex,
            onComplete: onComplete,
          ),
        ),
      ],
    );
  }
}
