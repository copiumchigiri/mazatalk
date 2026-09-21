import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mazatalk/features/companion/domain/skin.dart';
import '../../auth/application/auth_controller.dart';
import '../../placement/domain/placement_result.dart';
import '../data/child_repository.dart';
import '../data/local_child_repository.dart';
import '../domain/child_profile.dart';

/// Scoped to the signed-in account: switching accounts (or logging out)
/// produces a new repository, which rebuilds [ChildController] with that
/// account's children.
final childRepositoryProvider = Provider<ChildRepository>((ref) {
  final accountId =
      ref.watch(authControllerProvider.select((s) => s.accountId));
  return LocalChildRepository(accountId: accountId);
});

class ChildSessionState {
  final List<ChildProfile> children;
  final String? selectedChildId;
  final bool isLoading;

  const ChildSessionState({
    this.children = const [],
    this.selectedChildId,
    this.isLoading = true,
  });

  ChildProfile? get selectedChild =>
      children.where((c) => c.id == selectedChildId).firstOrNull;

  ChildSessionState copyWith({
    List<ChildProfile>? children,
    String? selectedChildId,
    bool clearSelectedChildId = false,
    bool? isLoading,
  }) {
    return ChildSessionState(
      children: children ?? this.children,
      selectedChildId:
          clearSelectedChildId ? null : (selectedChildId ?? this.selectedChildId),
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Owns the list of child profiles and the currently active child, including
/// coins/skins/lesson-progress mutations. Replaces the old `AppSession`
/// ChangeNotifier singleton with a Riverpod-managed, testable controller.
class ChildController extends Notifier<ChildSessionState> {
  ChildRepository? _repository;

  @override
  ChildSessionState build() {
    // Watch (not read): an account switch swaps the repository and re-runs
    // this build, resetting state to the new account's children.
    final repository = ref.watch(childRepositoryProvider);
    _repository = repository;
    _load(repository);
    return const ChildSessionState();
  }

  Future<void> _load(ChildRepository repository) async {
    final children = await repository.loadChildren();
    // A stale load from before an account switch must not leak across.
    if (_repository != repository) return;
    state = state.copyWith(
      children: children,
      selectedChildId: children.isNotEmpty ? children.first.id : null,
      isLoading: false,
    );
  }

  Future<void> _persist() => _repository!.saveChildren(state.children);

  Future<void> addChild(ChildProfile child) async {
    state = state.copyWith(
      children: [...state.children, child],
      selectedChildId: child.id,
    );
    await _persist();
  }

  Future<void> selectChild(String id) async {
    state = state.copyWith(selectedChildId: id);
    await _persist();
  }

  Future<void> clearSelection() async {
    state = state.copyWith(clearSelectedChildId: true);
  }

  Future<void> _updateChild(
    String childId,
    ChildProfile Function(ChildProfile) update,
  ) async {
    state = state.copyWith(
      children: [
        for (final c in state.children) c.id == childId ? update(c) : c,
      ],
    );
    await _persist();
  }

  Future<void> addCoins(String childId, int amount) {
    return _updateChild(childId, (c) => c.copyWith(coins: c.coins + amount));
  }

  /// Marks [lessonId] complete for [childId] and pays out [coinReward] coins
  /// the first time only — replaying a finished lesson doesn't double-pay.
  Future<void> completeLesson(
    String childId,
    String lessonId, {
    int coinReward = 20,
  }) {
    final child = state.children.where((c) => c.id == childId).firstOrNull;
    if (child == null || child.completedLessonIds.contains(lessonId)) {
      return Future.value();
    }

    return _updateChild(
      childId,
      (c) => c.copyWith(
        coins: c.coins + coinReward,
        completedLessonIds: [...c.completedLessonIds, lessonId],
      ),
    );
  }

  /// Persists where the child currently is so the app can resume exactly here
  /// on next launch.
  Future<void> updateCheckpoint(
    String childId, {
    required String lessonId,
    required int checkpoint,
  }) {
    return _updateChild(
      childId,
      (c) => c.copyWith(currentLessonId: lessonId, currentCheckpoint: checkpoint),
    );
  }

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Books one finished lesson play-through: XP, accuracy counters, daily
  /// streak, and any new mistake-bank entries — a single update/persist.
  /// [now] is injectable for streak tests.
  Future<void> recordLessonResults(
    String childId, {
    required int xp,
    required int answersTotal,
    required int answersCorrectFirstTry,
    List<String> mistakes = const [],
    DateTime? now,
  }) {
    final today = _dateKey(now ?? DateTime.now());
    final yesterday =
        _dateKey((now ?? DateTime.now()).subtract(const Duration(days: 1)));
    return _updateChild(
      childId,
      (c) {
        final streak = c.lastActiveDate == today
            ? c.dailyStreak
            : (c.lastActiveDate == yesterday ? c.dailyStreak + 1 : 1);
        return c.copyWith(
          xp: c.xp + xp,
          answersTotal: c.answersTotal + answersTotal,
          answersCorrectFirstTry:
              c.answersCorrectFirstTry + answersCorrectFirstTry,
          mistakeBank: {...c.mistakeBank, ...mistakes}.toList(),
          dailyStreak: streak,
          lastActiveDate: today,
        );
      },
    );
  }

  /// Practice mode: items answered right on the first try leave the bank.
  Future<void> removeMistakes(String childId, List<String> cleared) {
    if (cleared.isEmpty) return Future.value();
    return _updateChild(
      childId,
      (c) => c.copyWith(
        mistakeBank:
            c.mistakeBank.where((m) => !cleared.contains(m)).toList(),
      ),
    );
  }

  /// Opens a path chest once, paying out its bonus coins. Returns false if
  /// it was already opened (no state change).
  Future<bool> openChest(String childId, String chestId, {int coins = 15}) async {
    final child = state.children.where((c) => c.id == childId).firstOrNull;
    if (child == null || child.openedChestIds.contains(chestId)) return false;
    await _updateChild(
      childId,
      (c) => c.copyWith(
        coins: c.coins + coins,
        openedChestIds: [...c.openedChestIds, chestId],
      ),
    );
    return true;
  }

  /// Settings → "Redo the playground" (PROJECT_V4.md §7.3): overwrites
  /// interests and supplementary signals with the new run, but is
  /// deliberately monotonic on progress — a newly-placed lesson is only
  /// ever added, never removing a lesson the child already actually played
  /// or a prior placement already credited.
  Future<void> reapplyPlacement(String childId, PlacementResult result) {
    return _updateChild(childId, (c) {
      final newlyPlaced = result.placedLessonIds
          .where((id) => !c.completedLessonIds.contains(id));
      return c.copyWith(
        interestIds: result.interestIds,
        completedLessonIds: {...c.completedLessonIds, ...newlyPlaced}.toList(),
        placedLessonIds: {...c.placedLessonIds, ...newlyPlaced}.toList(),
        placementCompleted: true,
        placementCoreScore: result.coreScore,
        verbalComfort: result.verbalComfort,
        shapeAwareness: result.shapeAwareness,
        emotionAwareness: result.emotionAwareness,
        readyForMultiStep: result.readyForMultiStep,
      );
    });
  }

  /// Settings → "Start over from Lesson 1" (PROJECT_V4.md §7.3): un-credits
  /// only the lessons placement auto-credited. Lessons the child actually
  /// played stay complete.
  Future<void> resetPlacementToLessonOne(String childId) {
    return _updateChild(
      childId,
      (c) => c.copyWith(
        completedLessonIds: c.completedLessonIds
            .where((id) => !c.placedLessonIds.contains(id))
            .toList(),
        placedLessonIds: const [],
      ),
    );
  }

  Future<void> equipSkin(String childId, String skinId) {
    return _updateChild(childId, (c) => c.copyWith(equippedSkinId: skinId));
  }

  /// Unlocks and equips [skinId] for [childId] if already unlocked or
  /// affordable. Returns false (no state change) if the child can't afford it.
  Future<bool> purchaseSkin(String childId, String skinId) async {
    final child = state.children.where((c) => c.id == childId).firstOrNull;
    if (child == null) return false;

    if (child.unlockedSkinIds.contains(skinId)) {
      await equipSkin(childId, skinId);
      return true;
    }

    final skin = SkinCatalog.byId(skinId);
    if (child.coins < skin.price) return false;

    await _updateChild(
      childId,
      (c) => c.copyWith(
        coins: c.coins - skin.price,
        unlockedSkinIds: [...c.unlockedSkinIds, skinId],
        equippedSkinId: skinId,
      ),
    );
    return true;
  }

  Future<void> reset() async {
    state = const ChildSessionState(isLoading: false);
    await _persist();
  }
}

final childControllerProvider =
    NotifierProvider<ChildController, ChildSessionState>(ChildController.new);

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
