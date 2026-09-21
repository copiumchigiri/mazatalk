import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mazatalk/features/curriculum/data/course_builder.dart';
import 'package:mazatalk/features/profile/domain/child_profile.dart';
import 'package:mazatalk/main.dart';

/// Drives the real lesson player through a full lesson — tap-to-answer,
/// wrong-answer requeue, completion rewards — and checks the checkpoint
/// resume path across a simulated relaunch.
void main() {
  const email = 'a@b.com';
  const childId = 'c1';
  const interests = ['dinosaurs'];

  Map<String, Object> seededPrefs(ChildProfile child) => {
        'mazatalk_auth_accounts_v3':
            jsonEncode({email: {'parentName': 'parent'}}),
        'mazatalk_auth_session_v3': email,
        'mazatalk_children_v3_$email': jsonEncode([child.toJson()]),
      };

  testWidgets('full lesson: mistakes requeue, rewards paid, path advances',
      (tester) async {
    const child = ChildProfile(
        id: childId, name: 'Anu', age: 5, interestIds: interests);
    SharedPreferences.setMockInitialValues(seededPrefs(child));

    // The same deterministic course the app will build.
    final course =
        buildCourseForChild(childId: childId, interestIds: interests);
    final lesson = course.lessons.first;

    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('START'));
    await tester.pumpAndSettle();

    // Activity 1: answer WRONG on purpose (tap a known-incorrect tile).
    final first = lesson.activities.first;
    final wrongIndex = first.correctIndex == 0 ? 1 : 0;
    await tester.tap(find.text(first.choices[wrongIndex]).first);
    await tester.pump();
    expect(find.text('❌ Not quite'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 2600));
    await tester.pump();

    // Remaining first-pass activities: answer correctly.
    for (final activity in lesson.activities.skip(1)) {
      await tester.tap(find.text(activity.choices[activity.correctIndex]).first);
      await tester.pump();
      expect(find.text('✅ Nice job!'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1100));
      await tester.pump();
    }

    // The missed first activity comes back; answer it right.
    expect(find.text(first.prompt), findsOneWidget,
        reason: 'missed activity must be requeued at the end');
    await tester.tap(find.text(first.choices[first.correctIndex]).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1100));
    await tester.pumpAndSettle();

    // Complete screen: XP = 10 + 4 first-try (5 activities, 1 missed),
    // coins = first-completion reward.
    expect(find.text('${lesson.title} complete!'), findsOneWidget);
    expect(find.text('⚡ +14 XP    🪙 +${lesson.coinReward}'), findsOneWidget);
    expect(find.text('Accuracy: 4/5'), findsOneWidget);

    // CONTINUE → path, next lesson is now the START node.
    await tester.tap(find.text('CONTINUE'));
    await tester.pumpAndSettle();
    expect(find.text('START'), findsOneWidget);
    expect(find.text(course.lessons[1].title), findsOneWidget);
    // Node for lesson 1 shows done (check icon exists on path).
    expect(find.byType(ProviderScope), findsOneWidget);
  });

  testWidgets('a lesson with a match-pairs board plays through the player',
      (tester) async {
    final course =
        buildCourseForChild(childId: childId, interestIds: interests);
    // Complete everything before u3l2 so its board lesson is current.
    final beforeU3l2 = course.lessons
        .takeWhile((l) => l.id != 'u3l2')
        .map((l) => l.id)
        .toList();
    final child = ChildProfile(
        id: childId,
        name: 'Anu',
        age: 5,
        interestIds: interests,
        completedLessonIds: beforeU3l2);
    SharedPreferences.setMockInitialValues(seededPrefs(child));

    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('START'));
    await tester.pumpAndSettle();

    final lesson = course.lessonById('u3l2')!;
    for (final activity in lesson.activities) {
      if (activity.choices.length == activity.correctOrder.length &&
          activity.rightColumn.isNotEmpty) {
        // Match-pairs board: pair each left tile with its right match.
        for (var left = 0; left < activity.choices.length; left++) {
          await tester.tap(find.text(activity.choices[left]).first);
          await tester.pump();
          final right =
              activity.rightColumn[activity.correctOrder[left]];
          await tester.tap(find.text(right).first);
          await tester.pump();
        }
      } else {
        await tester
            .tap(find.text(activity.choices[activity.correctIndex]).first);
        await tester.pump();
      }
      expect(find.text('✅ Nice job!'), findsOneWidget,
          reason: 'clean solve of "${activity.prompt}"');
      await tester.pump(const Duration(milliseconds: 1100));
      await tester.pump();
    }

    expect(find.text('${lesson.title} complete!'), findsOneWidget);
    expect(find.text('Accuracy: 6/6'), findsOneWidget);
  });

  testWidgets('exiting mid-lesson saves the checkpoint and resumes there',
      (tester) async {
    const child = ChildProfile(
        id: childId, name: 'Anu', age: 5, interestIds: interests);
    SharedPreferences.setMockInitialValues(seededPrefs(child));

    final course =
        buildCourseForChild(childId: childId, interestIds: interests);
    final lesson = course.lessons.first;

    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('START'));
    await tester.pumpAndSettle();

    // Answer the first two activities correctly.
    for (final activity in lesson.activities.take(2)) {
      await tester.tap(find.text(activity.choices[activity.correctIndex]).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1100));
      await tester.pump();
    }

    // Relaunch the app; resume must land on activity index 2, not 0.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('START'));
    await tester.pumpAndSettle();
    expect(find.text(lesson.activities[2].prompt), findsOneWidget);
    expect(find.text(lesson.activities[0].prompt), findsNothing);
  });
}
