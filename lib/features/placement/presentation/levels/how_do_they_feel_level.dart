import 'package:flutter/material.dart';
import '../../../../core/widgets/maza_speech_bubble.dart';
import '../../application/playground_session_controller.dart';
import '../../domain/placement_result.dart';
import '../playground_level_timeout_mixin.dart';

const _scenario = "Your friend shares their toy with you! How do they feel?";
const _emotions = ['😊', '😢', '😠', '😨'];
const _expectedIndex = 0; // 😊

/// Level 8 — How Do They Feel? (PROJECT_V4.md §6): a bonus signal for the
/// parent dashboard's future EQ data, not a placement input. Every tap gets
/// the exact same green celebration regardless of which face was picked —
/// there's no on-screen "right answer" here, only a quietly recorded score
/// (PROJECT_V4.md §9: no red, no "wrong," anywhere in the playground).
class HowDoTheyFeelLevel extends StatefulWidget {
  final PlaygroundLevelComplete onComplete;

  const HowDoTheyFeelLevel({super.key, required this.onComplete});

  @override
  State<HowDoTheyFeelLevel> createState() => _HowDoTheyFeelLevelState();
}

class _HowDoTheyFeelLevelState extends State<HowDoTheyFeelLevel>
    with PlaygroundLevelTimeoutMixin {
  int? _tappedIndex;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    startLevelTimeout(kPlaygroundDefaultLevelTimeout, () => _finish(4, timedOut: true));
  }

  void _onTap(int index) {
    if (_done) return;
    cancelLevelTimeout();
    setState(() => _tappedIndex = index);
    _finish(index == _expectedIndex ? 10 : 6);
  }

  void _finish(int points, {bool timedOut = false}) {
    if (_done) return;
    _done = true;
    cancelLevelTimeout();
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      widget.onComplete(PlaygroundLevelOutcome(points, timedOut: timedOut));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MazaSpeechBubble(text: _scenario),
        const SizedBox(height: 24),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.3,
            ),
            itemCount: _emotions.length,
            itemBuilder: (context, index) {
              final tapped = _tappedIndex == index;
              return Material(
                color: tapped ? Colors.green.shade200 : Colors.white,
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    color: tapped ? Colors.green.shade700 : Colors.black,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _onTap(index),
                  child: Center(
                    child: Text(_emotions[index],
                        style: const TextStyle(fontSize: 40)),
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
