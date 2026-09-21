import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mazatalk/features/curriculum/data/course_builder.dart';
import 'package:mazatalk/features/curriculum/domain/lesson.dart';
import 'package:mazatalk/features/placement/application/playground_session_controller.dart';
import 'package:mazatalk/main.dart';

/// The full QA script from PROJECT_V3.md §11, updated for the V4 placement
/// playground (PROJECT_V4.md §13), as one automated journey: fresh signup →
/// handoff → playground → path → lessons (one with a mistake) → relaunch →
/// chest → skin purchase → logout → login → progress intact.
void main() {
  Future<void> relaunch(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();
  }

  /// Plays [lesson] from its first activity; optionally fails the first
  /// activity once (it gets requeued and answered right at the end).
  Future<void> playLesson(WidgetTester tester, Lesson lesson,
      {bool mistakeOnFirst = false}) async {
    Future<void> answer(activity, {required bool correctly}) async {
      final index = correctly
          ? activity.correctIndex
          : (activity.correctIndex == 0 ? 1 : 0);
      await tester.tap(find.text(activity.choices[index]).first);
      await tester.pump();
      await tester
          .pump(Duration(milliseconds: correctly ? 1100 : 2600));
      await tester.pump();
    }

    if (mistakeOnFirst) {
      await answer(lesson.activities.first, correctly: false);
    } else {
      await answer(lesson.activities.first, correctly: true);
    }
    for (final activity in lesson.activities.skip(1)) {
      await answer(activity, correctly: true);
    }
    if (mistakeOnFirst) {
      await answer(lesson.activities.first, correctly: true); // requeued
    }
    await tester.pumpAndSettle();
    expect(find.text('${lesson.title} complete!'), findsOneWidget);
    await tester.tap(find.text('CONTINUE'));
    await tester.pumpAndSettle();
  }

  testWidgets('full journey: signup to purchased skin with progress intact',
      (tester) async {
    SharedPreferences.setMockInitialValues({});

    // ---- Sign up + onboarding ----
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Бүртгүүлэх (Sign Up)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign up with Email'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'parent@test.com');
    await tester.enterText(find.byType(TextField).at(1), 'secret1');
    await tester.enterText(find.byType(TextField).at(2), 'secret1');
    await tester.tap(find.text('Sign up'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Anu');
    await tester.enterText(find.byType(TextField).at(1), '5');
    await tester.tap(find.text('Дараах (Next)'));
    // Not pumpAndSettle: the handoff screen (and every playground level)
    // hosts Maza via MazaSpeechBubble, whose bob animation is one-shot but
    // still means a bare push transition needs a bounded flush, not an
    // "until nothing's pending" one.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // ---- Handoff screen ----
    expect(find.textContaining('Anu'), findsWidgets);
    await tester.tap(find.text("We're ready! ▶"));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // ---- Placement playground: 10 levels ----
    // Levels 1–6 all time out here (this journey cares about the app
    // staying intact end to end, not exhaustively exercising every
    // playground mechanic — `placement_test.dart` and the widget tests
    // below cover the scoring math and Level 1's tap target directly).
    // Every core level's timeout floor is 2/10, so all five core levels
    // timing out lands exactly on the 0–20 bucket boundary: Lesson 1,
    // nothing auto-credited, keeping every `course.lessons[i]` index below
    // aligned with what's actually un-played.
    for (var i = 0; i < 6; i++) {
      await tester.pump(kPlaygroundDefaultLevelTimeout);
      await tester.pump(const Duration(milliseconds: 950));
      await tester.pump();
    }

    // Level 7 — Pick Your Favorites: replaces the old interest-picker form.
    // Tap order becomes `interestIds` order (course theming cycles through
    // it lesson by lesson — `course_builder.dart`).
    await tester.tap(find.text('🦖')); // dinosaurs
    await tester.tap(find.text('🚀')); // space
    await tester.tap(find.text('🐠')); // ocean
    await tester.pump(const Duration(milliseconds: 550));
    await tester.pump();

    // Level 8 — How Do They Feel: no wrong answer, tap any face.
    await tester.tap(find.text('😊'));
    await tester.pump(const Duration(milliseconds: 750));
    await tester.pump();

    // Level 9 — Memory Match, Level 10 — Copy the Pattern: let both time
    // out (extended 20s window each).
    await tester.pump(kPlaygroundExtendedLevelTimeout);
    await tester.pump(const Duration(milliseconds: 750));
    await tester.pump();
    await tester.pump(kPlaygroundExtendedLevelTimeout);
    await tester.pump(const Duration(milliseconds: 950));
    await tester.pumpAndSettle();

    // Placement lands directly on the Path screen — no separate
    // child-select tap, since `addChild` already selects the new child.
    expect(find.text('START'), findsOneWidget);

    // The child id was generated when the playground finished; rebuild its
    // course with the exact interests tapped in Level 7, in tap order.
    final prefs = await SharedPreferences.getInstance();
    final childJson = (jsonDecode(
            prefs.getString('mazatalk_children_v3_parent@test.com')!) as List)
        .first as Map<String, dynamic>;
    final childId = childJson['id'] as String;
    expect(childJson['placementCompleted'], isTrue);
    expect(childJson['placedLessonIds'], isEmpty); // low score -> Lesson 1
    final course = buildCourseForChild(
        childId: childId, interestIds: ['dinosaurs', 'space', 'ocean']);

    // ---- Lesson 1 with a deliberate mistake ----
    await tester.tap(find.text('START'));
    await tester.pumpAndSettle();
    await playLesson(tester, course.lessons[0], mistakeOnFirst: true);

    // Mistake landed in the practice bank.
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    expect(find.text('1 to review'), findsOneWidget);
    await tester.tapAt(const Offset(700, 300)); // close drawer
    await tester.pumpAndSettle();

    // ---- Relaunch mid-course: lands on path with lesson 1 done ----
    await relaunch(tester);
    expect(find.text('START'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);

    // ---- Lessons 2–4, then the chest ----
    for (var i = 1; i < 4; i++) {
      await tester.tap(find.text('START'));
      await tester.pumpAndSettle();
      await playLesson(tester, course.lessons[i]);
    }
    await tester.tap(find.text('Chest'));
    await tester.pumpAndSettle();
    expect(find.text('🎁 Chest opened! +15 🪙'), findsOneWidget);
    // 4 × 20 lesson coins + 15 chest = 95.
    expect(find.text('95'), findsOneWidget);

    // ---- Buy and equip a skin ----
    await tester.tap(find.text('🐻')); // appbar avatar → skins
    await tester.pumpAndSettle();
    await tester.tap(find.text('Panda'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Unlock'));
    await tester.pumpAndSettle();
    expect(find.text('Equipped'), findsOneWidget);
    expect(find.text('45'), findsOneWidget); // 95 − 50
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('🐼'), findsOneWidget); // new avatar on the path

    // ---- Log out, log back in: everything intact ----
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log out').last); // confirm dialog
    await tester.pumpAndSettle();
    expect(find.text('Maza Talk'), findsOneWidget);

    await tester.tap(find.text('Нэвтрэх (Log In)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log in with Email'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'parent@test.com');
    await tester.enterText(find.byType(TextField).at(1), 'secret1');
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    // Child card shows preserved streak/XP; entering shows 4 done lessons.
    expect(find.text('Anu'), findsOneWidget);
    expect(find.textContaining('🔥 1'), findsOneWidget);
    await tester.tap(find.text('Anu'));
    await tester.pumpAndSettle();
    // Path auto-scrolled to the current node; nearby done nodes show checks
    // (offscreen ones aren't built — the list virtualizes).
    expect(find.byIcon(Icons.check), findsWidgets);
    expect(find.text('45'), findsOneWidget);
    expect(find.text('🐼'), findsOneWidget);
    expect(find.text(course.lessons[4].title), findsOneWidget); // next START
  });
}
