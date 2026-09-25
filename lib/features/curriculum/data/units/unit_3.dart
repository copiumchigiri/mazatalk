import 'package:mazatalk/features/profile/domain/interest.dart';
import '../../domain/unit.dart';
import '../activity_factories.dart';

const _wordEmoji = ['🐱', '🐶', '☀️', '🎩', '🚌', '🔑', '🍃', '🌙'];
const _words = ['cat', 'dog', 'sun', 'hat', 'bus', 'key'];

/// Unit 3 — First Words: early reading begins (CVC words, lowercase,
/// numbers to 10, patterns). Multi-step types appear from here, capped at
/// 3 pairs / 3 tiles.
final unit3 = UnitTemplate(
  id: 'unit3',
  title: 'First Words',
  emoji: '📖',
  lessons: [
    LessonTemplate(
      id: 'u3l1',
      title: 'Letters K & L',
      buildActivities: (topic, rng) => [
        letterTap('K', rng),
        letterListen('K', rng),
        letterTap('L', rng),
        letterListen('L', rng),
        firstLetter('Key', '🔑', 'K', rng),
        firstLetter('Leaf', '🍃', 'L', rng),
      ],
    ),
    LessonTemplate(
      id: 'u3l2',
      title: 'Read: cat & dog',
      buildActivities: (topic, rng) => [
        wordForPicture('cat', '🐱', _words, rng),
        pictureForWord('cat', '🐱', _wordEmoji, rng),
        wordForPicture('dog', '🐶', _words, rng),
        tapWordYouHear('cat', _words, rng),
        matchPairs(
          'Match the word to its picture',
          const [('cat', '🐱'), ('dog', '🐶'), ('sun', '☀️')],
          rng,
          skillId: 'reading',
        ),
        tapWordYouHear('dog', _words, rng),
      ],
    ),
    LessonTemplate(
      id: 'u3l3',
      title: 'Letters M, N, O',
      buildActivities: (topic, rng) => [
        letterTap('M', rng),
        letterTap('N', rng),
        letterTap('O', rng),
        firstLetter('Moon', '🌙', 'M', rng),
        matchPairs(
          'Match big and small letters',
          const [('A', 'a'), ('B', 'b'), ('C', 'c')],
          rng,
          skillId: 'letters',
        ),
        firstLetter('Nest', '🪺', 'N', rng),
      ],
    ),
    LessonTemplate(
      id: 'u3l4',
      title: 'Numbers 8, 9, 10',
      buildActivities: (topic, rng) => [
        countObjects(topic, 8, rng, range: 10),
        numberTap(8, rng, range: 12),
        countObjects(topic, 9, rng, range: 10),
        numberTap(10, rng, range: 12),
        numberAfter(7, rng, range: 12),
        matchPairs(
          'Match the number to the group',
          [('1', topic.emoji), ('2', topic.emoji * 2), ('3', topic.emoji * 3)],
          rng,
          skillId: 'counting',
        ),
      ],
    ),
    LessonTemplate(
      id: 'u3l5',
      title: 'Read: sun & hat',
      buildActivities: (topic, rng) => [
        wordForPicture('sun', '☀️', _words, rng),
        pictureForWord('hat', '🎩', _wordEmoji, rng),
        fillBlankWord('cat', '🐱', 1, rng),
        fillBlankWord('sun', '☀️', 0, rng),
        tapWordYouHear('hat', _words, rng),
        fillBlankWord('dog', '🐶', 2, rng),
      ],
    ),
    LessonTemplate(
      id: 'u3l6',
      title: 'More shapes',
      buildActivities: (topic, rng) => [
        shapeTap(3), // star
        shapeNearTopic(topic, rng),
        patternNext(rng),
        trueFalseFact(
          'A square ⬜ has 4 sides',
          isTrue: true,
          skillId: 'shapes',
        ),
        patternNext(rng),
        shapeTap(rng.nextInt(shapeNames.length)),
      ],
    ),
    LessonTemplate(
      id: 'u3l7',
      title: 'Patterns',
      buildActivities: (topic, rng) => [
        patternNext(rng),
        sequenceTap(
          'Tap the numbers in order',
          const ['1', '2', '3'],
          rng,
          skillId: 'counting',
          spokenPrompt: 'Tap one, two, three in order',
        ),
        patternNext(rng),
        groupOf(topic, 3, rng),
        sequenceTap(
          'Tap the numbers in order',
          const ['4', '5', '6'],
          rng,
          skillId: 'counting',
        ),
        patternNext(rng),
      ],
    ),
    LessonTemplate(
      id: 'u3l8',
      title: 'Unit 3 Review',
      coinReward: 30,
      buildActivities: (topic, rng) => [
        letterTap('KLMNO'[rng.nextInt(5)], rng),
        wordForPicture('dog', '🐶', _words, rng),
        fillBlankWord('sun', '☀️', 1, rng),
        countObjects(topic, 8 + rng.nextInt(3), rng, range: 10),
        patternNext(rng),
        matchPairs(
          'Match big and small letters',
          const [('D', 'd'), ('E', 'e'), ('F', 'f')],
          rng,
          skillId: 'letters',
        ),
        numberAfter(8, rng, range: 12),
        tapWordYouHear('sun', _words, rng),
      ],
    ),
  ],
);
