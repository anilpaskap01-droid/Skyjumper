import 'package:flutter/material.dart';
import 'package:skyjumper/features/daily/daily_rewards_screen.dart';
import 'package:skyjumper/features/gameplay/gameplay_screen.dart';
import 'package:skyjumper/features/leaderboard/leaderboard_screen.dart';
import 'package:skyjumper/features/settings/settings_screen.dart';
import 'package:skyjumper/features/shop/shop_screen.dart';
import 'package:skyjumper/game/data/player_progress_repository.dart';
import 'package:skyjumper/game/data/skin_catalog.dart';
import 'package:skyjumper/widgets/skin_avatar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.progress});

  final PlayerProgressRepository progress;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> _open(Widget page) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
    if (mounted) setState(() {});
  }

  Future<void> _play() => _open(GameplayScreen(progress: widget.progress));
  Future<void> _market() => _open(ShopScreen(progress: widget.progress));
  Future<void> _inventory() => _open(ShopScreen(progress: widget.progress, initialInventory: true));
  Future<void> _global() => _open(LeaderboardScreen(progress: widget.progress));
  Future<void> _settings() => _open(SettingsScreen(progress: widget.progress));
  Future<void> _daily() => _open(DailyRewardsScreen(progress: widget.progress));

  @override
  Widget build(BuildContext context) {
    final progress = widget.progress;
    return Scaffold(
      backgroundColor: const Color(0xFF041226),
      body: Stack(
        children: <Widget>[
          const Positioned.fill(child: CustomPaint(painter: _MenuBackgroundPainter())),
          SafeArea(
            bottom: false,
            child: Column(
              children: <Widget>[
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 96),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: Column(
                          children: <Widget>[
                            _TopCurrencies(progress: progress),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: _DailyButton(
                                available: progress.canClaimDaily(),
                                onTap: _daily,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const _Logo(),
                            const SizedBox(height: 13),
                            _ContinueButton(onTap: _play),
                            const SizedBox(height: 10),
                            const _PromoBar(),
                            const SizedBox(height: 15),
                            _TopThreeCard(onOpenGlobal: _global),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _BottomNav(
              onMarket: _market,
              onInventory: _inventory,
              onPlay: _play,
              onGlobal: _global,
              onSettings: _settings,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopCurrencies extends StatelessWidget {
  const _TopCurrencies({required this.progress});

  final PlayerProgressRepository progress;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(child: _Currency(icon: Icons.emoji_events_rounded, value: _compact(progress.bestScore), color: const Color(0xFFFFD84B))),
        const SizedBox(width: 6),
        Expanded(child: _Currency(icon: Icons.diamond_rounded, value: '${progress.gems}', color: const Color(0xFF63EBFF), showPlus: true)),
        const SizedBox(width: 6),
        Expanded(child: _Currency(icon: Icons.auto_awesome_rounded, value: '${progress.seasonStars}', color: const Color(0xFFFF74E4))),
        const SizedBox(width: 6),
        Expanded(child: _Currency(icon: Icons.monetization_on_rounded, value: _compact(progress.gold), color: const Color(0xFFFFC83D))),
      ],
    );
  }

  static String _compact(int value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(value >= 10000000 ? 0 : 1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(value >= 100000 ? 0 : 1)}K';
    return '$value';
  }
}

class _Currency extends StatelessWidget {
  const _Currency({required this.icon, required this.value, required this.color, this.showPlus = false});

  final IconData icon;
  final String value;
  final Color color;
  final bool showPlus;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      decoration: BoxDecoration(
        color: const Color(0xE80A1C34),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF244D70)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(icon, color: color, size: 17),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12),
            ),
          ),
          if (showPlus) ...<Widget>[
            const SizedBox(width: 4),
            Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(color: Color(0xFF3ACD66), shape: BoxShape.circle),
              child: const Icon(Icons.add_rounded, size: 13, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }
}

class _DailyButton extends StatelessWidget {
  const _DailyButton({required this.available, required this.onTap});

  final bool available;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF35BC62),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
        side: BorderSide(color: available ? const Color(0xFF8AFFA8) : const Color(0xFF28894A)),
      ),
      icon: const Icon(Icons.card_giftcard_rounded, size: 18),
      label: Text(
        available ? 'GÜNLÜK ÖDÜLLER !' : 'GÜNLÜK ÖDÜLLER',
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: <Widget>[
        Text(
          'SKY',
          style: TextStyle(
            fontSize: 64,
            height: .82,
            fontWeight: FontWeight.w900,
            letterSpacing: -3,
            color: Color(0xFF7BE8FF),
            shadows: <Shadow>[Shadow(color: Color(0xFF25AFFF), blurRadius: 20), Shadow(color: Color(0xAAFFFFFF), blurRadius: 4)],
          ),
        ),
        Text(
          'JUMPER',
          style: TextStyle(
            fontSize: 54,
            height: .92,
            fontWeight: FontWeight.w900,
            letterSpacing: -2,
            color: Color(0xFFFF8B33),
            shadows: <Shadow>[Shadow(color: Color(0xFFFF582C), blurRadius: 22), Shadow(color: Color(0x88FFFFFF), blurRadius: 3)],
          ),
        ),
        SizedBox(height: 7),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(width: 56, child: Divider(color: Color(0xFFFFB43B), thickness: 1.5)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 9),
              child: Text('SEASON 1', style: TextStyle(color: Color(0xFFFFC34B), fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 2)),
            ),
            SizedBox(width: 56, child: Divider(color: Color(0xFFFFB43B), thickness: 1.5)),
          ],
        ),
      ],
    );
  }
}

class _ContinueButton extends StatelessWidget {
  const _ContinueButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 64,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(colors: <Color>[Color(0xFF12B6F5), Color(0xFF3BE2FF)]),
          border: Border.all(color: const Color(0xFF8FF4FF), width: 1.5),
          boxShadow: const <BoxShadow>[BoxShadow(color: Color(0x7735DFFF), blurRadius: 20)],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.play_arrow_rounded, size: 34, color: Colors.white),
            SizedBox(width: 6),
            Text('CONTINUE', style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
          ],
        ),
      ),
    );
  }
}

class _PromoBar extends StatelessWidget {
  const _PromoBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xC8091B31),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFF4AB9E7)),
      ),
      child: const Row(
        children: <Widget>[
          Icon(Icons.local_offer_rounded, color: Color(0xFFFFC447), size: 18),
          SizedBox(width: 7),
          Expanded(
            child: Text(
              'Fan Costumes 50% Off! Don’t Miss Out!',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopThreeCard extends StatelessWidget {
  const _TopThreeCard({required this.onOpenGlobal});

  final VoidCallback onOpenGlobal;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Expanded(
              child: Text('GLOBAL TOP 3', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.1)),
            ),
            IconButton(onPressed: onOpenGlobal, icon: const Icon(Icons.refresh_rounded, color: Colors.white60)),
          ],
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(9, 12, 9, 10),
          decoration: BoxDecoration(
            color: const Color(0xE807192D),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF28658B)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Expanded(child: _Podium(rank: 2, name: 'PASKO', skinId: 'custom_slot_16', skinName: 'Gubi', score: '4,491,478', height: 112)),
              SizedBox(width: 5),
              Expanded(child: _Podium(rank: 1, name: 'ORKUNK0', skinId: 'custom_slot_11', skinName: 'Void Knight', score: '10,453,217', height: 138)),
              SizedBox(width: 5),
              Expanded(child: _Podium(rank: 3, name: 'KLYRA', skinId: 'custom_slot_24', skinName: 'Wizard', score: '3,253,106', height: 101)),
            ],
          ),
        ),
      ],
    );
  }
}

class _Podium extends StatelessWidget {
  const _Podium({required this.rank, required this.name, required this.skinId, required this.skinName, required this.score, required this.height});

  final int rank;
  final String name;
  final String skinId;
  final String skinName;
  final String score;
  final double height;

  @override
  Widget build(BuildContext context) {
    final skin = skinById(skinId);
    final medal = rank == 1 ? const Color(0xFFFFD946) : rank == 2 ? const Color(0xFFC7E3F1) : const Color(0xFFC47D48);
    return Column(
      children: <Widget>[
        Text('#$rank', style: TextStyle(color: medal, fontSize: 16, fontWeight: FontWeight.w900)),
        SizedBox(height: 55, child: SkinAvatar(skin: skin)),
        Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11)),
        Text(skinName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white54, fontSize: 8)),
        const SizedBox(height: 4),
        Container(
          height: height - 70,
          width: double.infinity,
          alignment: Alignment.topCenter,
          padding: const EdgeInsets.only(top: 5),
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: <Color>[medal.withValues(alpha: .42), const Color(0xFF10243A)]),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
            border: Border.all(color: medal.withValues(alpha: .65)),
          ),
          child: Text(score, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900)),
        ),
      ],
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.onMarket, required this.onInventory, required this.onPlay, required this.onGlobal, required this.onSettings});

  final VoidCallback onMarket;
  final VoidCallback onInventory;
  final VoidCallback onPlay;
  final VoidCallback onGlobal;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 78,
        margin: const EdgeInsets.fromLTRB(8, 0, 8, 7),
        padding: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          color: const Color(0xF207172A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF21516F)),
          boxShadow: const <BoxShadow>[BoxShadow(color: Colors.black45, blurRadius: 18)],
        ),
        child: Row(
          children: <Widget>[
            Expanded(child: _NavItem(icon: Icons.storefront_rounded, label: 'MARKET', onTap: onMarket)),
            Expanded(child: _NavItem(icon: Icons.checkroom_rounded, label: 'ENVANTER', onTap: onInventory)),
            Expanded(
              child: Center(
                child: GestureDetector(
                  onTap: onPlay,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: <Color>[Color(0xFFFFD34A), Color(0xFFFF9B27)]),
                      boxShadow: <BoxShadow>[BoxShadow(color: Color(0x77FFAA22), blurRadius: 16)],
                    ),
                    child: const Icon(Icons.play_arrow_rounded, color: Color(0xFF18233A), size: 39),
                  ),
                ),
              ),
            ),
            Expanded(child: _NavItem(icon: Icons.public_rounded, label: 'GLOBAL', onTap: onGlobal)),
            Expanded(child: _NavItem(icon: Icons.settings_rounded, label: 'AYARLAR', onTap: onSettings)),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(icon, color: const Color(0xFF9DDFFF), size: 23),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}

class _MenuBackgroundPainter extends CustomPainter {
  const _MenuBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0, -.35),
          radius: 1.25,
          colors: <Color>[Color(0xFF102E56), Color(0xFF041226), Color(0xFF020915)],
        ).createShader(rect),
    );
    final star = Paint()..color = Colors.white.withValues(alpha: .55);
    for (var i = 0; i < 75; i++) {
      final x = ((i * 79 + 17) % 997) / 997 * size.width;
      final y = ((i * 137 + 23) % 991) / 991 * size.height;
      final radius = .5 + (i % 4) * .35;
      canvas.drawCircle(Offset(x, y), radius, star);
    }
    final circuit = Paint()
      ..color = const Color(0xFF1E6B8E).withValues(alpha: .16)
      ..strokeWidth = 1;
    for (double y = 110; y < size.height; y += 94) {
      canvas.drawLine(Offset(0, y), Offset(size.width * .18, y), circuit);
      canvas.drawLine(Offset(size.width * .82, y + 37), Offset(size.width, y + 37), circuit);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
