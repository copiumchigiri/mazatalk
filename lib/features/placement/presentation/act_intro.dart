import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/maza_speech_bubble.dart';
import '../domain/playground_acts.dart';

/// The card between acts: which stop of the trip we're at, Maza's line
/// (spoken), and one big play button. Nothing advances on its own — the
/// child taps when ready.
class ActIntro extends StatelessWidget {
  final PlaygroundAct act;
  final VoidCallback onGo;

  const ActIntro({super.key, required this.act, required this.onGo});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        Text(
          act.title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          act.place,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 34,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 32),
        MazaSpeechBubble(text: act.line),
        const Spacer(),
        Center(
          child: GestureDetector(
            key: const Key('act_intro_go'),
            onTap: onGo,
            child: Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
                boxShadow: [
                  BoxShadow(color: Color(0xFF0093A4), offset: Offset(0, 6)),
                ],
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 60,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Явцгаая!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}
