import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../profile/application/child_controller.dart';
import '../../profile/domain/child_profile.dart';
import '../application/playground_session_controller.dart';
import '../domain/placement_result.dart';
import 'levels/copy_the_pattern_level.dart';
import 'levels/count_the_friends_level.dart';
import 'levels/find_the_ball_level.dart';
import 'levels/find_the_letter_level.dart';
import 'levels/how_do_they_feel_level.dart';
import 'levels/match_the_shape_level.dart';
import 'levels/memory_match_level.dart';
import 'levels/pick_favorites_level.dart';
import 'levels/repeat_after_me_level.dart';
import 'levels/tap_the_color_level.dart';

/// The placement playground shell (PROJECT_V4.md §5): a dot-progress header
/// over whichever of the 10 levels is current, hosted through
/// [PlaygroundSessionController]. Two entry modes:
/// - **New child** (`name`/`age` passed via route `extra`, from
///   `ChildProfileScreen` → `HandoffScreen`): on completion, builds and
///   adds the child with placement already applied.
/// - **Redo** (no `name`/`age` — Settings → "Redo the playground" for the
///   already-selected child): on completion, overwrites that child's
///   placement via `reapplyPlacement`.
///
/// The session provider must already be fresh when this screen is pushed —
/// its caller invalidates it (`HandoffScreen`, `SettingsScreen`) from a
/// button handler, not this widget from `initState`/`build`, since
/// `ref.invalidate` needs the provider scope those lifecycle methods can't
/// reach yet.
class PlaygroundScreen extends ConsumerStatefulWidget {
  final String? name;
  final int? age;

  const PlaygroundScreen({super.key, this.name, this.age});

  @override
  ConsumerState<PlaygroundScreen> createState() => _PlaygroundScreenState();
}

class _PlaygroundScreenState extends ConsumerState<PlaygroundScreen> {
  late final int _seed;
  bool _handledCompletion = false;

  @override
  void initState() {
    super.initState();
    _seed = DateTime.now().millisecondsSinceEpoch;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(playgroundSessionControllerProvider);

    if (state.isComplete && state.result != null) {
      if (!_handledCompletion) {
        _handledCompletion = true;
        final result = state.result!;
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _finishPlayground(result));
      }
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DotProgress(
                current: state.currentIndex,
                total: PlaygroundLevelId.order.length,
              ),
              const SizedBox(height: 24),
              Expanded(child: _buildLevel(state.currentLevelId)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevel(String levelId) {
    void onComplete(PlaygroundLevelOutcome outcome) {
      ref
          .read(playgroundSessionControllerProvider.notifier)
          .completeCurrentLevel(outcome);
    }

    switch (levelId) {
      case PlaygroundLevelId.findTheBall:
        return FindTheBallLevel(seed: _seed, onComplete: onComplete);
      case PlaygroundLevelId.repeatAfterMe:
        return RepeatAfterMeLevel(onComplete: onComplete);
      case PlaygroundLevelId.tapTheColor:
        return TapTheColorLevel(seed: _seed, onComplete: onComplete);
      case PlaygroundLevelId.countTheFriends:
        return CountTheFriendsLevel(seed: _seed, onComplete: onComplete);
      case PlaygroundLevelId.findTheLetter:
        return FindTheLetterLevel(seed: _seed, onComplete: onComplete);
      case PlaygroundLevelId.matchTheShape:
        return MatchTheShapeLevel(seed: _seed, onComplete: onComplete);
      case PlaygroundLevelId.pickFavorites:
        return PickFavoritesLevel(seed: _seed, onComplete: onComplete);
      case PlaygroundLevelId.howDoTheyFeel:
        return HowDoTheyFeelLevel(onComplete: onComplete);
      case PlaygroundLevelId.memoryMatch:
        return MemoryMatchLevel(seed: _seed, onComplete: onComplete);
      case PlaygroundLevelId.copyThePattern:
        return CopyThePatternLevel(seed: _seed, onComplete: onComplete);
    }
    throw StateError('Unknown playground level: $levelId');
  }

  Future<void> _finishPlayground(PlacementResult result) async {
    final controller = ref.read(childControllerProvider.notifier);
    final name = widget.name;
    final age = widget.age;

    if (name != null && age != null) {
      await controller.addChild(ChildProfile(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        age: age,
        interestIds: result.interestIds,
        completedLessonIds: result.placedLessonIds,
        placedLessonIds: result.placedLessonIds,
        placementCompleted: true,
        placementCoreScore: result.coreScore,
        verbalComfort: result.verbalComfort,
        shapeAwareness: result.shapeAwareness,
        emotionAwareness: result.emotionAwareness,
        readyForMultiStep: result.readyForMultiStep,
      ));
    } else {
      final child = ref.read(childControllerProvider).selectedChild;
      if (child != null) {
        await controller.reapplyPlacement(child.id, result);
      }
    }

    if (!mounted) return;
    context.go('/home');
  }
}

class _DotProgress extends StatelessWidget {
  final int current;
  final int total;

  const _DotProgress({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < current ? Colors.black : Colors.grey.shade300,
            ),
          ),
        ],
      ],
    );
  }
}
