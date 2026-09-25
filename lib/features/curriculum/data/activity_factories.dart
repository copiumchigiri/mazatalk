import 'dart:math';
import 'package:mazatalk/features/profile/domain/interest.dart';
import '../domain/activity.dart';

/// Reusable activity builders shared by every unit file. Each returns one
/// [Activity], themed by the child's interest topic where it makes sense,
/// shuffled with the deterministic per-child rng so a child's course never
/// silently changes between launches.

const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

const colorNames = ['Red', 'Blue', 'Green', 'Yellow'];
const colorSwatches = ['🔴', '🔵', '🟢', '🟡'];
const shapeNames = ['Circle', 'Square', 'Triangle', 'Star'];
const shapeEmoji = ['⚪', '⬜', '🔺', '⭐'];

/// Picks [count]-1 distractors from [pool] (minus the answer), shuffles the
/// answer in, and returns the choices with the answer's index.
(List<String>, int) shuffleWithAnswer(
  String answer,
  List<String> pool,
  Random rng, {
  int count = 3,
}) {
  final distractors = pool.where((p) => p != answer).toList()..shuffle(rng);
  final choices = [answer, ...distractors.take(count - 1)]..shuffle(rng);
  return (choices, choices.indexOf(answer));
}

List<String> _letterPool() => letters.split('');

Activity letterTap(String letter, Random rng) {
  final (choices, correct) = shuffleWithAnswer(letter, _letterPool(), rng);
  return Activity(
    type: ActivityType.choiceText,
    skillId: 'letters',
    prompt: 'Tap the letter $letter',
    choices: choices,
    correctOrder: [correct],
  );
}

/// Listening variant: the prompt is spoken; pre-readers rely on the voice.
Activity letterListen(String letter, Random rng) {
  final (choices, correct) = shuffleWithAnswer(letter, _letterPool(), rng);
  return Activity(
    type: ActivityType.listenAndChoose,
    skillId: 'letters',
    prompt: 'Tap the letter $letter',
    spokenPrompt: 'Tap the letter $letter',
    choices: choices,
    correctOrder: [correct],
  );
}

Activity letterAfter(String letter, Random rng) {
  final index = letters.indexOf(letter);
  assert(index >= 0 && index < letters.length - 1);
  final answer = letters[index + 1];
  final (choices, correct) = shuffleWithAnswer(answer, _letterPool(), rng);
  return Activity(
    type: ActivityType.choiceText,
    skillId: 'letters',
    prompt: 'What letter comes after $letter?',
    choices: choices,
    correctOrder: [correct],
  );
}

Activity firstLetter(String word, String emoji, String letter, Random rng) {
  final (choices, correct) = shuffleWithAnswer(letter, _letterPool(), rng);
  return Activity(
    type: ActivityType.choiceText,
    skillId: 'letters',
    prompt: 'Which letter starts $emoji $word?',
    choices: choices,
    correctOrder: [correct],
  );
}

/// "How many 🦖 do you see?" with the objects in the prompt's second line.
Activity countObjects(Interest topic, int target, Random rng, {int range = 5}) {
  final options = <int>{target};
  while (options.length < 3) {
    options.add(1 + rng.nextInt(range));
  }
  final numbers = options.toList()..shuffle(rng);
  return Activity(
    type: ActivityType.countAndChoose,
    skillId: 'counting',
    prompt: 'How many ${topic.emoji} do you see?\n${topic.emoji * target}',
    spokenPrompt: 'How many ${topic.label} do you see?',
    choices: numbers.map((n) => '$n').toList(),
    correctOrder: [numbers.indexOf(target)],
  );
}

/// "Which group has 3?" — the choices themselves are emoji groups.
Activity groupOf(Interest topic, int target, Random rng, {int range = 4}) {
  final sizes = <int>{target};
  while (sizes.length < 3) {
    sizes.add(1 + rng.nextInt(range));
  }
  final ordered = sizes.toList()..shuffle(rng);
  return Activity(
    type: ActivityType.choicePicture,
    skillId: 'counting',
    prompt: 'Tap the group with $target ${topic.label}',
    choices: ordered.map((n) => topic.emoji * n).toList(),
    correctOrder: [ordered.indexOf(target)],
  );
}

Activity numberAfter(int n, Random rng, {int range = 20}) {
  final answer = '${n + 1}';
  final pool = [for (var i = 1; i <= range; i++) '$i'];
  final (choices, correct) = shuffleWithAnswer(answer, pool, rng);
  return Activity(
    type: ActivityType.choiceText,
    skillId: 'counting',
    prompt: 'What comes after $n?',
    choices: choices,
    correctOrder: [correct],
  );
}

Activity numberTap(int n, Random rng, {int range = 20}) {
  final pool = [for (var i = 1; i <= range; i++) '$i'];
  final (choices, correct) = shuffleWithAnswer('$n', pool, rng);
  return Activity(
    type: ActivityType.listenAndChoose,
    skillId: 'counting',
    prompt: 'Tap the number $n',
    spokenPrompt: 'Tap the number $n',
    choices: choices,
    correctOrder: [correct],
  );
}

Activity colorTap(int colorIndex) {
  return Activity(
    type: ActivityType.choicePicture,
    skillId: 'colors',
    prompt: 'Tap the color ${colorNames[colorIndex]}',
    spokenPrompt: 'Tap the color ${colorNames[colorIndex]}',
    choices: colorSwatches,
    correctOrder: [colorIndex],
  );
}

Activity colorOfTopic(Interest topic, Random rng) {
  final colorIndex = rng.nextInt(colorNames.length);
  return Activity(
    type: ActivityType.choicePicture,
    skillId: 'colors',
    prompt: 'This ${topic.label} is ${colorNames[colorIndex]}. Tap that color.',
    choices: colorSwatches,
    correctOrder: [colorIndex],
  );
}

Activity shapeTap(int shapeIndex) {
  return Activity(
    type: ActivityType.choicePicture,
    skillId: 'shapes',
    prompt: 'Tap the ${shapeNames[shapeIndex]}',
    spokenPrompt: 'Tap the ${shapeNames[shapeIndex]}',
    choices: shapeEmoji,
    correctOrder: [shapeIndex],
  );
}

Activity shapeNearTopic(Interest topic, Random rng) {
  final shapeIndex = rng.nextInt(shapeNames.length);
  return Activity(
    type: ActivityType.choicePicture,
    skillId: 'shapes',
    prompt: 'Tap the ${shapeNames[shapeIndex]} hiding near the ${topic.label}',
    choices: shapeEmoji,
    correctOrder: [shapeIndex],
  );
}

/// "Tap the dog" with emoji tiles.
Activity pictureForWord(
  String word,
  String emoji,
  List<String> distractorEmoji,
  Random rng,
) {
  final (choices, correct) = shuffleWithAnswer(emoji, distractorEmoji, rng);
  return Activity(
    type: ActivityType.choicePicture,
    skillId: 'vocabulary',
    prompt: 'Tap the $word',
    spokenPrompt: 'Tap the $word',
    choices: choices,
    correctOrder: [correct],
  );
}

/// "Which word names 🐶?" with word buttons.
Activity wordForPicture(
  String word,
  String emoji,
  List<String> distractorWords,
  Random rng,
) {
  final (choices, correct) = shuffleWithAnswer(word, distractorWords, rng);
  return Activity(
    type: ActivityType.choiceText,
    skillId: 'reading',
    prompt: 'Which word names this? $emoji',
    choices: choices,
    correctOrder: [correct],
  );
}

Activity animalSound(
  String sound,
  String animalEmoji,
  List<String> distractorEmoji,
  Random rng,
) {
  final (choices, correct) = shuffleWithAnswer(
    animalEmoji,
    distractorEmoji,
    rng,
  );
  return Activity(
    type: ActivityType.choicePicture,
    skillId: 'vocabulary',
    prompt: 'Which animal says "$sound"?',
    spokenPrompt: 'Which animal says $sound?',
    choices: choices,
    correctOrder: [correct],
  );
}

/// Semantic size comparison with a clearly-bigger and clearly-smaller pair.
Activity biggerSmaller(Random rng, {required bool bigger}) {
  const pairs = [
    ('🐘', '🐭'),
    ('🦕', '🐜'),
    ('🏔️', '⚽'),
    ('🚌', '🚲'),
    ('🌳', '🌼'),
  ];
  final (big, small) = pairs[rng.nextInt(pairs.length)];
  final answer = bigger ? big : small;
  final choices = [big, small]..shuffle(rng);
  return Activity(
    type: ActivityType.choicePicture,
    skillId: 'math',
    prompt: bigger ? 'Tap the BIG one' : 'Tap the small one',
    spokenPrompt: bigger ? 'Tap the big one' : 'Tap the small one',
    choices: choices,
    correctOrder: [choices.indexOf(answer)],
  );
}

Activity trueFalseFact(
  String statement, {
  required bool isTrue,
  String skillId = 'vocabulary',
}) {
  return Activity(
    type: ActivityType.trueFalse,
    skillId: skillId,
    prompt: statement,
    choices: const ['✅ Yes', '❌ No'],
    correctOrder: [isTrue ? 0 : 1],
  );
}

/// Match pairs (≤3): left column from [pairs].$1, right column shuffled.
/// correctOrder[i] = the right-column index that matches left choice i.
Activity matchPairs(
  String prompt,
  List<(String, String)> pairs,
  Random rng, {
  String skillId = 'vocabulary',
  String? spokenPrompt,
}) {
  assert(pairs.length <= 3, 'working-memory cap: max 3 pairs');
  final rights = pairs.map((p) => p.$2).toList()..shuffle(rng);
  return Activity(
    type: ActivityType.matchPairs,
    skillId: skillId,
    prompt: prompt,
    spokenPrompt: spokenPrompt,
    choices: pairs.map((p) => p.$1).toList(),
    rightColumn: rights,
    correctOrder: pairs.map((p) => rights.indexOf(p.$2)).toList(),
  );
}

/// `c _ t` with letter tiles; per-tap retry, single correct letter.
Activity fillBlankWord(String word, String emoji, int gapIndex, Random rng) {
  final letter = word[gapIndex].toUpperCase();
  final gapped = word
      .split('')
      .asMap()
      .entries
      .map((e) => e.key == gapIndex ? '_' : e.value)
      .join(' ');
  final (choices, correct) = shuffleWithAnswer(letter, _letterPool(), rng);
  return Activity(
    type: ActivityType.fillBlank,
    skillId: 'reading',
    prompt: 'Finish the word:  $gapped  $emoji',
    spokenPrompt: 'Finish the word $word',
    choices: choices,
    correctOrder: [correct],
  );
}

/// Tap tiles in order (≤3 tiles; 4 allowed in units 5–6 for sentences).
Activity sequenceTap(
  String prompt,
  List<String> orderedTiles,
  Random rng, {
  String skillId = 'reading',
  String? spokenPrompt,
}) {
  assert(orderedTiles.length <= 4, 'working-memory cap: max 4 tiles');
  final shuffled = orderedTiles.toList()..shuffle(rng);
  return Activity(
    type: ActivityType.sequence,
    skillId: skillId,
    prompt: prompt,
    spokenPrompt: spokenPrompt,
    choices: shuffled,
    correctOrder: [for (final t in orderedTiles) shuffled.indexOf(t)],
  );
}

/// Picture addition/subtraction: '🍎🍎 + 🍎 = ?'.
Activity mathPictures(
  Interest topic,
  int a,
  int b,
  Random rng, {
  required bool add,
}) {
  final result = add ? a + b : a - b;
  final symbol = add ? '+' : '−';
  final options = <int>{result};
  while (options.length < 3) {
    options.add(rng.nextInt(add ? a + b + 3 : a + 2));
  }
  final numbers = options.toList()..shuffle(rng);
  return Activity(
    type: ActivityType.countAndChoose,
    skillId: 'math',
    prompt: '${topic.emoji * a}  $symbol  ${topic.emoji * b}  =  ?',
    spokenPrompt: add ? 'What is $a plus $b?' : 'What is $a take away $b?',
    choices: numbers.map((n) => '$n').toList(),
    correctOrder: [numbers.indexOf(result)],
  );
}

/// Plain number math: '2 + 3 = ?'.
Activity mathNumbers(int a, int b, Random rng, {required bool add}) {
  final result = add ? a + b : a - b;
  final pool = [for (var i = 0; i <= 12; i++) '$i'];
  final (choices, correct) = shuffleWithAnswer('$result', pool, rng);
  return Activity(
    type: ActivityType.choiceText,
    skillId: 'math',
    prompt: '$a ${add ? '+' : '−'} $b = ?',
    spokenPrompt: add ? 'What is $a plus $b?' : 'What is $a take away $b?',
    choices: choices,
    correctOrder: [correct],
  );
}

/// Sight/heard word: spoken prompt, tap the right word.
Activity tapWordYouHear(String word, List<String> distractorWords, Random rng) {
  final (choices, correct) = shuffleWithAnswer(word, distractorWords, rng);
  return Activity(
    type: ActivityType.listenAndChoose,
    skillId: 'reading',
    prompt: 'Tap the word "$word"',
    spokenPrompt: 'Tap the word $word',
    choices: choices,
    correctOrder: [correct],
  );
}

/// '⚪⬜⚪⬜ … what comes next?' pattern completion.
Activity patternNext(Random rng) {
  final a = rng.nextInt(shapeEmoji.length);
  var b = rng.nextInt(shapeEmoji.length);
  if (b == a) b = (b + 1) % shapeEmoji.length;
  return Activity(
    type: ActivityType.choicePicture,
    skillId: 'math',
    prompt:
        '${shapeEmoji[a]}${shapeEmoji[b]}${shapeEmoji[a]}${shapeEmoji[b]}${shapeEmoji[a]}  What comes next?',
    spokenPrompt: 'What comes next in the pattern?',
    choices: shapeEmoji,
    correctOrder: [b],
  );
}

/// Match a sentence to its picture.
Activity sentenceForPicture(
  String sentence,
  String emoji,
  List<String> distractorEmoji,
  Random rng,
) {
  final (choices, correct) = shuffleWithAnswer(emoji, distractorEmoji, rng);
  return Activity(
    type: ActivityType.choicePicture,
    skillId: 'reading',
    prompt: 'Tap the picture: "$sentence"',
    spokenPrompt: sentence,
    choices: choices,
    correctOrder: [correct],
  );
}

const emotionEmoji = ['😊', '😢', '😠', '😨'];
const emotionNames = ['Happy', 'Sad', 'Angry', 'Scared'];

Activity emotionTap(int emotionIndex) {
  return Activity(
    type: ActivityType.choicePicture,
    skillId: 'eq',
    prompt: 'Who feels ${emotionNames[emotionIndex]}?',
    spokenPrompt: 'Tap the face that feels ${emotionNames[emotionIndex]}',
    choices: emotionEmoji,
    correctOrder: [emotionIndex],
  );
}

/// Social scenario with one kind answer.
Activity scenarioChoice(
  String scenario,
  String correctAnswer,
  List<String> distractors,
  Random rng,
) {
  final (choices, correct) = shuffleWithAnswer(correctAnswer, [
    correctAnswer,
    ...distractors,
  ], rng);
  return Activity(
    type: ActivityType.choiceText,
    skillId: 'eq',
    prompt: scenario,
    choices: choices,
    correctOrder: [correct],
  );
}

/// Tiny story (spoken aloud) + one comprehension question.
Activity storyQuestion(
  String story,
  String question,
  String answer,
  List<String> distractors,
  Random rng,
) {
  final (choices, correct) = shuffleWithAnswer(answer, [
    answer,
    ...distractors,
  ], rng);
  return Activity(
    type: ActivityType.choiceText,
    skillId: 'reading',
    prompt: '$story\n\n$question',
    spokenPrompt: '$story. $question',
    choices: choices,
    correctOrder: [correct],
  );
}

Activity greetingWave(Random rng) {
  final (choices, correct) = shuffleWithAnswer('👋', const [
    '👋',
    '🍎',
    '🚗',
    '🌧️',
  ], rng);
  return Activity(
    type: ActivityType.choicePicture,
    skillId: 'eq',
    prompt: 'Мазаалай says hello! Tap the wave',
    spokenPrompt: 'Say hello! Tap the wave',
    choices: choices,
    correctOrder: [correct],
  );
}
