import 'package:mazatalk/features/profile/domain/interest.dart';
import '../../domain/unit.dart';
import '../activity_factories.dart';

/// Unit 6 — Stories & Feelings: comprehension, emotions, social skills,
/// and a grand math/reading finale.
final unit6 = UnitTemplate(
  id: 'unit6',
  title: 'Stories & Feelings',
  emoji: '❤️',
  lessons: [
    LessonTemplate(
      id: 'u6l1',
      title: 'How do they feel?',
      buildActivities: (topic, rng) => [
        emotionTap(0), // happy
        emotionTap(1), // sad
        emotionTap(2), // angry
        emotionTap(3), // scared
        scenarioChoice(
          'You get ice cream 🍦. How do you feel?',
          '😊 Happy',
          const ['😢 Sad', '😠 Angry'],
          rng,
        ),
        matchPairs(
          'Match the feeling to the face',
          const [('Happy', '😊'), ('Sad', '😢'), ('Angry', '😠')],
          rng,
          skillId: 'eq',
        ),
      ],
    ),
    LessonTemplate(
      id: 'u6l2',
      title: 'Story time 1',
      buildActivities: (topic, rng) => [
        storyQuestion(
          'The little ${topic.label} was hungry. It ate a big red apple.',
          'What did it eat?',
          '🍎 An apple',
          const ['🍌 A banana', '🍕 A pizza'],
          rng,
        ),
        sequenceTap(
          'How does the tree grow? Tap in order',
          const ['🌱', '🌿', '🌳'],
          rng,
          skillId: 'eq',
          spokenPrompt: 'How does the tree grow? First the seed, then the plant, then the tree.',
        ),
        storyQuestion(
          'The ${topic.label} lost its ball. A friend helped find it.',
          'Who helped?',
          '🧒 A friend',
          const ['🤖 A robot', '🌧️ The rain'],
          rng,
        ),
        emotionTap(0),
        sentenceForPicture('The dog is happy.', '🐶', const ['🐶', '🌙', '🚌'], rng),
        tapWordYouHear('see', const ['I', 'see', 'my', 'a'], rng),
      ],
    ),
    LessonTemplate(
      id: 'u6l3',
      title: 'Day & night',
      buildActivities: (topic, rng) => [
        trueFalseFact('The sun ☀️ comes up in the morning',
            isTrue: true, skillId: 'eq'),
        matchPairs(
          'Match the time of day',
          const [('Morning', '🌅'), ('Night', '🌙'), ('Rain', '🌧️')],
          rng,
          skillId: 'eq',
        ),
        sequenceTap(
          'Tap the day in order: morning, day, night',
          const ['🌅', '☀️', '🌙'],
          rng,
          skillId: 'eq',
          spokenPrompt: 'First morning, then day, then night',
        ),
        scenarioChoice(
          'It is night 🌙. What do we do?',
          '😴 Sleep',
          const ['⚽ Play outside', '🍳 Eat breakfast'],
          rng,
        ),
        trueFalseFact('We sleep in the morning', isTrue: false, skillId: 'eq'),
        emotionTap(rng.nextInt(4)),
      ],
    ),
    LessonTemplate(
      id: 'u6l4',
      title: 'What happens next?',
      buildActivities: (topic, rng) => [
        sequenceTap(
          'What happens first? Tap in order',
          const ['🥚', '🐣', '🐔'],
          rng,
          skillId: 'eq',
          spokenPrompt: 'First the egg, then it hatches, then the chicken',
        ),
        patternNext(rng),
        storyQuestion(
          'It started to rain. The ${topic.label} opened an umbrella.',
          'Why the umbrella?',
          '🌧️ It was raining',
          const ['☀️ It was sunny', '🎉 A party'],
          rng,
        ),
        sequenceTap(
          'Wash your hands! Tap in order',
          const ['💧', '🧼', '🙌'],
          rng,
          skillId: 'eq',
          spokenPrompt: 'First water, then soap, then clean hands',
        ),
        scenarioChoice(
          'Your toy broke. What happens next?',
          '🔧 Ask for help to fix it',
          const ['😱 Scream all day', '🙈 Hide it'],
          rng,
        ),
        patternNext(rng),
      ],
    ),
    LessonTemplate(
      id: 'u6l5',
      title: 'Being a friend',
      buildActivities: (topic, rng) => [
        scenarioChoice(
          'Your friend is sad 😢. What do you do?',
          '🤗 Give a hug',
          const ['😆 Laugh at them', '🚶 Walk away'],
          rng,
        ),
        scenarioChoice(
          'Your friend has no crayons 🖍️. What do you do?',
          '🤝 Share yours',
          const ['🙅 Say no', '😤 Grab theirs'],
          rng,
        ),
        trueFalseFact('Sharing makes friends happy',
            isTrue: true, skillId: 'eq'),
        scenarioChoice(
          'You bumped into someone. What do you say?',
          '🙏 Sorry!',
          const ['😠 Move!', '🤫 Nothing'],
          rng,
        ),
        emotionTap(1),
        trueFalseFact('Hitting is a kind thing to do',
            isTrue: false, skillId: 'eq'),
      ],
    ),
    LessonTemplate(
      id: 'u6l6',
      title: 'Story time 2',
      buildActivities: (topic, rng) => [
        storyQuestion(
          'The ${topic.label} planted a seed. It watered it every day. A flower grew!',
          'What grew?',
          '🌸 A flower',
          const ['🍔 A burger', '🚗 A car'],
          rng,
        ),
        sequenceTap(
          'Tell the story in order',
          const ['🥚', '🐣', '🐤', '🐔'],
          rng,
          skillId: 'eq',
          spokenPrompt: 'Egg, hatching, chick, chicken — tap them in order',
        ),
        storyQuestion(
          'The ${topic.label} shared its lunch with a friend. The friend smiled.',
          'How did the friend feel?',
          '😊 Happy',
          const ['😢 Sad', '😨 Scared'],
          rng,
        ),
        sentenceForPicture('The cat sleeps.', '🐱', const ['🐱', '🐶', '☀️'], rng),
        emotionTap(0),
        scenarioChoice(
          'The story friend smiled. Why?',
          '🥪 Someone shared with them',
          const ['🌧️ It rained', '📺 TV time'],
          rng,
        ),
      ],
    ),
    LessonTemplate(
      id: 'u6l7',
      title: 'All-star math',
      buildActivities: (topic, rng) => [
        mathNumbers(3 + rng.nextInt(4), 1 + rng.nextInt(3), rng, add: true),
        mathPictures(topic, 6, 2, rng, add: false),
        countObjects(topic, 8 + rng.nextInt(3), rng, range: 10),
        numberAfter(19, rng, range: 21),
        mathNumbers(9, 3 + rng.nextInt(3), rng, add: false),
        patternNext(rng),
      ],
    ),
    LessonTemplate(
      id: 'u6l8',
      title: 'Final review',
      coinReward: 50,
      buildActivities: (topic, rng) => [
        letterTap('ABCDEFGHIJKLMNOPQRSTUVWXYZ'[rng.nextInt(26)], rng),
        letterAfter('ABCDEFGHIJKLMNOPQRSTUVWXY'[rng.nextInt(25)], rng),
        countObjects(topic, 5 + rng.nextInt(5), rng, range: 10),
        mathNumbers(4 + rng.nextInt(5), 2 + rng.nextInt(3), rng, add: true),
        sentenceForPicture('The dog runs.', '🐶', const ['🐶', '🐱', '🚌'], rng),
        emotionTap(rng.nextInt(4)),
        sequenceTap(
          'Make the sentence: "I see my cat"',
          const ['I', 'see', 'my', 'cat'],
          rng,
          spokenPrompt: 'Make the sentence: I see my cat',
        ),
        scenarioChoice(
          'You finished the whole course! How do you feel?',
          '🎉 Proud and happy',
          const ['😴 Asleep', '🙈 Hiding'],
          rng,
        ),
      ],
    ),
  ],
);
