import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Shown once a child finishes the final lesson of the course. Finished
/// lessons stay replayable from the path for practice.
class CourseCompleteScreen extends StatelessWidget {
  const CourseCompleteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🏆', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              const Text(
                "You've finished every adventure!",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Replay any lesson to practice — more adventures are on the way.',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => context.go('/skins'),
                  child: const Text('Visit your companion'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
