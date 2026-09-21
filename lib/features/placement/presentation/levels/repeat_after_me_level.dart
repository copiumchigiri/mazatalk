import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/speech_input_service.dart';
import '../../../../core/widgets/maza_speech_bubble.dart';
import '../../application/playground_session_controller.dart';
import '../../domain/placement_result.dart';
import '../playground_level_timeout_mixin.dart';

/// Level 2 — Repeat After Me (PROJECT_V4.md §6, §9): the app's most
/// important accessibility rule lives here. Speech is diagnostic only —
/// this level always completes, whether the child speaks, makes any sound,
/// stays silent, or never taps the mic at all. Nothing here is ever shown
/// as "wrong"; every outcome gets the same praise.
class RepeatAfterMeLevel extends ConsumerStatefulWidget {
  final PlaygroundLevelComplete onComplete;
  final String targetWord;

  const RepeatAfterMeLevel({
    super.key,
    required this.onComplete,
    this.targetWord = 'ball',
  });

  @override
  ConsumerState<RepeatAfterMeLevel> createState() =>
      _RepeatAfterMeLevelState();
}

enum _MicState { idle, listening }

class _RepeatAfterMeLevelState extends ConsumerState<RepeatAfterMeLevel>
    with PlaygroundLevelTimeoutMixin {
  _MicState _micState = _MicState.idle;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    // Never tapped the mic at all by the time this fires: still a valid,
    // non-shamed outcome (PROJECT_V4.md §6 Level 2).
    startLevelTimeout(kPlaygroundDefaultLevelTimeout, () => _finish(3, timedOut: true));
  }

  Future<void> _onMicTap() async {
    if (_done || _micState == _MicState.listening) return;
    setState(() => _micState = _MicState.listening);
    final attempt = await ref
        .read(speechInputServiceProvider)
        .listenFor(widget.targetWord, timeout: const Duration(seconds: 4));
    if (!mounted) return;
    final points = switch (attempt.result) {
      SpeechAttemptResult.matched => 10,
      SpeechAttemptResult.vocalized => 6,
      SpeechAttemptResult.silent => 4,
      SpeechAttemptResult.unavailable => 4,
    };
    _finish(points);
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
        MazaSpeechBubble(text: "Say '${widget.targetWord}'!"),
        const SizedBox(height: 16),
        Expanded(
          child: Center(
            child: GestureDetector(
              onTap: _onMicTap,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _micState == _MicState.listening
                      ? Colors.black
                      : Colors.white,
                  border: Border.all(color: Colors.black, width: 3),
                ),
                child: Center(
                  child: Text(
                    '🎤',
                    style: TextStyle(
                      fontSize: 56,
                      color: _micState == _MicState.listening
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(
          height: 22,
          child: Text(
            _micState == _MicState.listening ? "I'm listening..." : 'Tap the mic!',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
