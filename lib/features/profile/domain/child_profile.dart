import 'package:mazatalk/features/companion/domain/skin.dart';

/// A child's profile, including course progress used to resume exactly
/// where they left off on every app launch.
class ChildProfile {
  final String id;
  final String name;
  final int age;
  final List<String> interestIds;
  final List<String> disabilities;
  final bool preferNotToSay;
  final int coins;
  final String equippedSkinId;
  final List<String> unlockedSkinIds;
  final List<String> completedLessonIds;
  final String? currentLessonId;
  final int currentCheckpoint;

  // v3 progression/gamification. All default so v2 saves load unchanged.
  final int xp;
  final int dailyStreak;

  /// 'yyyy-MM-dd' of the last day a lesson was completed (streak math).
  final String? lastActiveDate;

  /// Activity fingerprints ('lessonId:activityIndex') answered wrong,
  /// consumed by Practice mode.
  final List<String> mistakeBank;

  final List<String> openedChestIds;

  /// Accuracy counters: first-try answers, total vs correct.
  final int answersTotal;
  final int answersCorrectFirstTry;

  // v4 placement playground (PROJECT_V4.md §8). All default so v3 saves
  // load unchanged; `placementCompleted` stays false until the playground
  // (or its skip link) runs once.
  final bool placementCompleted;

  /// 0–100, null until placement runs.
  final int? placementCoreScore;

  /// Lessons auto-credited by placement (0 XP/0 coins, distinct Path badge)
  /// rather than actually played — a subset of [completedLessonIds].
  final List<String> placedLessonIds;

  /// Supplementary placement signals — recorded for the parent dashboard
  /// only, never used to change the starting lesson (PROJECT_V4.md §7.1).
  final int? verbalComfort;
  final int? shapeAwareness;
  final int? emotionAwareness;
  final bool? readyForMultiStep;

  const ChildProfile({
    required this.id,
    required this.name,
    required this.age,
    this.interestIds = const [],
    this.disabilities = const [],
    this.preferNotToSay = false,
    this.coins = 0,
    this.equippedSkinId = SkinCatalog.defaultSkinId,
    this.unlockedSkinIds = const [SkinCatalog.defaultSkinId],
    this.completedLessonIds = const [],
    this.currentLessonId,
    this.currentCheckpoint = 0,
    this.xp = 0,
    this.dailyStreak = 0,
    this.lastActiveDate,
    this.mistakeBank = const [],
    this.openedChestIds = const [],
    this.answersTotal = 0,
    this.answersCorrectFirstTry = 0,
    this.placementCompleted = false,
    this.placementCoreScore,
    this.placedLessonIds = const [],
    this.verbalComfort,
    this.shapeAwareness,
    this.emotionAwareness,
    this.readyForMultiStep,
  });

  ChildProfile copyWith({
    List<String>? interestIds,
    int? coins,
    String? equippedSkinId,
    List<String>? unlockedSkinIds,
    List<String>? completedLessonIds,
    String? currentLessonId,
    int? currentCheckpoint,
    int? xp,
    int? dailyStreak,
    String? lastActiveDate,
    List<String>? mistakeBank,
    List<String>? openedChestIds,
    int? answersTotal,
    int? answersCorrectFirstTry,
    bool? placementCompleted,
    int? placementCoreScore,
    List<String>? placedLessonIds,
    int? verbalComfort,
    int? shapeAwareness,
    int? emotionAwareness,
    bool? readyForMultiStep,
  }) {
    return ChildProfile(
      id: id,
      name: name,
      age: age,
      interestIds: interestIds ?? this.interestIds,
      disabilities: disabilities,
      preferNotToSay: preferNotToSay,
      coins: coins ?? this.coins,
      equippedSkinId: equippedSkinId ?? this.equippedSkinId,
      unlockedSkinIds: unlockedSkinIds ?? this.unlockedSkinIds,
      completedLessonIds: completedLessonIds ?? this.completedLessonIds,
      currentLessonId: currentLessonId ?? this.currentLessonId,
      currentCheckpoint: currentCheckpoint ?? this.currentCheckpoint,
      xp: xp ?? this.xp,
      dailyStreak: dailyStreak ?? this.dailyStreak,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      mistakeBank: mistakeBank ?? this.mistakeBank,
      openedChestIds: openedChestIds ?? this.openedChestIds,
      answersTotal: answersTotal ?? this.answersTotal,
      answersCorrectFirstTry:
          answersCorrectFirstTry ?? this.answersCorrectFirstTry,
      placementCompleted: placementCompleted ?? this.placementCompleted,
      placementCoreScore: placementCoreScore ?? this.placementCoreScore,
      placedLessonIds: placedLessonIds ?? this.placedLessonIds,
      verbalComfort: verbalComfort ?? this.verbalComfort,
      shapeAwareness: shapeAwareness ?? this.shapeAwareness,
      emotionAwareness: emotionAwareness ?? this.emotionAwareness,
      readyForMultiStep: readyForMultiStep ?? this.readyForMultiStep,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'age': age,
        'interestIds': interestIds,
        'disabilities': disabilities,
        'preferNotToSay': preferNotToSay,
        'coins': coins,
        'equippedSkinId': equippedSkinId,
        'unlockedSkinIds': unlockedSkinIds,
        'completedLessonIds': completedLessonIds,
        'currentLessonId': currentLessonId,
        'currentCheckpoint': currentCheckpoint,
        'xp': xp,
        'dailyStreak': dailyStreak,
        'lastActiveDate': lastActiveDate,
        'mistakeBank': mistakeBank,
        'openedChestIds': openedChestIds,
        'answersTotal': answersTotal,
        'answersCorrectFirstTry': answersCorrectFirstTry,
        'placementCompleted': placementCompleted,
        'placementCoreScore': placementCoreScore,
        'placedLessonIds': placedLessonIds,
        'verbalComfort': verbalComfort,
        'shapeAwareness': shapeAwareness,
        'emotionAwareness': emotionAwareness,
        'readyForMultiStep': readyForMultiStep,
      };

  factory ChildProfile.fromJson(Map<String, dynamic> json) => ChildProfile(
        id: json['id'] as String,
        name: json['name'] as String,
        age: json['age'] as int,
        interestIds: (json['interestIds'] as List?)?.cast<String>() ?? const [],
        disabilities:
            (json['disabilities'] as List?)?.cast<String>() ?? const [],
        preferNotToSay: json['preferNotToSay'] as bool? ?? false,
        coins: json['coins'] as int? ?? 0,
        equippedSkinId:
            json['equippedSkinId'] as String? ?? SkinCatalog.defaultSkinId,
        unlockedSkinIds: (json['unlockedSkinIds'] as List?)?.cast<String>() ??
            const [SkinCatalog.defaultSkinId],
        completedLessonIds:
            (json['completedLessonIds'] as List?)?.cast<String>() ?? const [],
        currentLessonId: json['currentLessonId'] as String?,
        currentCheckpoint: json['currentCheckpoint'] as int? ?? 0,
        xp: json['xp'] as int? ?? 0,
        dailyStreak: json['dailyStreak'] as int? ?? 0,
        lastActiveDate: json['lastActiveDate'] as String?,
        mistakeBank: (json['mistakeBank'] as List?)?.cast<String>() ?? const [],
        openedChestIds:
            (json['openedChestIds'] as List?)?.cast<String>() ?? const [],
        answersTotal: json['answersTotal'] as int? ?? 0,
        answersCorrectFirstTry: json['answersCorrectFirstTry'] as int? ?? 0,
        placementCompleted: json['placementCompleted'] as bool? ?? false,
        placementCoreScore: json['placementCoreScore'] as int?,
        placedLessonIds:
            (json['placedLessonIds'] as List?)?.cast<String>() ?? const [],
        verbalComfort: json['verbalComfort'] as int?,
        shapeAwareness: json['shapeAwareness'] as int?,
        emotionAwareness: json['emotionAwareness'] as int?,
        readyForMultiStep: json['readyForMultiStep'] as bool?,
      );
}
