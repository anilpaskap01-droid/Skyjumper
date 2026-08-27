import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:skyjumper/game/data/player_progress_repository.dart';
import 'package:skyjumper/game/engine/gameplay_engine.dart';
import 'package:skyjumper/widgets/skin_avatar.dart';

class GameplayScreen extends StatefulWidget {
  const GameplayScreen({super.key, required this.progress});

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
  bool _initialized = false;
  bool _paused = false;
  int _previousGold = 0;
  int _floor = 0;
  double? _highestLandingY;
  double _impactUntil = -1;

  SkyJumperEngine get engine => _engine!;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final media = MediaQuery.of(context);
    final safeHeight = media.size.height - media.padding.vertical;
    final scale = media.size.width / 360;
    _engine = SkyJumperEngine(
      tuning: GameTuning(viewportHeight: safeHeight / scale),
    );
    _highestLandingY = engine.player.y;
  }

  void _onTick(Duration elapsed) {
    if (_engine == null || !mounted) return;
    final previous = _lastElapsed;
    _lastElapsed = elapsed;
    if (previous == null) return;
    if (_paused || engine.gameOver) {
      setState(() {});
      return;
    }

    final beforeVy = engine.player.vy;
    final dt = (elapsed - previous).inMicroseconds / 1000000.0;
    engine.update(dt);

    final landed = beforeVy > 0 && engine.player.vy < 0 && !engine.gameOver;
    if (landed) {
      final landingY = engine.player.y;
      final highest = _highestLandingY;
      if (highest == null || landingY < highest - 10) {
        _floor += 1;
        _highestLandingY = landingY;
      }
      _impactUntil = engine.elapsedSeconds + .13;
      if (widget.progress.vibrationEnabled) {
        unawaited(HapticFeedback.lightImpact());
      }
    }

    if (engine.runGold > _previousGold) {
      _previousGold = engine.runGold;
      if (widget.progress.soundEnabled) {
        unawaited(SystemSound.play(SystemSoundType.click));
      }
      if (widget.progress.vibrationEnabled) {
        unawaited(HapticFeedback.selectionClick());
      }
    }

    if (engine.gameOver && !_runCommitted) {
      _runCommitted = true;
      unawaited(_commitRun());
    }
    setState(() {});
  }

  Future<void> _commitRun() async {
    await widget.progress.commitRun(score: engine.score, runGold: engine.runGold);
    if (mounted) setState(() {});
  }

  void _setInput(double x, double width) {
    if (_paused || engine.gameOver) return;
    final center = width / 2;
    final dead = width * .07;
    if ((x - center).abs() <= dead) {
      engine.setHorizontalInput(0);
    } else {
      engine.setHorizontalInput(x < center ? -1 : 1);
    }
  }

  void _restart() {
    engine.reset();
    _runCommitted = false;
    _paused = false;
    _lastElapsed = null;
    _previousGold = 0;
    _floor = 0;
    _highestLandingY = engine.player.y;
    _impactUntil = -1;
    setState(() {});
  }

  void _togglePause() {
    if (engine.gameOver) return;
    engine.setHorizontalInput(0);
    setState(() => _paused = !_paused);
  }

  Future<void> _home() async {
    if (!_runCommitted) {
      _runCommitted = true;
      await _commitRun();
    }
    if (mounted) Navigator.of(context).pop();
  }

  int get _skinFrame {
    final jump = engine.tuning.jumpVelocity.abs();
    final normalized = ((engine.player.vy + jump) / (jump * 2)).clamp(0.0, 1.0);
    return (normalized * 15).round();
  }

  @override
  void dispose() {
    _ticker.dispose();
    if (!_runCommitted && _engine != null) {
      unawaited(widget.progress.commitRun(score: engine.score, runGold: engine.runGold));
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_engine == null) {
      return const Scaffold(backgroundColor: Color(0xFF061226));
    }

    final biome = _Biome.forFloor(_floor);
    final skin = widget.progress.equippedSkin;
    return Scaffold(
      backgroundColor: biome.bottom,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scale = constraints.maxWidth / engine.tuning.worldWidth;
            final playerCenterX = (engine.player.x + engine.player.width / 2) * scale;
            final playerBottom = (engine.player.y + engine.player.height - engine.cameraTop) * scale;
            final avatarWidth = 74 * scale;
            final avatarHeight = 98 * scale;
            final impact = widget.progress.cameraShakeEnabled &&
                !widget.progress.reducedEffects &&
                engine.elapsedSeconds < _impactUntil;
            final shake = impact ? math.sin(engine.elapsedSeconds * 180) * 3 * scale : 0.0;

            return Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (event) => _setInput(event.localPosition.dx, constraints.maxWidth),
              onPointerMove: (event) => _setInput(event.localPosition.dx, constraints.maxWidth),
              onPointerUp: (_) => engine.setHorizontalInput(0),
              onPointerCancel: (_) => engine.setHorizontalInput(0),
              child: Stack(
                children: <Widget>[
                  Positioned.fill(
                    child: Transform.translate(
                      offset: Offset(shake, 0),
                      child: CustomPaint(
                        painter: _GameplayPainter(
                          engine: engine,
                          biome: biome,
                          floor: _floor,
                          reducedEffects: widget.progress.reducedEffects,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: playerCenterX - avatarWidth / 2 + shake,
                    top: playerBottom - avatarHeight,
                    width: avatarWidth,
                    height: avatarHeight,
                    child: IgnorePointer(child: SkinAvatar(skin: skin, frame: _skinFrame)),
                  ),
                  Positioned(left: 9, top: 9, child: _ScoreHud(score: engine.score, combo: engine.combo)),
                  Positioned(
                    right: 11,
                    top: 8,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        _PauseButton(paused: _paused, onTap: _togglePause),
                        const SizedBox(height: 10),
                        _CoinPill(value: widget.progress.gold + engine.runGold),
                      ],
                    ),
                  ),
                  Positioned(
                    right: 9,
                    bottom: 16,
                    child: Text(
                      _altitudeLabel(),
                      style: const TextStyle(
                        color: Color(0xFFFFD04A),
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        shadows: <Shadow>[Shadow(color: Colors.black87, blurRadius: 4)],
                      ),
                    ),
                  ),
                  if (_paused && !engine.gameOver)
                    Positioned.fill(
                      child: _PauseOverlay(onResume: _togglePause, onRestart: _restart, onHome: _home),
                    ),
                  if (engine.gameOver)
                    Positioned.fill(
                      child: _GameOverOverlay(
                        score: engine.score,
                        best: math.max(widget.progress.bestScore, engine.score),
                        gold: engine.runGold,
                        onRestart: _restart,
                        onHome: _home,
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

  String _altitudeLabel() {
    final meters = math.max(0, (engine.tuning.startPlayerY - engine.highestPlayerY) * 3.2);
    if (meters >= 1000000) return '${(meters / 1000000).toStringAsFixed(1)}M';
    if (meters >= 1000) return '${(meters / 1000).toStringAsFixed(1)} km';
    return '${meters.toStringAsFixed(0)} m';
  }
}

class _ScoreHud extends StatelessWidget {
  const _ScoreHud({required this.score, required this.combo});

  final int score;
  final int combo;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xD91A2131),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white30),
          ),
          child: Text(
            '$score',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              height: 1,
              fontWeight: FontWeight.w900,
              shadows: <Shadow>[Shadow(color: Colors.black87, blurRadius: 3)],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 13,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: const Color(0xD90D4056),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFF34CFEF)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List<Widget>.generate(
              math.min(combo, 6),
              (_) => const Padding(
                padding: EdgeInsets.symmetric(horizontal: 1),
                child: Icon(Icons.change_history_rounded, size: 11, color: Color(0xFF47E6A0)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xDD0E6895),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: const Color(0xFF4EE9FF)),
          ),
          child: Text('x$combo', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
        ),
      ],
    );
  }
}

class _PauseButton extends StatelessWidget {
  const _PauseButton({required this.paused, required this.onTap});

  final bool paused;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xC9231B25),
          border: Border.all(color: Colors.white54),
        ),
        child: Icon(paused ? Icons.play_arrow_rounded : Icons.pause_rounded, color: Colors.white, size: 30),
      ),
    );
  }
}

class _CoinPill extends StatelessWidget {
  const _CoinPill({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xC9281E20),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFFFD15A).withValues(alpha: .65)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text('$value', style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900)),
          const SizedBox(width: 5),
          const Icon(Icons.monetization_on_rounded, color: Color(0xFFFFC735), size: 20),
        ],
      ),
    );
  }
}

class _GameplayPainter extends CustomPainter {
  _GameplayPainter({required this.engine, required this.biome, required this.floor, required this.reducedEffects});

  final SkyJumperEngine engine;
  final _Biome biome;
  final int floor;
  final bool reducedEffects;

  @override
  void paint(Canvas canvas, Size size) {
    final worldScale = size.width / engine.tuning.worldWidth;
    _background(canvas, size, worldScale);
    _platforms(canvas, size, worldScale);
    _coins(canvas, size, worldScale);
    _ruler(canvas, size);
  }

  void _background(Canvas canvas, Size size, double scale) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[biome.top, biome.mid, biome.bottom],
        ).createShader(rect),
    );

    if (biome.id == 'lava') {
      final glow = Paint()
        ..color = const Color(0xFFFF9D21).withValues(alpha: .7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4;
      for (var i = 0; i < 7; i++) {
        final y = ((i * 137 + engine.cameraTop.abs() * .2) % (size.height + 120)) - 60;
        final p = Path()
          ..moveTo(-20, y)
          ..cubicTo(size.width * .25, y - 25, size.width * .45, y + 35, size.width * .7, y + 2)
          ..cubicTo(size.width * .82, y - 18, size.width * .93, y + 22, size.width + 20, y - 4);
        canvas.drawPath(p, glow);
      }
    } else if (biome.id == 'crystal') {
      final crystal = Paint()
        ..color = const Color(0xFF70D7FF).withValues(alpha: .18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      for (var i = 0; i < 14; i++) {
        final x = ((i * 61) % 360) * scale;
        final y = ((i * 117 + engine.cameraTop.abs() * .13) % (size.height / scale + 80)) * scale;
        final p = Path()..moveTo(x, y - 22)..lineTo(x + 14, y)..lineTo(x, y + 24)..lineTo(x - 14, y)..close();
        canvas.drawPath(p, crystal);
      }
    } else if (biome.id == 'mount' || biome.id == 'iceberg') {
      final mountain = Path()
        ..moveTo(0, size.height)
        ..lineTo(size.width * .23, size.height * .6)
        ..lineTo(size.width * .42, size.height)
        ..lineTo(size.width * .63, size.height * .54)
        ..lineTo(size.width, size.height)
        ..close();
      canvas.drawPath(mountain, Paint()..color = biome.id == 'iceberg' ? const Color(0x448DE4F2) : const Color(0x553C4B57));
    } else if (biome.id == 'earth') {
      canvas.drawCircle(Offset(size.width * .78, size.height * .25), size.width * .18, Paint()..color = const Color(0xFF2D88C5));
      canvas.drawCircle(Offset(size.width * .73, size.height * .21), size.width * .07, Paint()..color = const Color(0xFF3FA45B));
    } else if (biome.id == 'moon') {
      canvas.drawCircle(Offset(size.width * .72, size.height * .23), size.width * .15, Paint()..color = const Color(0xFFB8BCC6));
    }

    if (reducedEffects) return;
    final particle = Paint()..color = Colors.white.withValues(alpha: biome.id == 'lava' ? .16 : .58);
    for (var i = 0; i < 35; i++) {
      final x = ((i * 83 + 11) % 359) * scale;
      final y = ((i * 103 + engine.cameraTop.abs() * (.05 + (i % 3) * .02)) % (size.height / scale + 80) - 40) * scale;
      canvas.drawCircle(Offset(x, y), (.6 + (i % 3) * .55) * scale, particle);
    }
  }

  void _platforms(Canvas canvas, Size size, double scale) {
    for (final platform in engine.platforms) {
      final y = (platform.y - engine.cameraTop) * scale;
      if (y < -40 || y > size.height + 40) continue;
      final rect = Rect.fromLTWH(platform.x * scale, y, platform.width * scale, platform.height * scale);
      if (platform.kind == PlatformKind.bounce) {
        final r = RRect.fromRectAndRadius(rect.inflate(2 * scale), Radius.circular(5 * scale));
        canvas.drawRRect(r, Paint()..color = const Color(0xFF43D892));
        for (var x = rect.left + 8 * scale; x < rect.right - 5 * scale; x += 12 * scale) {
          final tri = Path()
            ..moveTo(x, rect.center.dy - 3 * scale)
            ..lineTo(x + 4 * scale, rect.center.dy + 4 * scale)
            ..lineTo(x - 4 * scale, rect.center.dy + 4 * scale)
            ..close();
          canvas.drawPath(tri, Paint()..color = const Color(0xFFE7FFF3));
          canvas.drawPath(tri, Paint()..color = const Color(0xFF238B62)..style = PaintingStyle.stroke..strokeWidth = scale);
        }
        continue;
      }

      final r = RRect.fromRectAndRadius(rect, Radius.circular(5 * scale));
      canvas.drawRRect(r, Paint()..color = biome.platform);
      canvas.drawRRect(
        r,
        Paint()
          ..color = biome.platformEdge
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2 * scale,
      );
      final texture = Paint()
        ..color = Colors.black.withValues(alpha: .25)
        ..strokeWidth = scale;
      for (var x = rect.left + 7 * scale; x < rect.right; x += 11 * scale) {
        canvas.drawLine(Offset(x, rect.top + 3 * scale), Offset(x + 5 * scale, rect.bottom - 3 * scale), texture);
      }
      if (platform.kind == PlatformKind.moving) {
        canvas.drawCircle(Offset(rect.center.dx, rect.center.dy), 3 * scale, Paint()..color = const Color(0xFF73E5FF));
      }
    }
  }

  void _coins(Canvas canvas, Size size, double scale) {
    for (final coin in engine.coins) {
      if (coin.collected) continue;
      final y = (coin.y - engine.cameraTop) * scale;
      if (y < -30 || y > size.height + 30) continue;
      final center = Offset(coin.x * scale, y);
      canvas.drawCircle(center, coin.radius * 1.25 * scale, Paint()..color = const Color(0x55FFB400));
      canvas.drawCircle(center, coin.radius * scale, Paint()..color = const Color(0xFFFFC526));
      canvas.drawCircle(center, coin.radius * .7 * scale, Paint()..color = const Color(0xFFFFE36A)..style = PaintingStyle.stroke..strokeWidth = 1.7 * scale);
      final star = Path();
      for (var i = 0; i < 10; i++) {
        final a = -math.pi / 2 + i * math.pi / 5;
        final r = (i.isEven ? coin.radius * .48 : coin.radius * .21) * scale;
        final p = center + Offset(math.cos(a) * r, math.sin(a) * r);
        if (i == 0) star.moveTo(p.dx, p.dy); else star.lineTo(p.dx, p.dy);
      }
      star.close();
      canvas.drawPath(star, Paint()..color = const Color(0xFFCE8B00));
    }
  }

  void _ruler(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFFFA72C).withValues(alpha: .85)..strokeWidth = 1.5;
    for (double y = 8; y < size.height; y += 18) {
      final major = ((y / 18).round() % 5 == 0);
      canvas.drawLine(Offset(size.width - (major ? 20 : 11), y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GameplayPainter oldDelegate) => true;
}

class _PauseOverlay extends StatelessWidget {
  const _PauseOverlay({required this.onResume, required this.onRestart, required this.onHome});

  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withValues(alpha: .72),
      child: Center(
        child: Container(
          width: 290,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF091A31),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFF3BCFF1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text('DURAKLATILDI', style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w900)),
              const SizedBox(height: 16),
              _OverlayButton(label: 'DEVAM', icon: Icons.play_arrow_rounded, onTap: onResume, primary: true),
              const SizedBox(height: 8),
              _OverlayButton(label: 'YENİDEN BAŞLAT', icon: Icons.replay_rounded, onTap: onRestart),
              const SizedBox(height: 8),
              _OverlayButton(label: 'MENÜ', icon: Icons.home_rounded, onTap: onHome),
            ],
          ),
        ),
      ),
    );
  }
}

class _GameOverOverlay extends StatelessWidget {
  const _GameOverOverlay({required this.score, required this.best, required this.gold, required this.onRestart, required this.onHome});

  final int score;
  final int best;
  final int gold;
  final VoidCallback onRestart;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withValues(alpha: .74),
      child: Center(
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(21),
          decoration: BoxDecoration(
            color: const Color(0xFF07182C),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFFF8E35), width: 1.5),
            boxShadow: const <BoxShadow>[BoxShadow(color: Color(0x55FF6A2D), blurRadius: 22)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text('GAME OVER', style: TextStyle(color: Color(0xFFFF8D3A), fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
              const SizedBox(height: 14),
              _ResultRow(label: 'SCORE', value: '$score'),
              _ResultRow(label: 'BEST', value: '$best'),
              _ResultRow(label: 'GOLD', value: '+$gold'),
              const SizedBox(height: 16),
              _OverlayButton(label: 'TEKRAR', icon: Icons.replay_rounded, onTap: onRestart, primary: true),
              const SizedBox(height: 8),
              _OverlayButton(label: 'MENÜ', icon: Icons.home_rounded, onTap: onHome),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(label, style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.w800))),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _OverlayButton extends StatelessWidget {
  const _OverlayButton({required this.label, required this.icon, required this.onTap, this.primary = false});

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: FilledButton.icon(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: primary ? const Color(0xFF19AEEA) : const Color(0xFF152A43),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
        ),
        icon: Icon(icon),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
    );
  }
}

class _Biome {
  const _Biome(this.id, this.startFloor, this.top, this.mid, this.bottom, this.platform, this.platformEdge);

  final String id;
  final int startFloor;
  final Color top;
  final Color mid;
  final Color bottom;
  final Color platform;
  final Color platformEdge;

  static const values = <_Biome>[
    _Biome('lava', 0, Color(0xFF6B170E), Color(0xFFB83316), Color(0xFF3A100D), Color(0xFF6B3A25), Color(0xFF24150F)),
    _Biome('crystal', 15, Color(0xFF173966), Color(0xFF4B72A7), Color(0xFF152441), Color(0xFF7ED6E6), Color(0xFFCBFAFF)),
    _Biome('gold', 30, Color(0xFF5D4215), Color(0xFFC28A22), Color(0xFF4D3210), Color(0xFFB88325), Color(0xFFFFE18A)),
    _Biome('soil', 45, Color(0xFF3E261D), Color(0xFF73513C), Color(0xFF251A16), Color(0xFF70523D), Color(0xFFB28A68)),
    _Biome('ground', 65, Color(0xFF5D7E95), Color(0xFF95B8C7), Color(0xFF527064), Color(0xFF71834E), Color(0xFFB3C987)),
    _Biome('mount', 85, Color(0xFF61798D), Color(0xFF9AB2C0), Color(0xFF45515B), Color(0xFF666A68), Color(0xFFB4BBB9)),
    _Biome('iceberg', 107, Color(0xFF55BDF0), Color(0xFFB8EDFF), Color(0xFF76C7E3), Color(0xFFD4F4FF), Color(0xFF79B7D0)),
    _Biome('sky', 130, Color(0xFF3298E6), Color(0xFF8CD4FF), Color(0xFFD9F3FF), Color(0xFFF2F6FB), Color(0xFF9BC1D7)),
    _Biome('atmosphere', 155, Color(0xFF183F76), Color(0xFF356CB4), Color(0xFF101F45), Color(0xFF4C6E8C), Color(0xFF8BAAC0)),
    _Biome('earth', 182, Color(0xFF071836), Color(0xFF0E3764), Color(0xFF050C20), Color(0xFF3A5069), Color(0xFF7990A6)),
    _Biome('moon', 210, Color(0xFF111429), Color(0xFF2E314A), Color(0xFF090B18), Color(0xFF777781), Color(0xFFC0C0C7)),
    _Biome('space', 237, Color(0xFF120A45), Color(0xFF382183), Color(0xFF0B0627), Color(0xFF4B326D), Color(0xFF9A78BC)),
    _Biome('galaxy', 265, Color(0xFF17055D), Color(0xFF4821A9), Color(0xFF0A0330), Color(0xFF5E4388), Color(0xFFC193FF)),
  ];

  static _Biome forFloor(int floor) {
    var selected = values.first;
    for (final biome in values) {
      if (floor >= biome.startFloor) selected = biome;
    }
    return selected;
  }
}
