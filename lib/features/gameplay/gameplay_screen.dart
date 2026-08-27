import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:skyjumper/game/data/player_progress_repository.dart';
import 'package:skyjumper/game/data/skin_catalog.dart';
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
  bool _initializedForLayout = false;
  bool _paused = false;
  int _previousRunGold = 0;
  double _landingEffectUntil = -1;

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

    final previousElapsed = _lastElapsed;
    _lastElapsed = elapsed;
    if (previousElapsed == null) return;
    if (_paused || current.gameOver) {
      setState(() {});
      return;
    }

    final dt = (elapsed - previousElapsed).inMicroseconds / 1000000.0;
    final beforeVy = current.player.vy;
    current.update(dt);

    if (current.runGold > _previousRunGold) {
      _previousRunGold = current.runGold;
      if (widget.progress.soundEnabled) {
        unawaited(SystemSound.play(SystemSoundType.click));
      }
      if (widget.progress.vibrationEnabled) {
        unawaited(HapticFeedback.selectionClick());
      }
    }

    final landed = beforeVy > 0 && current.player.vy < 0 && !current.gameOver;
    if (landed) {
      _landingEffectUntil = current.elapsedSeconds + 0.13;
      if (widget.progress.vibrationEnabled) {
        unawaited(HapticFeedback.lightImpact());
      }
    }

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
    if (engine.gameOver || _paused) return;
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
    _paused = false;
    _lastElapsed = null;
    _previousRunGold = 0;
    _landingEffectUntil = -1;
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

  @override
  void dispose() {
    _ticker.dispose();
    if (!_runCommitted && _engine != null) {
      _runCommitted = true;
      unawaited(
        widget.progress.commitRun(
          score: engine.score,
          runGold: engine.runGold,
        ),
      );
    }
    super.dispose();
  }

  int _frameForSkin(SkinDefinition skin) {
    if (skin.visualKind != SkinVisualKind.spriteSheet) return 0;
    if (engine.elapsedSeconds <= _landingEffectUntil) {
      if (skin.id == 'pirate') return 6;
      if (skin.id == 'king') return 10;
    }

    final vy = engine.player.vy;
    final jump = engine.tuning.jumpVelocity.abs();
    if (vy < 0) {
      final t = (1 - (-vy / jump)).clamp(0.0, 1.0);
      if (skin.id == 'pirate') {
        return (2 + t * 2).round().clamp(2, 4).toInt();
      }
      if (skin.id == 'king') {
        return (3 + t * 4).round().clamp(3, 7).toInt();
      }
    }

    final fall = (vy / jump).clamp(0.0, 1.0);
    if (skin.id == 'pirate') {
      return (5 + fall * 2).round().clamp(5, 7).toInt();
    }
    if (skin.id == 'king') {
      return (8 + fall * 4).round().clamp(8, 12).toInt();
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    if (_engine == null) {
      return const Scaffold(backgroundColor: Color(0xFF090A18));
    }

    final skin = widget.progress.equippedSkin;
    return Scaffold(
      backgroundColor: const Color(0xFF090A18),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scale = constraints.maxWidth / engine.tuning.worldWidth;
            final playerVisualWidth = 84.0 * scale;
            final playerVisualHeight = 96.0 * scale;
            final playerCenterX =
                (engine.player.x + engine.player.width / 2) * scale;
            final playerBottomY =
                (engine.player.y + engine.player.height - engine.cameraTop) *
                    scale;
            final frame = _frameForSkin(skin);

            final shakeActive = widget.progress.cameraShakeEnabled &&
                !widget.progress.reducedEffects &&
                engine.elapsedSeconds <= _landingEffectUntil;
            final shakeX = shakeActive
                ? math.sin(engine.elapsedSeconds * 165) * 3.2 * scale
                : 0.0;
            final shakeY = shakeActive
                ? math.cos(engine.elapsedSeconds * 190) * 1.8 * scale
                : 0.0;

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
                    child: Transform.translate(
                      offset: Offset(shakeX, shakeY),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _GameplayPainter(
                                engine: engine,
                                reducedEffects: widget.progress.reducedEffects,
                              ),
                            ),
                          ),
                          Positioned(
                            left: playerCenterX - playerVisualWidth / 2,
                            top: playerBottomY - playerVisualHeight,
                            width: playerVisualWidth,
                            height: playerVisualHeight,
                            child: IgnorePointer(
                              child: SkinAvatar(skin: skin, frame: frame),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    top: 10,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _HudPill(
                          icon: Icons.stars_rounded,
                          text: '${engine.score}',
                        ),
                        const SizedBox(height: 7),
                        _HudPill(
                          icon: Icons.local_fire_department_rounded,
                          text: 'x${engine.combo}',
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    right: 12,
                    top: 10,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _HudPill(
                          icon: Icons.monetization_on_rounded,
                          text: '${widget.progress.gold + engine.runGold}',
                        ),
                        const SizedBox(height: 7),
                        _HudPill(
                          icon: Icons.timer_outlined,
                          text: _formatTime(engine.elapsedSeconds),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: constraints.maxWidth / 2 - 23,
                    child: IconButton.filled(
                      onPressed: _togglePause,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withValues(alpha: 0.46),
                        foregroundColor: Colors.white,
                      ),
                      icon: Icon(
                        _paused
                            ? Icons.play_arrow_rounded
                            : Icons.pause_rounded,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    bottom: 12,
                    child: const _ControlHint(
                      icon: Icons.chevron_left_rounded,
                      label: 'SOL',
                    ),
                  ),
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: const _ControlHint(
                      icon: Icons.chevron_right_rounded,
                      label: 'SAĞ',
                    ),
                  ),
                  if (_paused && !engine.gameOver)
                    Positioned.fill(
                      child: _PausePanel(
                        onResume: _togglePause,
                        onRestart: _restart,
                        onHome: _home,
                      ),
                    ),
                  if (engine.gameOver)
                    Positioned.fill(
                      child: _GameOverPanel(
                        score: engine.score,
                        bestScore:
                            math.max(widget.progress.bestScore, engine.score),
                        runGold: engine.runGold,
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

  String _formatTime(double seconds) {
    final total = seconds.floor();
    final minutes = total ~/ 60;
    final rest = total % 60;
    return '${minutes.toString().padLeft(2, '0')}:${rest.toString().padLeft(2, '0')}';
  }
}

enum _Biome { snow, lava, space }

class _GameplayPainter extends CustomPainter {
  _GameplayPainter({required this.engine, required this.reducedEffects});

  final SkyJumperEngine engine;
  final bool reducedEffects;

  _Biome get biome {
    if (engine.score < 2400) return _Biome.snow;
    if (engine.score < 8200) return _Biome.lava;
    return _Biome.space;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / engine.tuning.worldWidth;
    _paintBackground(canvas, size, scale);

    for (final platform in engine.platforms) {
      final y = (platform.y - engine.cameraTop) * scale;
      if (y < -50 || y > size.height + 50) continue;

      final color = _platformColor(platform.kind);
      final platformRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          platform.x * scale,
          y,
          platform.width * scale,
          platform.height * scale,
        ),
        Radius.circular(7 * scale),
      );
      canvas.drawRRect(platformRect, Paint()..color = color);
      canvas.drawRRect(
        platformRect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6 * scale
          ..color = Colors.white.withValues(alpha: 0.55),
      );
    }

    for (final coin in engine.coins) {
      if (coin.collected) continue;
      final y = (coin.y - engine.cameraTop) * scale;
      if (y < -30 || y > size.height + 30) continue;
      final center = Offset(coin.x * scale, y);
      canvas.drawCircle(
        center,
        coin.radius * 1.22 * scale,
        Paint()..color = const Color(0x55FFB700),
      );
      canvas.drawCircle(
        center,
        coin.radius * scale,
        Paint()..color = const Color(0xFFFFC928),
      );
      canvas.drawCircle(
        center,
        coin.radius * 0.5 * scale,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8 * scale
          ..color = const Color(0xFFFFF0A0),
      );
    }
  }

  void _paintBackground(Canvas canvas, Size size, double scale) {
    late final List<Color> colors;
    switch (biome) {
      case _Biome.snow:
        colors = const [Color(0xFF4DB9FA), Color(0xFFBDEEFF)];
        break;
      case _Biome.lava:
        colors = const [
          Color(0xFF321018),
          Color(0xFFB52B16),
          Color(0xFFF2872A),
        ];
        break;
      case _Biome.space:
        colors = const [
          Color(0xFF08051D),
          Color(0xFF29155C),
          Color(0xFF522B86),
        ];
        break;
    }

    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ).createShader(rect),
    );

    if (reducedEffects) return;
    final particlePaint = Paint()..color = Colors.white.withValues(alpha: 0.55);
    for (var i = 0; i < 26; i++) {
      final x = ((i * 73 + 19) % 353) * scale;
      final drift =
          engine.cameraTop.abs() * (0.08 + (i % 3) * 0.03);
      final y =
          ((i * 97 + drift) % (size.height / scale + 100) - 50) * scale;
      var radius = (i % 3 + 1) * 0.9 * scale;
      if (biome == _Biome.lava) {
        particlePaint.color =
            const Color(0xFFFFB145).withValues(alpha: 0.52);
        radius *= 1.4;
      } else if (biome == _Biome.space) {
        particlePaint.color = Colors.white.withValues(alpha: 0.65);
        radius *= 0.75;
      } else {
        particlePaint.color = Colors.white.withValues(alpha: 0.56);
      }
      canvas.drawCircle(Offset(x, y), radius, particlePaint);
    }
  }

  Color _platformColor(PlatformKind kind) {
    switch (biome) {
      case _Biome.snow:
        switch (kind) {
          case PlatformKind.normal:
            return const Color(0xFFEAFBFF);
          case PlatformKind.moving:
            return const Color(0xFF8DD8FF);
          case PlatformKind.bounce:
            return const Color(0xFFFFA35C);
        }
      case _Biome.lava:
        switch (kind) {
          case PlatformKind.normal:
            return const Color(0xFF713D2B);
          case PlatformKind.moving:
            return const Color(0xFF9A4FD6);
          case PlatformKind.bounce:
            return const Color(0xFFFFC052);
        }
      case _Biome.space:
        switch (kind) {
          case PlatformKind.normal:
            return const Color(0xFF5E56A8);
          case PlatformKind.moving:
            return const Color(0xFF4AC9D4);
          case PlatformKind.bounce:
            return const Color(0xFFFF8B5A);
        }
    }
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
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.white24),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: Colors.white),
            const SizedBox(width: 5),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w900,
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
        opacity: 0.34,
        child: Container(
          width: 70,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(17),
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
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PausePanel extends StatelessWidget {
  const _PausePanel({
    required this.onResume,
    required this.onRestart,
    required this.onHome,
  });

  final VoidCallback onResume;
  final VoidCallback onRestart;
  final Future<void> Function() onHome;

  @override
  Widget build(BuildContext context) {
    return _OverlayCard(
      title: 'DURAKLATILDI',
      children: [
        FilledButton.icon(
          onPressed: onResume,
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('DEVAM ET'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: onRestart,
          icon: const Icon(Icons.replay_rounded),
          label: const Text('BAŞTAN BAŞLA'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: onHome,
          icon: const Icon(Icons.home_rounded),
          label: const Text('ANA MENÜ'),
        ),
      ],
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
  final Future<void> Function() onHome;

  @override
  Widget build(BuildContext context) {
    return _OverlayCard(
      title: 'GAME OVER',
      children: [
        Text(
          '$score',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 40,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          'EN İYİ  $bestScore',
          style: const TextStyle(color: Colors.white70),
        ),
        Text(
          '+ $runGold GOLD',
          style: const TextStyle(color: Color(0xFFFFCB4B)),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: onRestart,
          icon: const Icon(Icons.replay_rounded),
          label: const Text('TEKRAR'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: onHome,
          icon: const Icon(Icons.home_rounded),
          label: const Text('ANA MENÜ'),
        ),
      ],
    );
  }
}

class _OverlayCard extends StatelessWidget {
  const _OverlayCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.72),
      child: Center(
        child: Container(
          width: 310,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFF15182D),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: Colors.white12),
            boxShadow: const [BoxShadow(blurRadius: 28, color: Colors.black45)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 16),
              ...children.map((child) {
                if (child is FilledButton || child is OutlinedButton) {
                  return SizedBox(width: double.infinity, child: child);
                }
                return child;
              }),
            ],
          ),
        ),
      ),
    );
  }
}
