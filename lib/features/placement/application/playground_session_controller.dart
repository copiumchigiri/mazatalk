import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/placement_result.dart';

/// Default per-level timeout (PROJECT_V4.md §5 rule #3). Levels 7 (Pick
/// Your Favorites) and 9 (Memory Match) use [kPlaygroundExtendedLevelTimeout]
/// instead since they're inherently multi-step.
const kPlaygroundDefaultLevelTimeout = Duration(seconds: 12);
const kPlaygroundExtendedLevelTimeout = Duration(seconds: 20);

class PlaygroundSessionState {
  final int currentIndex;
  final Map<String, int> scores;
  final Map<String, Object?> payloads;
  final bool isComplete;
  final PlacementResult? result;

  const PlaygroundSessionState({
    this.currentIndex = 0,
    this.scores = const {},
    this.payloads = const {},
    this.isComplete = false,
    this.result,
  });

  String get currentLevelId => PlaygroundLevelId.order[currentIndex];

  PlaygroundSessionState copyWith({
    int? currentIndex,
    Map<String, int>? scores,
    Map<String, Object?>? payloads,
    bool? isComplete,
    PlacementResult? result,
  }) {
    return PlaygroundSessionState(
      currentIndex: currentIndex ?? this.currentIndex,
      scores: scores ?? this.scores,
      payloads: payloads ?? this.payloads,
      isComplete: isComplete ?? this.isComplete,
      result: result ?? this.result,
    );
  }
}

/// Owns the 10-level session: which level is showing, each level's score
/// and payload, and — once the 10th completes — the computed
/// [PlacementResult] (PROJECT_V4.md §5, §7). One instance per playground
/// visit; the screen that creates it is responsible for invalidating it
/// (via `ref.invalidate`) before a "redo" run.
class PlaygroundSessionController extends Notifier<PlaygroundSessionState> {
  @override
  PlaygroundSessionState build() => const PlaygroundSessionState();

  void completeCurrentLevel(PlaygroundLevelOutcome outcome) {
    final current = state;
    if (current.isComplete) return;

    final levelId = current.currentLevelId;
    final scores = {...current.scores, levelId: outcome.points};
    final payloads = {...current.payloads, levelId: outcome.payload};
    final nextIndex = current.currentIndex + 1;

    if (nextIndex >= PlaygroundLevelId.order.length) {
      state = current.copyWith(
        scores: scores,
        payloads: payloads,
        isComplete: true,
        result: _computeResult(scores, payloads),
      );
    } else {
      state = current.copyWith(
        currentIndex: nextIndex,
        scores: scores,
        payloads: payloads,
      );
    }
  }

  PlacementResult _computeResult(
    Map<String, int> scores,
    Map<String, Object?> payloads,
  ) {
    final interestIds =
        (payloads[PlaygroundLevelId.pickFavorites] as List<String>?) ??
            const [];
    return PlacementResult.fromLevelScores(
      levelScores: scores,
      interestIds: interestIds,
      verbalComfort: scores[PlaygroundLevelId.repeatAfterMe],
      shapeAwareness: scores[PlaygroundLevelId.matchTheShape],
      emotionAwareness: scores[PlaygroundLevelId.howDoTheyFeel],
      readyForMultiStep: payloads[PlaygroundLevelId.memoryMatch] as bool?,
    );
  }
}

final playgroundSessionControllerProvider = NotifierProvider<
    PlaygroundSessionController, PlaygroundSessionState>(
  PlaygroundSessionController.new,
);
