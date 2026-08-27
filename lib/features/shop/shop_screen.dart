import 'package:flutter/material.dart';
import 'package:skyjumper/game/data/player_progress_repository.dart';
import 'package:skyjumper/game/data/skin_catalog.dart';
import 'package:skyjumper/widgets/skin_avatar.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key, required this.progress});

  final PlayerProgressRepository progress;

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  bool _ownedOnly = false;

  Future<void> _handleSkin(SkinDefinition skin) async {
    final progress = widget.progress;
    if (progress.ownsSkin(skin.id)) {
      await progress.equipSkin(skin.id);
      if (mounted) setState(() {});
      return;
    }

    final bought = await progress.purchaseSkin(skin);
    if (!mounted) return;
    if (bought) {
      await progress.equipSkin(skin.id);
      if (mounted) setState(() {});
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Yeterli GOLD yok. ${skin.name} için ${skin.price} GOLD gerekiyor.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.progress;
    final visible = _ownedOnly
        ? kSkinCatalog.where((skin) => progress.ownsSkin(skin.id)).toList()
        : kSkinCatalog;

    return Scaffold(
      backgroundColor: const Color(0xFF090A17),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text(
          'SKIN MARKET',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.1),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB62E).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFFC34D)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.monetization_on_rounded,
                      size: 18,
                      color: Color(0xFFFFC34D),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${progress.gold}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.15,
            colors: [Color(0xFF24285C), Color(0xFF090A17)],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: _FilterButton(
                        label: 'MARKET',
                        selected: !_ownedOnly,
                        onTap: () => setState(() => _ownedOnly = false),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _FilterButton(
                        label: 'ENVANTER',
                        selected: _ownedOnly,
                        onTap: () => setState(() => _ownedOnly = true),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 2, 14, 26),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: visible.length,
                  itemBuilder: (context, index) {
                    final skin = visible[index];
                    return _SkinCard(
                      skin: skin,
                      owned: progress.ownsSkin(skin.id),
                      equipped: progress.equippedSkinId == skin.id,
                      onTap: () => _handleSkin(skin),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor:
            selected ? const Color(0xFF6574FF) : const Color(0xFF1C203D),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 13),
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _SkinCard extends StatelessWidget {
  const _SkinCard({
    required this.skin,
    required this.owned,
    required this.equipped,
    required this.onTap,
  });

  final SkinDefinition skin;
  final bool owned;
  final bool equipped;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF15182C),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          width: equipped ? 2.2 : 1,
          color: equipped ? skin.accent : Colors.white12,
        ),
        boxShadow: equipped
            ? [
                BoxShadow(
                  color: skin.accent.withValues(alpha: 0.18),
                  blurRadius: 18,
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(17),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      skin.accent.withValues(alpha: 0.24),
                      Colors.black.withValues(alpha: 0.12),
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: SkinAvatar(skin: skin, frame: 0),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              skin.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 38,
              child: FilledButton(
                onPressed: onTap,
                style: FilledButton.styleFrom(
                  backgroundColor: equipped
                      ? const Color(0xFF2FB775)
                      : owned
                          ? const Color(0xFF5F6EEB)
                          : const Color(0xFFFFA928),
                  foregroundColor:
                      equipped || owned ? Colors.white : Colors.black87,
                  padding: EdgeInsets.zero,
                ),
                child: Text(
                  equipped
                      ? 'EQUIPPED'
                      : owned
                          ? (skin.special ? 'ÖZEL • EQUIP' : 'EQUIP')
                          : '${skin.price} GOLD',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
