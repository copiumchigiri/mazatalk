import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/widgets/maza_speech_bubble.dart';
import '../../application/playground_session_controller.dart';
import '../../domain/placement_result.dart';
import '../playground_level_timeout_mixin.dart';

const _animals = ['🐶', '🐱', '🐰'];

/// Level 9 — Memory Match (PROJECT_V4.md §6): a 3-pair working-memory probe.
/// Feeds the supplementary `readyForMultiStep` signal only — V3's own rule
/// that Unit 1 never uses `matchPairs`/`sequence` activities is unchanged
/// by this result (PROJECT_V3.md §5); it's recorded for future
/// personalization, not acted on in V4. No red on a mismatch — tiles just
/// flip back.
class MemoryMatchLevel extends StatefulWidget {
  final int seed;
  final PlaygroundLevelComplete onComplete;

  const MemoryMatchLevel({
    super.key,
    required this.seed,
    required this.onComplete,
  });

  @override
  State<MemoryMatchLevel> createState() => _MemoryMatchLevelState();
}

class _MemoryMatchLevelState extends State<MemoryMatchLevel>
    with PlaygroundLevelTimeoutMixin {
  late final List<String> _tiles;
  final List<bool> _revealed = List.filled(6, false);
  final List<bool> _matched = List.filled(6, false);
  int? _firstIndex;
  bool _busy = false;
  bool _done = false;

  int get _matchedPairs => _matched.where((m) => m).length ~/ 2;

  @override
  void initState() {
    super.initState();
    final rng = Random(widget.seed ^ 'memory_match'.hashCode);
    _tiles = [..._animals, ..._animals]..shuffle(rng);
    startLevelTimeout(kPlaygroundExtendedLevelTimeout, () => _finish(timedOut: true));
  }

  void _onTap(int index) {
    if (_done || _busy || _revealed[index] || _matched[index]) return;

    setState(() => _revealed[index] = true);

    if (_firstIndex == null) {
      _firstIndex = index;
      return;
    }

    final first = _firstIndex!;
    _firstIndex = null;

    if (_tiles[first] == _tiles[index]) {
      setState(() {
        _matched[first] = true;
        _matched[index] = true;
      });
      if (_matchedPairs == _animals.length) {
        _finish();
      }
      return;
    }

    _busy = true;
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() {
        _revealed[first] = false;
        _revealed[index] = false;
        _busy = false;
      });
    });
  }

  void _finish({bool timedOut = false}) {
    if (_done) return;
    _done = true;
    cancelLevelTimeout();
    final pairs = _matchedPairs;
    final points = ((pairs / _animals.length) * 10).round();
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      widget.onComplete(PlaygroundLevelOutcome(
        points,
        timedOut: timedOut,
        payload: pairs >= 2,
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MazaSpeechBubble(text: 'Find the matching friends!'),
        const SizedBox(height: 16),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemCount: _tiles.length,
            itemBuilder: (context, index) {
              final faceUp = _revealed[index] || _matched[index];
              return Material(
                color: _matched[index] ? Colors.green.shade200 : Colors.white,
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    color: _matched[index] ? Colors.green.shade700 : Colors.black,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: InkWell(
                  key: Key('memory_tile_$index'),
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _onTap(index),
                  child: Center(
                    child: Text(
                      faceUp ? _tiles[index] : '❓',
                      style: const TextStyle(fontSize: 30),
                    ),
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
