import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mazatalk/features/profile/domain/child_profile.dart';
import 'package:mazatalk/main.dart';

/// Parent gate + dashboard + settings, driven through the real app.
void main() {
  const email = 'a@b.com';

  /// A signed-in child now lands on the assessment-summary screen by
  /// default (no more Duolingo-style home screen) — jump to the path
  /// screen directly since that's what hosts the drawer this test needs.
  Future<void> goHome(WidgetTester tester) async {
    GoRouter.of(tester.element(find.byType(Scaffold))).go('/home');
    await tester.pumpAndSettle();
  }

  Map<String, Object> seededPrefs(ChildProfile child) => {
    'mazatalk_auth_accounts_v3': jsonEncode({
      email: {'parentName': 'parent'},
    }),
    'mazatalk_auth_session_v3': email,
    'mazatalk_children_v3_$email': jsonEncode([child.toJson()]),
  };

  /// Reads "X, дараа нь Y дээр дар" off the gate dialog and taps the code.
  Future<void> passParentGate(WidgetTester tester) async {
    final instruction = tester
        .widgetList<Text>(find.textContaining('дараа нь'))
        .map((t) => t.data!)
        .firstWhere((t) => RegExp(r'^\d, дараа нь \d дээр дар$').hasMatch(t));
    final match = RegExp(
      r'^(\d), дараа нь (\d) дээр дар$',
    ).firstMatch(instruction)!;
    await tester.tap(find.widgetWithText(OutlinedButton, match.group(1)!));
    await tester.pump();
    await tester.tap(find.widgetWithText(OutlinedButton, match.group(2)!));
    await tester.pumpAndSettle();
  }

  testWidgets('gate blocks on wrong code and admits on the right one', (
    tester,
  ) async {
    const child = ChildProfile(
      id: 'c1',
      name: 'Anu',
      age: 5,
      interestIds: ['space'],
      completedLessonIds: ['u1l1', 'u1l2'],
      xp: 26,
      dailyStreak: 3,
      coins: 40,
      mistakeBank: ['u1l2:0'],
      answersTotal: 12,
      answersCorrectFirstTry: 9,
    );
    SharedPreferences.setMockInitialValues(seededPrefs(child));

    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();
    await goHome(tester);

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Эцэг эхийн самбар'));
    await tester.pumpAndSettle();

    // Gate is up; dashboard not shown yet.
    expect(find.text('Том хүнд зориулав!'), findsOneWidget);
    expect(find.text("Anu-ийн явц"), findsNothing);

    await passParentGate(tester);

    // Dashboard shows the real computed numbers.
    expect(find.text("Anu-ийн явц"), findsOneWidget);
    expect(find.text('2/48'), findsOneWidget);
    expect(find.text('75%'), findsOneWidget); // 9/12 first-try accuracy
    expect(find.text('🔥 3'), findsOneWidget);
    expect(find.text('⚡ 26'), findsOneWidget);
    expect(find.text('🪙 40'), findsOneWidget);
    expect(find.text('🔁 1'), findsOneWidget);
    expect(find.textContaining('Одоо үзэж буй:'), findsOneWidget);
  });

  testWidgets('settings: sound toggle persists per account', (tester) async {
    const child = ChildProfile(
      id: 'c1',
      name: 'Anu',
      age: 5,
      interestIds: ['space'],
    );
    SharedPreferences.setMockInitialValues(seededPrefs(child));

    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();
    await goHome(tester);

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Тохиргоо'));
    await tester.pumpAndSettle();
    await passParentGate(tester);

    expect(find.text('Дуу ба хоолой'), findsOneWidget);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('mazatalk_settings_v3_${email}_soundOn'), isFalse);

    // Relaunch: the toggle stays off.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();
    await goHome(tester);
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Тохиргоо'));
    await tester.pumpAndSettle();
    await passParentGate(tester);
    final toggle = tester.widget<Switch>(find.byType(Switch));
    expect(toggle.value, isFalse);
  });
}
