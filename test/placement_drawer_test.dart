import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mazatalk/features/profile/domain/child_profile.dart';
import 'package:mazatalk/main.dart';

/// The side menu on the post-signup test screens, driven through the real
/// app (router + auth) so logging out really has to work end to end.
void main() {
  const email = 'a@b.com';

  Future<void> launchSignedIn(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const child = ChildProfile(
      id: 'c1',
      name: 'Anu',
      age: 5,
      interestIds: ['dinosaurs', 'space', 'ocean'],
      placementCompleted: true,
      placementCoreScore: 60,
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
    // Signed-in + a selected child lands on the assessment summary.
    expect(find.byKey(const Key('placement_menu_button')), findsOneWidget);
  }

  Future<void> openMenu(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('placement_menu_button')));
    await tester.pumpAndSettle();
  }

  testWidgets('Гарах asks to confirm, then logs out to the welcome screen', (
    tester,
  ) async {
    await launchSignedIn(tester);
    await openMenu(tester);

    await tester.tap(find.text('Гарах'));
    await tester.pumpAndSettle();
    expect(find.text('Гарах уу?'), findsOneWidget); // the confirm dialog

    // Confirm (the dialog's own red «Гарах», not the menu's).
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Гарах'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Maza Talk'), findsOneWidget); // welcome screen
    expect(find.byKey(const Key('placement_menu_button')), findsNothing);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('mazatalk_auth_session_v3'), isNull);
  });

  testWidgets('Болих keeps you signed in', (tester) async {
    await launchSignedIn(tester);
    await openMenu(tester);

    await tester.tap(find.text('Гарах'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Болих'));
    await tester.pumpAndSettle();

    expect(find.text('Гарах уу?'), findsNothing);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('mazatalk_auth_session_v3'), email);
  });

  testWidgets('Бүртгэл солих logs out and lands on the login screen', (
    tester,
  ) async {
    await launchSignedIn(tester);
    await openMenu(tester);

    await tester.tap(find.text('Бүртгэл солих'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('placement_menu_button')), findsNothing);
    expect(find.text('Нэвтрэх'), findsWidgets); // login screen title
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('mazatalk_auth_session_v3'), isNull);
  });

  testWidgets('Хүүхэд солих goes to the child picker', (tester) async {
    await launchSignedIn(tester);
    await openMenu(tester);

    await tester.tap(find.text('Хүүхэд солих'));
    await tester.pumpAndSettle();

    expect(find.text('Хүүхдээ сонгоно уу'), findsOneWidget);
  });
}
