import 'placement_result.dart';

/// "Мазагийн аялал" (Maza's trip): the playground is one story told in three
/// acts of three levels each. An act opens with an intro card and gets its
/// own backdrop; the progress bar shows Maza walking between act stops.
class PlaygroundAct {
  final int index;

  /// Shown as "Бүлэг N".
  final String title;
  final String place;

  /// Maza's line on the intro card (also spoken — see tools/tts_phrases.txt).
  final String line;
  final List<String> levelIds;

  const PlaygroundAct({
    required this.index,
    required this.title,
    required this.place,
    required this.line,
    required this.levelIds,
  });
}

const playgroundActs = [
  PlaygroundAct(
    index: 0,
    title: 'Бүлэг 1',
    place: 'Тал нутаг',
    line: 'Маза бөмбөгөө алджээ. Тусалцгаая!',
    levelIds: [
      PlaygroundLevelId.findTheBall,
      PlaygroundLevelId.repeatAfterMe,
      PlaygroundLevelId.tapTheColor,
    ],
  ),
  PlaygroundAct(
    index: 1,
    title: 'Бүлэг 2',
    place: 'Голын эрэг',
    line: 'Одоо голын эрэг дээр гарцгаая!',
    levelIds: [
      PlaygroundLevelId.countTheFriends,
      PlaygroundLevelId.findTheLetter,
      PlaygroundLevelId.matchTheShape,
    ],
  ),
  PlaygroundAct(
    index: 2,
    title: 'Бүлэг 3',
    place: 'Гэрийн дэргэд',
    line: 'Сүүлийн зогсоол! Гэрийн дэргэд зугаацъя!',
    levelIds: [
      PlaygroundLevelId.pickFavorites,
      PlaygroundLevelId.howDoTheyFeel,
      PlaygroundLevelId.copyThePattern,
    ],
  ),
];

PlaygroundAct actForLevel(String levelId) =>
    playgroundActs.firstWhere((a) => a.levelIds.contains(levelId));
