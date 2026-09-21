/// Topics a child can pick during onboarding. Shown to every child equally —
/// personalization is driven by what they pick, not by assumptions about them.
enum Interest {
  dinosaurs,
  cars,
  trains,
  space,
  ocean,
  animals,
  music,
  art,
  fairyTales,
  sports,
}

extension InterestDisplay on Interest {
  String get emoji {
    switch (this) {
      case Interest.dinosaurs:
        return '🦖';
      case Interest.cars:
        return '🚗';
      case Interest.trains:
        return '🚂';
      case Interest.space:
        return '🚀';
      case Interest.ocean:
        return '🐠';
      case Interest.animals:
        return '🐶';
      case Interest.music:
        return '🎵';
      case Interest.art:
        return '🎨';
      case Interest.fairyTales:
        return '👑';
      case Interest.sports:
        return '⚽';
    }
  }

  String get label {
    switch (this) {
      case Interest.dinosaurs:
        return 'Dinosaurs';
      case Interest.cars:
        return 'Cars';
      case Interest.trains:
        return 'Trains';
      case Interest.space:
        return 'Space';
      case Interest.ocean:
        return 'Ocean';
      case Interest.animals:
        return 'Animals';
      case Interest.music:
        return 'Music';
      case Interest.art:
        return 'Art';
      case Interest.fairyTales:
        return 'Fairy Tales';
      case Interest.sports:
        return 'Sports';
    }
  }

  String get id => name;
}

Interest? interestFromId(String id) {
  for (final interest in Interest.values) {
    if (interest.id == id) return interest;
  }
  return null;
}
