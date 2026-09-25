import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'duo_progress_bar.dart';
import 'placement_drawer.dart';

/// Shared frame for every post-signup test screen: hamburger (opens the
/// [PlacementDrawer]) at the top-left, an optional Duolingo-style progress
/// bar beside it, then the screen's [body].
class PlacementScaffold extends StatelessWidget {
  final Widget body;

  /// 0..1; null hides the bar (handoff / summary screens).
  final double? progress;

  /// Act flags on the progress bar, and Maza riding its end.
  final int progressStops;
  final bool showMaza;

  /// Painted behind everything (the act backdrop); plain white when null.
  final Widget? background;

  final String? name;
  final int? age;
  final EdgeInsetsGeometry padding;

  const PlacementScaffold({
    super.key,
    required this.body,
    this.progress,
    this.progressStops = 0,
    this.showMaza = false,
    this.background,
    this.name,
    this.age,
    this.padding = const EdgeInsets.fromLTRB(24, 0, 24, 24),
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: PlacementDrawer(name: name, age: age),
      body: Stack(
        children: [
          if (background != null) Positioned.fill(child: background!),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 24, 12),
                  child: Row(
                    children: [
                      Builder(
                        builder: (context) => IconButton(
                          key: const Key('placement_menu_button'),
                          tooltip: 'Цэс',
                          icon: const Icon(
                            Icons.menu_rounded,
                            size: 30,
                            color: AppColors.primary,
                          ),
                          onPressed: () => Scaffold.of(context).openDrawer(),
                        ),
                      ),
                      if (progress != null) ...[
                        const SizedBox(width: 4),
                        Expanded(
                          child: DuoProgressBar(
                            value: progress!,
                            stops: progressStops,
                            showMaza: showMaza,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(padding: padding, child: body),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
