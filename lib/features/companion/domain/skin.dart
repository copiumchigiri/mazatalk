import 'package:flutter/material.dart';

enum SkinRarity { blue, green, purple, gold }

extension SkinRarityStyle on SkinRarity {
  Color get color {
    switch (this) {
      case SkinRarity.blue:
        return Colors.blue;
      case SkinRarity.green:
        return Colors.green.shade600;
      case SkinRarity.purple:
        return Colors.purple;
      case SkinRarity.gold:
        return const Color(0xFFC9971E);
    }
  }

  String get label {
    switch (this) {
      case SkinRarity.blue:
        return "Blue";
      case SkinRarity.green:
        return "Green";
      case SkinRarity.purple:
        return "Purple";
      case SkinRarity.gold:
        return "Gold";
    }
  }
}

/// A cosmetic skin for the child's persistent companion character.
class Skin {
  final String id;
  final String name;
  final String emoji;
  final SkinRarity rarity;
  final int price;

  const Skin({
    required this.id,
    required this.name,
    required this.emoji,
    required this.rarity,
    this.price = 0,
  });
}

class SkinCatalog {
  static const String defaultSkinId = 'bear_classic';

  static const List<Skin> all = [
    Skin(id: 'bear_classic', name: 'Classic Bear', emoji: '🐻', rarity: SkinRarity.blue, price: 0),
    Skin(id: 'panda', name: 'Panda', emoji: '🐼', rarity: SkinRarity.blue, price: 50),
    Skin(id: 'rabbit', name: 'Rabbit', emoji: '🐰', rarity: SkinRarity.blue, price: 60),
    Skin(id: 'fox', name: 'Fox', emoji: '🦊', rarity: SkinRarity.green, price: 100),
    Skin(id: 'wolf', name: 'Wolf', emoji: '🐺', rarity: SkinRarity.green, price: 120),
    Skin(id: 'koala', name: 'Koala', emoji: '🐨', rarity: SkinRarity.green, price: 110),
    Skin(id: 'tiger', name: 'Tiger', emoji: '🐯', rarity: SkinRarity.purple, price: 250),
    Skin(id: 'dragon', name: 'Dragon', emoji: '🐉', rarity: SkinRarity.purple, price: 300),
    Skin(id: 'lion', name: 'Lion', emoji: '🦁', rarity: SkinRarity.purple, price: 280),
    Skin(id: 'phoenix', name: 'Phoenix', emoji: '🦅', rarity: SkinRarity.gold, price: 500),
    Skin(id: 'unicorn', name: 'Unicorn', emoji: '🦄', rarity: SkinRarity.gold, price: 600),
  ];

  static Skin byId(String id) =>
      all.firstWhere((s) => s.id == id, orElse: () => all.first);
}
