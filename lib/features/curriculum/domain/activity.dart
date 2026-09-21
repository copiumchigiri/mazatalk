/// How the child interacts with one question. All types are tap-only —
/// the target users (ages 4–7) can't type.
enum ActivityType {
  /// Tap 1 of 3–4 text buttons.
  choiceText,

  /// Tap 1 of up to 4 big emoji tiles.
  choicePicture,

  /// Prompt is spoken aloud (TTS); tap the matching answer.
  listenAndChoose,

  /// Objects shown as an emoji row; tap the right number.
  countAndChoose,

  /// Two columns; tap one from each side to match. Max 3 pairs.
  matchPairs,

  /// A word with a gap (`c _ t`) plus letter choices.
  fillBlank,

  /// Tap tiles in order to build a sentence / story order. Max 3–4 tiles.
  sequence,

  /// Big ✅ / ❌ under a statement.
  trueFalse,
}

/// One question/interaction inside a lesson. For single-answer types
/// [correctOrder] holds one index; for [ActivityType.sequence] it holds the
/// tap order; for [ActivityType.matchPairs] it maps each left-column index
/// to its match in [rightColumn].
class Activity {
  final ActivityType type;

  /// 'letters' | 'counting' | 'colors' | 'shapes' | 'reading' | 'math' |
  /// 'vocabulary' | 'eq' — used for the parent dashboard skill breakdown.
  final String skillId;

  final String prompt;

  /// What TTS reads aloud; null means speak [prompt].
  final String? spokenPrompt;

  final List<String> choices;

  /// matchPairs only: the right-hand column.
  final List<String> rightColumn;

  final List<int> correctOrder;

  const Activity({
    required this.type,
    required this.skillId,
    required this.prompt,
    required this.choices,
    required this.correctOrder,
    this.spokenPrompt,
    this.rightColumn = const [],
  });

  bool get isSingleAnswer =>
      type != ActivityType.matchPairs && type != ActivityType.sequence;

  /// The answer for single-answer types.
  int get correctIndex => correctOrder.first;
}
