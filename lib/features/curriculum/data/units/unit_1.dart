import '../../domain/unit.dart';
import '../activity_factories.dart';
import '../mongolian_letters.dart';

/// Unit 1 — First Sounds & Small Numbers. Single-tap activity types ONLY
/// (see PROJECT_V3.md §5 age caps): a 4-year-old ramps up here before any
/// multi-step task appears.
final unit1 = UnitTemplate(
  id: 'unit1',
  title: 'Эхний дуу ба жижиг тоо',
  emoji: '🔤',
  lessons: [
    LessonTemplate(
      id: 'u1l1',
      // Opens with the see / say / trace intro for «А»
      // (`LetterCatalog.forLesson`), then these practice questions.
      title: 'А үсэг',
      buildActivities: (topic, rng) => [
        mnLetterTap('А', rng),
        mnLetterListen('А', rng),
        mnFirstLetter('Алим', 'А', rng),
        mnLetterTap('А', rng),
        mnLetterListen('А', rng),
      ],
    ),
    LessonTemplate(
      id: 'u1l2',
      title: 'Letters A & B',
      buildActivities: (topic, rng) => [
        letterTap('A', rng),
        letterListen('A', rng),
        letterTap('B', rng),
        letterListen('B', rng),
        firstLetter('Apple', '🍎', 'A', rng),
        firstLetter('Ball', '⚽', 'B', rng),
      ],
    ),
    LessonTemplate(
      id: 'u1l3',
      title: 'Count 1–3',
      buildActivities: (topic, rng) => [
        countObjects(topic, 1, rng, range: 3),
        countObjects(topic, 2, rng, range: 3),
        countObjects(topic, 3, rng, range: 3),
        groupOf(topic, 2, rng, range: 3),
        numberAfter(1, rng, range: 5),
        numberAfter(2, rng, range: 5),
      ],
    ),
    LessonTemplate(
      id: 'u1l4',
      title: 'Letters C & D',
      buildActivities: (topic, rng) => [
        letterTap('C', rng),
        letterListen('C', rng),
        letterTap('D', rng),
        letterListen('D', rng),
        firstLetter('Cat', '🐱', 'C', rng),
        firstLetter('Dog', '🐶', 'D', rng),
      ],
    ),
    LessonTemplate(
      id: 'u1l5',
      title: 'Colors',
      buildActivities: (topic, rng) => [
        colorTap(0),
        colorTap(2), // green
        colorOfTopic(topic, rng),
        colorTap(3), // yellow
        colorTap(1),
        colorOfTopic(topic, rng),
      ],
    ),
    LessonTemplate(
      id: 'u1l6',
      title: 'Letter E & review',
      buildActivities: (topic, rng) => [
        letterTap('E', rng),
        letterListen('E', rng),
        firstLetter('Egg', '🥚', 'E', rng),
        letterTap('ABCDE'[rng.nextInt(5)], rng),
        letterTap('ABCDE'[rng.nextInt(5)], rng),
        firstLetter('Ball', '⚽', 'B', rng),
      ],
    ),
    LessonTemplate(
      id: 'u1l7',
      title: 'Count 1–5',
      buildActivities: (topic, rng) => [
        countObjects(topic, 4, rng),
        countObjects(topic, 5, rng),
        groupOf(topic, 3, rng),
        numberAfter(2, rng, range: 6),
        numberAfter(3, rng, range: 6),
        numberAfter(4, rng, range: 6),
      ],
    ),
    LessonTemplate(
      id: 'u1l8',
      title: 'Unit 1 Review',
      coinReward: 30,
      buildActivities: (topic, rng) => [
        letterTap('ABCDE'[rng.nextInt(5)], rng),
        countObjects(topic, 1 + rng.nextInt(5), rng),
        colorTap(rng.nextInt(colorNames.length)),
        firstLetter('Apple', '🍎', 'A', rng),
        groupOf(topic, 2 + rng.nextInt(2), rng),
        numberAfter(1 + rng.nextInt(4), rng, range: 6),
        letterListen('ABCDE'[rng.nextInt(5)], rng),
        colorOfTopic(topic, rng),
      ],
    ),
  ],
);
