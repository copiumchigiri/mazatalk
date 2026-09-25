import 'dart:ui';

/// One pen stroke of a letter: a polyline in a 0..1 square, drawn in the
/// order it should be written (start → end).
class GlyphStroke {
  final List<Offset> points;
  const GlyphStroke(this.points);
}

/// A letter the child can see, say and trace. Stroke geometry is normalised
/// so the same data drives the big display letter and the tracing guide.
class LetterGlyph {
  /// The Cyrillic capital, e.g. «А».
  final String letter;

  /// How the letter is said aloud in the "say it" step, e.g. «Ааа».
  final String sound;

  /// Short spoken name for the speaker button, e.g. «Аа».
  final String spokenName;

  final List<GlyphStroke> strokes;

  const LetterGlyph({
    required this.letter,
    required this.sound,
    required this.spokenName,
    required this.strokes,
  });

  /// Steps shown in the progress bar: see, say, one per stroke, complete.
  int get totalSteps => 3 + strokes.length;
}

/// Letters that have a see/say/trace intro, and which lesson opens with it.
class LetterCatalog {
  static const a = LetterGlyph(
    letter: 'А',
    sound: 'Ааа',
    spokenName: 'Аа',
    strokes: [
      // 1: apex down to the bottom-left foot.
      GlyphStroke([Offset(.5, .04), Offset(.13, .96)]),
      // 2: apex down to the bottom-right foot.
      GlyphStroke([Offset(.5, .04), Offset(.87, .96)]),
      // 3: the crossbar, left to right.
      GlyphStroke([Offset(.3, .68), Offset(.7, .68)]),
    ],
  );

  static const _byLessonId = {'u1l1': a};

  /// The intro for [lessonId], or null when the lesson has none.
  static LetterGlyph? forLesson(String lessonId) => _byLessonId[lessonId];
}
