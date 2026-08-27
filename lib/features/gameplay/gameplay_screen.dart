import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:skyjumper/game/data/player_progress_repository.dart';
import 'package:skyjumper/game/engine/gameplay_engine.dart';

class GameplayScreen extends StatefulWidget {
  const GameplayScreen({
    super.key,
    required this.progress,
  });

  final PlayerProgressRepository progress;

  @override
  State<GameplayScreen> createState() => _GameplayScreenState();
}

class _GameplayScreenState extends State<GameplayScreen>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  SkyJumperEngine? _engine;
  Duration? _lastElapsed;
  bool _runCommitted = false;
  bool _initializedForLayout = false;

  SkyJumperEngine get engine => _engine!;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initializedForLayout) return;
    _initializedForLayout = true;

    final media = MediaQuery.of(context);
    final safeHeight = media.size.height - media.padding.vertical;
    final scale = media.size.width / 360.0;
    final logicalHeight = safeHeight / scale;
    _engine = SkyJumperEngine(
      tuning: GameTuning(viewportHeight: logicalHeight),
    );
  }

  void _onTick(Duration elapsed) {
    final current = _engine;
    if (current == null || !mounted) return;

    final previous = _lastElapsed;
    _lastElapsed = elapsed;
    if (previous == null) return;

    final dt = (elapsed - previous).inMicroseconds / 1000000.0;
    current.update(dt);

    if (current.gameOver && !_runCommitted) {
      _runCommitted = true;
      unawaited(_commitRun());
    }

    setState(() {});
  }

  Future<void> _commitRun() async {
    await widget.progress.commitRun(
      score: engine.score,
      runGold: engine.runGold,
    );
    if (mounted) setState(() {});
  }

  void _setInputFromX(double x, double width) {
    if (engine.gameOver) return;
    final deadZone = width * 0.08;
    final center = width / 2;
    if ((x - center).abs() <= deadZone) {
      engine.setHorizontalInput(0);
    } else {
      engine.setHorizontalInput(x < center ? -1 : 1);
    }
  }

  void _restart() {
    engine.reset();
    _runCommitted = false;
    _lastElapsed = null;
    setState(() {});
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_engine == null) {
      return const Scaffold(body: SizedBox.expand());
    }

    return Scaffold(
      backgroundColor: const Color(0xFF9BE7FF),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (event) =>
                  _setInputFromX(event.localPosition.dx, constraints.maxWidth),
              onPointerMove: (event) =>
                  _setInputFromX(event.localPosition.dx, constraints.maxWidth),
              onPointerUp: (_) => engine.setHorizontalInput(0),
              onPointerCancel: (_) => engine.setHorizontalInput(0),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _GameplayPainter(engine: engine),
                    ),
                  ),
                  Positioned(
                    left: 14,
                    top: 12,
                    child: _HudPill(
                      icon: Icons.monetization_on_rounded,
                      text: '${engine.runGold}',
                    ),
                  ),
                  Positioned(
                    right: 14,
                    top: 12,
                    child: _HudPill(
                      icon: Icons.stars_rounded,
                      text: '${engine.score}',
                    ),
                  ),
                  Positioned(
                    left: 14,
                    top: 58,
                    child: _HudPill(
                      icon: Icons.local_fire_department_rounded,
                      text: 'x${engine.combo}',
                    ),
                  ),
                  Positioned(
                    left: 12,
                    bottom: 12,
                    child: _ControlHint(
                      icon: Icons.chevron_left_rounded,
                      label: 'SOL',
                    ),
                  ),
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: _ControlHint(
                      icon: Icons.chevron_right_rounded,
                      label: 'SAĞ',
                    ),
                  ),
                  if (engine.gameOver)
                    Positioned.fill(
                      child: _GameOverPanel(
                        score: engine.score,
                        bestScore: widget.progress.bestScore,
                        runGold: engine.runGold,
                        onRestart: _restart,
                        onHome: () => Navigator.of(context).pop(),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _GameplayPainter extends CustomPainter {
  _GameplayPainter({required this.engine});

  final SkyJumperEngine engine;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / engine.tuning.worldWidth;

    final skyRect = Offset.zero & size;
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF5EC8FF), Color(0xFFDDF8FF)],
      ).createShader(skyRect);
    canvas.drawRect(skyRect, skyPaint);

    final cloudPaint = Paint()..color = Colors.white.withValues(alpha: 0.38);
    for (var i = 0; i < 8; i++) {
      final x = ((i * 71 + 20) % 340) * scale;
      final worldY = engine.cameraTop + 80 + i * 135;
      final y = (worldY - engine.cameraTop) * scale;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, y),
          width: 66 * scale,
          height: 22 * scale,
        ),
        cloudPaint,
      );
    }

    for (final platform in engine.platforms) {
      final y = (platform.y - engine.cameraTop) * scale;
      if (y < -30 || y > size.height + 30) continue;

      Color color;
      switch (platform.kind) {
        case PlatformKind.normal:
          color = const Color(0xFF4CAF50);
        case PlatformKind.moving:
          color = const Color(0xFF7E57C2);
        case PlatformKind.bounce:
          color = const Color(0xFFFF8A3D);
      }

      final platformRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          platform.x * scale,
          y,
          platform.width * scale,
          platform.height * scale,
        ),
        Radius.circular(6 * scale),
      );
      canvas.drawRRect(platformRect, Paint()..color = color);
      canvas.drawRRect(
        platformRect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2 * scale
          ..color = Colors.white.withValues(alpha: 0.7),
      );
    }

    for (final coin in engine.coins) {
      if (coin.collected) continue;
      final y = (coin.y - engine.cameraTop) * scale;
      if (y < -30 || y > size.height + 30) continue;
      canvas.drawCircle(
        Offset(coin.x * scale, y),
        coin.radius * scale,
        Paint()..color = const Color(0xFFFFC928),
      );
      canvas.drawCircle(
        Offset(coin.x * scale, y),
        coin.radius * 0.52 * scale,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2 * scale
          ..color = const Color(0xFFFFF3A1),
      );
    }

    final px = engine.player.x * scale;
    final py = (engine.player.y - engine.cameraTop) * scale;
    final playerRect = Rect.fromLTWH(
      px,
      py,
      engine.player.width * scale,
      engine.player.height * scale,
    );

    // Stable pivot/no rotation: the recovered sprite rule is respected even
    // before the original raster character sheets are restored.
    canvas.drawOval(playerRect, Paint()..color = const Color(0xFFFF8A32));
    final eyePaint = Paint()..color = const Color(0xFF1D1D1D);
    canvas.drawCircle(
      Offset(px + engine.player.width * 0.34 * scale,
          py + engine.player.height * 0.39 * scale),
      2.2 * scale,
      eyePaint,
    );
    canvas.drawCircle(
      Offset(px + engine.player.width * 0.66 * scale,
          py + engine.player.height * 0.39 * scale),
      2.2 * scale,
      eyePaint,
    );
    final smile = Path()
      ..moveTo(px + engine.player.width * 0.35 * scale,
          py + engine.player.height * 0.62 * scale)
      ..quadraticBezierTo(
        px + engine.player.width * 0.50 * scale,
        py + engine.player.height * 0.73 * scale,
        px + engine.player.width * 0.67 * scale,
        py + engine.player.height * 0.60 * scale,
      );
    canvas.drawPath(
      smile,
      Paint()
        ..color = eyePaint.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * scale
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _GameplayPainter oldDelegate) => true;
}

class _HudPill extends StatelessWidget {
  const _HudPill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white24),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ControlHint extends StatelessWidget {
  const _ControlHint({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: 0.42,
        child: Container(
          width: 72,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 24),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GameOverPanel extends StatelessWidget {
  const _GameOverPanel({
    required this.score,
    required this.bestScore,
    required this.runGold,
    required this.onRestart,
    required this.onHome,
  });

  final int score;
  final int bestScore;
  final int runGold;
  final VoidCallback onRestart;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.68),
      child: Center(
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFFDFBF4),
            borderRadius: BorderRadius.circular(26),
            boxShadow: const [
              BoxShadow(blurRadius: 24, color: Colors.black38),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'GAME OVER',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 18),
              Text('Skor  $score',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800)),
              Text('En İyi  $bestScore',
                  style: const TextStyle(fontSize: 16)),
              Text('Coin  +$runGold',
                  style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onRestart,
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('TEKRAR'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onHome,
                  icon: const Icon(Icons.home_rounded),
                  label: const Text('ANA MENÜ'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
