import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/curriculum/application/course_controller.dart';
import '../features/curriculum/domain/course.dart';
import '../features/profile/application/child_controller.dart';
import '../features/profile/domain/child_profile.dart';
import '../features/profile/domain/interest.dart';

const _skillLabels = {
  'letters': 'Үсэг 🅰️',
  'counting': 'Тоолол 🔢',
  'colors': 'Өнгө 🎨',
  'shapes': 'Хэлбэр 🔷',
  'reading': 'Унших 📖',
  'vocabulary': 'Үг 💬',
  'math': 'Математик ➕',
  'eq': 'Мэдрэмж ❤️',
};

/// Parent-facing stats, all computed from the child's real progress data.
/// Reached through the parent gate on the path screen's drawer.
class ParentDashboardScreen extends ConsumerWidget {
  const ParentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final child = ref.watch(childControllerProvider).selectedChild;
    final course = child == null
        ? null
        : ref
              .read(courseResolverProvider)
              .forChild(childId: child.id, interestIds: child.interestIds);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Эцэг эхийн самбар",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.5),
          child: Container(color: Colors.black, height: 1.5),
        ),
      ),
      body: child == null || course == null
          ? const Center(child: Text("Хүүхэд сонгоогүй байна."))
          : _DashboardBody(child: child, course: course),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  final ChildProfile child;
  final Course course;
  const _DashboardBody({required this.child, required this.course});

  @override
  Widget build(BuildContext context) {
    final completed = child.completedLessonIds.toSet();
    final currentUnit = course.unitOf(
      course.firstIncomplete(child.completedLessonIds)?.id ??
          course.lessons.last.id,
    );
    final accuracy = child.answersTotal == 0
        ? null
        : (child.answersCorrectFirstTry * 100 / child.answersTotal).round();

    // Completed activities per skill, for the breakdown rows.
    final skillCounts = <String, int>{};
    var totalActivities = 0;
    for (final lesson in course.lessons) {
      if (!completed.contains(lesson.id)) continue;
      for (final activity in lesson.activities) {
        skillCounts[activity.skillId] =
            (skillCounts[activity.skillId] ?? 0) + 1;
        totalActivities++;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "${child.name}-ийн явц",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Colors.grey,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _metricCard(
                  "Хичээл",
                  "${completed.length}/${course.lessons.length}",
                  Colors.green.shade50,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _metricCard(
                  "Оновчтой байдал",
                  accuracy == null ? "—" : "$accuracy%",
                  Colors.blue.shade50,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _metricCard(
                  "Daily streak",
                  "🔥 ${child.dailyStreak}",
                  Colors.orange.shade50,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _metricCard(
                  "XP",
                  "⚡ ${child.xp}",
                  Colors.purple.shade50,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _metricCard(
                  "Coins",
                  "🪙 ${child.coins}",
                  Colors.amber.shade50,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _metricCard(
                  "Давтах",
                  "🔁 ${child.mistakeBank.length}",
                  Colors.red.shade50,
                ),
              ),
            ],
          ),
          if (currentUnit != null) ...[
            const SizedBox(height: 16),
            Text(
              "Одоо үзэж буй: ${currentUnit.emoji} ${currentUnit.title}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
          const Divider(height: 40),
          const Text(
            "ХИЧЭЭЛИЙН ҮЕ ШАТ",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          for (final unit in course.units)
            _progressRow(
              '${unit.emoji} ${unit.title}',
              unit.lessons.isEmpty
                  ? 0.0
                  : unit.lessons.where((l) => completed.contains(l.id)).length /
                        unit.lessons.length,
            ),
          const Divider(height: 40),
          const Text(
            "ДАДЛАГАЖСАН ЧАДВАР",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          if (totalActivities == 0)
            const Text(
              "Дууссан хичээл алга.",
              style: TextStyle(color: Colors.grey),
            )
          else
            for (final entry in _skillLabels.entries)
              if ((skillCounts[entry.key] ?? 0) > 0)
                _progressRow(
                  entry.value,
                  (skillCounts[entry.key] ?? 0) / totalActivities,
                  trailing: '${skillCounts[entry.key]}',
                ),
          const SizedBox(height: 24),
          Text(
            "Сонирхол: ${child.interestIds.map((id) => interestFromId(id)?.label ?? id).join(', ')}",
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _metricCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: Colors.black, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  Widget _progressRow(String label, double percent, {String? trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 14,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black, width: 1.5),
                    borderRadius: BorderRadius.circular(7),
                    color: Colors.white,
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: percent.clamp(0.0, 1.0),
                  child: Container(
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            trailing ?? "${(percent * 100).toInt()}%",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
