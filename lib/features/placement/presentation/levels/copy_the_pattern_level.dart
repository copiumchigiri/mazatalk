import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/widgets/maza_speech_bubble.dart';
import '../../domain/placement_result.dart';
import '../../../../core/theme/app_colors.dart';
import '../art/play_feedback.dart';
import '../play_tile.dart';

// Three drum pads: cyan, pink and sun-yellow.
const _padColors = [AppColors.primary, AppColors.secondary, Color(0xFFFFC800)];

enum _Phase { demo, input, celebrate }

/// Level 10 — Copy the Pattern (PROJECT_V4.md §6): the playground's closing
/// flourish and a core placement input (sequencing, Unit 1 Lesson 6/7
/// territory). Maza taps 3 objects in order, the child repeats it; one
/// retry (a second demo) is allowed on a mismatch before scoring. There is
/// no timeout — the level waits indefinitely for the child's input.
class CopyThePatternLevel extends StatefulWidget {
  final int seed;
  final PlaygroundLevelComplete onComplete;

  const CopyThePatternLevel({
    super.key,
    required this.seed,
    required this.onComplete,
  });

  @override
  State<CopyThePatternLevel> createState() => _CopyThePatternLevelState();
}

class _CopyThePatternLevelState extends State<CopyThePatternLevel>
    with PlayFeedbackMixin {
  late final List<int> _pattern; // indices into _objectIcons, tap order
  _Phase _phase = _Phase.demo;
  int? _demoHighlight;
  int _inputProgress = 0;
  bool _usedRetry = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    final rng = Random(widget.seed ^ 'copy_the_pattern'.hashCode);
    _pattern = List.generate(_padColors.length, (i) => i)..shuffle(rng);
    _runDemo();
  }

  Future<void> _runDemo() async {
    if (!mounted || _done) return;
    setState(() {
      _phase = _Phase.demo;
      _inputProgress = 0;
    });
    for (final index in _pattern) {
      if (!mounted || _done) return;
      setState(() => _demoHighlight = index);
      await Future.delayed(const Duration(milliseconds: 550));
      if (!mounted || _done) return;
      setState(() => _demoHighlight = null);
      await Future.delayed(const Duration(milliseconds: 200));
    }
    if (!mounted || _done) return;
    setState(() => _phase = _Phase.input);
  }

  void _onTap(int index) {
    if (_done || _phase != _Phase.input) return;
    if (index == _pattern[_inputProgress]) {
      setState(() => _inputProgress++);
      if (_inputProgress == _pattern.length) {
        _finish(_usedRetry ? 6 : 10);
      }
      return;
    }
    if (_usedRetry) {
      _finish(2);
      return;
    }
    _usedRetry = true;
    _runDemo();
  }

  void _finish(int points) {
    if (_done) return;
    _done = true;
    setState(() => _phase = _Phase.celebrate);
    cheer();
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      // Repeating the 3-step pattern, even on the retry, is the
      // `readyForMultiStep` signal (this level replaced Memory Match there).
      widget.onComplete(PlaygroundLevelOutcome(points, payload: points >= 6));
    });
  }

  @override
  Widget build(BuildContext context) {
    final promptText = switch (_phase) {
      _Phase.demo => 'Мазаг ажиглаарай!',
      _Phase.input => 'Одоо чи оролдоорой!',
      _Phase.celebrate => 'Чи чадлаа!',
    };
    return withCheer(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MazaSpeechBubble(text: promptText),
          const SizedBox(height: 32),
          Expanded(
            child: Center(
              child: _phase == _Phase.celebrate
                  ? const _Celebration()
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < _padColors.length; i++) ...[
                          if (i > 0) const SizedBox(width: 20),
                          _ObjectTile(
                            key: Key('pattern_tile_$i'),
                            color: _padColors[i],
                            highlighted: _demoHighlight == i,
                            enabled: _phase == _Phase.input,
                            onTap: () => _onTap(i),
                          ),
                        ],
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ObjectTile extends StatelessWidget {
  final Color color;
  final bool highlighted;
  final bool enabled;
  final VoidCallback onTap;

  const _ObjectTile({
    super.key,
    required this.color,
    required this.highlighted,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 84,
      height: 84,
      child: PlayTile(
        circle: true,
        state: highlighted ? PlayTileState.selected : PlayTileState.normal,
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: highlighted ? 1 : .6),
          ),
        ),
      ),
    );
  }
}

class _Celebration extends StatelessWidget {
  const _Celebration();

  @override
  Widget build(BuildContext context) =>
      const Icon(Icons.celebration, size: 56, color: AppColors.primary);
}
