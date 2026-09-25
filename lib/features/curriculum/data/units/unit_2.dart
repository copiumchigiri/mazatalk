import '../../domain/unit.dart';
import '../activity_factories.dart';

const _animalEmoji = ['🐶', '🐱', '🐦', '🐟', '🐻', '🦆', '🐮', '🐴'];
const _animalWords = ['dog', 'cat', 'bird', 'fish', 'bear', 'duck'];

/// Unit 2 — Animal Friends: more letters, first vocabulary, shapes, 6–7.
final unit2 = UnitTemplate(
  id: 'unit2',
  title: 'Animal Friends',
  emoji: '🐻',
  lessons: [
    LessonTemplate(
      id: 'u2l1',
      title: 'Letters F & G',
      buildActivities: (topic, rng) => [
        letterTap('F', rng),
        letterListen('F', rng),
        letterTap('G', rng),
        letterListen('G', rng),
        firstLetter('Fish', '🐟', 'F', rng),
        firstLetter('Grapes', '🍇', 'G', rng),
      ],
    ),
    LessonTemplate(
      id: 'u2l2',
      title: 'Animal words 1',
      buildActivities: (topic, rng) => [
        pictureForWord('dog', '🐶', _animalEmoji, rng),
        wordForPicture('dog', '🐶', _animalWords, rng),
        pictureForWord('cat', '🐱', _animalEmoji, rng),
        wordForPicture('cat', '🐱', _animalWords, rng),
        pictureForWord('bird', '🐦', _animalEmoji, rng),
        wordForPicture('bird', '🐦', _animalWords, rng),
      ],
    ),
    LessonTemplate(
      id: 'u2l3',
      title: 'Letters H, I, J',
      buildActivities: (topic, rng) => [
        letterTap('H', rng),
        letterTap('I', rng),
        letterTap('J', rng),
        firstLetter('Hat', '🎩', 'H', rng),
        firstLetter('Ice', '🧊', 'I', rng),
        firstLetter('Juice', '🧃', 'J', rng),
      ],
    ),
    LessonTemplate(
      id: 'u2l4',
      title: 'Shapes',
      buildActivities: (topic, rng) => [
        shapeTap(0), // circle
        shapeTap(1), // square
        shapeTap(2), // triangle
        shapeNearTopic(topic, rng),
        trueFalseFact('A ball ⚽ is round', isTrue: true, skillId: 'shapes'),
        shapeTap(3), // star
      ],
    ),
    LessonTemplate(
      id: 'u2l5',
      title: 'Animal words 2',
      buildActivities: (topic, rng) => [
        pictureForWord('fish', '🐟', _animalEmoji, rng),
        pictureForWord('bear', '🐻', _animalEmoji, rng),
        pictureForWord('duck', '🦆', _animalEmoji, rng),
        animalSound('Moo', '🐮', _animalEmoji, rng),
        animalSound('Woof', '🐶', _animalEmoji, rng),
        animalSound('Meow', '🐱', _animalEmoji, rng),
      ],
    ),
    LessonTemplate(
      id: 'u2l6',
      title: 'Numbers 6 & 7',
      buildActivities: (topic, rng) => [
        countObjects(topic, 6, rng, range: 7),
        numberTap(6, rng, range: 9),
        countObjects(topic, 7, rng, range: 7),
        numberTap(7, rng, range: 9),
        numberAfter(5, rng, range: 9),
        numberAfter(6, rng, range: 9),
      ],
    ),
    LessonTemplate(
      id: 'u2l7',
      title: 'Big & small',
      buildActivities: (topic, rng) => [
        biggerSmaller(rng, bigger: true),
        biggerSmaller(rng, bigger: false),
        trueFalseFact(
          'An elephant 🐘 is bigger than a mouse 🐭',
          isTrue: true,
          skillId: 'math',
        ),
        biggerSmaller(rng, bigger: true),
        trueFalseFact(
          'An ant 🐜 is bigger than a bus 🚌',
          isTrue: false,
          skillId: 'math',
        ),
        biggerSmaller(rng, bigger: false),
      ],
    ),
    LessonTemplate(
      id: 'u2l8',
      title: 'Unit 2 Review',
      coinReward: 30,
      buildActivities: (topic, rng) => [
        letterTap('FGHIJ'[rng.nextInt(5)], rng),
        pictureForWord('dog', '🐶', _animalEmoji, rng),
        shapeTap(rng.nextInt(shapeNames.length)),
        countObjects(topic, 6 + rng.nextInt(2), rng, range: 8),
        animalSound('Meow', '🐱', _animalEmoji, rng),
        numberAfter(4 + rng.nextInt(2), rng, range: 9),
        biggerSmaller(rng, bigger: rng.nextBool()),
        wordForPicture('bird', '🐦', _animalWords, rng),
      ],
    ),
  ],
);
