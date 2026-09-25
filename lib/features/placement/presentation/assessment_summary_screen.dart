import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/maza_speech_bubble.dart';
import '../../profile/application/child_controller.dart';
import '../application/playground_session_controller.dart';
import '../domain/peer_benchmark.dart';
import 'placement_scaffold.dart';

/// The screen every test round lands on instead of the Duolingo-style path
/// home screen: current scores + a peer-comparison tracker, with a single
/// button that starts the next round of tests. There is no persistent home
/// screen in this flow — this *is* the home screen.
class AssessmentSummaryScreen extends ConsumerWidget {
  const AssessmentSummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final child = ref.watch(childControllerProvider).selectedChild;

    if (child == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return PlacementScaffold(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MazaSpeechBubble(
            text: '${child.name}, сайн байна! Эндээс явцыг чинь харцгаая.',
            spokenText: 'Сайн байна! Эндээс явцыг чинь харцгаая.',
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView(
              children: [
                if (child.placementCoreScore != null)
                  _TrackerRow(
                    label: 'Ерөнхий оноо',
                    score: child.placementCoreScore!,
                    maxScore: 100,
                    age: child.age,
                  ),
                if (child.verbalComfort != null)
                  _TrackerRow(
                    label: 'Ярианы тав тух',
                    score: child.verbalComfort!,
                    maxScore: 10,
                    age: child.age,
                  ),
                if (child.shapeAwareness != null)
                  _TrackerRow(
                    label: 'Дүрс танилт',
                    score: child.shapeAwareness!,
                    maxScore: 10,
                    age: child.age,
                  ),
                if (child.emotionAwareness != null)
                  _TrackerRow(
                    label: 'Мэдрэмж танилт',
                    score: child.emotionAwareness!,
                    maxScore: 10,
                    age: child.age,
                  ),
              ],
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                ref.invalidate(playgroundSessionControllerProvider);
                context.push('/playground');
              },
              child: const Text(
                'Дараагийн шалгалт руу ▶',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackerRow extends StatelessWidget {
  final String label;
  final int score;
  final int maxScore;
  final int age;

  const _TrackerRow({
    required this.label,
    required this.score,
    required this.maxScore,
    required this.age,
  });

  @override
  Widget build(BuildContext context) {
    final normalized = score / maxScore * 10;
    final percentile = PeerBenchmark.percentile(score: normalized, age: age);
    final fraction = (score / maxScore).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              Text(
                '$score / $maxScore',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 14,
              backgroundColor: AppColors.borderSubtle,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Ижил насныхаас $percentile%-иас илүү гүйцэтгэлтэй',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
