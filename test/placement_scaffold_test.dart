import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazatalk/features/placement/domain/placement_result.dart';
import 'package:mazatalk/features/placement/domain/playground_acts.dart';
import 'package:mazatalk/features/placement/presentation/duo_progress_bar.dart';
import 'package:mazatalk/features/placement/presentation/playground_screen.dart';

Future<void> _pumpPlayground(WidgetTester tester) async {
  await tester.pumpWidget(
    const ProviderScope(
      child: MaterialApp(home: PlaygroundScreen(name: 'Анужин', age: 4)),
    ),
  );
  await tester.pump();
}

void main() {
  test('the 9 levels split into 3 acts of 3, in play order', () {
    expect(PlaygroundLevelId.order.length, 9);
    expect(playgroundActs.length, 3);
    expect(
      playgroundActs.expand((a) => a.levelIds).toList(),
      PlaygroundLevelId.order,
    );
    for (final act in playgroundActs) {
      expect(act.levelIds.length, 3);
    }
  });

  testWidgets('playground opens on an act intro; nothing starts by itself', (
    tester,
  ) async {
    await _pumpPlayground(tester);

    expect(find.text('Бүлэг 1'), findsOneWidget);
    expect(find.text('Тал нутаг'), findsOneWidget);
    expect(find.byKey(const Key('placement_ball')), findsNothing);

    // No auto-advance: minutes later we're still on the intro.
    await tester.pump(const Duration(minutes: 5));
    expect(find.byKey(const Key('act_intro_go')), findsOneWidget);

    await tester.tap(find.byKey(const Key('act_intro_go')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('placement_ball')), findsOneWidget);
    expect(find.byKey(const Key('act_intro_go')), findsNothing);
  });

  testWidgets('progress bar shows 3 act stops and Maza riding it', (
    tester,
  ) async {
    await _pumpPlayground(tester);

    expect(find.byType(DuoProgressBar), findsOneWidget);
    for (var i = 1; i <= 3; i++) {
      expect(find.byKey(Key('progress_stop_$i')), findsOneWidget);
    }
    expect(find.byKey(const Key('progress_maza')), findsOneWidget);
  });

  testWidgets('hamburger is top-left and opens the account menu', (
    tester,
  ) async {
    await _pumpPlayground(tester);

    final menu = find.byKey(const Key('placement_menu_button'));
    expect(menu, findsOneWidget);
    expect(tester.getTopLeft(menu).dx, lessThan(60));
    await tester.tap(menu);
    await tester.pumpAndSettle();

    expect(find.text('Анужин'), findsOneWidget);
    expect(find.text('4 настай'), findsOneWidget);
    expect(find.text('Хүүхэд солих'), findsOneWidget);
    expect(find.text('Бүртгэл солих'), findsOneWidget);
    expect(find.text('Гарах'), findsOneWidget);
  });
}
