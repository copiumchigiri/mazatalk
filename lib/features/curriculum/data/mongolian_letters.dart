import 'dart:math';
import '../domain/activity.dart';
import 'activity_factories.dart' show shuffleWithAnswer;

/// The Mongolian (Cyrillic) letters the course teaches first, in order.
const mongolianLetters = ['А', 'Б', 'В', 'Г', 'Д'];

List<String> _pool() => mongolianLetters;

/// "Find the letter «А»" — read-and-tap.
Activity mnLetterTap(String letter, Random rng) {
  final (choices, correct) = shuffleWithAnswer(letter, _pool(), rng, count: 4);
  return Activity(
    type: ActivityType.choiceText,
    skillId: 'letters',
    prompt: '"$letter" үсгийг ол!',
    choices: choices,
    correctOrder: [correct],
  );
}

/// Listening variant: Maza says the prompt; pre-readers rely on the voice.
Activity mnLetterListen(String letter, Random rng) {
  final (choices, correct) = shuffleWithAnswer(letter, _pool(), rng, count: 4);
  return Activity(
    type: ActivityType.listenAndChoose,
    skillId: 'letters',
    prompt: '"$letter" үсгийг ол!',
    spokenPrompt: '"$letter" үсгийг ол!',
    choices: choices,
    correctOrder: [correct],
  );
}

/// "Which letter does «Алим» start with?"
Activity mnFirstLetter(String word, String letter, Random rng) {
  final (choices, correct) = shuffleWithAnswer(letter, _pool(), rng, count: 4);
  return Activity(
    type: ActivityType.choiceText,
    skillId: 'letters',
    prompt: '$word гэдэг үг ямар үсгээр эхэлдэг вэ?',
    choices: choices,
    correctOrder: [correct],
  );
}
