import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/speech_input_service.dart';
import '../../../../core/widgets/maza_speech_bubble.dart';
import '../../domain/placement_result.dart';
import '../../../../core/theme/app_colors.dart';
import '../art/play_feedback.dart';
import '../gentle_glow.dart';

/// Level 2 — Repeat After Me (PROJECT_V4.md §6, §9): the app's most
/// important accessibility rule lives here. Speech is diagnostic only —
/// this level always completes once the child taps the mic, whether they
/// speak, make any sound, or stay silent. Nothing here is ever shown as
/// "wrong"; every outcome gets the same praise. There is no timeout — the
/// mic just waits, gently pulsing, until it's tapped.
class RepeatAfterMeLevel extends ConsumerStatefulWidget {
  final PlaygroundLevelComplete onComplete;
  final String targetWord;

  const RepeatAfterMeLevel({
    super.key,
    required this.onComplete,
    this.targetWord = 'бөмбөг',
  });

  @override
  ConsumerState<RepeatAfterMeLevel> createState() => _RepeatAfterMeLevelState();
}

enum _MicState { idle, listening }

class _RepeatAfterMeLevelState extends ConsumerState<RepeatAfterMeLevel>
    with PlayFeedbackMixin {
  _MicState _micState = _MicState.idle;
  bool _done = false;

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

  void _finish(int points) {
    if (_done) return;
    _done = true;
    cheer();
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
          MazaSpeechBubble(text: "'${widget.targetWord}' гэж хэлээрэй!"),
          const SizedBox(height: 16),
          Expanded(
            child: Center(
              child: GentleGlow(
                child: GestureDetector(
                  onTap: _onMicTap,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _micState == _MicState.listening
                          ? AppColors.primary
                          : Colors.white,
                      border: Border.all(color: AppColors.primary, width: 3),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.primaryLight,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.mic,
                        size: 56,
                        color: _micState == _MicState.listening
                            ? Colors.white
                            : AppColors.primary,
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
              _micState == _MicState.listening
                  ? 'Би чагнаж байна...'
                  : 'Микрофон дээр дар!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
