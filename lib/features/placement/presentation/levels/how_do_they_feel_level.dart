import 'package:flutter/material.dart';
import '../../../../core/widgets/maza_speech_bubble.dart';
import '../../domain/placement_result.dart';
import '../art/painters.dart';
import '../art/play_art.dart';
import '../art/play_feedback.dart';
import '../play_tile.dart';

const _scenario =
    'Найз чинь тоглоомоо тантай хуваалцлаа! Тэр ямар '
    'мэдрэмжтэй байна вэ?';
const _feelings = [Feeling.happy, Feeling.sad, Feeling.angry, Feeling.scared];
const _expectedIndex = 0; // happy

/// Act 3, level 2 — How Do They Feel (PROJECT_V4.md §6): Maza's friend
/// shared a toy with him; which face shows how the friend feels? Feeds
/// `emotionAwareness` (and the parent dashboard's future EQ data), not
/// placement. Every tap gets the same star burst and praise — there is no
/// on-screen "wrong" (PROJECT_V4.md §9), only a quietly recorded score.
/// There is no timeout. Faces are keyed `feeling_<index>` (0 = happy).
class HowDoTheyFeelLevel extends StatefulWidget {
  final PlaygroundLevelComplete onComplete;

  const HowDoTheyFeelLevel({super.key, required this.onComplete});

  @override
  State<HowDoTheyFeelLevel> createState() => _HowDoTheyFeelLevelState();
}

class _HowDoTheyFeelLevelState extends State<HowDoTheyFeelLevel>
    with PlayFeedbackMixin {
  int? _tappedIndex;
  bool _done = false;

  void _onTap(int index) {
    if (_done) return;
    _done = true;
    setState(() => _tappedIndex = index);
    cheer();
    final points = index == _expectedIndex ? 10 : 6;
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      widget.onComplete(PlaygroundLevelOutcome(points));
    });
  }

  @override
  Widget build(BuildContext context) {
    return withCheer(
      Column(
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
                childAspectRatio: 1.1,
              ),
              itemCount: _feelings.length,
              itemBuilder: (context, index) => PlayTile(
                key: Key('feeling_$index'),
                state: _tappedIndex == index
                    ? PlayTileState.selected
                    : PlayTileState.normal,
                onTap: () => _onTap(index),
                child: PlayArt(
                  name: 'face_${_feelings[index].name}',
                  placeholder: FacePainter(_feelings[index]),
                  width: 84,
                  height: 84,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
