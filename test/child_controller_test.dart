import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mazatalk/features/profile/application/child_controller.dart';
import 'package:mazatalk/features/profile/data/local_child_repository.dart';
import 'package:mazatalk/features/profile/domain/child_profile.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  /// Children are account-scoped, so tests run against a signed-in
  /// repository and wait for the controller's initial load to settle
  /// before mutating state.
  Future<(ProviderContainer, ChildController)> makeController() async {
    final container = ProviderContainer(
      overrides: [
        childRepositoryProvider.overrideWithValue(
          const LocalChildRepository(accountId: 'test@example.com'),
        ),
      ],
    );
    final controller = container.read(childControllerProvider.notifier);
    while (container.read(childControllerProvider).isLoading) {
      await Future<void>.delayed(Duration.zero);
    }
    return (container, controller);
  }

  test('completeLesson pays coins once and is idempotent on replay', () async {
    final (container, controller) = await makeController();
    addTearDown(container.dispose);

    await controller.addChild(
      const ChildProfile(id: 'c1', name: 'Test', age: 5),
    );

    await controller.completeLesson('c1', 'lesson_dinosaurs', coinReward: 20);
    var child = container.read(childControllerProvider).selectedChild!;
    expect(child.coins, 20);
    expect(child.completedLessonIds, ['lesson_dinosaurs']);

    // Replaying the same lesson must not double-pay.
    await controller.completeLesson('c1', 'lesson_dinosaurs', coinReward: 20);
    child = container.read(childControllerProvider).selectedChild!;
    expect(child.coins, 20);
    expect(child.completedLessonIds.length, 1);
  });

  test('updateCheckpoint persists the resume position', () async {
    final (container, controller) = await makeController();
    addTearDown(container.dispose);

    await controller.addChild(
      const ChildProfile(id: 'c1', name: 'Test', age: 5),
    );
    await controller.updateCheckpoint(
      'c1',
      lessonId: 'lesson_space',
      checkpoint: 2,
    );

    final child = container.read(childControllerProvider).selectedChild!;
    expect(child.currentLessonId, 'lesson_space');
    expect(child.currentCheckpoint, 2);
  });

  test(
    'purchaseSkin fails without enough coins and succeeds after earning them',
    () async {
      final (container, controller) = await makeController();
      addTearDown(container.dispose);

      await controller.addChild(
        const ChildProfile(id: 'c1', name: 'Test', age: 5),
      );

      final tooSoon = await controller.purchaseSkin('c1', 'panda');
      expect(tooSoon, isFalse);

      await controller.addCoins('c1', 50);
      final success = await controller.purchaseSkin('c1', 'panda');
      expect(success, isTrue);

      final child = container.read(childControllerProvider).selectedChild!;
      expect(child.equippedSkinId, 'panda');
      expect(child.unlockedSkinIds, contains('panda'));
    },
  );

  test(
    'daily streak: same day holds, next day increments, gap resets',
    () async {
      final (container, controller) = await makeController();
      addTearDown(container.dispose);
      await controller.addChild(
        const ChildProfile(id: 'c1', name: 'T', age: 5),
      );

      Future<void> record(DateTime now) => controller.recordLessonResults(
        'c1',
        xp: 10,
        answersTotal: 5,
        answersCorrectFirstTry: 5,
        now: now,
      );
      ChildProfile child() =>
          container.read(childControllerProvider).selectedChild!;

      await record(DateTime(2026, 7, 1, 9));
      expect(child().dailyStreak, 1);
      await record(DateTime(2026, 7, 1, 18)); // same day → unchanged
      expect(child().dailyStreak, 1);
      await record(DateTime(2026, 7, 2, 8)); // next day → +1
      expect(child().dailyStreak, 2);
      await record(DateTime(2026, 7, 3, 8));
      expect(child().dailyStreak, 3);
      await record(DateTime(2026, 7, 10, 8)); // gap → reset to 1
      expect(child().dailyStreak, 1);
    },
  );

  test(
    'recordLessonResults accumulates xp/accuracy and dedupes mistakes',
    () async {
      final (container, controller) = await makeController();
      addTearDown(container.dispose);
      await controller.addChild(
        const ChildProfile(id: 'c1', name: 'T', age: 5),
      );

      await controller.recordLessonResults(
        'c1',
        xp: 14,
        answersTotal: 5,
        answersCorrectFirstTry: 4,
        mistakes: ['u1l1:0'],
      );
      await controller.recordLessonResults(
        'c1',
        xp: 12,
        answersTotal: 6,
        answersCorrectFirstTry: 2,
        mistakes: ['u1l1:0', 'u1l2:3'],
      );

      final child = container.read(childControllerProvider).selectedChild!;
      expect(child.xp, 26);
      expect(child.answersTotal, 11);
      expect(child.answersCorrectFirstTry, 6);
      expect(child.mistakeBank, ['u1l1:0', 'u1l2:3']);

      await controller.removeMistakes('c1', ['u1l1:0']);
      expect(
        container.read(childControllerProvider).selectedChild!.mistakeBank,
        ['u1l2:3'],
      );
    },
  );

  test('account switch swaps to the new account\'s children', () async {
    // Simulate two accounts by pre-seeding storage for account A only.
    const repoA = LocalChildRepository(accountId: 'a@b.com');
    await repoA.saveChildren([
      const ChildProfile(id: 'a1', name: 'AnnasKid', age: 6),
    ]);

    final containerA = ProviderContainer(
      overrides: [childRepositoryProvider.overrideWithValue(repoA)],
    );
    addTearDown(containerA.dispose);
    containerA.read(childControllerProvider.notifier);
    while (containerA.read(childControllerProvider).isLoading) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(
      containerA.read(childControllerProvider).children.map((c) => c.name),
      ['AnnasKid'],
    );

    final containerB = ProviderContainer(
      overrides: [
        childRepositoryProvider.overrideWithValue(
          const LocalChildRepository(accountId: 'b@c.com'),
        ),
      ],
    );
    addTearDown(containerB.dispose);
    containerB.read(childControllerProvider.notifier);
    while (containerB.read(childControllerProvider).isLoading) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(containerB.read(childControllerProvider).children, isEmpty);
  });
}
