import 'package:flutter/material.dart';

/// One piece of playground art. Loads `assets/art/<name>.png` when the
/// illustrator's file exists and otherwise paints [placeholder], so the app
/// always renders and dropping in a PNG needs no code change
/// (file list: ART_BRIEF.md).
class PlayArt extends StatelessWidget {
  final String name;
  final CustomPainter placeholder;
  final double? width;
  final double? height;
  final BoxFit fit;

  const PlayArt({
    super.key,
    required this.name,
    required this.placeholder,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Image.asset(
        'assets/art/$name.png',
        fit: fit,
        errorBuilder: (context, error, stack) =>
            CustomPaint(painter: placeholder, child: const SizedBox.expand()),
      ),
    );
  }
}
