import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/widgets/maza_speech_bubble.dart';
import '../../application/playground_session_controller.dart';
import '../../domain/placement_result.dart';
import '../playground_level_timeout_mixin.dart';

const _decoyEmoji = ['🌳', '🧒', '🛝', '🐦', '🎈', '🌸', '🪁', '☁️', '🦋'];
const _gridColumns = 3;
const _gridRows = 4;

/// Level 1 — Find the Ball (PROJECT_V4.md §6): a Where's-Waldo-style scan.
/// One ⚽ hidden among scattered decoy emoji; tap it to advance. Misses are
/// silent (a small dim, never red) and a soft hint appears after two misses
/// or 6 seconds of no input — this level never blocks, it only hints.
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
    with PlaygroundLevelTimeoutMixin {
  late final List<int> _cellOrder;
  int _missCount = 0;
  bool _hintShown = false;
  bool _done = false;
  Timer? _hintTimer;

  @override
  void initState() {
    super.initState();
    final rng = Random(widget.seed ^ PlaygroundLevelId.findTheBall.hashCode);
    _cellOrder = List.generate(_gridColumns * _gridRows, (i) => i)
      ..shuffle(rng);
    startLevelTimeout(kPlaygroundDefaultLevelTimeout, () => _finish(2, timedOut: true));
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

  void _onDecoyTap() {
    if (_done) return;
    setState(() {
      _missCount++;
      if (_missCount >= 2) _hintShown = true;
    });
  }

  void _onBallTap() {
    if (_done) return;
    cancelLevelTimeout();
    _hintTimer?.cancel();
    _finish(_hintShown ? 6 : 10);
  }

  void _finish(int points, {bool timedOut = false}) {
    if (_done) return;
    _done = true;
    cancelLevelTimeout();
    _hintTimer?.cancel();
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
        const MazaSpeechBubble(text: 'Look around... find the ball!'),
        const SizedBox(height: 16),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cellWidth = constraints.maxWidth / _gridColumns;
              final cellHeight = constraints.maxHeight / _gridRows;
              // Decoys fill every cell except the ball's; extras are dropped
              // if the emoji list is longer than the remaining cells.
              final decoyCells = _cellOrder.skip(1).toList();
              return Stack(
                children: [
                  for (var i = 0;
                      i < decoyCells.length && i < _decoyEmoji.length;
                      i++)
                    _positionedTile(
                      decoyCells[i],
                      cellWidth,
                      cellHeight,
                      GestureDetector(
                        key: Key('placement_decoy_$i'),
                        onTap: _onDecoyTap,
                        child: Text(_decoyEmoji[i],
                            style: const TextStyle(fontSize: 32)),
                      ),
                    ),
                  _positionedTile(
                    _cellOrder.first,
                    cellWidth,
                    cellHeight,
                    GestureDetector(
                      key: const Key('placement_ball'),
                      onTap: _onBallTap,
                      child: Container(
                        decoration: _hintShown
                            ? BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.25),
                                    blurRadius: 18,
                                    spreadRadius: 6,
                                  ),
                                ],
                              )
                            : null,
                        child: const Text('⚽', style: TextStyle(fontSize: 36)),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _positionedTile(
      int cellIndex, double cellWidth, double cellHeight, Widget child) {
    final row = cellIndex ~/ _gridColumns;
    final col = cellIndex % _gridColumns;
    return Positioned(
      left: col * cellWidth,
      top: row * cellHeight,
      width: cellWidth,
      height: cellHeight,
      child: Center(child: child),
    );
  }
}
