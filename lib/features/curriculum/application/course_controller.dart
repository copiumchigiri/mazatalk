import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/course_builder.dart';
import '../domain/course.dart';

/// Hands out each child's [Course], memoized per child id. Generation is
/// pure/deterministic (see [buildCourseForChild]) so nothing is persisted —
/// this cache only avoids rebuilding activity lists on every screen build.
class CourseResolver {
  final _cache = <String, Course>{};

  Course forChild({
    required String childId,
    required List<String> interestIds,
  }) {
    return _cache.putIfAbsent(
      childId,
      () => buildCourseForChild(childId: childId, interestIds: interestIds),
    );
  }
}

final courseResolverProvider = Provider<CourseResolver>((ref) {
  return CourseResolver();
});
