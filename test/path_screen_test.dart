import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mazatalk/features/profile/domain/child_profile.dart';
import 'package:mazatalk/main.dart';

/// A signed-in child now lands on the assessment-summary screen by default
/// (PROJECT context: no more Duolingo-style home screen) — these tests
/// target the curriculum path screen directly, so jump there explicitly.
Future<void> goHome(WidgetTester tester) async {
  GoRouter.of(tester.element(find.byType(Scaffold))).go('/home');
  await tester.pumpAndSettle();
}

/// Path screen behavior with a mid-course child: node states, locked-node
/// guard, chest opening, and entering the current lesson.
void main() {
  const email = 'a@b.com';

  Map<String, Object> seededPrefs(ChildProfile child) => {
    'mazatalk_auth_accounts_v3': jsonEncode({
      email: {'parentName': 'parent'},
    }),
    'mazatalk_auth_session_v3': email,
    'mazatalk_children_v3_$email': jsonEncode([child.toJson()]),
  };

  testWidgets('mid-course child sees states, opens chest, starts lesson', (
    tester,
  ) async {
    // 4 lessons done → chest_4 reached, u1l5 ("Colors") is current.
    const child = ChildProfile(
      id: 'c1',
      name: 'Anu',
      age: 5,
      interestIds: ['dinosaurs'],
      completedLessonIds: ['u1l1', 'u1l2', 'u1l3', 'u1l4'],
      coins: 10,
    );
    SharedPreferences.setMockInitialValues(seededPrefs(child));

    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();
    await goHome(tester);

    // Landed on the path screen, START on the current lesson.
    expect(find.text('ЭХЛЭХ'), findsOneWidget);
    expect(find.text('Colors'), findsOneWidget);

    // Tapping a locked lesson shows the guard snackbar, no navigation.
    await tester.tap(find.text('Letter E & review'));
    await tester.pump();
    expect(find.text('Өмнөх хичээлээ эхлээд дуусга!'), findsOneWidget);
    await tester.pumpAndSettle();

    // The reached chest opens once and pays out.
    await tester.tap(find.text('Авдар'));
    await tester.pumpAndSettle();
    expect(find.text('🎁 Авдар нээгдлээ! +15 🪙'), findsOneWidget);
    expect(find.text('25'), findsOneWidget); // 10 + 15 coins in the stat bar
    await tester.pumpAndSettle();

    // Chest shows opened and cannot pay twice.
    expect(find.text('Нээсэн'), findsOneWidget);
    await tester.tap(find.text('Нээсэн'));
    await tester.pumpAndSettle();
    expect(find.text('25'), findsOneWidget);

    // START opens the current lesson in the player.
    await tester.tap(find.text('ЭХЛЭХ'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Tap the color'), findsOneWidget);
  });
}
