import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/tts_service.dart';

/// Maza (the bear mascot) narrating one short line: spoken aloud via TTS
/// and shown in a speech bubble. Shared across the placement playground
/// (PROJECT_V4.md §4) — every level hosts its prompt through this widget so
/// pre-readers never have to read UI on their own.
class MazaSpeechBubble extends ConsumerStatefulWidget {
  /// Shown on screen. Kept short (playground copy is written for
  /// listening, not reading).
  final String text;

  /// What TTS speaks; null means speak [text].
  final String? spokenText;

  /// Speak automatically when this text first appears / changes.
  final bool autoSpeak;

  const MazaSpeechBubble({
    super.key,
    required this.text,
    this.spokenText,
    this.autoSpeak = true,
  });

  @override
  ConsumerState<MazaSpeechBubble> createState() => _MazaSpeechBubbleState();
}

class _MazaSpeechBubbleState extends ConsumerState<MazaSpeechBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bobController;
  late final Animation<double> _bobAnimation;

  @override
  void initState() {
    super.initState();
    // A one-shot bob per spoken line, not an infinite loop: besides being
    // less visually distracting, an unbounded repeating animation makes
    // `tester.pumpAndSettle()` hang forever on any screen holding this
    // widget — every playground level does — so tests would be forced to
    // avoid the most common pump helper everywhere Maza talks.
    _bobController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _bobAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -8.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _bobController, curve: Curves.easeInOut));
    if (widget.autoSpeak) _speak();
  }

  @override
  void didUpdateWidget(covariant MazaSpeechBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.autoSpeak && widget.text != oldWidget.text) _speak();
  }

  @override
  void dispose() {
    _bobController.dispose();
    super.dispose();
  }

  void _speak() {
    ref.read(ttsServiceProvider).speak(widget.spokenText ?? widget.text);
    _bobController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: _bobAnimation,
          builder: (context, child) => Transform.translate(
            offset: Offset(0, _bobAnimation.value),
            child: child,
          ),
          child: const _MazaAvatar(),
        ),
        const SizedBox(width: 4),
        Expanded(child: _Bubble(text: widget.text, onReplay: _speak)),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  final String text;
  final VoidCallback onReplay;
  const _Bubble({required this.text, required this.onReplay});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.only(left: 20, right: 4, top: 10, bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.black, width: 2),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  text,
                  style:
                      const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.volume_up, color: Colors.black),
                tooltip: 'Hear it again',
                onPressed: onReplay,
              ),
            ],
          ),
        ),
        // Small tail pointing back toward Maza.
        Positioned(
          left: -6,
          top: 22,
          child: Transform.rotate(
            angle: 0.78539816339, // 45deg
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black, width: 2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MazaAvatar extends StatelessWidget {
  const _MazaAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: const Center(child: Text('🐻', style: TextStyle(fontSize: 32))),
    );
  }
}
