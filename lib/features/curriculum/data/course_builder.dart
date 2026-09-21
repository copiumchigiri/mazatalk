import 'dart:math';
import 'package:mazatalk/features/profile/domain/interest.dart';
import '../domain/course.dart';
import '../domain/lesson.dart';
import '../domain/unit.dart';
import 'units/unit_1.dart';
import 'units/unit_2.dart';
import 'units/unit_3.dart';
import 'units/unit_4.dart';
import 'units/unit_5.dart';
import 'units/unit_6.dart';

/// The whole course, in teaching order: 6 units × 8 lessons = 48.
List<UnitTemplate> courseUnitTemplates() =>
    [unit1, unit2, unit3, unit4, unit5, unit6];

/// Builds the personalized course for one child. Pure and deterministic:
/// same child id + interests always yield byte-identical content, so the
/// course is never persisted — saved progress references the fixed lesson
/// ids ('u1l3') which exist for every child.
///
/// Theming cycles through the child's interests lesson by lesson, so a
/// dinosaur kid counts 🦖 where a space kid counts 🚀 — same skill, same
/// position in the course.
Course buildCourseForChild({
  required String childId,
  required List<String> interestIds,
}) {
  final picked =
      interestIds.map(interestFromId).whereType<Interest>().toList();
  final topics = picked.isEmpty ? [Interest.animals] : picked;

  final units = <CourseUnit>[];
  var lessonIndex = 0;
  for (final template in courseUnitTemplates()) {
    final lessons = <Lesson>[];
    for (final lessonTemplate in template.lessons) {
      final topic = topics[lessonIndex % topics.length];
      final rng = Random(childId.hashCode ^ lessonIndex);
      lessons.add(Lesson(
        id: lessonTemplate.id,
        title: lessonTemplate.title,
        topicId: topic.id,
        activities: lessonTemplate.buildActivities(topic, rng),
        coinReward: lessonTemplate.coinReward,
      ));
      lessonIndex++;
    }
    units.add(CourseUnit(
      id: template.id,
      title: template.title,
      emoji: template.emoji,
      lessons: lessons,
    ));
  }
  return Course(units);
}
