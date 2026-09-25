import 'package:flutter/material.dart';
import '../domain/skin.dart';

/// A skin's face: its illustration when it has one (the default Maza bear is
/// the app logo), otherwise its emoji. Circular and [size] × [size].
class SkinAvatar extends StatelessWidget {
  final Skin skin;
  final double size;

  const SkinAvatar({super.key, required this.skin, required this.size});

  @override
  Widget build(BuildContext context) {
    final asset = skin.imageAsset;
    if (asset != null) {
      return ClipOval(
        child: Image.asset(asset, width: size, height: size, fit: BoxFit.cover),
      );
    }
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Text(skin.emoji, style: TextStyle(fontSize: size * .55)),
      ),
    );
  }
}
