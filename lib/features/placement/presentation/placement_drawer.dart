import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/application/auth_controller.dart';
import '../../profile/application/child_controller.dart';

/// Side menu for the post-signup test screens: who's playing at the top,
/// account actions at the bottom. [name]/[age] cover the not-yet-saved child
/// mid-signup; otherwise the selected child is shown.
class PlacementDrawer extends ConsumerWidget {
  final String? name;
  final int? age;

  const PlacementDrawer({super.key, this.name, this.age});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final child = ref.watch(childControllerProvider).selectedChild;
    final displayName = name ?? child?.name ?? '';
    final displayAge = age ?? child?.age;

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
              color: AppColors.background,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: AppColors.primary, width: 3),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (displayAge != null)
                    Text(
                      '$displayAge настай',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
            ),
            const Spacer(),
            const Divider(height: 1),
            // Everything a tap needs (router, auth controller) is grabbed
            // *before* the menu closes: once it is popped this widget is
            // disposed, and reading `ref` / using `context` afterwards throws.
            _DrawerAction(
              icon: Icons.child_care,
              label: 'Хүүхэд солих',
              onTap: () {
                final router = GoRouter.of(context);
                Navigator.pop(context);
                router.go('/select-child');
              },
            ),
            _DrawerAction(
              icon: Icons.swap_horiz,
              label: 'Бүртгэл солих',
              onTap: () async {
                final router = GoRouter.of(context);
                final auth = ref.read(authControllerProvider.notifier);
                Navigator.pop(context);
                await auth.logout();
                router.go('/login');
              },
            ),
            _DrawerAction(
              icon: Icons.logout,
              label: 'Гарах',
              color: Colors.red,
              // Confirm on top of the still-open menu, then log out.
              onTap: () => _confirmLogout(
                context,
                ref.read(authControllerProvider.notifier),
                GoRouter.of(context),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(
    BuildContext context,
    AuthController auth,
    GoRouter router,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Гарах уу?'),
        content: const Text('Үргэлжлүүлэхийн тулд дахин нэвтэрнэ үү.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Болих'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await auth.logout();
              router.go('/');
            },
            child: const Text('Гарах', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _DrawerAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _DrawerAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: color == Colors.red ? color : AppColors.primary,
      ),
      title: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
      onTap: onTap,
    );
  }
}
