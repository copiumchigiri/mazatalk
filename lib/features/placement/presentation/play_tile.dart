import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

enum PlayTileState { normal, selected, dimmed }

/// The playground's shared tappable tile: white card, cyan outline and a
/// chunky bottom edge (the Duolingo "pressable button" look). Selected tiles
/// fill with the soft brand cyan; dimmed ones fade toward the background.
/// Never red — a wrong tap only dims (PROJECT_V4.md §9).
class PlayTile extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final PlayTileState state;
  final double radius;
  final bool circle;

  const PlayTile({
    super.key,
    required this.child,
    this.onTap,
    this.state = PlayTileState.normal,
    this.radius = 20,
    this.circle = false,
  });

  @override
  Widget build(BuildContext context) {
    final (fill, outline, edge) = switch (state) {
      PlayTileState.selected => (
        AppColors.background,
        AppColors.primary,
        AppColors.primary,
      ),
      PlayTileState.dimmed => (
        AppColors.surfaceSoft,
        AppColors.borderSubtle,
        AppColors.borderSubtle,
      ),
      PlayTileState.normal => (
        Colors.white,
        AppColors.primaryLight,
        AppColors.primaryLight,
      ),
    };
    final borderRadius = BorderRadius.circular(radius);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : borderRadius,
        color: fill,
        border: Border.all(color: outline, width: 2),
        boxShadow: [BoxShadow(color: edge, offset: const Offset(0, 4))],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          customBorder: circle
              ? const CircleBorder()
              : RoundedRectangleBorder(borderRadius: borderRadius),
          onTap: onTap,
          child: Center(child: child),
        ),
      ),
    );
  }
}
