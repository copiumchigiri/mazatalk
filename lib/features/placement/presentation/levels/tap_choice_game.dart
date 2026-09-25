import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/placement_result.dart';
import '../art/play_feedback.dart';
import '../play_tile.dart';

/// Shared tap-one-of-N mechanic behind Tap the Color, Count the Friends and
/// Find the Letter: tap the right tile, first try scores 10, a miss-then-
/// correct scores 6. There is no timeout — the level waits indefinitely for
/// a real answer and only gently pulses while it waits. **No red anywhere**
/// (PROJECT_V4.md §9): a wrong tap wiggles and dims the tile, and Maza says
/// to try again; a right tap sets off the star burst and Maza's praise.
///
/// Tiles show [choices] as text unless [faceBuilder] supplies art (paint
/// pots, etc.). Each tile is keyed `choice_<index>`.
class TapChoiceGame extends StatefulWidget {
  final List<String> choices;
  final int correctIndex;
  final PlaygroundLevelComplete onComplete;
  final Widget Function(int index)? faceBuilder;

  const TapChoiceGame({
    super.key,
    required this.choices,
    required this.correctIndex,
    required this.onComplete,
    this.faceBuilder,
  });

  @override
  State<TapChoiceGame> createState() => _TapChoiceGameState();
}

class _TapChoiceGameState extends State<TapChoiceGame> with PlayFeedbackMixin {
  int _missCount = 0;
  int? _flashIndex;
  int? _revealCorrectIndex;
  int? _wiggleIndex;
  int _wiggleTick = 0;
  bool _done = false;

  void _onTap(int index) {
    if (_done) return;
    if (index == widget.correctIndex) {
      _finish(_missCount == 0 ? 10 : 6);
      return;
    }
    setState(() {
      _missCount++;
      _flashIndex = index;
      _wiggleIndex = index;
      _wiggleTick++;
    });
    tryAgain();
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _flashIndex = null);
    });
  }

  void _finish(int points) {
    if (_done) return;
    _done = true;
    setState(() => _revealCorrectIndex = widget.correctIndex);
    cheer();
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      widget.onComplete(PlaygroundLevelOutcome(points));
    });
  }

  @override
  Widget build(BuildContext context) {
    return withCheer(
      GridView.builder(
        padding: EdgeInsets.zero,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.3,
        ),
        itemCount: widget.choices.length,
        itemBuilder: (context, index) {
          final dimmed = _flashIndex == index;
          return Wiggle(
            trigger: _wiggleIndex == index ? _wiggleTick : 0,
            child: PlayTile(
              key: Key('choice_$index'),
              state: _revealCorrectIndex == index
                  ? PlayTileState.selected
                  : (dimmed ? PlayTileState.dimmed : PlayTileState.normal),
              onTap: () => _onTap(index),
              child:
                  widget.faceBuilder?.call(index) ??
                  Text(
                    widget.choices[index],
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: dimmed
                          ? AppColors.textLight
                          : AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
            ),
          );
        },
      ),
    );
  }
}
