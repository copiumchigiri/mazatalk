import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/speech_input_service.dart';
import '../../../core/services/tts_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/maza_speech_bubble.dart';
import '../../placement/presentation/art/play_feedback.dart';
import '../../placement/presentation/duo_progress_bar.dart';
import '../../placement/presentation/gentle_glow.dart';
import '../domain/letter_glyph.dart';
import 'letter_trace_canvas.dart';

enum _Step { see, say, trace, complete }

const _ink = Color(0xFF1F3552);

/// How a lesson on a letter opens: see it, say it, trace it stroke by stroke,
/// celebrate. Nothing is ever marked wrong — leaving the path just brings a
/// gentle "step back onto the path" from Maza — and the mic step can always
/// be skipped. [onDone] fires when the child taps continue on the last step.
class LetterIntroFlow extends ConsumerStatefulWidget {
  final LetterGlyph glyph;
  final VoidCallback onDone;
  final VoidCallback onExit;

  const LetterIntroFlow({
    super.key,
    required this.glyph,
    required this.onDone,
    required this.onExit,
  });

  @override
  ConsumerState<LetterIntroFlow> createState() => _LetterIntroFlowState();
}

class _LetterIntroFlowState extends ConsumerState<LetterIntroFlow>
    with PlayFeedbackMixin {
  _Step _step = _Step.see;
  int _strokesDone = 0;
  bool _strokeStarted = false;
  bool _offPath = false;
  bool _listening = false;

  LetterGlyph get _glyph => widget.glyph;

  /// 1-based step shown as "n/total".
  int get _stepNumber => switch (_step) {
    _Step.see => 1,
    _Step.say => 2,
    _Step.trace => 3 + _strokesDone.clamp(0, _glyph.strokes.length - 1),
    _Step.complete => _glyph.totalSteps,
  };

  String get _bubbleText {
    final l = _glyph.letter;
    switch (_step) {
      case _Step.see:
        return 'Энэ бол $l.';
      case _Step.say:
        return '${_glyph.sound}... гэж хэлээд үзье!';
      case _Step.trace:
        if (_offPath) return 'Зүгээр ээ! Дахин оролдоод үзье.';
        if (_strokesDone > 0 && !_strokeStarted) {
          return 'Маш сайн! Одоо дараагийн зураасаа зурья!';
        }
        return 'Одоо хамтдаа $l үсгийг зурья!';
      case _Step.complete:
        return 'Гайхалтай! Чи $l үсгийг зурлаа!';
    }
  }

  void _speakName() => ref.read(ttsServiceProvider).speak(_glyph.spokenName);

  Future<void> _onMic() async {
    if (_listening) return;
    setState(() => _listening = true);
    await ref
        .read(speechInputServiceProvider)
        .listenFor(_glyph.letter.toLowerCase());
    if (!mounted) return;
    // Speech is diagnostic only: any outcome moves on with the same praise.
    setState(() {
      _listening = false;
      _step = _Step.trace;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 20, 8),
              child: Row(
                children: [
                  IconButton(
                    key: const Key('letter_back'),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppColors.primary,
                      size: 28,
                    ),
                    onPressed: widget.onExit,
                  ),
                  Expanded(
                    child: DuoProgressBar(
                      value: _stepNumber / _glyph.totalSteps,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '$_stepNumber/${_glyph.totalSteps}',
                    key: const Key('letter_step_count'),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: MazaSpeechBubble(text: _bubbleText),
            ),
            Expanded(
              child: withCheer(
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _center(),
                ),
              ),
            ),
            SizedBox(
              height: 104,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                child: _bottom(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _speaker() => Container(
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white,
      border: Border.all(color: AppColors.primaryLight, width: 2),
      boxShadow: const [
        BoxShadow(color: AppColors.primaryLight, offset: Offset(0, 3)),
      ],
    ),
    child: IconButton(
      key: const Key('letter_speaker'),
      tooltip: 'Дахин сонсох',
      icon: const Icon(Icons.volume_up_rounded, color: AppColors.primary),
      onPressed: _speakName,
    ),
  );

  Widget _center() {
    switch (_step) {
      case _Step.see:
      case _Step.complete:
        final complete = _step == _Step.complete;
        return Column(
          children: [
            const SizedBox(height: 12),
            Expanded(
              child: GlyphView(
                glyph: _glyph,
                color: complete ? AppColors.primary : _ink,
              ),
            ),
            const SizedBox(height: 12),
            _speaker(),
            const SizedBox(height: 10),
            SizedBox(
              height: 44,
              child: Text(
                complete ? 'Одоо дахиад ${_glyph.sound} гэж хэлээд үзье!' : '',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        );
      case _Step.say:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GentleGlow(
              child: GestureDetector(
                key: const Key('letter_mic'),
                onTap: _onMic,
                child: Container(
                  width: 132,
                  height: 132,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary,
                    border: Border.all(color: AppColors.primaryLight, width: 8),
                  ),
                  child: const Icon(Icons.mic, color: Colors.white, size: 60),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              _listening
                  ? 'Би чагнаж байна...'
                  : 'Дарж, ${_glyph.sound} гэж хэлээрэй.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        );
      case _Step.trace:
        return LetterTraceCanvas(
          key: const Key('trace_canvas'),
          glyph: _glyph,
          onStrokeStarted: () => setState(() => _strokeStarted = true),
          onStrokeDone: (i) => setState(() {
            _strokesDone = i + 1;
            _strokeStarted = false;
            _offPath = false;
            cheerTrigger++; // stars only — Maza's line speaks the praise
          }),
          onOffPath: (off) => setState(() => _offPath = off),
          onAllDone: () =>
              Future.delayed(const Duration(milliseconds: 900), () {
                if (mounted) setState(() => _step = _Step.complete);
              }),
        );
    }
  }

  Widget _bottom() {
    switch (_step) {
      case _Step.see:
        return _bigButton(
          key: const Key('letter_next'),
          label: 'Дараах',
          onTap: () => setState(() => _step = _Step.say),
        );
      case _Step.say:
        return Align(
          alignment: Alignment.topCenter,
          child: TextButton(
            key: const Key('letter_skip'),
            onPressed: () => setState(() => _step = _Step.trace),
            child: const Text('Алгасах', style: TextStyle(fontSize: 18)),
          ),
        );
      case _Step.trace:
        final hint = _offPath
            ? 'Зөв зам руу буцаад орвол үргэлжлүүлж болно.'
            : (_strokeStarted || _strokesDone > 0
                  ? ''
                  : 'Дээрх цэгээс эхлээрэй.');
        return Center(
          child: Text(
            hint,
            key: const Key('trace_hint'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        );
      case _Step.complete:
        return _bigButton(
          key: const Key('letter_continue'),
          label: 'Үргэлжлүүлэх',
          onTap: widget.onDone,
        );
    }
  }

  Widget _bigButton({
    required Key key,
    required String label,
    required VoidCallback onTap,
  }) => Align(
    alignment: Alignment.topCenter,
    child: SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        key: key,
        onPressed: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: const TextStyle(fontSize: 17)),
            const SizedBox(width: 10),
            const Icon(Icons.arrow_forward, size: 22),
          ],
        ),
      ),
    ),
  );
}
