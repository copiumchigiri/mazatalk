import 'package:flutter/material.dart';
import '../../../../core/widgets/maza_speech_bubble.dart';
import '../../../profile/domain/interest.dart';
import '../../domain/placement_result.dart';
import '../../../../core/theme/app_colors.dart';
import '../art/painters.dart';
import '../art/play_art.dart';
import '../art/play_feedback.dart';
import '../play_tile.dart';

/// Mongolian icon + label for each [Interest], local to this level. Kept
/// separate from [Interest.emoji]/[Interest.label] on purpose — those feed
/// English curriculum lesson sentences elsewhere (e.g.
/// `activity_factories.dart`, `unit_6.dart`) that this level must not touch.
const _icons = {
  Interest.dinosaurs: Icons.egg_alt,
  Interest.cars: Icons.directions_car,
  Interest.trains: Icons.train,
  Interest.space: Icons.rocket_launch,
  Interest.ocean: Icons.waves,
  Interest.animals: Icons.pets,
  Interest.music: Icons.music_note,
  Interest.art: Icons.palette,
  Interest.fairyTales: Icons.auto_stories,
  Interest.sports: Icons.sports_soccer,
};

Widget _interestArt(Interest interest, double size) => PlayArt(
  name: 'interest_${interest.id}',
  placeholder: IconArtPainter(_icons[interest]!),
  width: size,
  height: size,
);

const _labels = {
  Interest.dinosaurs: 'Үлэг гүрвэл',
  Interest.cars: 'Машин',
  Interest.trains: 'Галт тэрэг',
  Interest.space: 'Сансар',
  Interest.ocean: 'Далай',
  Interest.animals: 'Амьтад',
  Interest.music: 'Хөгжим',
  Interest.art: 'Урлаг',
  Interest.fairyTales: 'Үлгэр',
  Interest.sports: 'Спорт',
};

/// Act 3, level 1 — Pick Your Favorites (PROJECT_V4.md §6): Maza is packing
/// his backpack for the trip. The child taps 3 things they like and each one
/// drops into a backpack slot. There's no correct answer, so this always
/// scores full credit — it exists to capture `interestIds` (tap order is
/// preserved; interestIds[0] anchors Lesson 1's theme, per the curriculum's
/// topic-cycling in `course_builder.dart`). There is no timeout.
///
/// Keys: `interest_<id>` (grid tiles), `backpack_slot_<0..2>`.
class PickFavoritesLevel extends StatefulWidget {
  final int seed;
  final PlaygroundLevelComplete onComplete;

  const PickFavoritesLevel({
    super.key,
    required this.seed,
    required this.onComplete,
  });

  @override
  State<PickFavoritesLevel> createState() => _PickFavoritesLevelState();
}

class _PickFavoritesLevelState extends State<PickFavoritesLevel>
    with PlayFeedbackMixin {
  final List<Interest> _picked = [];
  bool _done = false;

  void _onTap(Interest interest) {
    if (_done) return;
    setState(() {
      if (_picked.contains(interest)) {
        _picked.remove(interest);
      } else if (_picked.length < 3) {
        _picked.add(interest);
      }
    });
    if (_picked.length == 3) {
      cheer();
      Future.delayed(const Duration(milliseconds: 500), _finish);
    }
  }

  void _finish() {
    if (_done || !mounted) return;
    _done = true;
    widget.onComplete(
      PlaygroundLevelOutcome(10, payload: _picked.map((i) => i.id).toList()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return withCheer(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const MazaSpeechBubble(
            text: 'Мазагийн үүргэвчинд дуртай 3 зүйлээ хий!',
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.9,
              ),
              itemCount: Interest.values.length,
              itemBuilder: (context, index) {
                final interest = Interest.values[index];
                return PlayTile(
                  key: Key('interest_${interest.id}'),
                  state: _picked.contains(interest)
                      ? PlayTileState.selected
                      : PlayTileState.normal,
                  onTap: () => _onTap(interest),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _interestArt(interest, 36),
                      const SizedBox(height: 4),
                      Text(
                        _labels[interest]!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const PlayArt(
                name: 'backpack',
                placeholder: BackpackPainter(),
                width: 64,
                height: 64,
              ),
              const SizedBox(width: 12),
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(
                  child: AnimatedContainer(
                    key: Key('backpack_slot_$i'),
                    duration: const Duration(milliseconds: 200),
                    height: 58,
                    decoration: BoxDecoration(
                      color: i < _picked.length
                          ? AppColors.background
                          : AppColors.surfaceSoft,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: i < _picked.length
                            ? AppColors.primary
                            : AppColors.borderSubtle,
                        width: 2,
                      ),
                    ),
                    child: i < _picked.length
                        ? Center(child: _interestArt(_picked[i], 34))
                        : null,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
