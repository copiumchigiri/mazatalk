import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/maza_speech_bubble.dart';
import '../../domain/placement_result.dart';
import '../art/painters.dart';
import '../art/play_art.dart';
import '../art/play_feedback.dart';

const _shapes = [PlayShape.circle, PlayShape.square, PlayShape.triangle];
// Accusative forms, for "put the <shape> in its hole".
const _shapeAccusative = {
  PlayShape.circle: 'Дугуйг',
  PlayShape.square: 'Дөрвөлжинг',
  PlayShape.triangle: 'Гурвалжинг',
};
const _shapeArt = {
  PlayShape.circle: 'shape_circle',
  PlayShape.square: 'shape_square',
  PlayShape.triangle: 'shape_triangle',
};

/// Act 2, level 3 — Match the Shape (PROJECT_V4.md §6): a shape-sorter
/// puzzle. One solid piece sits at the bottom; the child drags it into the
/// hole that has its outline. A wrong hole wiggles and the piece slides back
/// (no red); first-try scores 10, otherwise 6. A forward probe feeding only
/// the supplementary `shapeAwareness` signal.
///
/// Keys: `shape_drag` (the piece), `shape_hole_<index>` (the holes, left to
/// right); [holeShapes] exposes the order for tests.
class MatchTheShapeLevel extends StatefulWidget {
  final int seed;
  final PlaygroundLevelComplete onComplete;

  const MatchTheShapeLevel({
    super.key,
    required this.seed,
    required this.onComplete,
  });

  /// The hole order and target piece for [seed] — same math as the state, so
  /// tests can drop the piece in the right hole without peeking at widgets.
  static ({List<PlayShape> holes, PlayShape target}) layoutFor(int seed) {
    final rng = Random(seed ^ 'match_the_shape'.hashCode);
    final holes = [..._shapes]..shuffle(rng);
    return (holes: holes, target: holes[rng.nextInt(holes.length)]);
  }

  @override
  State<MatchTheShapeLevel> createState() => _MatchTheShapeLevelState();
}

class _MatchTheShapeLevelState extends State<MatchTheShapeLevel>
    with PlayFeedbackMixin {
  late final List<PlayShape> _holes;
  late final PlayShape _target;
  int _misses = 0;
  int? _wiggleHole;
  int _wiggleTick = 0;
  bool _placed = false;

  @override
  void initState() {
    super.initState();
    final layout = MatchTheShapeLevel.layoutFor(widget.seed);
    _holes = layout.holes;
    _target = layout.target;
  }

  void _onDrop(int holeIndex) {
    if (_placed) return;
    if (_holes[holeIndex] == _target) {
      setState(() => _placed = true);
      cheer();
      Future.delayed(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        widget.onComplete(PlaygroundLevelOutcome(_misses == 0 ? 10 : 6));
      });
    } else {
      setState(() {
        _misses++;
        _wiggleHole = holeIndex;
        _wiggleTick++;
      });
      tryAgain();
    }
  }

  Widget _piece(PlayShape shape, {bool hole = false, double size = 96}) =>
      PlayArt(
        name: hole ? '${_shapeArt[shape]!}_hole' : _shapeArt[shape]!,
        placeholder: ShapePainter(shape, hole: hole),
        width: size,
        height: size,
      );

  @override
  Widget build(BuildContext context) {
    return withCheer(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MazaSpeechBubble(
            text: '${_shapeAccusative[_target]} зөв нүхэнд нь хий!',
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (var i = 0; i < _holes.length; i++)
                DragTarget<PlayShape>(
                  onWillAcceptWithDetails: (_) => !_placed,
                  onAcceptWithDetails: (_) => _onDrop(i),
                  builder: (context, candidates, rejected) => Wiggle(
                    trigger: _wiggleHole == i ? _wiggleTick : 0,
                    child: SizedBox(
                      key: Key('shape_hole_$i'),
                      width: 96,
                      height: 96,
                      child: _placed && _holes[i] == _target
                          ? _piece(_holes[i])
                          : _piece(_holes[i], hole: true),
                    ),
                  ),
                ),
            ],
          ),
          const Spacer(),
          SizedBox(
            height: 120,
            child: Center(
              child: _placed
                  ? const SizedBox.shrink()
                  : Draggable<PlayShape>(
                      key: const Key('shape_drag'),
                      data: _target,
                      feedback: Material(
                        type: MaterialType.transparency,
                        child: _piece(_target),
                      ),
                      childWhenDragging: Opacity(
                        opacity: .25,
                        child: _piece(_target),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primaryLight,
                            width: 2,
                          ),
                        ),
                        child: _piece(_target),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
