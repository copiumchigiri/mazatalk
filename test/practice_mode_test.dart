import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mazatalk/features/curriculum/data/course_builder.dart';
import 'package:mazatalk/features/profile/domain/child_profile.dart';
import 'package:mazatalk/main.dart';

/// Practice mode end-to-end: banked mistakes become an ad-hoc lesson,
/// first-try-correct answers leave the bank, XP is reduced, no coins.
void main() {
  const email = 'a@b.com';
  const childId = 'c1';
  const interests = ['dinosaurs'];

  /// A signed-in child now lands on the assessment-summary screen by
  /// default (no more Duolingo-style home screen) — jump to the path
  /// screen directly since that's what hosts the drawer this test needs.
  Future<void> goHome(WidgetTester tester) async {
    GoRouter.of(tester.element(find.byType(Scaffold))).go('/home');
    await tester.pumpAndSettle();
  }

  testWidgets('practice clears first-try-correct mistakes and pays 5+n XP', (
    tester,
  ) async {
    final course = buildCourseForChild(
      childId: childId,
      interestIds: interests,
    );
    // Bank two known mistakes from lesson u1l2 (letters A & B).
    final child = ChildProfile(
      id: childId,
      name: 'Anu',
      age: 5,
      interestIds: interests,
      completedLessonIds: course.lessons.take(2).map((l) => l.id).toList(),
      mistakeBank: const ['u1l2:0', 'u1l2:4'],
      coins: 7,
    );
    SharedPreferences.setMockInitialValues({
      'mazatalk_auth_accounts_v3': jsonEncode({
        email: {'parentName': 'parent'},
      }),
      'mazatalk_auth_session_v3': email,
      'mazatalk_children_v3_$email': jsonEncode([child.toJson()]),
    });

    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();
    await goHome(tester);

    // Drawer → Practice (shows the bank count).
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    expect(find.text('2 давтах'), findsOneWidget);
    await tester.tap(find.text('Давтлага'));
    await tester.pumpAndSettle();

    // Both banked activities come from u1l2; answer them correctly.
    final lesson = course.lessonById('u1l2')!;
    for (final index in [0, 4]) {
      final activity = lesson.activities[index];
      await tester.tap(
        find.text(activity.choices[activity.correctIndex]).first,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1100));
      await tester.pump();
    }
    await tester.pumpAndSettle();

    // Complete screen: practice XP = 5 base + 2 first-try, no coin line.
    expect(find.text('Давтлага дууслаа!'), findsOneWidget);
    expect(find.text('⚡ +7 XP'), findsOneWidget);
    expect(find.textContaining('🪙'), findsNothing);

    await tester.tap(find.text('ҮРГЭЛЖЛҮҮЛЭХ'));
    await tester.pumpAndSettle();

    // Bank emptied; coins untouched.
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    expect(find.text('2 давтах'), findsNothing);
    final saved = SharedPreferences.getInstance();
    final prefs = await saved;
    final children =
        jsonDecode(prefs.getString('mazatalk_children_v3_$email')!) as List;
    final updated = ChildProfile.fromJson(
      children.first as Map<String, dynamic>,
    );
    expect(updated.mistakeBank, isEmpty);
    expect(updated.coins, 7);
    expect(updated.xp, 7);
  });
}
