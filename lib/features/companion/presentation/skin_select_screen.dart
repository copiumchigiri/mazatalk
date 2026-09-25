import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../profile/application/child_controller.dart';
import '../../profile/domain/child_profile.dart';
import '../domain/skin.dart';
import 'skin_avatar.dart';

class SkinSelectScreen extends ConsumerWidget {
  const SkinSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final child = ref.watch(childControllerProvider).selectedChild;
    if (child == null) {
      return const Scaffold(body: SizedBox.shrink());
    }
    final equipped = SkinCatalog.byId(child.equippedSkinId);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Хувцас"),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 1.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Text("🪙", style: TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(
                  "${child.coins}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Column(
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: equipped.rarity.color, width: 4),
                    color: Colors.grey.shade100,
                  ),
                  alignment: Alignment.center,
                  child: SkinAvatar(skin: equipped, size: 104),
                ),
                const SizedBox(height: 12),
                Text(
                  equipped.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  equipped.rarity.label,
                  style: TextStyle(
                    color: equipped.rarity.color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 20,
                crossAxisSpacing: 12,
                childAspectRatio: 0.78,
              ),
              itemCount: SkinCatalog.all.length,
              itemBuilder: (context, index) {
                final skin = SkinCatalog.all[index];
                final isUnlocked = child.unlockedSkinIds.contains(skin.id);
                final isEquipped = skin.id == child.equippedSkinId;
                return _SkinTile(
                  skin: skin,
                  isUnlocked: isUnlocked,
                  isEquipped: isEquipped,
                  onTap: () =>
                      _handleTap(context, ref, child, skin, isUnlocked),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _handleTap(
    BuildContext context,
    WidgetRef ref,
    ChildProfile child,
    Skin skin,
    bool isUnlocked,
  ) {
    final controller = ref.read(childControllerProvider.notifier);
    if (isUnlocked) {
      controller.equipSkin(child.id, skin.id);
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text("${skin.name}-г нээх үү?"),
        content: Text(
          "Үнэ: ${skin.price} зоос. Танд ${child.coins} зоос байна.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Болих"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final success = await controller.purchaseSkin(child.id, skin.id);
              if (!success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Зоос хүрэлцэхгүй байна — хичээлээ үргэлжлүүлээрэй!",
                    ),
                  ),
                );
              }
            },
            child: const Text("Нээх"),
          ),
        ],
      ),
    );
  }
}

class _SkinTile extends StatelessWidget {
  final Skin skin;
  final bool isUnlocked;
  final bool isEquipped;
  final VoidCallback onTap;

  const _SkinTile({
    required this.skin,
    required this.isUnlocked,
    required this.isEquipped,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isUnlocked ? skin.rarity.color : Colors.grey.shade400;
    final nameColor = isUnlocked ? skin.rarity.color : Colors.grey;

    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: isUnlocked ? 1.0 : 0.45,
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isEquipped ? Colors.black : borderColor,
                  width: isEquipped ? 3.5 : 2.5,
                ),
                color: Colors.grey.shade100,
              ),
              alignment: Alignment.center,
              child: SkinAvatar(skin: skin, size: 54),
            ),
            const SizedBox(height: 6),
            Text(
              skin.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: nameColor,
              ),
            ),
            if (!isUnlocked)
              Text(
                "🪙 ${skin.price}",
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              )
            else if (isEquipped)
              const Text(
                "Өмссөн",
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
