import '../../curriculum/domain/activity.dart';
import '../../curriculum/domain/lesson.dart';

/// Pure state machine for one play-through of a lesson: the activity queue,
/// DuoABC-style mistake requeue (missed activities come back at the end of
/// the lesson until answered correctly), first-try accuracy, combo, XP and
/// the resume checkpoint. No Flutter imports — unit-testable on its own.
class LessonSession {
  final Lesson lesson;
  final int startCheckpoint;

  /// 10 for real lessons, 5 for practice runs.
  final int xpBase;

  final List<int> _queue;
  final int _initialLength;
  int _pos = 0;
  final Set<int> _missed = {};
  int _firstTryCorrect = 0;
  int _combo = 0;

  LessonSession(this.lesson, {this.startCheckpoint = 0, this.xpBase = 10})
      : _queue = [
          for (var i = startCheckpoint; i < lesson.activities.length; i++) i
        ],
        _initialLength = lesson.activities.length - startCheckpoint;

  bool get isComplete => _pos >= _queue.length;

  Activity get current => lesson.activities[_queue[_pos]];

  /// Index of the current activity within the lesson (mistake fingerprints).
  int get currentActivityIndex => _queue[_pos];

  /// 0..1 for the top progress bar. Grows the queue on mistakes, so the bar
  /// can retreat slightly after a wrong answer — same as Duolingo.
  double get progress => _queue.isEmpty ? 1 : _pos / _queue.length;

  /// Consecutive correct answers ("3 in a row! 🔥").
  int get combo => _combo;

  /// First-pass activity index to resume from if the child exits mid-lesson.
  /// Requeued mistakes are not part of the checkpoint — an exited lesson
  /// resumes at the first activity the child never reached.
  int get checkpoint =>
      startCheckpoint + (_pos > _initialLength ? _initialLength : _pos);

  void answer(bool correct) {
    assert(!isComplete, 'answer() called on a finished session');
    final index = _queue[_pos];
    if (correct) {
      if (!_missed.contains(index)) _firstTryCorrect++;
      _combo++;
    } else {
      _missed.add(index);
      _combo = 0;
      _queue.add(index); // come back to it at the end
    }
    _pos++;
  }

  int get answersTotal => _initialLength;
  int get answersCorrectFirstTry => _firstTryCorrect;

  /// Base + 1 per first-try-correct answer.
  int get xpEarned => xpBase + _firstTryCorrect;

  /// Lesson-activity indices the child got wrong at least once.
  Set<int> get missedIndices => Set.unmodifiable(_missed);

  /// 'lessonId:activityIndex' entries for the practice-mode mistake bank.
  List<String> get mistakeFingerprints =>
      [for (final i in _missed) '${lesson.id}:$i'];
}
