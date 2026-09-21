import 'activity.dart';

/// One sitting (3–5 minutes) of activities. Lesson ids are fixed by the
/// course structure ('u1l3'), never derived from the child's interests, so
/// saved progress stays valid whatever theme the content was generated with.
class Lesson {
  final String id;
  final String title;

  /// The interest this instance was themed with (display only).
  final String topicId;

  final List<Activity> activities;
  final int coinReward;

  const Lesson({
    required this.id,
    required this.title,
    required this.topicId,
    required this.activities,
    this.coinReward = 20,
  });
}
