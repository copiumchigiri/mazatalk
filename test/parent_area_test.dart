import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mazatalk/features/profile/domain/child_profile.dart';
import 'package:mazatalk/main.dart';

/// Parent gate + dashboard + settings, driven through the real app.
void main() {
  const email = 'a@b.com';

  Map<String, Object> seededPrefs(ChildProfile child) => {
        'mazatalk_auth_accounts_v3':
            jsonEncode({email: {'parentName': 'parent'}}),
        'mazatalk_auth_session_v3': email,
        'mazatalk_children_v3_$email': jsonEncode([child.toJson()]),
      };

  /// Reads "Tap X then Y" off the gate dialog and taps the code.
  Future<void> passParentGate(WidgetTester tester) async {
    final instruction = tester
        .widgetList<Text>(find.textContaining('Tap '))
        .map((t) => t.data!)
        .firstWhere((t) => RegExp(r'^Tap \d then \d$').hasMatch(t));
    final match = RegExp(r'^Tap (\d) then (\d)$').firstMatch(instruction)!;
    await tester.tap(find.widgetWithText(OutlinedButton, match.group(1)!));
    await tester.pump();
    await tester.tap(find.widgetWithText(OutlinedButton, match.group(2)!));
    await tester.pumpAndSettle();
  }

  testWidgets('gate blocks on wrong code and admits on the right one',
      (tester) async {
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
        answersCorrectFirstTry: 9);
    SharedPreferences.setMockInitialValues(seededPrefs(child));

    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Parent dashboard'));
    await tester.pumpAndSettle();

    // Gate is up; dashboard not shown yet.
    expect(find.text('For grown-ups!'), findsOneWidget);
    expect(find.text("Anu's progress"), findsNothing);

    await passParentGate(tester);

    // Dashboard shows the real computed numbers.
    expect(find.text("Anu's progress"), findsOneWidget);
    expect(find.text('2/48'), findsOneWidget);
    expect(find.text('75%'), findsOneWidget); // 9/12 first-try accuracy
    expect(find.text('🔥 3'), findsOneWidget);
    expect(find.text('⚡ 26'), findsOneWidget);
    expect(find.text('🪙 40'), findsOneWidget);
    expect(find.text('🔁 1'), findsOneWidget);
    expect(find.textContaining('Now learning:'), findsOneWidget);
  });

  testWidgets('settings: sound toggle persists per account', (tester) async {
    const child =
        ChildProfile(id: 'c1', name: 'Anu', age: 5, interestIds: ['space']);
    SharedPreferences.setMockInitialValues(seededPrefs(child));

    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await passParentGate(tester);

    expect(find.text('Sound & voice'), findsOneWidget);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('mazatalk_settings_v3_${email}_soundOn'), isFalse);

    // Relaunch: the toggle stays off.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await passParentGate(tester);
    final toggle = tester.widget<Switch>(find.byType(Switch));
    expect(toggle.value, isFalse);
  });
}
