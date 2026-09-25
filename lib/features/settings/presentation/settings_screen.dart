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
      appBar: AppBar(title: const Text('Тохиргоо')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Дуу ба хоолой'),
            subtitle: const Text('Дуут заавар ба сэтгэгдэл'),
            activeThumbColor: Colors.black,
            value: settings.soundOn,
            onChanged: (value) =>
                ref.read(settingsControllerProvider.notifier).setSoundOn(value),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.person, color: Colors.black),
            title: Text(auth.parentName ?? 'Эцэг эх'),
            subtitle: Text(auth.accountId ?? ''),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.swap_horiz, color: Colors.black),
            title: const Text('Хүүхэд солих'),
            onTap: () => context.go('/select-child'),
          ),
          if (child != null) ...[
            const Divider(),
            ListTile(
              leading: const Text('🎪', style: TextStyle(fontSize: 22)),
              title: const Text('Тоглоомын шалгалтыг дахин өгөх'),
              subtitle: child.placementCoreScore != null
                  ? Text('Сүүлийн оноо: ${child.placementCoreScore}/100')
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
                title: const Text('1-р хичээлээс дахин эхлэх'),
                subtitle: const Text(
                  'Шалгалтаар авсан оноог арилгана; жинхэнээсээ тоглосон хичээлүүд хэвээр үлдэнэ',
                ),
                onTap: () => _confirmResetPlacement(context, ref, child.id),
              ),
          ],
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Гарах', style: TextStyle(color: Colors.red)),
            onTap: () => _confirmLogout(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text(
              'Энэ төхөөрөмжийн бүх өгөгдлийг устгах',
              style: TextStyle(color: Colors.red),
            ),
            subtitle: const Text('Бүх хүүхэд болон бүх явцыг устгана'),
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
        title: const Text('Гарах уу?'),
        content: const Text('Үргэлжлүүлэн суралцахын тулд дахин нэвтэрнэ үү.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Болих'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await ref.read(authControllerProvider.notifier).logout();
              if (context.mounted) context.go('/');
            },
            child: const Text('Гарах', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// PROJECT_V4.md §7.3: undoes only the lessons the placement playground
  /// auto-credited. Lessons the child actually played stay complete.
  void _confirmResetPlacement(
    BuildContext context,
    WidgetRef ref,
    String childId,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('1-р хичээлээс дахин эхлэх үү?'),
        content: const Text(
          'Хүүхдийн жинхэнээсээ тоглоогүй хичээлүүдийн шалгалтаар авсан оноог арилгана. '
          'Бодитоор дууссан явц хэвээр үлдэнэ.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Болих'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await ref
                  .read(childControllerProvider.notifier)
                  .resetPlacementToLessonOne(childId);
            },
            child: const Text(
              'Start over',
              style: TextStyle(color: Colors.red),
            ),
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
        title: const Text('Бүх өгөгдлийг устгах уу?'),
        content: const Text(
          'Энэ төхөөрөмж дээрх бүх хүүхдийн профайл болон суралцсан явц устгагдана.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(firstContext),
            child: const Text('Болих'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(firstContext);
              showDialog(
                context: context,
                builder: (secondContext) => AlertDialog(
                  title: const Text('Та үнэхээр итгэлтэй байна уу?'),
                  content: const Text('Үүнийг буцаах боломжгүй.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(secondContext),
                      child: const Text('Өгөгдлөө хадгалах'),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(secondContext);
                        await ref
                            .read(childControllerProvider.notifier)
                            .reset();
                        if (context.mounted) context.go('/select-child');
                      },
                      child: const Text(
                        'Бүгдийг устгах',
                        style: TextStyle(color: Colors.red),
                      ),
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
