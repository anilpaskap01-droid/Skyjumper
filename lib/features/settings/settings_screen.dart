import 'package:flutter/material.dart';
import 'package:skyjumper/game/data/player_progress_repository.dart';
import 'package:skyjumper/services/google_auth_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.progress});

  final PlayerProgressRepository progress;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final GoogleAuthService _googleAuth = GoogleAuthService.instance;
  String? _googleEmail;
  String? _googleName;
  bool _googleBusy = false;

  @override
  void initState() {
    super.initState();
    _restoreGoogleSession();
  }

  Future<void> _restoreGoogleSession() async {
    final account = await _googleAuth.restoreSession();
    if (!mounted || account == null) return;
    setState(() {
      _googleEmail = account.email;
      _googleName = account.displayName;
    });
  }

  Future<void> _signInGoogle() async {
    if (!_googleAuth.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('GOOGLE_CLIENT_ID tanımlı değil. ZIP içindeki kurulum dosyasına bak.'),
        ),
      );
      return;
    }

    setState(() => _googleBusy = true);
    try {
      final account = await _googleAuth.signIn();
      if (!mounted || account == null) return;
      setState(() {
        _googleEmail = account.email;
        _googleName = account.displayName;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google giriş hatası: $error')),
      );
    } finally {
      if (mounted) setState(() => _googleBusy = false);
    }
  }

  Future<void> _signOutGoogle() async {
    setState(() => _googleBusy = true);
    try {
      await _googleAuth.signOut();
      if (!mounted) return;
      setState(() {
        _googleEmail = null;
        _googleName = null;
      });
    } finally {
      if (mounted) setState(() => _googleBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.progress;
    final googleSignedIn = _googleEmail != null;
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
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 11),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0C1328),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF7AA7FF), width: 1.25),
                        ),
                        child: Row(
                          children: <Widget>[
                            const Icon(Icons.account_circle_rounded, color: Color(0xFF9AB7FF), size: 38),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    googleSignedIn ? (_googleName?.isNotEmpty == true ? _googleName! : 'GOOGLE HESABI') : 'GOOGLE HESABI',
                                    style: const TextStyle(color: Color(0xFFB8C8FF), fontWeight: FontWeight.w900),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    googleSignedIn
                                        ? _googleEmail!
                                        : (_googleAuth.isConfigured ? 'Firebase olmadan Google ile giriş' : 'Client ID build sırasında verilecek'),
                                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: _googleBusy ? null : (googleSignedIn ? _signOutGoogle : _signInGoogle),
                              child: _googleBusy
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                  : Text(googleSignedIn ? 'ÇIKIŞ' : 'GİRİŞ'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 1),
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
