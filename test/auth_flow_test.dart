import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mazatalk/core/services/speech_input_service.dart';
import 'package:mazatalk/main.dart';
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

/// End-to-end flow through the real app widget: sign up → onboarding →
/// placement playground → lesson, then a simulated relaunch that must
/// restore the session and resume without showing the welcome screen.
void main() {
  /// A signed-in child now lands on the assessment-summary screen by
  /// default (no more Duolingo-style home screen) — jump to the path
  /// screen directly for the parts of this test that exercise lessons.
  Future<void> goHome(WidgetTester tester) async {
    GoRouter.of(tester.element(find.byType(Scaffold))).go('/home');
    await tester.pumpAndSettle();
  }

  Future<void> playPlaceground(WidgetTester tester) => playPlayground(tester);

  testWidgets('signup → onboarding → lesson → relaunch resumes session', (
    tester,
  ) async {
    // The default 800×600 test surface puts some grid tiles (e.g. the
    // 5-letter grid) right at the edge, where the ball/mic/tile taps this
    // test drives can miss; a generous surface avoids that entirely.
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});

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

    // Welcome screen.
    expect(find.text('Maza Talk'), findsOneWidget);
    await tester.tap(find.text('Бүртгүүлэх'));
    await tester.pumpAndSettle();

    // Method picker → email signup.
    await tester.tap(find.text('И-мэйлээр бүртгүүлэх'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'parent@test.com');
    await tester.enterText(find.byType(TextField).at(1), 'secret1');
    await tester.enterText(find.byType(TextField).at(2), 'secret1');
    await tester.tap(find.text('Бүртгүүлэх'));
    await tester.pumpAndSettle();

    // Child profile creation.
    expect(find.text('Хүүхдийн профайл үүсгэх'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(0), 'Anu');
    await tester.enterText(find.byType(TextField).at(1), '5');
    await tester.tap(find.text('Дараах'));
    await tester.pumpAndSettle();

    // Parent questionnaire: rate all three at "3", then continue.
    for (var i = 0; i < 3; i++) {
      await tester.ensureVisible(find.text('3').at(i));
      await tester.tap(find.text('3').at(i));
    }
    await tester.pump();
    await tester.ensureVisible(find.text('Дараах'));
    await tester.tap(find.text('Дараах'));
    // Not pumpAndSettle: the handoff/playground screens host Maza via
    // MazaSpeechBubble — a bounded flush, not an "until nothing's
    // pending" one (see full_journey_test.dart for the same note).
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Handoff screen, then the placement playground (PROJECT_V4.md §2–§6):
    // answer every level for real — this test only cares that the journey
    // lands on the path screen with a real child, not the placement score.
    expect(find.textContaining('Anu'), findsWidgets);
    await tester.tap(find.text('Бэлэн боллоо ▶'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await playPlaceground(tester);

    // Placement lands on the assessment-summary tracker (no separate
    // child-select tap — `addChild` already selects the new child). This
    // journey answers levels for real now, so the resulting core score
    // (and therefore starting lesson) varies — only check a real child
    // reaches the path screen, not which lesson it starts on.
    expect(find.textContaining('Anu'), findsWidgets);
    await goHome(tester);
    expect(find.text('ЭХЛЭХ'), findsOneWidget);

    // Simulated relaunch: fresh widget tree + fresh providers, same prefs.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();

    // No welcome screen — session restored, child auto-selected.
    expect(find.text('Maza Talk'), findsNothing);
    await goHome(tester);
    expect(find.text('ЭХЛЭХ'), findsOneWidget);
  });

  testWidgets('login rejects a wrong password with an inline error', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Нэвтрэх'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('И-мэйлээр нэвтрэх'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'admin@gmail.com');
    await tester.enterText(find.byType(TextField).at(1), 'WrongPassword');
    await tester.tap(find.text('Дараах'));
    await tester.pumpAndSettle();

    expect(find.text('И-мэйл эсвэл нууц үг буруу байна.'), findsOneWidget);

    // Correct demo credentials succeed.
    await tester.enterText(find.byType(TextField).at(1), 'Password');
    await tester.tap(find.text('Дараах'));
    await tester.pumpAndSettle();
    expect(find.text('Хүүхдээ сонгоно уу'), findsOneWidget);
  });
}
