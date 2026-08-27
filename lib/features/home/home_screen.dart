import 'package:flutter/material.dart';
import 'package:skyjumper/features/gameplay/gameplay_screen.dart';
import 'package:skyjumper/game/data/player_progress_repository.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.progress,
  });

  final PlayerProgressRepository progress;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> _play() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GameplayScreen(progress: widget.progress),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openSettings() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => _SettingsPanel(progress: widget.progress),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF5CC9FF), Color(0xFFDDF8FF)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
            child: Column(
              children: [
                Row(
                  children: [
                    _StatChip(
                      icon: Icons.monetization_on_rounded,
                      value: '${widget.progress.gold}',
                    ),
                    const Spacer(),
                    IconButton.filledTonal(
                      onPressed: _openSettings,
                      icon: const Icon(Icons.settings_rounded),
                    ),
                  ],
                ),
                const Spacer(flex: 2),
                const Text(
                  'SKY\nJUMPER',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    height: 0.82,
                    fontSize: 58,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -2,
                    color: Color(0xFF15263B),
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    'EN İYİ  ${widget.progress.bestScore}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF24374D),
                    ),
                  ),
                ),
                const Spacer(flex: 3),
                SizedBox(
                  width: double.infinity,
                  height: 68,
                  child: FilledButton(
                    onPressed: _play,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFF7A2E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.play_arrow_rounded, size: 36),
                        SizedBox(width: 4),
                        Text(
                          'OYNA',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
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

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFFFA000)),
          const SizedBox(width: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _SettingsPanel extends StatefulWidget {
  const _SettingsPanel({required this.progress});

  final PlayerProgressRepository progress;

  @override
  State<_SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends State<_SettingsPanel> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ayarlar',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Ses'),
              value: widget.progress.soundEnabled,
              onChanged: (value) async {
                await widget.progress.setSoundEnabled(value);
                if (mounted) setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }
}
