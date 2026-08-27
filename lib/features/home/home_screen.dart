import 'package:flutter/material.dart';
import 'package:skyjumper/features/gameplay/gameplay_screen.dart';
import 'package:skyjumper/features/settings/settings_screen.dart';
import 'package:skyjumper/features/shop/shop_screen.dart';
import 'package:skyjumper/game/data/player_progress_repository.dart';
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
  Future<void> _shop() => _open(ShopScreen(progress: widget.progress));
  Future<void> _settings() => _open(SettingsScreen(progress: widget.progress));

  @override
  Widget build(BuildContext context) {
    final progress = widget.progress;
    final selectedSkin = progress.equippedSkin;

    return Scaffold(
      backgroundColor: const Color(0xFF080816),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.35),
            radius: 1.18,
            colors: [Color(0xFF2B2364), Color(0xFF080816)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
            child: Column(
              children: [
                Row(
                  children: [
                    _TopStat(
                      icon: Icons.emoji_events_rounded,
                      label: 'BEST',
                      value: '${progress.bestScore}',
                    ),
                    const Spacer(),
                    _TopStat(
                      icon: Icons.monetization_on_rounded,
                      label: 'GOLD',
                      value: '${progress.gold}',
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      onPressed: _settings,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.09),
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.settings_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'SKY',
                  style: TextStyle(
                    fontSize: 54,
                    height: 0.82,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -2,
                    color: Color(0xFF72D7FF),
                    shadows: [Shadow(blurRadius: 22, color: Color(0xAA2D9CFF))],
                  ),
                ),
                const Text(
                  'JUMPER',
                  style: TextStyle(
                    fontSize: 48,
                    height: 0.95,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.5,
                    color: Color(0xFFFF8B38),
                    shadows: [Shadow(blurRadius: 22, color: Color(0xAAFF5F22))],
                  ),
                ),
                const Spacer(),
                Container(
                  width: 220,
                  height: 260,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        selectedSkin.accent.withValues(alpha: 0.26),
                        Colors.white.withValues(alpha: 0.035),
                      ],
                    ),
                    border: Border.all(
                      color: selectedSkin.accent.withValues(alpha: 0.48),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: selectedSkin.accent.withValues(alpha: 0.16),
                        blurRadius: 30,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: SkinAvatar(skin: selectedSkin, frame: 0),
                ),
                const SizedBox(height: 10),
                Text(
                  selectedSkin.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    letterSpacing: 1.6,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 66,
                  child: FilledButton.icon(
                    onPressed: _play,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFF7C2C),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded, size: 34),
                    label: const Text(
                      'OYNA',
                      style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: _shop,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF6975E9)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    icon: const Icon(Icons.checkroom_rounded),
                    label: const Text(
                      'MARKET / ENVANTER',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopStat extends StatelessWidget {
  const _TopStat({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFFFFC347), size: 19),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
