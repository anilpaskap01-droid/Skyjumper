import 'package:flutter/material.dart';
import 'package:skyjumper/game/data/player_progress_repository.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.progress});

  final PlayerProgressRepository progress;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final progress = widget.progress;
    return Scaffold(
      backgroundColor: const Color(0xFF080A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'AYARLAR',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.3),
        ),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.7),
            radius: 1.1,
            colors: [Color(0xFF202C66), Color(0xFF080A1A)],
          ),
        ),
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
            children: [
              _SettingTile(
                icon: Icons.volume_up_rounded,
                title: 'SES VE MÜZİK',
                subtitle: 'Oyun sesleri ve sistem geri bildirimi',
                value: progress.soundEnabled,
                onChanged: (value) async {
                  await progress.setSoundEnabled(value);
                  if (mounted) setState(() {});
                },
              ),
              _SettingTile(
                icon: Icons.vibration_rounded,
                title: 'TİTREŞİM',
                subtitle: 'Coin ve inişlerde dokunsal geri bildirim',
                value: progress.vibrationEnabled,
                onChanged: (value) async {
                  await progress.setVibrationEnabled(value);
                  if (mounted) setState(() {});
                },
              ),
              _SettingTile(
                icon: Icons.videocam_rounded,
                title: 'DARBE SARSINTISI',
                subtitle: 'Sert inişlerde kısa kamera tepkisi',
                value: progress.cameraShakeEnabled,
                onChanged: (value) async {
                  await progress.setCameraShakeEnabled(value);
                  if (mounted) setState(() {});
                },
              ),
              _SettingTile(
                icon: Icons.auto_awesome_rounded,
                title: 'AZALTILMIŞ EFEKT',
                subtitle: 'Daha sade görsel efekt ve daha az hareket',
                value: progress.reducedEffects,
                onChanged: (value) async {
                  await progress.setReducedEffects(value);
                  if (mounted) setState(() {});
                },
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white12),
                ),
                child: const Text(
                  'Tüm ayarlar ve oyun ilerlemesi yalnızca cihazda saklanır. '
                  'Firebase, reklam SDK’sı veya uygulama içi satın alma kullanılmaz.',
                  style: TextStyle(color: Colors.white60, height: 1.35),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF141832).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: value
              ? const Color(0xFF6E7DFF).withValues(alpha: 0.65)
              : Colors.white12,
        ),
      ),
      child: SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        secondary: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: const Color(0xFF6274FF).withValues(alpha: 0.18),
          ),
          child: Icon(icon, color: const Color(0xFF9DA8FF)),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.4,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Colors.white54),
        ),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
