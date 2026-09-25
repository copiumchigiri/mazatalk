import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mazatalk/core/services/speech_input_service.dart';
import 'package:mazatalk/features/curriculum/data/course_builder.dart';
import 'package:mazatalk/features/curriculum/domain/lesson.dart';
import 'package:mazatalk/features/letters/domain/letter_glyph.dart';
import 'package:mazatalk/main.dart';
import 'helpers/letter_flow.dart';
import 'helpers/playground_flow.dart';

/// Resolves instantly instead of hitting the real speech_to_text platform
/// channel, which never resolves inside a `testWidgets` fake-async zone
/// without a channel mock (see `playground_levels_test.dart` for the same
/// pattern used against `RepeatAfterMeLevel` directly).
class _ScriptedSpeechInputService extends SpeechInputService {
  @override
  Future<SpeechAttempt> listenFor(
    String targetWord, {
    Duration? timeout,
  }) async {
    return const SpeechAttempt(SpeechAttemptResult.unavailable);
  }
}

/// The full QA script from PROJECT_V3.md §11, updated for the V4 placement
/// playground (PROJECT_V4.md §13), as one automated journey: fresh signup →
/// handoff → playground → path → lessons (one with a mistake) → relaunch →
/// chest → skin purchase → logout → login → progress intact.
void main() {
  /// A signed-in child now lands on the assessment-summary screen by
  /// default (no more Duolingo-style home screen) — jump to the path
  /// screen directly for the parts of this test that exercise the
  /// curriculum (lessons, chests, skins).
  Future<void> goHome(WidgetTester tester) async {
    GoRouter.of(tester.element(find.byType(Scaffold))).go('/home');
    await tester.pumpAndSettle();
  }

  Future<void> relaunch(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();
    await goHome(tester);
  }

  /// Lessons that open with a letter intro need it played before questions.
  Future<void> playIntroIfAny(WidgetTester tester, Lesson lesson) async {
    final glyph = LetterCatalog.forLesson(lesson.id);
    if (glyph == null) return;
    await playLetterIntro(tester, glyph);
    await tester.pumpAndSettle();
  }

  /// Plays [lesson] from its first activity; optionally fails the first
  /// activity once (it gets requeued and answered right at the end).
  Future<void> playLesson(
    WidgetTester tester,
    Lesson lesson, {
    bool mistakeOnFirst = false,
  }) async {
    Future<void> answer(activity, {required bool correctly}) async {
      final index = correctly
          ? activity.correctIndex
          : (activity.correctIndex == 0 ? 1 : 0);
      await tester.tap(find.text(activity.choices[index]).first);
      await tester.pump();
      await tester.pump(Duration(milliseconds: correctly ? 1100 : 2600));
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
    expect(find.text('${lesson.title} дууслаа!'), findsOneWidget);
    await tester.tap(find.text('ҮРГЭЛЖЛҮҮЛЭХ'));
    await tester.pumpAndSettle();
  }

  testWidgets('full journey: signup to purchased skin with progress intact', (
    tester,
  ) async {
    // The default 800×600 test surface puts some grid tiles (e.g. the
    // 5-letter grid) right at the edge, where the taps this test drives
    // can miss; a generous surface avoids that entirely.
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});

    // ---- Sign up + onboarding ----
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          speechInputServiceProvider.overrideWithValue(
            _ScriptedSpeechInputService(),
          ),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Бүртгүүлэх'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('И-мэйлээр бүртгүүлэх'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'parent@test.com');
    await tester.enterText(find.byType(TextField).at(1), 'secret1');
    await tester.enterText(find.byType(TextField).at(2), 'secret1');
    await tester.tap(find.text('Бүртгүүлэх'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Anu');
    await tester.enterText(find.byType(TextField).at(1), '5');
    await tester.tap(find.text('Дараах'));
    await tester.pumpAndSettle();

    // ---- Parent questionnaire: rate all three at "3", then continue ----
    for (var i = 0; i < 3; i++) {
      await tester.ensureVisible(find.text('3').at(i));
      await tester.tap(find.text('3').at(i));
    }
    await tester.pump();
    await tester.ensureVisible(find.text('Дараах'));
    await tester.tap(find.text('Дараах'));
    // Not pumpAndSettle: the handoff screen (and every playground level)
    // hosts Maza via MazaSpeechBubble, whose bob animation is one-shot but
    // still means a bare push transition needs a bounded flush, not an
    // "until nothing's pending" one.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // ---- Handoff screen ----
    expect(find.textContaining('Anu'), findsWidgets);
    await tester.tap(find.text('Бэлэн боллоо ▶'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // ---- Placement playground: 9 levels in 3 acts, answered for real ----
    // Pick Favorites: tap order becomes `interestIds` order (course theming
    // cycles through it lesson by lesson — `course_builder.dart`).
    const interestIds = ['dinosaurs', 'space', 'ocean'];
    await playPlayground(tester, favorites: interestIds);

    // Placement lands on the assessment-summary tracker — no separate
    // child-select tap, since `addChild` already selects the new child.
    // Jump to the path screen for the curriculum part of this journey.
    expect(find.textContaining('Anu'), findsWidgets);
    await goHome(tester);
    expect(find.text('ЭХЛЭХ'), findsOneWidget);

    // Back to the default surface: the curriculum assertions below (e.g.
    // "exactly one Chest") assume the path screen's normal list
    // virtualization, which the oversized placement surface changes.
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    await tester.pumpAndSettle();

    // The child id was generated when the playground finished; rebuild its
    // course with the exact interests tapped in Level 7, in tap order. This
    // journey now answers every level for real, so the resulting core
    // score (and therefore how many lessons placement auto-credits) isn't
    // fixed — read `placedLessonIds` back to find the real starting index
    // instead of assuming it's always 0.
    final prefs = await SharedPreferences.getInstance();
    final childJson =
        (jsonDecode(prefs.getString('mazatalk_children_v3_parent@test.com')!)
                    as List)
                .first
            as Map<String, dynamic>;
    final childId = childJson['id'] as String;
    expect(childJson['placementCompleted'], isTrue);
    final placedLessonIds = (childJson['placedLessonIds'] as List)
        .cast<String>();
    final start = placedLessonIds.length;
    final course = buildCourseForChild(
      childId: childId,
      interestIds: interestIds,
    );

    // ---- Lesson 1 with a deliberate mistake ----
    await tester.tap(find.text('ЭХЛЭХ'));
    await tester.pumpAndSettle();
    await playIntroIfAny(tester, course.lessons[start]);
    await playLesson(tester, course.lessons[start], mistakeOnFirst: true);

    // Mistake landed in the practice bank.
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    expect(find.text('1 давтах'), findsOneWidget);
    await tester.tapAt(const Offset(700, 300)); // close drawer
    await tester.pumpAndSettle();

    // ---- Relaunch mid-course: lands on path with lesson 1 done ----
    await relaunch(tester);
    expect(find.text('ЭХЛЭХ'), findsOneWidget);
    // The lesson just played is saved as done. (Checked in storage, not by
    // counting check marks: the path auto-scrolls to the current lesson, so
    // whether the one just above it is on screen depends on the start point.)
    final prefsNow = await SharedPreferences.getInstance();
    final savedAfterRelaunch =
        (jsonDecode(prefsNow.getString('mazatalk_children_v3_parent@test.com')!)
                    as List)
                .first
            as Map<String, dynamic>;
    expect(
      (savedAfterRelaunch['completedLessonIds'] as List),
      contains(course.lessons[start].id),
    );

    // ---- Lessons 2–4, then the chest ----
    for (var i = start + 1; i < start + 4; i++) {
      await tester.tap(find.text('ЭХЛЭХ'));
      await tester.pumpAndSettle();
      await playIntroIfAny(tester, course.lessons[i]);
      await playLesson(tester, course.lessons[i]);
    }
    // The just-played 4 lessons pay their own `coinReward` (usually 20, but
    // some lessons pay more) — compute the total from the actual lessons
    // played rather than assuming a fixed 80, since which 4 lessons those
    // are now depends on `start`.
    final playedCoins = course.lessons
        .sublist(start, start + 4)
        .map((l) => l.coinReward)
        .fold(0, (a, b) => a + b);

    // Chest_4 (the first chest, needing only lessons 0–3 complete) is
    // always reached by this point regardless of `start` — but with a
    // nonzero `start` the path list's auto-scroll may have moved past it
    // to a later, still-unreached chest, so scroll to the top first to
    // land on chest_4 specifically.
    await tester.fling(find.byType(ListView), const Offset(0, 5000), 5000);
    await tester.pumpAndSettle();
    var scrollGuard = 0;
    while (find.text('Авдар').evaluate().isEmpty && scrollGuard < 10) {
      await tester.drag(find.byType(ListView), const Offset(0, -150));
      await tester.pumpAndSettle();
      scrollGuard++;
    }
    // The earliest (lowest-index) "Chest" label in list order is always
    // chest_4, which is reached as soon as `start + 4 >= 4` (always true) —
    // a later chest further down may also be visible but not yet reached.
    await tester.tap(find.text('Авдар').first);
    await tester.pumpAndSettle();
    expect(find.text('🎁 Авдар нээгдлээ! +15 🪙'), findsOneWidget);
    final coinsAfterChest = playedCoins + 15;
    expect(find.text('$coinsAfterChest'), findsOneWidget);

    // ---- Buy and equip a skin ----
    await tester.tap(
      find.byKey(const Key('path_avatar')),
    ); // appbar avatar → skins
    await tester.pumpAndSettle();
    await tester.tap(find.text('Panda'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Нээх'));
    await tester.pumpAndSettle();
    expect(find.text('Өмссөн'), findsOneWidget);
    final coinsAfterSkin = coinsAfterChest - 50;
    expect(find.text('$coinsAfterSkin'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('🐼'), findsOneWidget); // new avatar on the path

    // ---- Log out, log back in: everything intact ----
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Гарах'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Гарах').last); // confirm dialog
    await tester.pumpAndSettle();
    expect(find.text('Maza Talk'), findsOneWidget);

    await tester.tap(find.text('Нэвтрэх'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('И-мэйлээр нэвтрэх'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'parent@test.com');
    await tester.enterText(find.byType(TextField).at(1), 'secret1');
    await tester.tap(find.text('Дараах'));
    await tester.pumpAndSettle();

    // Child card shows preserved streak/XP; entering shows 4 done lessons.
    expect(find.text('Anu'), findsOneWidget);
    expect(find.textContaining('🔥 1'), findsOneWidget);
    await tester.tap(find.text('Anu'));
    await tester.pumpAndSettle();
    await goHome(tester);
    // Path auto-scrolled to the current node; the played lessons are still
    // recorded as done (checked in `completedLessonIds` above).
    expect(find.text('$coinsAfterSkin'), findsOneWidget);
    expect(find.text('🐼'), findsOneWidget);
    expect(
      find.text(course.lessons[start + 4].title),
      findsOneWidget,
    ); // next START
  });
}
