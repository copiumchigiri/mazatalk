import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/maza_speech_bubble.dart';
import '../../domain/placement_result.dart';
import '../art/painters.dart';
import '../art/play_art.dart';
import '../art/play_feedback.dart';

const _gridColumns = 3;
const _gridRows = 4;
const _bushCount = 8;

/// Act 1, level 1 — Find the Ball (PROJECT_V4.md §6): Maza's ball is hiding
/// under one of the bushes in the meadow. Empty bushes just wiggle (never
/// red); after two misses or 6 seconds of no input a soft glow marks the
/// right bush. There is no timeout — the level waits for the child to find
/// the ball, and the glow is the only nudge that ever fires.
///
/// Keys: `placement_ball` (the ball's bush), `placement_decoy_<i>` (empty).
class FindTheBallLevel extends StatefulWidget {
  final int seed;
  final PlaygroundLevelComplete onComplete;

  const FindTheBallLevel({
    super.key,
    required this.seed,
    required this.onComplete,
  });

  @override
  State<FindTheBallLevel> createState() => _FindTheBallLevelState();
}

class _FindTheBallLevelState extends State<FindTheBallLevel>
    with PlayFeedbackMixin {
  late final List<int> _cells; // [0] holds the ball, the rest are empty
  int _missCount = 0;
  int? _wiggleDecoy;
  int _wiggleTick = 0;
  bool _hintShown = false;
  bool _found = false;
  bool _done = false;
  Timer? _hintTimer;

  @override
  void initState() {
    super.initState();
    final rng = Random(widget.seed ^ PlaygroundLevelId.findTheBall.hashCode);
    _cells = (List.generate(
      _gridColumns * _gridRows,
      (i) => i,
    )..shuffle(rng)).take(_bushCount).toList();
    _hintTimer = Timer(const Duration(seconds: 6), () {
      if (!mounted || _done) return;
      setState(() => _hintShown = true);
    });
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    super.dispose();
  }

  void _onDecoyTap(int i) {
    if (_done) return;
    setState(() {
      _missCount++;
      _wiggleDecoy = i;
      _wiggleTick++;
      if (_missCount >= 2) _hintShown = true;
    });
    tryAgain();
  }

  void _onBallTap() {
    if (_done) return;
    _done = true;
    _hintTimer?.cancel();
    setState(() => _found = true);
    cheer();
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      widget.onComplete(PlaygroundLevelOutcome(_hintShown ? 6 : 10));
    });
  }

  @override
  Widget build(BuildContext context) {
    return withCheer(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const MazaSpeechBubble(text: 'Бөмбөг бутанд нуугдсан байна. Ол!'),
          const SizedBox(height: 16),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cellWidth = constraints.maxWidth / _gridColumns;
                final cellHeight = constraints.maxHeight / _gridRows;
                return Stack(
                  children: [
                    // The ball's bush (index 0) is added last so its peeking
                    // ball draws over any neighbouring bush.
                    for (final i in [
                      for (var k = 1; k < _cells.length; k++) k,
                      0,
                    ])
                      Positioned(
                        left: (_cells[i] % _gridColumns) * cellWidth,
                        top: (_cells[i] ~/ _gridColumns) * cellHeight,
                        width: cellWidth,
                        height: cellHeight,
                        child: Center(
                          child: i == 0
                              ? OverflowBox(
                                  maxWidth: 140,
                                  maxHeight: 100,
                                  child: _ballBush(),
                                )
                              : _decoyBush(i - 1),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _bush() => const PlayArt(
    name: 'bush',
    placeholder: BushPainter(),
    width: 92,
    height: 84,
  );

  Widget _decoyBush(int i) => Wiggle(
    trigger: _wiggleDecoy == i ? _wiggleTick : 0,
    child: GestureDetector(
      key: Key('placement_decoy_$i'),
      behavior: HitTestBehavior.opaque,
      onTap: () => _onDecoyTap(i),
      child: _bush(),
    ),
  );

  // The ball rests half-tucked behind its bush with a slice showing on the
  // right, so a child can spot it. Tapping the bush lifts the bush away and
  // rolls the ball out into view — positions animate, sizes never do.
  Widget _ballBush() => GestureDetector(
    key: const Key('placement_ball'),
    behavior: HitTestBehavior.opaque,
    onTap: _onBallTap,
    child: SizedBox(
      width: 140,
      height: 100,
      child: Stack(
        alignment: Alignment.bottomLeft,
        clipBehavior: Clip.none,
        children: [
          if (_hintShown && !_found)
            Positioned(
              left: 62,
              bottom: 6,
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: .5),
                      blurRadius: 20,
                      spreadRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOutBack,
            left: _found ? 43 : 86,
            bottom: 4,
            child: const PlayArt(
              name: 'ball',
              placeholder: BallPainter(),
              width: 54,
              height: 54,
            ),
          ),
          Positioned(
            left: 24,
            bottom: 0,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOut,
              offset: _found ? const Offset(0, -1) : Offset.zero,
              child: _bush(),
            ),
          ),
        ],
      ),
    ),
  );
}
