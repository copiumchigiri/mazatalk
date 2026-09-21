import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/parent_gate.dart';
import '../../auth/application/auth_controller.dart';
import '../../companion/domain/skin.dart';
import '../../curriculum/application/course_controller.dart';
import '../../curriculum/domain/course.dart';
import '../../profile/application/child_controller.dart';
import '../../profile/domain/child_profile.dart';

/// The Duolingo-style home: a vertical path of lesson nodes. Done nodes are
/// filled, the current node carries a START bubble, everything ahead is
/// locked. Deliberately designless — default Material, black/white, emoji.
class PathScreen extends ConsumerStatefulWidget {
  const PathScreen({super.key});

  @override
  ConsumerState<PathScreen> createState() => _PathScreenState();
}

/// One row in the flattened path list.
sealed class _Row {
  const _Row();
}

class _UnitHeaderRow extends _Row {
  final String title;
  const _UnitHeaderRow(this.title);
}

class _NodeRow extends _Row {
  final PathNode node;
  final int lessonIndex; // running index for left/right winding
  const _NodeRow(this.node, this.lessonIndex);
}

const _rowHeight = 110.0;

class _PathScreenState extends ConsumerState<PathScreen> {
  final _scrollController = ScrollController();
  bool _didAutoScroll = false;

  /// go_router keeps this screen alive under pushed lesson routes, so the
  /// one-shot auto-scroll must re-arm whenever the current lesson moves —
  /// returning from a finished lesson should land on the newly-unlocked node.
  String? _lastCurrentLessonId;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<_Row> _buildRows(Course course) {
    final rows = <_Row>[];
    var lessonIndex = 0;
    for (final unit in course.units) {
      rows.add(_UnitHeaderRow('${unit.emoji}  ${unit.title}'));
      var count = 0;
      for (final lesson in unit.lessons) {
        rows.add(_NodeRow(PathNode.lesson(lesson), lessonIndex));
        lessonIndex++;
        count++;
        // Chest positions are counted over the whole course.
        final globalCount = course.indexOf(lesson.id) + 1;
        if (globalCount % Course.chestInterval == 0) {
          rows.add(_NodeRow(PathNode.chest('chest_$globalCount'), lessonIndex));
          lessonIndex++;
        }
      }
      assert(count == unit.lessons.length);
    }
    return rows;
  }

  void _autoScrollTo(int rowIndex) {
    if (_didAutoScroll || !_scrollController.hasClients) return;
    _didAutoScroll = true;
    final target = (rowIndex * _rowHeight - 180)
        .clamp(0.0, _scrollController.position.maxScrollExtent);
    _scrollController.jumpTo(target);
  }

  @override
  Widget build(BuildContext context) {
    final child = ref.watch(childControllerProvider).selectedChild;
    if (child == null) {
      // Router redirects momentarily; render nothing meanwhile.
      return const Scaffold(body: SizedBox.shrink());
    }
    final course = ref
        .read(courseResolverProvider)
        .forChild(childId: child.id, interestIds: child.interestIds);
    final rows = _buildRows(course);
    final currentLesson = course.firstIncomplete(child.completedLessonIds);
    if (_lastCurrentLessonId != currentLesson?.id) {
      _lastCurrentLessonId = currentLesson?.id;
      _didAutoScroll = false;
    }

    final currentRowIndex = rows.indexWhere((r) =>
        r is _NodeRow &&
        r.node.type == PathNodeType.lesson &&
        r.node.lesson!.id == currentLesson?.id);
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => _autoScrollTo(currentRowIndex < 0 ? 0 : currentRowIndex));

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _StatChip(emoji: '🔥', value: '${child.dailyStreak}'),
            const SizedBox(width: 8),
            _StatChip(emoji: '⚡', value: '${child.xp}'),
            const SizedBox(width: 8),
            _StatChip(emoji: '🪙', value: '${child.coins}'),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => context.push('/skins'),
              child: CircleAvatar(
                backgroundColor: AppColors.background,
                child: Text(
                  SkinCatalog.byId(child.equippedSkinId).emoji,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(context, child),
      body: ListView.builder(
        controller: _scrollController,
        itemExtent: _rowHeight,
        itemCount: rows.length,
        itemBuilder: (context, index) {
          final row = rows[index];
          return switch (row) {
            _UnitHeaderRow() => _UnitHeader(title: row.title),
            _NodeRow() => _buildNode(context, row, child, course,
                isCurrent: row.node.type == PathNodeType.lesson &&
                    row.node.lesson!.id == currentLesson?.id),
          };
        },
      ),
    );
  }

  Widget _buildNode(
    BuildContext context,
    _NodeRow row,
    ChildProfile child,
    Course course, {
    required bool isCurrent,
  }) {
    final node = row.node;
    // Wind left/right: -0.4, 0, 0.4, 0, -0.4, ...
    const offsets = [-0.4, 0.0, 0.4, 0.0];
    final alignment = Alignment(offsets[row.lessonIndex % offsets.length], 0);

    if (node.type == PathNodeType.chest) {
      final opened = child.openedChestIds.contains(node.id);
      final reached = course.isChestReached(node.id, child.completedLessonIds);
      return Align(
        alignment: alignment,
        child: _ChestNode(
          opened: opened,
          reached: reached,
          onTap: () => _onChestTap(node, opened: opened, reached: reached),
        ),
      );
    }

    final lesson = node.lesson!;
    final isDone = child.completedLessonIds.contains(lesson.id);
    // Auto-credited by the placement playground rather than actually played
    // (PROJECT_V4.md §7.2) — still counts as done for unlock purposes, but
    // shown distinctly so a parent or curious kid can tell it was inferred.
    final isPlaced = child.placedLessonIds.contains(lesson.id);
    final isUnlocked = course.isUnlocked(lesson.id, child.completedLessonIds);
    return Align(
      alignment: alignment,
      child: _LessonNode(
        title: lesson.title,
        isDone: isDone,
        isPlaced: isDone && isPlaced,
        isCurrent: isCurrent,
        isLocked: !isUnlocked,
        onTap: () {
          if (!isUnlocked) {
            ScaffoldMessenger.of(context)
              ..clearSnackBars()
              ..showSnackBar(const SnackBar(
                  content: Text('Complete the previous lesson!')));
            return;
          }
          context.push('/lesson?lessonId=${lesson.id}');
        },
      ),
    );
  }

  Future<void> _onChestTap(
    PathNode node, {
    required bool opened,
    required bool reached,
  }) async {
    final child = ref.read(childControllerProvider).selectedChild;
    if (child == null || opened) return;
    final messenger = ScaffoldMessenger.of(context);
    if (!reached) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(
            const SnackBar(content: Text('Reach the chest to open it!')));
      return;
    }
    final ok = await ref
        .read(childControllerProvider.notifier)
        .openChest(child.id, node.id, coins: node.chestCoins);
    if (ok) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(
            SnackBar(content: Text('🎁 Chest opened! +${node.chestCoins} 🪙')));
    }
  }

  Widget _buildDrawer(BuildContext context, ChildProfile child) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.grey.shade200,
                child: Text(SkinCatalog.byId(child.equippedSkinId).emoji),
              ),
              title: Text(child.name,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Age ${child.age}'),
            ),
            const Divider(),
            ListTile(
              leading: const Text('🔁', style: TextStyle(fontSize: 22)),
              title: const Text('Practice'),
              subtitle: child.mistakeBank.isNotEmpty
                  ? Text('${child.mistakeBank.length} to review')
                  : null,
              onTap: () {
                Navigator.pop(context);
                context.push('/practice');
              },
            ),
            ListTile(
              leading: const Text('🐻', style: TextStyle(fontSize: 22)),
              title: const Text('Companion & skins'),
              onTap: () {
                Navigator.pop(context);
                context.push('/skins');
              },
            ),
            ListTile(
              leading: const Icon(Icons.family_restroom, color: Colors.black),
              title: const Text('Parent dashboard'),
              onTap: () => _openParentGated('/parent-dashboard'),
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.black),
              title: const Text('Settings'),
              onTap: () => _openParentGated('/settings'),
            ),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.swap_horiz, color: Colors.red),
              title: const Text('Change child',
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                context.go('/select-child');
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title:
                  const Text('Log out', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmLogout(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Parent-facing screens sit behind the tap-code gate.
  Future<void> _openParentGated(String route) async {
    Navigator.pop(context); // close the drawer
    final passed = await showParentGate(context);
    if (passed && mounted) {
      // ignore: use_build_context_synchronously
      context.push(route);
    }
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content:
            const Text("You'll need to log in again to continue learning."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await ref.read(authControllerProvider.notifier).logout();
              if (context.mounted) context.go('/');
            },
            child: const Text('Log out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String emoji;
  final String value;
  const _StatChip({required this.emoji, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ],
    );
  }
}

class _UnitHeader extends StatelessWidget {
  final String title;
  const _UnitHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          const Expanded(child: Divider(color: Colors.black, thickness: 1.5)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
            ),
          ),
          const Expanded(child: Divider(color: Colors.black, thickness: 1.5)),
        ],
      ),
    );
  }
}

class _LessonNode extends StatelessWidget {
  final String title;
  final bool isDone;
  final bool isPlaced;
  final bool isCurrent;
  final bool isLocked;
  final VoidCallback onTap;

  const _LessonNode({
    required this.title,
    required this.isDone,
    this.isPlaced = false,
    required this.isCurrent,
    required this.isLocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = isCurrent ? 64.0 : 56.0;
    return InkWell(
      borderRadius: BorderRadius.circular(48),
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isCurrent)
            const Text('START',
                style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 1.5)),
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDone
                  ? (isPlaced ? Colors.grey.shade500 : Colors.black)
                  : (isLocked ? Colors.grey.shade300 : Colors.white),
              border: Border.all(
                color: isLocked ? Colors.grey.shade400 : Colors.black,
                width: isCurrent ? 3 : 2,
              ),
            ),
            child: Center(
              child: isDone
                  ? const Icon(Icons.check, color: Colors.white, size: 26)
                  : Text(
                      isLocked ? '🔒' : '▶️',
                      style: TextStyle(fontSize: isCurrent ? 26 : 20),
                    ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            isPlaced ? '$title · placed' : title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isLocked ? Colors.grey : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChestNode extends StatelessWidget {
  final bool opened;
  final bool reached;
  final VoidCallback onTap;

  const _ChestNode({
    required this.opened,
    required this.reached,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(48),
      onTap: onTap,
      child: Opacity(
        opacity: (reached && !opened) ? 1.0 : 0.4,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(opened ? '✅' : '🎁',
                style: TextStyle(fontSize: reached && !opened ? 40 : 34)),
            Text(
              opened ? 'Opened' : 'Chest',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
