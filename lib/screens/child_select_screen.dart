import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import '../features/auth/application/auth_controller.dart';
import '../features/companion/domain/skin.dart';
import '../features/companion/presentation/skin_avatar.dart';
import '../features/profile/application/child_controller.dart';
import 'onboarding_screens.dart' show MascotPlaceholder, OnboardingButton;

/// Single-child accounts auto-select their one child elsewhere (see the
/// resume engine); this screen stays available as a manual switcher and as
/// the landing point right after onboarding/login.
class ChildSelectScreen extends ConsumerWidget {
  const ChildSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(childControllerProvider);
    final children = session.children;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          TextButton.icon(
            onPressed: () => _confirmLogout(context, ref),
            icon: const Icon(
              Icons.logout,
              color: AppColors.textSecondary,
              size: 18,
            ),
            label: const Text(
              "Гарах",
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Align(
                alignment: Alignment.center,
                child: MascotPlaceholder(),
              ),
              const SizedBox(height: 24),
              const Text(
                "Хүүхдээ сонгоно уу",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: children.isEmpty
                    ? const Center(
                        child: Text(
                          "Хүүхэд нэмээгүй байна.",
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.separated(
                        itemCount: children.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final child = children[index];
                          return _ChildTile(
                            name: child.name,
                            age: child.age,
                            avatar: SkinCatalog.byId(child.equippedSkinId),
                            streak: child.dailyStreak,
                            xp: child.xp,
                            onTap: () async {
                              await ref
                                  .read(childControllerProvider.notifier)
                                  .selectChild(child.id);
                              if (context.mounted) {
                                context.go('/assessment-summary');
                              }
                            },
                          );
                        },
                      ),
              ),
              const SizedBox(height: 16),
              OnboardingButton(
                text: "+ Хүүхэд нэмэх",
                isPrimary: true,
                onPressed: () => context.push('/child/new'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Гарах уу?"),
        content: const Text("Үргэлжлүүлэхийн тулд дахин нэвтэрнэ үү."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Болих"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await ref.read(authControllerProvider.notifier).logout();
              await ref.read(childControllerProvider.notifier).clearSelection();
              if (context.mounted) context.go('/');
            },
            child: const Text("Гарах", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _ChildTile extends StatelessWidget {
  final String name;
  final int age;
  final Skin avatar;
  final int streak;
  final int xp;
  final VoidCallback onTap;

  const _ChildTile({
    required this.name,
    required this.age,
    required this.avatar,
    required this.streak,
    required this.xp,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.border, width: 1.5),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: AppColors.background,
              child: SkinAvatar(skin: avatar, size: 52),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  "$age настай",
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                Text(
                  "🔥 $streak  ·  ⚡ $xp",
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
