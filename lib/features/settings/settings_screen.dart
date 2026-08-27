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
      backgroundColor: const Color(0xFF040A17),
      body: Stack(
        children: <Widget>[
          const Positioned.fill(child: CustomPaint(painter: _CircuitBackgroundPainter())),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 26),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 460),
                  padding: const EdgeInsets.fromLTRB(14, 20, 14, 16),
                  decoration: BoxDecoration(
                    color: const Color(0xEE090C22),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFFF35CA), width: 1.5),
                    boxShadow: const <BoxShadow>[
                      BoxShadow(color: Color(0x66FF2DC7), blurRadius: 22),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Text(
                        'AYARLAR',
                        style: TextStyle(
                          color: Color(0xFFFF49D0),
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          shadows: <Shadow>[Shadow(color: Color(0xFFFF2AC7), blurRadius: 15)],
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'CİHAZA GÖRE OYUN HİSSİNİ AYARLA',
                        style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: .8),
                      ),
                      const SizedBox(height: 20),
                      _NeonSetting(
                        color: const Color(0xFF37D9FF),
                        icon: Icons.volume_up_rounded,
                        title: 'SES VE MÜZİK',
                        subtitle: 'Oyun ve arayüz sesleri',
                        value: progress.soundEnabled,
                        onChanged: (value) async {
                          await progress.setSoundEnabled(value);
                          if (mounted) setState(() {});
                        },
                      ),
                      _NeonSetting(
                        color: const Color(0xFF55F68B),
                        icon: Icons.vibration_rounded,
                        title: 'TİTREŞİM',
                        subtitle: 'İniş ve coinlerde dokunsal tepki',
                        value: progress.vibrationEnabled,
                        onChanged: (value) async {
                          await progress.setVibrationEnabled(value);
                          if (mounted) setState(() {});
                        },
                      ),
                      _NeonSetting(
                        color: const Color(0xFFFFB843),
                        icon: Icons.videocam_rounded,
                        title: 'DARBE SARSINTISI',
                        subtitle: 'İnişlerde kısa kamera tepkisi',
                        value: progress.cameraShakeEnabled,
                        onChanged: (value) async {
                          await progress.setCameraShakeEnabled(value);
                          if (mounted) setState(() {});
                        },
                      ),
                      _NeonSetting(
                        color: const Color(0xFFFF4EC7),
                        icon: Icons.auto_awesome_rounded,
                        title: 'AZALTILMIŞ EFEKT',
                        subtitle: 'Daha az hareket ve parçacık',
                        value: progress.reducedEffects,
                        onChanged: (value) async {
                          await progress.setReducedEffects(value);
                          if (mounted) setState(() {});
                        },
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF5DE8FF),
                            side: const BorderSide(color: Color(0xFF49DDF7), width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(Icons.arrow_back_rounded),
                          label: const Text('MENÜYE DÖN', style: TextStyle(fontWeight: FontWeight.w900)),
                        ),
                      ),
                      const SizedBox(height: 9),
                      const Text(
                        'Değişiklikler anında kaydedilir.',
                        style: TextStyle(color: Colors.white38, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NeonSetting extends StatelessWidget {
  const _NeonSetting({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1328),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: .86), width: 1.25),
        boxShadow: <BoxShadow>[BoxShadow(color: color.withValues(alpha: .16), blurRadius: 10)],
      ),
      child: SwitchListTile.adaptive(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        value: value,
        onChanged: onChanged,
        activeColor: color,
        secondary: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .13),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: .45)),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w900, letterSpacing: .7)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 11)),
      ),
    );
  }
}

class _CircuitBackgroundPainter extends CustomPainter {
  const _CircuitBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF040A17));
    final grid = Paint()
      ..color = const Color(0xFF143A52).withValues(alpha: .32)
      ..strokeWidth = 1;
    for (double x = 8; x < size.width; x += 26) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 8; y < size.height; y += 26) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final nodes = Paint()..color = const Color(0xFF33CFF2).withValues(alpha: .4);
    for (double x = 21; x < size.width; x += 78) {
      for (double y = 18; y < size.height; y += 78) {
        canvas.drawCircle(Offset(x, y), 1.8, nodes);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
