import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/application/auth_controller.dart';
import '../../placement/application/playground_session_controller.dart';
import '../../profile/application/child_controller.dart';
import '../application/settings_controller.dart';

/// Parent-facing settings: sound toggle, account info, child switching,
/// log out, and device-data deletion. Reached through the parent gate.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final auth = ref.watch(authControllerProvider);
    final child = ref.watch(childControllerProvider).selectedChild;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Sound & voice'),
            subtitle: const Text('Spoken prompts and feedback'),
            activeThumbColor: Colors.black,
            value: settings.soundOn,
            onChanged: (value) => ref
                .read(settingsControllerProvider.notifier)
                .setSoundOn(value),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.person, color: Colors.black),
            title: Text(auth.parentName ?? 'Parent'),
            subtitle: Text(auth.accountId ?? ''),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.swap_horiz, color: Colors.black),
            title: const Text('Change child'),
            onTap: () => context.go('/select-child'),
          ),
          if (child != null) ...[
            const Divider(),
            ListTile(
              leading: const Text('🎪', style: TextStyle(fontSize: 22)),
              title: const Text('Redo the playground'),
              subtitle: child.placementCoreScore != null
                  ? Text('Last score: ${child.placementCoreScore}/100')
                  : null,
              onTap: () {
                // The provider may still hold a completed session from an
                // earlier run — invalidate can't safely happen inside the
                // playground screen's own initState/build, so it happens
                // here, from this button handler.
                ref.invalidate(playgroundSessionControllerProvider);
                context.push('/playground');
              },
            ),
            if (child.placedLessonIds.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.replay, color: Colors.black),
                title: const Text('Start over from Lesson 1'),
                subtitle: const Text(
                    "Clears placement credit; lessons they've actually played stay complete"),
                onTap: () => _confirmResetPlacement(context, ref, child.id),
              ),
          ],
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Log out', style: TextStyle(color: Colors.red)),
            onTap: () => _confirmLogout(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Delete all data on this device',
                style: TextStyle(color: Colors.red)),
            subtitle: const Text('Removes every child and all progress'),
            onTap: () => _confirmDelete(context, ref),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
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

  /// PROJECT_V4.md §7.3: undoes only the lessons the placement playground
  /// auto-credited. Lessons the child actually played stay complete.
  void _confirmResetPlacement(BuildContext context, WidgetRef ref, String childId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Start over from Lesson 1?'),
        content: const Text(
            "This clears placement credit for lessons your child hasn't "
            'actually played yet. Progress they\'ve really completed stays.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await ref
                  .read(childControllerProvider.notifier)
                  .resetPlacementToLessonOne(childId);
            },
            child: const Text('Start over', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// Destructive — double confirm.
  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (firstContext) => AlertDialog(
        title: const Text('Delete all data?'),
        content: const Text(
            'Every child profile and all learning progress on this device will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(firstContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(firstContext);
              showDialog(
                context: context,
                builder: (secondContext) => AlertDialog(
                  title: const Text('Are you absolutely sure?'),
                  content: const Text('This cannot be undone.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(secondContext),
                      child: const Text('Keep my data'),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(secondContext);
                        await ref
                            .read(childControllerProvider.notifier)
                            .reset();
                        if (context.mounted) context.go('/select-child');
                      },
                      child: const Text('Delete everything',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
