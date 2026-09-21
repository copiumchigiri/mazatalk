import 'package:flutter_test/flutter_test.dart';
import 'package:mazatalk/features/curriculum/data/course_builder.dart';
import 'package:mazatalk/features/curriculum/domain/activity.dart';
import 'package:mazatalk/features/curriculum/domain/course.dart';

void main() {
  Course build({String childId = 'child-1', List<String> interests = const ['dinosaurs', 'space']}) =>
      buildCourseForChild(childId: childId, interestIds: interests);

  group('course generation', () {
    test('generates the full course: 6 units × 8 lessons = 48', () {
      final course = build();
      expect(course.units.length, 6);
      for (final unit in course.units) {
        expect(unit.lessons.length, 8, reason: 'unit ${unit.id}');
      }
      expect(course.lessons.length, 48);
    });

    test('is deterministic: same child gets byte-identical content', () {
      final a = build();
      final b = build();
      for (var i = 0; i < a.lessons.length; i++) {
        final la = a.lessons[i];
        final lb = b.lessons[i];
        expect(la.id, lb.id);
        for (var j = 0; j < la.activities.length; j++) {
          expect(la.activities[j].prompt, lb.activities[j].prompt);
          expect(la.activities[j].choices, lb.activities[j].choices);
          expect(la.activities[j].correctOrder, lb.activities[j].correctOrder);
        }
      }
    });

    test('lesson ids are stable across different interests', () {
      final dino = build(interests: ['dinosaurs']);
      final space = build(childId: 'child-2', interests: ['space']);
      expect(
        dino.lessons.map((l) => l.id).toList(),
        space.lessons.map((l) => l.id).toList(),
      );
    });

    test('theming cycles through the child\'s interests', () {
      final course = build(interests: ['dinosaurs', 'space']);
      expect(course.lessons[0].topicId, 'dinosaurs');
      expect(course.lessons[1].topicId, 'space');
      expect(course.lessons[2].topicId, 'dinosaurs');
    });

    test('no interests falls back to a default topic', () {
      final course = build(interests: []);
      expect(course.lessons, isNotEmpty);
      expect(course.lessons.first.topicId, 'animals');
    });
  });

  group('content validator (walks every generated activity)', () {
    // Several children with different interest sets — authoring mistakes
    // that only appear with certain themes/seeds get caught here.
    final children = [
      ('c1', ['dinosaurs']),
      ('c2', ['space', 'ocean']),
      ('c3', ['music', 'art', 'sports']),
      ('c4', <String>[]),
      ('a-very-long-child-id-9999', ['fairyTales', 'trains', 'cars', 'animals']),
    ];

    test('every activity is self-consistent and age-capped', () {
      for (final (childId, interests) in children) {
        final course = buildCourseForChild(
            childId: childId, interestIds: interests);
        for (final unit in course.units) {
          for (final lesson in unit.lessons) {
            expect(lesson.activities.length, inInclusiveRange(5, 10),
                reason: '${lesson.id} activity count');
            for (final activity in lesson.activities) {
              final where = '$childId ${lesson.id} "${activity.prompt}"';
              expect(activity.prompt, isNotEmpty, reason: where);
              expect(activity.choices.length, inInclusiveRange(2, 4),
                  reason: where);
              expect(activity.correctOrder, isNotEmpty, reason: where);
              for (final index in activity.correctOrder) {
                expect(index, inInclusiveRange(0, activity.choices.length - 1),
                    reason: where);
              }
              if (activity.isSingleAnswer) {
                expect(activity.correctOrder.length, 1, reason: where);
              }
              // Choices must be distinct or the child can tap "the right
              // answer" and be told it's wrong.
              expect(activity.choices.toSet().length,
                  activity.choices.length,
                  reason: '$where duplicate choices');
              switch (activity.type) {
                case ActivityType.matchPairs:
                  expect(activity.choices.length, lessThanOrEqualTo(3),
                      reason: '$where pairs cap');
                  expect(activity.rightColumn.length,
                      activity.choices.length,
                      reason: where);
                case ActivityType.sequence:
                  // 3-tile cap; 4 allowed only from unit 5 (sentences).
                  final cap =
                      (unit.id == 'unit5' || unit.id == 'unit6') ? 4 : 3;
                  expect(activity.correctOrder.length, lessThanOrEqualTo(cap),
                      reason: '$where sequence cap');
                  expect(activity.correctOrder.toSet().length,
                      activity.correctOrder.length,
                      reason: '$where sequence order must be a permutation');
                default:
                  break;
              }
              // Unit 1 must stay single-tap only (age ramp-up).
              if (unit.id == 'unit1') {
                expect(
                  activity.type,
                  isNot(isIn([
                    ActivityType.matchPairs,
                    ActivityType.sequence,
                    ActivityType.fillBlank,
                  ])),
                  reason: '$where multi-step type in unit 1',
                );
              }
            }
          }
        }
      }
    });
  });

  group('unlock and path logic', () {
    test('lessons unlock strictly in order', () {
      final course = build();
      final first = course.lessons[0].id;
      final second = course.lessons[1].id;
      final third = course.lessons[2].id;

      expect(course.isUnlocked(first, []), isTrue);
      expect(course.isUnlocked(second, []), isFalse);
      expect(course.isUnlocked(second, [first]), isTrue);
      expect(course.isUnlocked(third, [second]), isFalse,
          reason: 'skipping a lesson must not unlock later ones');
    });

    test('firstIncomplete points at the resume lesson', () {
      final course = build();
      expect(course.firstIncomplete([]), course.lessons.first);
      final done = course.lessons.map((l) => l.id).toList();
      expect(course.firstIncomplete(done), isNull);
      expect(course.firstIncomplete(done.take(3)), course.lessons[3]);
    });

    test('a chest node follows every 4th lesson', () {
      final course = build();
      final nodes = course.pathNodes();
      final expectedChests = course.lessons.length ~/ Course.chestInterval;
      expect(nodes.where((n) => n.type == PathNodeType.chest).length,
          expectedChests);
      // The 5th node (index 4) is the chest after lessons 1–4.
      expect(nodes[4].type, PathNodeType.chest);
      expect(nodes[4].nodeId, 'chest_4');
    });

    test('chests are reached only when all lessons before them are done', () {
      final course = build();
      final ids = course.lessons.map((l) => l.id).toList();
      expect(course.isChestReached('chest_4', ids.take(3)), isFalse);
      expect(course.isChestReached('chest_4', ids.take(4)), isTrue);
      expect(course.isChestReached('chest_8', ids.take(4)), isFalse);
      expect(course.isChestReached('chest_8', ids.take(8)), isTrue);
    });

    test('next() walks the course and ends with null', () {
      final course = build();
      expect(course.next(course.lessons.first.id), course.lessons[1]);
      expect(course.next(course.lessons.last.id), isNull);
    });
  });
}
