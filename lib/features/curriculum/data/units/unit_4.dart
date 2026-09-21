import '../../domain/unit.dart';
import '../activity_factories.dart';

const _sightWords = ['the', 'and', 'is', 'a', 'my', 'see'];

/// Unit 4 — Numbers at Work: addition, teens, sight words, comparisons.
final unit4 = UnitTemplate(
  id: 'unit4',
  title: 'Numbers at Work',
  emoji: '➕',
  lessons: [
    LessonTemplate(
      id: 'u4l1',
      title: 'Letters P & Q',
      buildActivities: (topic, rng) => [
        letterTap('P', rng),
        letterListen('P', rng),
        letterTap('Q', rng),
        letterListen('Q', rng),
        firstLetter('Pig', '🐷', 'P', rng),
        firstLetter('Queen', '👸', 'Q', rng),
      ],
    ),
    LessonTemplate(
      id: 'u4l2',
      title: 'Add to 5',
      buildActivities: (topic, rng) => [
        mathPictures(topic, 2, 1, rng, add: true),
        mathPictures(topic, 3, 2, rng, add: true),
        mathNumbers(2, 2, rng, add: true),
        mathPictures(topic, 1, 3, rng, add: true),
        mathNumbers(1, 4, rng, add: true),
        mathNumbers(3, 1, rng, add: true),
      ],
    ),
    LessonTemplate(
      id: 'u4l3',
      title: 'Letters R, S, T',
      buildActivities: (topic, rng) => [
        letterTap('R', rng),
        letterTap('S', rng),
        letterTap('T', rng),
        firstLetter('Rainbow', '🌈', 'R', rng),
        firstLetter('Sun', '☀️', 'S', rng),
        firstLetter('Train', '🚂', 'T', rng),
      ],
    ),
    LessonTemplate(
      id: 'u4l4',
      title: 'Numbers 11–15',
      buildActivities: (topic, rng) => [
        numberTap(11, rng, range: 16),
        numberTap(13, rng, range: 16),
        numberAfter(11, rng, range: 16),
        numberTap(15, rng, range: 16),
        numberAfter(13, rng, range: 16),
        numberAfter(14, rng, range: 16),
      ],
    ),
    LessonTemplate(
      id: 'u4l5',
      title: 'Add to 10',
      buildActivities: (topic, rng) => [
        mathPictures(topic, 4, 3, rng, add: true),
        mathNumbers(6, 3, rng, add: true),
        mathPictures(topic, 5, 2, rng, add: true),
        mathNumbers(4, 4, rng, add: true),
        mathNumbers(7, 2, rng, add: true),
        sequenceTap(
          'Tap the numbers in order',
          const ['8', '9', '10'],
          rng,
          skillId: 'counting',
        ),
      ],
    ),
    LessonTemplate(
      id: 'u4l6',
      title: 'Sight words',
      buildActivities: (topic, rng) => [
        tapWordYouHear('the', _sightWords, rng),
        tapWordYouHear('and', _sightWords, rng),
        tapWordYouHear('is', _sightWords, rng),
        sequenceTap(
          'Make the sentence: "the red cat"',
          const ['the', 'red', 'cat'],
          rng,
          spokenPrompt: 'Make the sentence: the red cat',
        ),
        tapWordYouHear('a', _sightWords, rng),
        tapWordYouHear('my', _sightWords, rng),
      ],
    ),
    LessonTemplate(
      id: 'u4l7',
      title: 'Which is more?',
      buildActivities: (topic, rng) => [
        groupOf(topic, 4, rng, range: 5),
        trueFalseFact('5 is more than 2', isTrue: true, skillId: 'math'),
        biggerSmaller(rng, bigger: true),
        trueFalseFact('1 is more than 3', isTrue: false, skillId: 'math'),
        groupOf(topic, 6, rng, range: 7),
        countObjects(topic, 5 + rng.nextInt(3), rng, range: 8),
      ],
    ),
    LessonTemplate(
      id: 'u4l8',
      title: 'Unit 4 Review',
      coinReward: 30,
      buildActivities: (topic, rng) => [
        letterTap('PQRST'[rng.nextInt(5)], rng),
        mathPictures(topic, 2 + rng.nextInt(3), 1 + rng.nextInt(2), rng,
            add: true),
        numberTap(11 + rng.nextInt(5), rng, range: 16),
        tapWordYouHear(_sightWords[rng.nextInt(_sightWords.length)],
            _sightWords, rng),
        mathNumbers(3 + rng.nextInt(4), 1 + rng.nextInt(3), rng, add: true),
        trueFalseFact('4 is more than 1', isTrue: true, skillId: 'math'),
        firstLetter('Train', '🚂', 'T', rng),
        sequenceTap(
          'Tap the numbers in order',
          const ['11', '12', '13'],
          rng,
          skillId: 'counting',
        ),
      ],
    ),
  ],
);
