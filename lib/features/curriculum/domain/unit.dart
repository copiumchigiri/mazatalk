import 'dart:math';
import 'package:mazatalk/features/profile/domain/interest.dart';
import 'activity.dart';
import 'lesson.dart';

/// A generated chapter of the course.
class CourseUnit {
  final String id;
  final String title;
  final String emoji;
  final List<Lesson> lessons;

  const CourseUnit({
    required this.id,
    required this.title,
    required this.emoji,
    required this.lessons,
  });
}

/// Authoring-side template for one lesson: fixed id/title, activities built
/// per child from their theme topic and a deterministic rng.
class LessonTemplate {
  final String id;
  final String title;
  final int coinReward;
  final List<Activity> Function(Interest topic, Random rng) buildActivities;

  const LessonTemplate({
    required this.id,
    required this.title,
    required this.buildActivities,
    this.coinReward = 20,
  });
}

/// Authoring-side template for one unit.
class UnitTemplate {
  final String id;
  final String title;
  final String emoji;
  final List<LessonTemplate> lessons;

  const UnitTemplate({
    required this.id,
    required this.title,
    required this.emoji,
    required this.lessons,
  });
}
