/// What one playground level reports when it finishes (PROJECT_V4.md §5) —
/// every level always reports something, there is no failure case, only a
/// varying [points] score (0–10).
class PlaygroundLevelOutcome {
  final int points;
  final bool timedOut;

  /// Level-specific extra data: `List<String>` interest ids from Pick Your
  /// Favorites, `bool` (readyForMultiStep) from Copy the Pattern, etc.
  final Object? payload;

  const PlaygroundLevelOutcome(
    this.points, {
    this.timedOut = false,
    this.payload,
  });
}

typedef PlaygroundLevelComplete = void Function(PlaygroundLevelOutcome outcome);

/// Ids for the 9 playground levels, in play order (Memory Match was cut —
/// Copy the Pattern already probes working memory and now supplies
/// `readyForMultiStep`).
class PlaygroundLevelId {
  static const findTheBall = 'find_the_ball';
  static const repeatAfterMe = 'repeat_after_me';
  static const tapTheColor = 'tap_the_color';
  static const countTheFriends = 'count_the_friends';
  static const findTheLetter = 'find_the_letter';
  static const matchTheShape = 'match_the_shape';
  static const pickFavorites = 'pick_favorites';
  static const howDoTheyFeel = 'how_do_they_feel';
  static const copyThePattern = 'copy_the_pattern';

  static const order = [
    findTheBall,
    repeatAfterMe,
    tapTheColor,
    countTheFriends,
    findTheLetter,
    matchTheShape,
    pickFavorites,
    howDoTheyFeel,
    copyThePattern,
  ];
}

/// The five levels that map directly onto Unit 1's own skills (PROJECT_V4.md
/// §7.1) — these, and only these, decide the starting lesson. The rest
/// (repeat-after-me, shapes, interests, emotions) are recorded as
/// supplementary signals and never move the start point.
const corePlacementLevelIds = [
  PlaygroundLevelId.findTheBall,
  PlaygroundLevelId.tapTheColor,
  PlaygroundLevelId.countTheFriends,
  PlaygroundLevelId.findTheLetter,
  PlaygroundLevelId.copyThePattern,
];

/// Unit 1's lesson ids that placement is allowed to start a child at
/// (`lib/features/curriculum/data/units/unit_1.dart`). Deliberately excludes
/// `u1l7`/`u1l8` (Unit 1's counting-catchup and review lessons) — placement
/// never auto-skips the lessons that exist to catch gaps (PROJECT_V4.md §7.2).
const unit1PlaceableLessonIds = [
  'u1l1',
  'u1l2',
  'u1l3',
  'u1l4',
  'u1l5',
  'u1l6',
];

/// Core score (0–100) → starting lesson, per the bucket table in
/// PROJECT_V4.md §7.2.
String startingLessonIdForCoreScore(int coreScore) {
  if (coreScore <= 20) return unit1PlaceableLessonIds[0];
  if (coreScore <= 40) return unit1PlaceableLessonIds[1];
  if (coreScore <= 55) return unit1PlaceableLessonIds[2];
  if (coreScore <= 70) return unit1PlaceableLessonIds[3];
  if (coreScore <= 85) return unit1PlaceableLessonIds[4];
  return unit1PlaceableLessonIds[5];
}

/// What the playground produced: where to start the child in Unit 1, plus
/// the supplementary signals gathered along the way. Never crosses into
/// Unit 2 or skips Unit 1's review lessons (PROJECT_V4.md §7.2).
class PlacementResult {
  /// 0–100, normalized sum of the 5 core levels.
  final int coreScore;

  /// Lessons before [startingLessonId] — credited with 0 XP/coins and
  /// flagged distinctly on the Path screen, never actually played.
  final List<String> placedLessonIds;

  final String startingLessonId;

  final List<String> interestIds;

  /// 0–10 from Repeat After Me; null if that level never ran (skip path).
  final int? verbalComfort;

  /// 0–10 from Match the Shape.
  final int? shapeAwareness;

  /// 0–10 from How Do They Feel.
  final int? emotionAwareness;

  /// From Copy the Pattern: whether the child repeated the 3-step pattern
  /// (even on the retry).
  final bool? readyForMultiStep;

  const PlacementResult({
    required this.coreScore,
    required this.placedLessonIds,
    required this.startingLessonId,
    required this.interestIds,
    this.verbalComfort,
    this.shapeAwareness,
    this.emotionAwareness,
    this.readyForMultiStep,
  });

  /// The handoff screen's "Skip playing" link (PROJECT_V4.md §3, §9): start
  /// at Lesson 1 exactly like a pre-V4 child, no supplementary signals.
  /// [interestIds] should already be backfilled by the caller so theming
  /// still has something to cycle through.
  factory PlacementResult.skipped({required List<String> interestIds}) {
    return PlacementResult(
      coreScore: 0,
      placedLessonIds: const [],
      startingLessonId: unit1PlaceableLessonIds.first,
      interestIds: interestIds,
    );
  }

  /// Computes placement from the 10 levels' scores (PROJECT_V4.md §7).
  factory PlacementResult.fromLevelScores({
    required Map<String, int> levelScores,
    required List<String> interestIds,
    int? verbalComfort,
    int? shapeAwareness,
    int? emotionAwareness,
    bool? readyForMultiStep,
  }) {
    final coreSum = corePlacementLevelIds
        .map((id) => levelScores[id] ?? 0)
        .fold<int>(0, (sum, score) => sum + score);
    final maxCoreSum = corePlacementLevelIds.length * 10;
    final coreScore = ((coreSum * 100) / maxCoreSum).round().clamp(0, 100);

    final startingLessonId = startingLessonIdForCoreScore(coreScore);
    final startingIndex = unit1PlaceableLessonIds.indexOf(startingLessonId);
    final placedLessonIds = unit1PlaceableLessonIds.sublist(0, startingIndex);

    return PlacementResult(
      coreScore: coreScore,
      placedLessonIds: placedLessonIds,
      startingLessonId: startingLessonId,
      interestIds: interestIds,
      verbalComfort: verbalComfort,
      shapeAwareness: shapeAwareness,
      emotionAwareness: emotionAwareness,
      readyForMultiStep: readyForMultiStep,
    );
  }
}
