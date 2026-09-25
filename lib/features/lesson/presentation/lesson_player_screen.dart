import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/tts_service.dart';
import '../../curriculum/application/course_controller.dart';
import '../../curriculum/domain/activity.dart';
import '../../curriculum/domain/course.dart';
import '../../curriculum/domain/lesson.dart';
import '../../profile/application/child_controller.dart';
import '../../letters/domain/letter_glyph.dart';
import '../../letters/presentation/letter_intro_flow.dart';
import '../domain/lesson_session.dart';
import 'activities/multi_step_boards.dart';
import 'lesson_complete_screen.dart';

/// DuoABC-style player: one activity per screen, the tap IS the answer (no
/// CHECK button), instant tile feedback (wrong tile red, correct tile green),
/// auto-advance, and missed activities requeued at the end of the lesson.
class LessonPlayerScreen extends ConsumerStatefulWidget {
  final String? lessonId;

  /// Practice mode: an ad-hoc lesson built from the child's mistake bank
  /// (or random completed-lesson activities when the bank is empty). Awards
  /// reduced XP, never coins, and clears first-try-correct bank items.
  final bool practice;

  const LessonPlayerScreen({super.key, this.lessonId, this.practice = false});

  @override
  ConsumerState<LessonPlayerScreen> createState() => _LessonPlayerScreenState();
}

enum _Phase { answering, correct, wrong }

const _correctAdvanceDelay = Duration(milliseconds: 1000);
const _wrongAdvanceDelay = Duration(milliseconds: 2500);

class _LessonPlayerScreenState extends ConsumerState<LessonPlayerScreen> {
  LessonSession? _session;
  bool _loading = true;

  /// A see / say / trace intro to play before the first question (only when
  /// the lesson has one and we're not resuming mid-lesson).
  LetterGlyph? _intro;
  bool _introDone = false;

  /// Whether checkpoints/currentLessonId may be persisted — true only when
  /// playing the child's actual current lesson (not a replay of a finished
  /// one, which is practice and must not move the resume pointer backwards).
  bool _trackProgress = true;

  _Phase _phase = _Phase.answering;
  int? _tappedIndex;
  Timer? _advanceTimer;

  /// Bumped per activity shown so multi-step boards get a fresh state even
  /// when the same activity is requeued.
  int _step = 0;

  // Snapshot for the complete screen.
  bool _completed = false;
  int _coinsEarned = 0;
  int _xpEarned = 0;
  int _accuracyCorrect = 0;
  int _accuracyTotal = 0;
  int _streak = 0;
  bool _courseFinished = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _advanceTimer?.cancel();
    super.dispose();
  }

  /// Practice only: fingerprint behind each synthetic-lesson activity index
  /// (empty for random-fallback activities — those never clear the bank).
  List<String> _practiceFingerprints = const [];

  void _load() {
    final child = ref.read(childControllerProvider).selectedChild;
    if (child == null) return;

    final course = ref
        .read(courseResolverProvider)
        .forChild(childId: child.id, interestIds: child.interestIds);

    if (widget.practice) {
      _loadPractice(
        child.id,
        child.interestIds,
        child.mistakeBank,
        child.completedLessonIds,
        course,
      );
      return;
    }

    final targetId =
        widget.lessonId ??
        child.currentLessonId ??
        course.firstIncomplete(child.completedLessonIds)?.id ??
        course.lessons.first.id;
    final lesson = course.lessonById(targetId) ?? course.lessons.first;

    final isReplay = child.completedLessonIds.contains(lesson.id);
    final resumeHere = !isReplay && lesson.id == child.currentLessonId;
    final startCheckpoint = resumeHere
        ? child.currentCheckpoint.clamp(0, lesson.activities.length - 1)
        : 0;

    setState(() {
      _session = LessonSession(lesson, startCheckpoint: startCheckpoint);
      _trackProgress = !isReplay;
      _intro = startCheckpoint == 0 ? LetterCatalog.forLesson(lesson.id) : null;
      _loading = false;
    });
    if (_intro == null) _speakPrompt();
  }

  void _loadPractice(
    String childId,
    List<String> interestIds,
    List<String> mistakeBank,
    List<String> completedLessonIds,
    Course course,
  ) {
    final activities = <Activity>[];
    final fingerprints = <String>[];

    for (final fingerprint in mistakeBank.take(8)) {
      final parts = fingerprint.split(':');
      if (parts.length != 2) continue;
      final lesson = course.lessonById(parts[0]);
      final index = int.tryParse(parts[1]);
      if (lesson == null ||
          index == null ||
          index >= lesson.activities.length) {
        continue;
      }
      activities.add(lesson.activities[index]);
      fingerprints.add(fingerprint);
    }

    if (activities.isEmpty) {
      // Nothing banked: review random activities from finished lessons.
      final rng = Random();
      final done = course.lessons
          .where((l) => completedLessonIds.contains(l.id))
          .toList();
      final pool = [for (final l in done) ...l.activities]..shuffle(rng);
      activities.addAll(pool.take(8));
      fingerprints.addAll(List.filled(activities.length, ''));
    }

    if (activities.isEmpty) {
      // Brand-new child with nothing to practice: fall back to lesson 1.
      activities.addAll(course.lessons.first.activities);
      fingerprints.addAll(List.filled(activities.length, ''));
    }

    final practiceLesson = Lesson(
      id: 'practice',
      title: 'Давтлага',
      topicId: interestIds.isEmpty ? 'animals' : interestIds.first,
      activities: activities,
      coinReward: 0,
    );
    setState(() {
      _session = LessonSession(practiceLesson, xpBase: 5);
      _practiceFingerprints = fingerprints;
      _trackProgress = false;
      _loading = false;
    });
    _speakPrompt();
  }

  Lesson get _lesson => _session!.lesson;

  /// Auto-speak every prompt: the target users are pre-readers.
  void _speakPrompt() {
    final session = _session;
    if (session == null || session.isComplete) return;
    final activity = session.current;
    ref
        .read(ttsServiceProvider)
        .speak(activity.spokenPrompt ?? activity.prompt);
  }

  void _onChoiceTap(int index) {
    final session = _session;
    if (session == null || _phase != _Phase.answering || session.isComplete) {
      return;
    }
    final correct = index == session.current.correctIndex;
    setState(() {
      _tappedIndex = index;
      _phase = correct ? _Phase.correct : _Phase.wrong;
    });
    ref
        .read(ttsServiceProvider)
        .speak(correct ? 'Маш сайн!' : 'За, дахин оролдоод үзье!');
    _advanceTimer = Timer(
      correct ? _correctAdvanceDelay : _wrongAdvanceDelay,
      _advance,
    );
  }

  /// Multi-step boards (matchPairs/fillBlank/sequence) evaluate per tap
  /// internally; they report once the board is solved, `clean` meaning no
  /// wrong taps along the way.
  void _onBoardFinished(bool clean) {
    if (_phase != _Phase.answering) return;
    setState(() {
      _tappedIndex = null;
      _phase = clean ? _Phase.correct : _Phase.wrong;
    });
    ref.read(ttsServiceProvider).speak(clean ? 'Маш сайн!' : 'Сайн байна!');
    _advanceTimer = Timer(
      clean ? _correctAdvanceDelay : const Duration(milliseconds: 1500),
      _advance,
    );
  }

  Future<void> _advance() async {
    _advanceTimer?.cancel();
    _advanceTimer = null;
    final session = _session;
    if (session == null || _phase == _Phase.answering) return;

    session.answer(_phase == _Phase.correct);

    if (session.isComplete) {
      await _finishLesson(session);
      return;
    }

    final child = ref.read(childControllerProvider).selectedChild;
    if (_trackProgress && child != null) {
      await ref
          .read(childControllerProvider.notifier)
          .updateCheckpoint(
            child.id,
            lessonId: _lesson.id,
            checkpoint: session.checkpoint,
          );
    }
    if (!mounted) return;
    setState(() {
      _phase = _Phase.answering;
      _tappedIndex = null;
      _step++;
    });
    _speakPrompt();
  }

  Future<void> _finishLesson(LessonSession session) async {
    final controller = ref.read(childControllerProvider.notifier);
    final child = ref.read(childControllerProvider).selectedChild;
    final lesson = _lesson;
    if (child == null) return;

    var firstCompletion = false;
    if (widget.practice) {
      // First-try-correct banked items leave the mistake bank.
      final cleared = <String>[
        for (var i = 0; i < _practiceFingerprints.length; i++)
          if (_practiceFingerprints[i].isNotEmpty &&
              !session.missedIndices.contains(i))
            _practiceFingerprints[i],
      ];
      await controller.removeMistakes(child.id, cleared);
    } else {
      firstCompletion = !child.completedLessonIds.contains(lesson.id);
      await controller.completeLesson(
        child.id,
        lesson.id,
        coinReward: lesson.coinReward,
      );
    }
    await controller.recordLessonResults(
      child.id,
      xp: session.xpEarned,
      answersTotal: session.answersTotal,
      answersCorrectFirstTry: session.answersCorrectFirstTry,
      mistakes: widget.practice ? const [] : session.mistakeFingerprints,
    );

    final course = ref
        .read(courseResolverProvider)
        .forChild(childId: child.id, interestIds: child.interestIds);
    final updated = ref.read(childControllerProvider).selectedChild ?? child;
    final next = course.next(lesson.id);
    if (_trackProgress && next != null) {
      await controller.updateCheckpoint(
        child.id,
        lessonId: next.id,
        checkpoint: 0,
      );
    }

    if (!mounted) return;
    setState(() {
      _completed = true;
      _coinsEarned = firstCompletion ? lesson.coinReward : 0;
      _xpEarned = session.xpEarned;
      _accuracyCorrect = session.answersCorrectFirstTry;
      _accuracyTotal = session.answersTotal;
      _streak = updated.dailyStreak;
      _courseFinished =
          !widget.practice &&
          course.firstIncomplete(updated.completedLessonIds) == null;
    });
  }

  void _confirmExit() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Хичээлээ зогсоох уу?'),
        content: const Text('Энэ хичээл дээрх явц хадгалагдана.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Үргэлжлүүлэх'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.go('/home');
            },
            child: const Text('Гарах', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    if (_loading || session == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_intro != null && !_introDone && !_completed) {
      return LetterIntroFlow(
        glyph: _intro!,
        onExit: () => context.go('/home'),
        onDone: () {
          setState(() => _introDone = true);
          _speakPrompt();
        },
      );
    }
    if (_completed) {
      return LessonCompleteScreen(
        lessonTitle: _lesson.title,
        xpEarned: _xpEarned,
        coinsEarned: _coinsEarned,
        accuracyCorrect: _accuracyCorrect,
        accuracyTotal: _accuracyTotal,
        streak: _streak,
        onContinue: () =>
            context.go(_courseFinished ? '/course-complete' : '/home'),
      );
    }

    final activity = session.current;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.close, color: Colors.black),
              onPressed: _confirmExit,
            ),
            Expanded(
              child: LinearProgressIndicator(
                value: session.progress,
                minHeight: 10,
                borderRadius: BorderRadius.circular(5),
                color: Colors.black,
                backgroundColor: Colors.grey.shade300,
              ),
            ),
            const SizedBox(width: 16),
          ],
        ),
      ),
      // Tap anywhere skips the feedback wait (young kids tap everything).
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _phase == _Phase.answering ? null : _advance,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 22,
                child: session.combo >= 2 && _phase != _Phase.wrong
                    ? Text(
                        '${session.combo} in a row! 🔥',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      )
                    : null,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      activity.prompt,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.volume_up, color: Colors.black),
                    tooltip: 'Hear it again',
                    onPressed: _speakPrompt,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(child: _buildChoices(activity)),
              _FeedbackBanner(phase: _phase),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChoices(Activity activity) {
    switch (activity.type) {
      case ActivityType.matchPairs:
        return MatchPairsBoard(
          key: ValueKey('board$_step'),
          activity: activity,
          onFinished: _onBoardFinished,
        );
      case ActivityType.fillBlank:
        return FillBlankBoard(
          key: ValueKey('board$_step'),
          activity: activity,
          onFinished: _onBoardFinished,
        );
      case ActivityType.sequence:
        return SequenceBoard(
          key: ValueKey('board$_step'),
          activity: activity,
          onFinished: _onBoardFinished,
        );
      default:
        break;
    }
    final isGrid =
        activity.type == ActivityType.choicePicture ||
        activity.type == ActivityType.trueFalse;
    if (isGrid) {
      // Non-scrolling 2-wide grid that always fits the available height:
      // every tile stays on screen — a pre-reader can't discover tiles
      // hidden behind a scroll.
      final count = activity.choices.length;
      return Column(
        children: [
          for (var i = 0; i < count; i += 2) ...[
            if (i > 0) const SizedBox(height: 12),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _choiceTile(activity, i, fontSize: 36)),
                  const SizedBox(width: 12),
                  if (i + 1 < count)
                    Expanded(child: _choiceTile(activity, i + 1, fontSize: 36))
                  else
                    const Expanded(child: SizedBox()),
                ],
              ),
            ),
          ],
        ],
      );
    }
    return Column(
      children: [
        for (var i = 0; i < activity.choices.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          SizedBox(
            height: 56,
            width: double.infinity,
            child: _choiceTile(activity, i, fontSize: 20),
          ),
        ],
      ],
    );
  }

  Widget _choiceTile(Activity activity, int index, {required double fontSize}) {
    Color background = Colors.white;
    Color border = Colors.black;
    if (_phase != _Phase.answering) {
      if (index == activity.correctIndex) {
        // The correct tile lights green — for pre-readers this highlight
        // (plus the voice, once TTS lands) IS the feedback, not the text.
        background = Colors.green.shade200;
        border = Colors.green.shade700;
      } else if (index == _tappedIndex) {
        background = Colors.red.shade200;
        border = Colors.red.shade700;
      }
    }
    return Material(
      color: background,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: border, width: 2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _onChoiceTap(index),
        child: Center(
          child: Text(
            activity.choices[index],
            style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _FeedbackBanner extends StatelessWidget {
  final _Phase phase;
  const _FeedbackBanner({required this.phase});

  @override
  Widget build(BuildContext context) {
    // Parent-facing garnish; the tile highlight carries the real feedback.
    final (text, color) = switch (phase) {
      _Phase.answering => ('', Colors.transparent),
      _Phase.correct => ('✅ Маш сайн!', Colors.green.shade100),
      _Phase.wrong => ('❌ Дахин оролдоно уу', Colors.red.shade100),
    };
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: 56,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
