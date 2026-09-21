import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/maza_speech_bubble.dart';
import '../../profile/application/child_controller.dart';
import '../../profile/domain/child_profile.dart';
import '../../profile/domain/interest.dart';
import '../application/playground_session_controller.dart';
import '../domain/placement_result.dart';

/// The beat between "parent is holding the phone" and "child is holding
/// the phone" (PROJECT_V4.md §3) — skipping this, a child's Level 1 starts
/// before they're even looking at the screen.
class HandoffScreen extends ConsumerWidget {
  final String name;
  final int age;

  const HandoffScreen({super.key, required this.name, required this.age});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            children: [
              const Spacer(),
              MazaSpeechBubble(
                text:
                    'Time to play, $name! Give the phone to $name — Maza has some fun games! 🎈',
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    // A safety-net reset: harmless (the provider is already
                    // fresh here) unless this handoff is a retry after an
                    // earlier attempt was backed out of mid-playground.
                    ref.invalidate(playgroundSessionControllerProvider);
                    context.push('/playground',
                        extra: {'name': name, 'age': age});
                  },
                  child: const Text("We're ready! ▶",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => _skip(context, ref),
                child: const Text(
                  'Skip playing, start at Lesson 1 (parent)',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The handoff screen's escape hatch (PROJECT_V4.md §3, §9): a real,
  /// full-size link, no confirmation nag — a parent in a hurry or a child
  /// who's overwhelmed by a new screen gets the same default course V3
  /// already ships. Interests are still backfilled at random so theming
  /// has something to cycle through.
  Future<void> _skip(BuildContext context, WidgetRef ref) async {
    final backfilled = [...Interest.values]..shuffle();
    final result = PlacementResult.skipped(
      interestIds: backfilled.take(3).map((i) => i.id).toList(),
    );
    await ref.read(childControllerProvider.notifier).addChild(
          ChildProfile(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: name,
            age: age,
            interestIds: result.interestIds,
            completedLessonIds: result.placedLessonIds,
            placedLessonIds: result.placedLessonIds,
            placementCompleted: true,
            placementCoreScore: result.coreScore,
          ),
        );
    if (!context.mounted) return;
    context.go('/home');
  }
}
