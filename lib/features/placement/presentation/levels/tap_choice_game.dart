import 'package:flutter/material.dart';
import '../../domain/placement_result.dart';
import '../playground_level_timeout_mixin.dart';

/// Shared tap-one-of-N mechanic behind Levels 3, 4, 5 and 6 (Tap the Color,
/// Count the Friends, Find the Letter, Match the Shape — PROJECT_V4.md §6):
/// tap the right tile, first try scores 10, a miss-then-correct scores 6,
/// the level timeout scores 2 (a floor low enough that an entirely
/// non-responsive session can still land in the lowest placement bucket —
/// PROJECT_V4.md §7.2's "0–20 → Lesson 1" is otherwise unreachable).
/// **No red anywhere** (PROJECT_V4.md §9) — a
/// wrong tap only dims briefly, never turns red or says "wrong"; the
/// correct tile lights green whether the child found it or the timeout
/// revealed it.
class TapChoiceGame extends StatefulWidget {
  final List<String> choices;
  final int correctIndex;
  final PlaygroundLevelComplete onComplete;
  final Duration timeout;

  const TapChoiceGame({
    super.key,
    required this.choices,
    required this.correctIndex,
    required this.onComplete,
    this.timeout = const Duration(seconds: 12),
  });

  @override
  State<TapChoiceGame> createState() => _TapChoiceGameState();
}

class _TapChoiceGameState extends State<TapChoiceGame>
    with PlaygroundLevelTimeoutMixin {
  int _missCount = 0;
  int? _flashIndex;
  int? _revealCorrectIndex;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    startLevelTimeout(widget.timeout, () => _finish(2, timedOut: true));
  }

  void _onTap(int index) {
    if (_done) return;
    if (index == widget.correctIndex) {
      cancelLevelTimeout();
      _finish(_missCount == 0 ? 10 : 6);
      return;
    }
    setState(() {
      _missCount++;
      _flashIndex = index;
    });
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _flashIndex = null);
    });
  }

  void _finish(int points, {bool timedOut = false}) {
    if (_done) return;
    _done = true;
    cancelLevelTimeout();
    setState(() => _revealCorrectIndex = widget.correctIndex);
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      widget.onComplete(PlaygroundLevelOutcome(points, timedOut: timedOut));
    });
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.3,
      ),
      itemCount: widget.choices.length,
      itemBuilder: (context, index) => _Tile(
        label: widget.choices[index],
        highlighted: _revealCorrectIndex == index,
        dimmed: _flashIndex == index,
        onTap: () => _onTap(index),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final String label;
  final bool highlighted;
  final bool dimmed;
  final VoidCallback onTap;

  const _Tile({
    required this.label,
    required this.highlighted,
    required this.dimmed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final background = highlighted
        ? Colors.green.shade200
        : (dimmed ? Colors.grey.shade300 : Colors.white);
    final border = highlighted ? Colors.green.shade700 : Colors.black;
    return Material(
      color: background,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: border, width: 2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Center(
          child: Text(
            label,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
