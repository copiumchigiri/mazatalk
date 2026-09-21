import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/widgets/maza_speech_bubble.dart';
import '../../application/playground_session_controller.dart';
import '../../domain/placement_result.dart';
import '../playground_level_timeout_mixin.dart';

const _objects = ['⚽', '🎈', '🌟'];

enum _Phase { demo, input, celebrate }

/// Level 10 — Copy the Pattern (PROJECT_V4.md §6): the playground's closing
/// flourish and a core placement input (sequencing, Unit 1 Lesson 6/7
/// territory). Maza taps 3 objects in order, the child repeats it; one
/// retry (a second demo) is allowed on a mismatch before scoring.
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
    with PlaygroundLevelTimeoutMixin {
  late final List<int> _pattern; // indices into _objects, tap order
  _Phase _phase = _Phase.demo;
  int? _demoHighlight;
  int _inputProgress = 0;
  bool _usedRetry = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    final rng = Random(widget.seed ^ 'copy_the_pattern'.hashCode);
    _pattern = List.generate(_objects.length, (i) => i)..shuffle(rng);
    startLevelTimeout(kPlaygroundExtendedLevelTimeout, () => _finish(2, timedOut: true));
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

  void _finish(int points, {bool timedOut = false}) {
    if (_done) return;
    _done = true;
    cancelLevelTimeout();
    setState(() => _phase = _Phase.celebrate);
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      widget.onComplete(PlaygroundLevelOutcome(points, timedOut: timedOut));
    });
  }

  @override
  Widget build(BuildContext context) {
    final promptText = switch (_phase) {
      _Phase.demo => 'Watch Maza!',
      _Phase.input => 'Now you try!',
      _Phase.celebrate => 'You did it!',
    };
    return Column(
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
                      for (var i = 0; i < _objects.length; i++) ...[
                        if (i > 0) const SizedBox(width: 20),
                        _ObjectTile(
                          key: Key('pattern_tile_$i'),
                          emoji: _objects[i],
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
    );
  }
}

class _ObjectTile extends StatelessWidget {
  final String emoji;
  final bool highlighted;
  final bool enabled;
  final VoidCallback onTap;

  const _ObjectTile({
    super.key,
    required this.emoji,
    required this.highlighted,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 84,
        height: 84,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: highlighted ? Colors.black : Colors.white,
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: Center(
          child: Text(emoji, style: const TextStyle(fontSize: 40)),
        ),
      ),
    );
  }
}

class _Celebration extends StatelessWidget {
  const _Celebration();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.4, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.elasticOut,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: const Text('🎉⭐🎉', style: TextStyle(fontSize: 56)),
    );
  }
}
