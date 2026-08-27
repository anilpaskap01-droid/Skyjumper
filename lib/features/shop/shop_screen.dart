import 'package:flutter/material.dart';
import 'package:skyjumper/game/data/player_progress_repository.dart';
import 'package:skyjumper/game/data/skin_catalog.dart';
import 'package:skyjumper/widgets/skin_avatar.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({
    super.key,
    required this.progress,
    this.initialInventory = false,
  });

  final PlayerProgressRepository progress;
  final bool initialInventory;

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  late bool _ownedOnly;

  @override
  void initState() {
    super.initState();
    _ownedOnly = widget.initialInventory;
  }

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
      SnackBar(content: Text('${skin.name} için ${skin.price} GOLD gerekiyor.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.progress;
    final visible = _ownedOnly
        ? kSkinCatalog.where((skin) => progress.ownsSkin(skin.id)).toList()
        : kSkinCatalog;

    return Scaffold(
      backgroundColor: const Color(0xFF050F20),
      appBar: AppBar(
        backgroundColor: const Color(0xFF071426),
        foregroundColor: Colors.white,
        title: Text(
          _ownedOnly ? 'ENVANTER' : 'MARKET',
          style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.1),
        ),
        actions: <Widget>[
          _CurrencyChip(icon: Icons.diamond_rounded, value: '${progress.gems}', color: const Color(0xFF65E9FF)),
          const SizedBox(width: 6),
          _CurrencyChip(icon: Icons.monetization_on_rounded, value: '${progress.gold}', color: const Color(0xFFFFC739)),
          const SizedBox(width: 10),
        ],
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.6),
            radius: 1.2,
            colors: <Color>[Color(0xFF122C51), Color(0xFF050F20)],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: _TabButton(
                        text: 'MARKET',
                        selected: !_ownedOnly,
                        onTap: () => setState(() => _ownedOnly = false),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _TabButton(
                        text: 'ENVANTER',
                        selected: _ownedOnly,
                        onTap: () => setState(() => _ownedOnly = true),
                      ),
                    ),
                  ],
                ),
              ),
              if (!_ownedOnly)
                Container(
                  margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A1B31),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFFB445).withValues(alpha: .55)),
                  ),
                  child: const Row(
                    children: <Widget>[
                      Icon(Icons.local_offer_rounded, color: Color(0xFFFFC44B), size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'FAN COSTUMES • SEASON 1 COLLECTION',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: visible.isEmpty
                    ? const Center(child: Text('Henüz skin yok.', style: TextStyle(color: Colors.white54)))
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 2, 12, 24),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: .73,
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

class _CurrencyChip extends StatelessWidget {
  const _CurrencyChip({required this.icon, required this.value, required this.color});

  final IconData icon;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1D33),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: .45)),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, color: color, size: 17),
          const SizedBox(width: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({required this.text, required this.selected, required this.onTap});

  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: selected ? const Color(0xFF1599D2) : const Color(0xFF10233D),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w900)),
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
    final border = equipped ? const Color(0xFF51E5FF) : const Color(0xFF244769);
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF091A2E),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border, width: equipped ? 2 : 1),
        boxShadow: equipped
            ? <BoxShadow>[const BoxShadow(color: Color(0x334ADFFF), blurRadius: 16)]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(9),
        child: Column(
          children: <Widget>[
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[skin.accent.withValues(alpha: .24), const Color(0xFF06101D)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(7),
                  child: SkinAvatar(skin: skin),
                ),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              skin.name.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              height: 37,
              child: FilledButton(
                onPressed: onTap,
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.zero,
                  backgroundColor: equipped
                      ? const Color(0xFF28B879)
                      : owned
                          ? const Color(0xFF168BC1)
                          : const Color(0xFFFFB938),
                  foregroundColor: equipped || owned ? Colors.white : const Color(0xFF1B2230),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                ),
                child: Text(
                  equipped
                      ? 'EQUIPPED'
                      : owned
                          ? 'EQUIP'
                          : '${skin.price} GOLD',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
