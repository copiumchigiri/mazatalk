import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Duolingo-style lesson progress: a fat pill track with a rounded cyan fill
/// and a soft highlight stripe. [value] is 0..1; changes animate. With
/// [stops] the track shows that many act flags, and [showMaza] rides Maza's
/// face along the end of the fill — he walks the trip as levels finish.
class DuoProgressBar extends StatelessWidget {
  final double value;
  final int stops;
  final bool showMaza;

  const DuoProgressBar({
    super.key,
    required this.value,
    this.stops = 0,
    this.showMaza = false,
  });

  @override
  Widget build(BuildContext context) {
    final target = value.clamp(0.0, 1.0);
    return TweenAnimationBuilder<double>(
      tween: Tween(end: target),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => LayoutBuilder(
        builder: (context, constraints) {
          const height = 16.0;
          const marker = 34.0;
          final width = constraints.maxWidth;
          // Keep a visible rounded nub once there's any progress.
          final fillWidth = v <= 0 ? 0.0 : (width * v).clamp(height, width);
          return SizedBox(
            height: marker,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.centerLeft,
              children: [
                Container(
                  height: height,
                  decoration: BoxDecoration(
                    color: AppColors.borderSubtle,
                    borderRadius: BorderRadius.circular(height),
                  ),
                ),
                Container(
                  width: fillWidth,
                  height: height,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(height),
                  ),
                  padding: const EdgeInsets.only(left: 8, right: 8, top: 3),
                  alignment: Alignment.topCenter,
                  child: fillWidth > 24
                      ? Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        )
                      : null,
                ),
                for (var i = 1; i <= stops; i++)
                  Positioned(
                    left: (width * i / stops - 7).clamp(0.0, width - 14),
                    child: Container(
                      key: Key('progress_stop_$i'),
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: v >= i / stops - 0.001
                            ? Colors.white
                            : AppColors.surfaceSoft,
                        border: Border.all(
                          color: v >= i / stops - 0.001
                              ? AppColors.primary
                              : AppColors.textLight,
                          width: 2.5,
                        ),
                      ),
                    ),
                  ),
                if (showMaza)
                  Positioned(
                    left: (fillWidth - marker / 2).clamp(0.0, width - marker),
                    child: Container(
                      key: const Key('progress_maza'),
                      width: marker,
                      height: marker,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(
                          color: AppColors.primary,
                          width: 2.5,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
