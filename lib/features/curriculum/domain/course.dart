import 'lesson.dart';
import 'unit.dart';

enum PathNodeType { lesson, chest }

/// One node on the path screen: a lesson, or a bonus chest between lessons.
class PathNode {
  final String id;
  final PathNodeType type;
  final Lesson? lesson;
  final int chestCoins;

  const PathNode.lesson(Lesson this.lesson)
      : id = '',
        type = PathNodeType.lesson,
        chestCoins = 0;

  const PathNode.chest(this.id, {this.chestCoins = 15})
      : type = PathNodeType.chest,
        lesson = null;

  String get nodeId => type == PathNodeType.lesson ? lesson!.id : id;
}

/// The full generated course for one child: fixed skills and lesson order
/// for everyone, themed per child. Deterministic — rebuilding for the same
/// child always produces identical content, so nothing needs persisting.
class Course {
  final List<CourseUnit> units;
  final List<Lesson> lessons;

  Course(this.units) : lessons = [for (final u in units) ...u.lessons];

  /// A chest node follows every [chestInterval]-th lesson.
  static const chestInterval = 4;

  Lesson? lessonById(String id) {
    for (final lesson in lessons) {
      if (lesson.id == id) return lesson;
    }
    return null;
  }

  int indexOf(String lessonId) => lessons.indexWhere((l) => l.id == lessonId);

  Lesson? next(String currentLessonId) {
    final index = indexOf(currentLessonId);
    if (index == -1 || index + 1 >= lessons.length) return null;
    return lessons[index + 1];
  }

  CourseUnit? unitOf(String lessonId) {
    for (final unit in units) {
      if (unit.lessons.any((l) => l.id == lessonId)) return unit;
    }
    return null;
  }

  /// Lessons unlock strictly in order.
  bool isUnlocked(String lessonId, Iterable<String> completedLessonIds) {
    final completed = completedLessonIds.toSet();
    final index = indexOf(lessonId);
    if (index == -1) return false;
    for (var i = 0; i < index; i++) {
      if (!completed.contains(lessons[i].id)) return false;
    }
    return true;
  }

  /// The lesson the child should be playing next (null = course finished).
  Lesson? firstIncomplete(Iterable<String> completedLessonIds) {
    final completed = completedLessonIds.toSet();
    for (final lesson in lessons) {
      if (!completed.contains(lesson.id)) return lesson;
    }
    return null;
  }

  /// A chest is reachable once every lesson before it is complete.
  bool isChestReached(String chestId, Iterable<String> completedLessonIds) {
    final completed = completedLessonIds.toSet();
    var count = 0;
    for (final lesson in lessons) {
      if (!completed.contains(lesson.id)) return false;
      count++;
      if (count % chestInterval == 0 && 'chest_$count' == chestId) return true;
    }
    return false;
  }

  List<PathNode> pathNodes() {
    final nodes = <PathNode>[];
    var count = 0;
    for (final lesson in lessons) {
      nodes.add(PathNode.lesson(lesson));
      count++;
      if (count % chestInterval == 0) {
        nodes.add(PathNode.chest('chest_$count'));
      }
    }
    return nodes;
  }
}
