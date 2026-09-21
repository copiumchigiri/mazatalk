import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/widgets/maza_speech_bubble.dart';
import '../../domain/placement_result.dart';
import 'tap_choice_game.dart';

/// Level 4 — Count the Friends (PROJECT_V4.md §6): counting, mirroring
/// Unit 1's counting lessons. Interests aren't known yet at this point in
/// the playground (Level 7 runs later), so a generic 🧸 is used.
class CountTheFriendsLevel extends StatelessWidget {
  final int seed;
  final PlaygroundLevelComplete onComplete;

  const CountTheFriendsLevel({
    super.key,
    required this.seed,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final rng = Random(seed ^ 'count_the_friends'.hashCode);
    final target = 2 + rng.nextInt(4); // 2..5
    final numberChoices = {target}..addAll(
        List.generate(5, (i) => i + 1).where((n) => n != target),
      );
    final choices = numberChoices.take(4).toList()..shuffle(rng);
    final correctIndex = choices.indexOf(target);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MazaSpeechBubble(text: 'How many teddy bears?'),
        const SizedBox(height: 12),
        Text(
          List.filled(target, '🧸').join(' '),
          style: const TextStyle(fontSize: 30),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Expanded(
          child: TapChoiceGame(
            choices: choices.map((n) => '$n').toList(),
            correctIndex: correctIndex,
            onComplete: onComplete,
          ),
        ),
      ],
    );
  }
}
