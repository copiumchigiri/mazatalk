import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mazatalk/features/placement/application/playground_session_controller.dart';
import 'package:mazatalk/main.dart';

/// End-to-end flow through the real app widget: sign up → onboarding →
/// placement playground → lesson, then a simulated relaunch that must
/// restore the session and resume without showing the welcome screen.
void main() {
  testWidgets('signup → onboarding → lesson → relaunch resumes session',
      (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();

    // Welcome screen.
    expect(find.text('Maza Talk'), findsOneWidget);
    await tester.tap(find.text('Бүртгүүлэх (Sign Up)'));
    await tester.pumpAndSettle();

    // Method picker → email signup.
    await tester.tap(find.text('Sign up with Email'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'parent@test.com');
    await tester.enterText(find.byType(TextField).at(1), 'secret1');
    await tester.enterText(find.byType(TextField).at(2), 'secret1');
    await tester.tap(find.text('Sign up'));
    await tester.pumpAndSettle();

    // Child profile creation.
    expect(find.text('Хүүхдийн профайл үүсгэх'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(0), 'Anu');
    await tester.enterText(find.byType(TextField).at(1), '5');
    await tester.tap(find.text('Дараах (Next)'));
    // Not pumpAndSettle: the handoff/playground screens host Maza via
    // MazaSpeechBubble — a bounded flush, not an "until nothing's
    // pending" one (see full_journey_test.dart for the same note).
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Handoff screen, then the placement playground (PROJECT_V4.md §2–§6):
    // let every level time out — this test only cares that the journey
    // lands on the path screen with a real child, not the placement score.
    expect(find.textContaining('Anu'), findsWidgets);
    await tester.tap(find.text("We're ready! ▶"));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    for (var i = 0; i < 10; i++) {
      await tester.pump(kPlaygroundExtendedLevelTimeout);
      await tester.pump(const Duration(milliseconds: 950));
      await tester.pump();
    }
    await tester.pumpAndSettle();

    // Placement lands directly on the path screen (no separate child-select
    // tap — `addChild` already selects the new child).
    expect(find.text('START'), findsOneWidget);
    expect(find.text('Say hello!'), findsWidgets);

    // Simulated relaunch: fresh widget tree + fresh providers, same prefs.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();

    // No welcome screen — session restored, child auto-selected, path
    // screen shown directly with resume one tap away.
    expect(find.text('Maza Talk'), findsNothing);
    expect(find.text('START'), findsOneWidget);
  });

  testWidgets('login rejects a wrong password with an inline error',
      (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Нэвтрэх (Log In)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log in with Email'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'admin@gmail.com');
    await tester.enterText(find.byType(TextField).at(1), 'WrongPassword');
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('Email or password is incorrect.'), findsOneWidget);

    // Correct demo credentials succeed.
    await tester.enterText(find.byType(TextField).at(1), 'Password');
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Хүүхдээ сонгоно уу'), findsOneWidget);
  });
}
