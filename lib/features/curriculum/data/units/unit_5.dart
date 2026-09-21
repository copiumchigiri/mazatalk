import '../../domain/unit.dart';
import '../activity_factories.dart';

/// Needs the letter pool for "what comes after" drills.
const _sightWords2 = ['I', 'see', 'a', 'my', 'cat', 'dog'];
const _sceneEmoji = ['🐶', '☀️', '🐟', '🐱', '🚌', '🌙'];

/// Unit 5 — Reading & Taking Away: the last letters, full alphabet,
/// numbers to 20, subtraction, first sentences. Sequences may reach 4
/// tiles from this unit on.
final unit5 = UnitTemplate(
  id: 'unit5',
  title: 'Reading & Taking Away',
  emoji: '📚',
  lessons: [
    LessonTemplate(
      id: 'u5l1',
      title: 'Letters U, V, W',
      buildActivities: (topic, rng) => [
        letterTap('U', rng),
        letterTap('V', rng),
        letterTap('W', rng),
        firstLetter('Umbrella', '☂️', 'U', rng),
        firstLetter('Violin', '🎻', 'V', rng),
        firstLetter('Whale', '🐋', 'W', rng),
      ],
    ),
    LessonTemplate(
      id: 'u5l2',
      title: 'Take away',
      buildActivities: (topic, rng) => [
        mathPictures(topic, 3, 1, rng, add: false),
        mathPictures(topic, 4, 2, rng, add: false),
        mathNumbers(5, 2, rng, add: false),
        mathPictures(topic, 5, 3, rng, add: false),
        mathNumbers(4, 1, rng, add: false),
        trueFalseFact('3 − 1 = 2', isTrue: true, skillId: 'math'),
      ],
    ),
    LessonTemplate(
      id: 'u5l3',
      title: 'X, Y, Z & the alphabet',
      buildActivities: (topic, rng) => [
        letterTap('X', rng),
        letterTap('Y', rng),
        letterTap('Z', rng),
        firstLetter('Zebra', '🦓', 'Z', rng),
        letterAfter('G', rng),
        letterAfter('M', rng),
      ],
    ),
    LessonTemplate(
      id: 'u5l4',
      title: 'Numbers 16–20',
      buildActivities: (topic, rng) => [
        numberTap(16, rng, range: 20),
        numberTap(18, rng, range: 20),
        numberAfter(16, rng, range: 20),
        numberTap(20, rng, range: 20),
        numberAfter(18, rng, range: 20),
        sequenceTap(
          'Tap the numbers in order',
          const ['18', '19', '20'],
          rng,
          skillId: 'counting',
        ),
      ],
    ),
    LessonTemplate(
      id: 'u5l5',
      title: 'Read a sentence',
      buildActivities: (topic, rng) => [
        sentenceForPicture('The dog runs.', '🐶', _sceneEmoji, rng),
        sentenceForPicture('The sun is yellow.', '☀️', _sceneEmoji, rng),
        sentenceForPicture('The fish swims.', '🐟', _sceneEmoji, rng),
        tapWordYouHear('see', _sightWords2, rng),
        fillBlankWord('bus', '🚌', 0, rng),
        sentenceForPicture('The cat sleeps.', '🐱', _sceneEmoji, rng),
      ],
    ),
    LessonTemplate(
      id: 'u5l6',
      title: 'Build a sentence',
      buildActivities: (topic, rng) => [
        tapWordYouHear('I', _sightWords2, rng),
        sequenceTap(
          'Make the sentence: "I see a cat"',
          const ['I', 'see', 'a', 'cat'],
          rng,
          spokenPrompt: 'Make the sentence: I see a cat',
        ),
        tapWordYouHear('my', _sightWords2, rng),
        sequenceTap(
          'Make the sentence: "I see a dog"',
          const ['I', 'see', 'a', 'dog'],
          rng,
          spokenPrompt: 'Make the sentence: I see a dog',
        ),
        matchPairs(
          'Match the word to its picture',
          const [('cat', '🐱'), ('dog', '🐶'), ('bus', '🚌')],
          rng,
          skillId: 'reading',
        ),
        tapWordYouHear('see', _sightWords2, rng),
      ],
    ),
    LessonTemplate(
      id: 'u5l7',
      title: 'Subtract to 10',
      buildActivities: (topic, rng) => [
        mathPictures(topic, 7, 3, rng, add: false),
        mathNumbers(10, 5, rng, add: false),
        mathPictures(topic, 9, 4, rng, add: false),
        mathNumbers(8, 2, rng, add: false),
        mathNumbers(6, 6, rng, add: false),
        trueFalseFact('10 − 5 = 5', isTrue: true, skillId: 'math'),
      ],
    ),
    LessonTemplate(
      id: 'u5l8',
      title: 'Unit 5 Review',
      coinReward: 30,
      buildActivities: (topic, rng) => [
        letterTap('UVWXYZ'[rng.nextInt(6)], rng),
        letterAfter('ABCDEFGHIJKLMNOPQRSTUVWXY'[rng.nextInt(25)], rng),
        numberTap(16 + rng.nextInt(5), rng, range: 20),
        mathNumbers(6 + rng.nextInt(4), 1 + rng.nextInt(4), rng, add: false),
        sentenceForPicture('The dog runs.', '🐶', _sceneEmoji, rng),
        sequenceTap(
          'Make the sentence: "I see a bus"',
          const ['I', 'see', 'a', 'bus'],
          rng,
          spokenPrompt: 'Make the sentence: I see a bus',
        ),
        mathPictures(topic, 5 + rng.nextInt(3), 2, rng, add: false),
        tapWordYouHear('I', _sightWords2, rng),
      ],
    ),
  ],
);
