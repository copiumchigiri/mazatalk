import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mazatalk/core/services/speech_input_service.dart';
import 'package:mazatalk/features/placement/domain/placement_result.dart';
import 'package:mazatalk/features/profile/application/child_controller.dart';
import 'package:mazatalk/features/profile/data/local_child_repository.dart';
import 'package:mazatalk/features/profile/domain/child_profile.dart';

void main() {
  group('startingLessonIdForCoreScore bucket boundaries (PROJECT_V4.md §7.2)', () {
    final cases = {
      0: 'u1l1',
      20: 'u1l1',
      21: 'u1l2',
      40: 'u1l2',
      41: 'u1l3',
      55: 'u1l3',
      56: 'u1l4',
      70: 'u1l4',
      71: 'u1l5',
      85: 'u1l5',
      86: 'u1l6',
      100: 'u1l6',
    };
    cases.forEach((score, expected) {
      test('score $score -> $expected', () {
        expect(startingLessonIdForCoreScore(score), expected);
      });
    });
  });

  group('PlacementResult.fromLevelScores', () {
    test('core score is the sum of exactly the 5 core levels, normalized', () {
      // Core levels: findTheBall, tapTheColor, countTheFriends,
      // findTheLetter, copyThePattern — 5 x 10 = 50 max -> /100.
      final result = PlacementResult.fromLevelScores(
        levelScores: {
          PlaygroundLevelId.findTheBall: 10,
          PlaygroundLevelId.tapTheColor: 10,
          PlaygroundLevelId.countTheFriends: 10,
          PlaygroundLevelId.findTheLetter: 10,
          PlaygroundLevelId.copyThePattern: 10,
          // Non-core levels must never affect the core score.
          PlaygroundLevelId.repeatAfterMe: 0,
          PlaygroundLevelId.matchTheShape: 0,
          PlaygroundLevelId.howDoTheyFeel: 0,
        },
        interestIds: const ['dinosaurs'],
      );
      expect(result.coreScore, 100);
      expect(result.startingLessonId, 'u1l6');
      expect(result.placedLessonIds, ['u1l1', 'u1l2', 'u1l3', 'u1l4', 'u1l5']);
    });

    test('an entirely non-responsive session still reaches the lowest bucket', () {
      // The floor score for every core level's timeout is 2 (never 0, but
      // low enough that 5 x 2 = 10 -> 20%, landing in the 0-20 bucket).
      final result = PlacementResult.fromLevelScores(
        levelScores: {
          PlaygroundLevelId.findTheBall: 2,
          PlaygroundLevelId.tapTheColor: 2,
          PlaygroundLevelId.countTheFriends: 2,
          PlaygroundLevelId.findTheLetter: 2,
          PlaygroundLevelId.copyThePattern: 2,
        },
        interestIds: const ['dinosaurs'],
      );
      expect(result.coreScore, 20);
      expect(result.startingLessonId, 'u1l1');
      expect(result.placedLessonIds, isEmpty);
    });

    test('missing core level scores count as zero, not an error', () {
      final result = PlacementResult.fromLevelScores(
        levelScores: const {},
        interestIds: const ['dinosaurs'],
      );
      expect(result.coreScore, 0);
      expect(result.startingLessonId, 'u1l1');
    });

    test('supplementary signals pass through untouched', () {
      final result = PlacementResult.fromLevelScores(
        levelScores: const {},
        interestIds: const ['space'],
        verbalComfort: 6,
        shapeAwareness: 10,
        emotionAwareness: 10,
        readyForMultiStep: true,
      );
      expect(result.verbalComfort, 6);
      expect(result.shapeAwareness, 10);
      expect(result.emotionAwareness, 10);
      expect(result.readyForMultiStep, isTrue);
    });
  });

  test('PlacementResult.skipped starts at Lesson 1 with no signals', () {
    final result = PlacementResult.skipped(interestIds: const ['ocean']);
    expect(result.coreScore, 0);
    expect(result.startingLessonId, 'u1l1');
    expect(result.placedLessonIds, isEmpty);
    expect(result.verbalComfort, isNull);
    expect(result.interestIds, ['ocean']);
  });

  group('ChildController placement integration', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    Future<(ProviderContainer, ChildController)> makeController() async {
      final container = ProviderContainer(overrides: [
        childRepositoryProvider.overrideWithValue(
          const LocalChildRepository(accountId: 'test@example.com'),
        ),
      ]);
      final controller = container.read(childControllerProvider.notifier);
      while (container.read(childControllerProvider).isLoading) {
        await Future<void>.delayed(Duration.zero);
      }
      return (container, controller);
    }

    test('reapplyPlacement credits placed lessons at 0 XP/0 coins', () async {
      final (container, controller) = await makeController();
      addTearDown(container.dispose);
      await controller.addChild(const ChildProfile(id: 'c1', name: 'T', age: 5));

      final result = PlacementResult.fromLevelScores(
        levelScores: {
          PlaygroundLevelId.findTheBall: 10,
          PlaygroundLevelId.tapTheColor: 10,
          PlaygroundLevelId.countTheFriends: 10,
          PlaygroundLevelId.findTheLetter: 6,
          PlaygroundLevelId.copyThePattern: 6,
        },
        interestIds: const ['dinosaurs', 'space', 'ocean'],
      );
      await controller.reapplyPlacement('c1', result);

      final child = container.read(childControllerProvider).selectedChild!;
      expect(child.coins, 0);
      expect(child.xp, 0);
      expect(child.placementCompleted, isTrue);
      expect(child.placementCoreScore, result.coreScore);
      expect(child.placedLessonIds, result.placedLessonIds);
      expect(child.completedLessonIds, result.placedLessonIds);
      expect(child.interestIds, ['dinosaurs', 'space', 'ocean']);
    });

    test(
        'a placed lesson later actually played never double-pays (completeLesson guard)',
        () async {
      final (container, controller) = await makeController();
      addTearDown(container.dispose);
      await controller.addChild(const ChildProfile(id: 'c1', name: 'T', age: 5));
      await controller.reapplyPlacement(
        'c1',
        PlacementResult.fromLevelScores(
          levelScores: const {
            PlaygroundLevelId.findTheBall: 10,
            PlaygroundLevelId.tapTheColor: 10,
            PlaygroundLevelId.countTheFriends: 10,
            PlaygroundLevelId.findTheLetter: 10,
            PlaygroundLevelId.copyThePattern: 6,
          },
          interestIds: const ['dinosaurs'],
        ),
      );
      var child = container.read(childControllerProvider).selectedChild!;
      expect(child.placedLessonIds, isNotEmpty);
      final placedLessonId = child.placedLessonIds.first;

      // Replaying a placed lesson for real must not pay out again.
      await controller.completeLesson('c1', placedLessonId, coinReward: 20);
      child = container.read(childControllerProvider).selectedChild!;
      expect(child.coins, 0);
      expect(
        child.completedLessonIds.where((id) => id == placedLessonId).length,
        1,
      );
    });

    test('reapplyPlacement never un-credits real progress (monotonic)',
        () async {
      final (container, controller) = await makeController();
      addTearDown(container.dispose);
      await controller.addChild(const ChildProfile(id: 'c1', name: 'T', age: 5));

      // Child actually plays and completes u1l1..u1l4 for real (real coins).
      for (final id in ['u1l1', 'u1l2', 'u1l3', 'u1l4']) {
        await controller.completeLesson('c1', id, coinReward: 20);
      }
      var child = container.read(childControllerProvider).selectedChild!;
      expect(child.coins, 80);
      expect(child.placedLessonIds, isEmpty); // none of these were "placed"

      // A redo comes back with a much lower score than actual progress.
      await controller.reapplyPlacement(
        'c1',
        PlacementResult.fromLevelScores(
          levelScores: const {
            PlaygroundLevelId.findTheBall: 2,
            PlaygroundLevelId.tapTheColor: 2,
            PlaygroundLevelId.countTheFriends: 2,
            PlaygroundLevelId.findTheLetter: 2,
            PlaygroundLevelId.copyThePattern: 2,
          },
          interestIds: const ['space'],
        ),
      );

      child = container.read(childControllerProvider).selectedChild!;
      // Real progress and its coin payout are untouched.
      expect(child.coins, 80);
      expect(child.completedLessonIds,
          containsAll(['u1l1', 'u1l2', 'u1l3', 'u1l4']));
      // The low-score redo's placement bucket (Lesson 1, nothing placed)
      // adds nothing new — it never un-credits lessons already complete.
      expect(child.placedLessonIds, isEmpty);
      // Interests still overwrite, per §7.3 ("Redo... overwrites the prior
      // placement").
      expect(child.interestIds, ['space']);
    });

    test('resetPlacementToLessonOne clears only placed lessons', () async {
      final (container, controller) = await makeController();
      addTearDown(container.dispose);
      await controller.addChild(const ChildProfile(id: 'c1', name: 'T', age: 5));

      await controller.reapplyPlacement(
        'c1',
        PlacementResult.fromLevelScores(
          levelScores: const {
            PlaygroundLevelId.findTheBall: 10,
            PlaygroundLevelId.tapTheColor: 10,
            PlaygroundLevelId.countTheFriends: 10,
            PlaygroundLevelId.findTheLetter: 10,
            PlaygroundLevelId.copyThePattern: 10,
          },
          interestIds: const ['dinosaurs'],
        ),
      );
      // Placed at u1l6 -> u1l1..u1l5 auto-credited.
      var child = container.read(childControllerProvider).selectedChild!;
      expect(child.placedLessonIds.length, 5);

      // Child also really plays u1l6 for real (earns coins).
      await controller.completeLesson('c1', 'u1l6', coinReward: 20);
      child = container.read(childControllerProvider).selectedChild!;
      expect(child.coins, 20);

      await controller.resetPlacementToLessonOne('c1');
      child = container.read(childControllerProvider).selectedChild!;
      expect(child.placedLessonIds, isEmpty);
      // The placed lessons are gone from completedLessonIds...
      expect(child.completedLessonIds, ['u1l6']);
      // ...but the real completion and its coins are untouched.
      expect(child.coins, 20);
    });
  });

  group('SpeechInputService', () {
    test('degrades to unavailable instead of throwing with no platform channel',
        () async {
      final service = SpeechInputService();
      final attempt = await service.listenFor('ball',
          timeout: const Duration(milliseconds: 10));
      expect(attempt.result, SpeechAttemptResult.unavailable);
    });
  });
}
