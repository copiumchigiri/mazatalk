import 'package:flutter/material.dart';

/// Plain, centered, emoji-only celebration shown when a lesson's queue
/// (including requeued mistakes) is finished.
class LessonCompleteScreen extends StatelessWidget {
  final String lessonTitle;
  final int xpEarned;
  final int coinsEarned;
  final int accuracyCorrect;
  final int accuracyTotal;
  final int streak;
  final VoidCallback onContinue;

  const LessonCompleteScreen({
    super.key,
    required this.lessonTitle,
    required this.xpEarned,
    required this.coinsEarned,
    required this.accuracyCorrect,
    required this.accuracyTotal,
    this.streak = 0,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              Text(
                '$lessonTitle дууслаа!',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                '⚡ +$xpEarned XP${coinsEarned > 0 ? '    🪙 +$coinsEarned' : ''}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Оновчтой байдал: $accuracyCorrect/$accuracyTotal',
                style: const TextStyle(fontSize: 15, color: Colors.grey),
              ),
              if (streak > 0) ...[
                const SizedBox(height: 8),
                Text(
                  '🔥 Тасралтгүй: $streak өдөр',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: onContinue,
                  child: const Text(
                    'ҮРГЭЛЖЛҮҮЛЭХ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
