import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/widgets/maza_speech_bubble.dart';
import '../../../profile/domain/interest.dart';
import '../../application/playground_session_controller.dart';
import '../../domain/placement_result.dart';
import '../playground_level_timeout_mixin.dart';

/// Level 7 — Pick Your Favorites (PROJECT_V4.md §6): replaces the old
/// `InterestSelectScreen` form. Tap 3 toybox tiles; there's no correct
/// answer here, so this always scores full credit — it exists purely to
/// capture `interestIds` the same way the retired form used to, just in the
/// playground's voice. Tap order is preserved (interestIds[0] anchors
/// Lesson 1's theme, per the curriculum's topic-cycling in
/// `course_builder.dart`), and any unpicked slots at the extended timeout
/// are backfilled at random so theming always has 3 interests to cycle
/// through.
class PickFavoritesLevel extends StatefulWidget {
  final int seed;
  final PlaygroundLevelComplete onComplete;

  const PickFavoritesLevel({
    super.key,
    required this.seed,
    required this.onComplete,
  });

  @override
  State<PickFavoritesLevel> createState() => _PickFavoritesLevelState();
}

class _PickFavoritesLevelState extends State<PickFavoritesLevel>
    with PlaygroundLevelTimeoutMixin {
  final List<Interest> _picked = [];
  bool _done = false;

  @override
  void initState() {
    super.initState();
    startLevelTimeout(
        kPlaygroundExtendedLevelTimeout, () => _finish(timedOut: true));
  }

  void _onTap(Interest interest) {
    if (_done) return;
    setState(() {
      if (_picked.contains(interest)) {
        _picked.remove(interest);
      } else if (_picked.length < 3) {
        _picked.add(interest);
      }
    });
    if (_picked.length == 3) {
      cancelLevelTimeout();
      Future.delayed(const Duration(milliseconds: 500), () => _finish());
    }
  }

  void _finish({bool timedOut = false}) {
    if (_done) return;
    _done = true;
    cancelLevelTimeout();
    final result = [..._picked];
    if (result.length < 3) {
      final remaining =
          Interest.values.where((i) => !result.contains(i)).toList()
            ..shuffle(Random(widget.seed ^ 'pick_favorites'.hashCode));
      result.addAll(remaining.take(3 - result.length));
    }
    widget.onComplete(PlaygroundLevelOutcome(
      10,
      timedOut: timedOut,
      payload: result.map((i) => i.id).toList(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MazaSpeechBubble(text: 'Tap 3 things you love!'),
        const SizedBox(height: 16),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.9,
            ),
            itemCount: Interest.values.length,
            itemBuilder: (context, index) {
              final interest = Interest.values[index];
              final isSelected = _picked.contains(interest);
              return GestureDetector(
                onTap: () => _onTap(interest),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.black : Colors.white,
                    border: Border.all(color: Colors.black, width: 2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(interest.emoji, style: const TextStyle(fontSize: 30)),
                      const SizedBox(height: 4),
                      Text(
                        interest.label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
