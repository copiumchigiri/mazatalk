import 'package:flutter_test/flutter_test.dart';
import 'package:mazatalk/features/curriculum/domain/activity.dart';
import 'package:mazatalk/features/curriculum/domain/lesson.dart';
import 'package:mazatalk/features/lesson/domain/lesson_session.dart';

Lesson _lesson(int activityCount) => Lesson(
  id: 'l1',
  title: 'Test',
  topicId: 'animals',
  activities: [
    for (var i = 0; i < activityCount; i++)
      Activity(
        type: ActivityType.choiceText,
        skillId: 'letters',
        prompt: 'q$i',
        choices: const ['a', 'b', 'c'],
        correctOrder: const [0],
      ),
  ],
);

void main() {
  test('all-correct run: completes in order, full XP, no mistakes', () {
    final session = LessonSession(_lesson(4));
    for (var i = 0; i < 4; i++) {
      expect(session.isComplete, isFalse);
      expect(session.currentActivityIndex, i);
      session.answer(true);
    }
    expect(session.isComplete, isTrue);
    expect(session.answersCorrectFirstTry, 4);
    expect(session.xpEarned, 14);
    expect(session.mistakeFingerprints, isEmpty);
    expect(session.combo, 4);
  });

  test(
    'wrong answer requeues the activity at the end until answered right',
    () {
      final session = LessonSession(_lesson(3));
      session.answer(false); // q0 wrong → requeued
      session.answer(true); // q1
      session.answer(true); // q2
      expect(
        session.isComplete,
        isFalse,
        reason: 'missed activity must come back',
      );
      expect(session.currentActivityIndex, 0);
      session.answer(false); // wrong again → requeued again
      expect(session.isComplete, isFalse);
      expect(session.currentActivityIndex, 0);
      session.answer(true);
      expect(session.isComplete, isTrue);

      // Accuracy counts first tries only; XP excludes the missed one.
      expect(session.answersTotal, 3);
      expect(session.answersCorrectFirstTry, 2);
      expect(session.xpEarned, 12);
      expect(session.mistakeFingerprints, ['l1:0']);
    },
  );

  test('combo counts consecutive correct and resets on a miss', () {
    final session = LessonSession(_lesson(4));
    session.answer(true);
    session.answer(true);
    expect(session.combo, 2);
    session.answer(false);
    expect(session.combo, 0);
    session.answer(true);
    expect(session.combo, 1);
  });

  test('checkpoint tracks first-pass progress only', () {
    final session = LessonSession(_lesson(4));
    expect(session.checkpoint, 0);
    session.answer(true);
    expect(session.checkpoint, 1);
    session.answer(false);
    expect(session.checkpoint, 2);
    session.answer(true);
    session.answer(true);
    // Now in the requeue phase — checkpoint stays at the end of first pass.
    expect(session.checkpoint, 4);
    session.answer(true);
    expect(session.isComplete, isTrue);
  });

  test('startCheckpoint resumes mid-lesson', () {
    final session = LessonSession(_lesson(5), startCheckpoint: 3);
    expect(session.currentActivityIndex, 3);
    expect(session.answersTotal, 2);
    session.answer(true);
    session.answer(true);
    expect(session.isComplete, isTrue);
    expect(session.xpEarned, 12);
  });

  test('progress runs 0→1 and retreats when the queue grows', () {
    final session = LessonSession(_lesson(2));
    expect(session.progress, 0);
    session.answer(false); // queue grows to 3
    expect(session.progress, closeTo(1 / 3, 0.001));
    session.answer(true);
    session.answer(true);
    expect(session.progress, 1);
  });
}
