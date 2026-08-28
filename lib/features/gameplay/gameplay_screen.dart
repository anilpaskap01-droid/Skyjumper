import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

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

  String _altitudeLabel() {
    final meters = math.max(
      0,
      (engine.tuning.startPlayerY - engine.highestPlayerY) * 3.2,
    );
    if (meters >= 1000000) return '${(meters / 1000000).toStringAsFixed(1)}M';
    if (meters >= 1000) return '${(meters / 1000).toStringAsFixed(1)} km';
    return '${meters.toStringAsFixed(0)} m';
  }

  List<Widget> _platformWidgets(double scale, _Biome biome, double shake, double height) {
    final widgets = <Widget>[];
    for (final platform in engine.platforms) {
      final y = (platform.y - engine.cameraTop) * scale;
      if (y < -60 || y > height + 60) continue;
      widgets.add(
        Positioned(
          left: platform.x * scale + shake,
          top: y - 7 * scale,
          width: platform.width * scale,
          height: 28 * scale,
          child: IgnorePointer(
            child: _RealPlatform(
              biomeId: biome.id,
              kind: platform.kind,
            ),
          ),
        ),
      );
    }
    return widgets;
  }

  List<Widget> _coinWidgets(double scale, double shake, double height) {
    final widgets = <Widget>[];
    for (final coin in engine.coins) {
      if (coin.collected) continue;
      final y = (coin.y - engine.cameraTop) * scale;
      if (y < -40 || y > height + 40) continue;
      final size = coin.radius * 2.8 * scale;
      widgets.add(
        Positioned(
          left: coin.x * scale - size / 2 + shake,
          top: y - size / 2,
          width: size,
          height: size,
          child: const IgnorePointer(
            child: _RawBundledImage(
              path: 'assets/powerups/coin_gold.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
      );
    }
    return widgets;
  }

  @override
  void dispose() {
    _ticker.dispose();
    if (!_runCommitted && _engine != null) {
      unawaited(
        widget.progress.commitRun(score: engine.score, runGold: engine.runGold),
      );
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
            final playerCenterX =
                (engine.player.x + engine.player.width / 2) * scale;
            final playerBottom =
                (engine.player.y + engine.player.height - engine.cameraTop) * scale;
            final avatarWidth = 74 * scale;
            final avatarHeight = 98 * scale;
            final impact = widget.progress.cameraShakeEnabled &&
                !widget.progress.reducedEffects &&
                engine.elapsedSeconds < _impactUntil;
            final shake = impact
                ? math.sin(engine.elapsedSeconds * 180) * 3 * scale
                : 0.0;

            return Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (event) =>
                  _setInput(event.localPosition.dx, constraints.maxWidth),
              onPointerMove: (event) =>
                  _setInput(event.localPosition.dx, constraints.maxWidth),
              onPointerUp: (_) => engine.setHorizontalInput(0),
              onPointerCancel: (_) => engine.setHorizontalInput(0),
              child: Stack(
                children: <Widget>[
                  Positioned.fill(
                    child: _RawBundledImage(
                      path: 'assets/backgrounds/${biome.id}.png',
                      fit: BoxFit.cover,
                      fallback: _GradientFallback(biome: biome),
                    ),
                  ),
                  ..._platformWidgets(
                    scale,
                    biome,
                    shake,
                    constraints.maxHeight,
                  ),
                  ..._coinWidgets(scale, shake, constraints.maxHeight),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(painter: _RulerPainter()),
                    ),
                  ),
                  Positioned(
                    left: playerCenterX - avatarWidth / 2 + shake,
                    top: playerBottom - avatarHeight,
                    width: avatarWidth,
                    height: avatarHeight,
                    child: IgnorePointer(
                      child: SkinAvatar(skin: skin, frame: _skinFrame),
                    ),
                  ),
                  Positioned(
                    left: 9,
                    top: 9,
                    child: _ScoreHud(score: engine.score, combo: engine.combo),
                  ),
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
                        shadows: <Shadow>[
                          Shadow(color: Colors.black87, blurRadius: 4),
                        ],
                      ),
                    ),
                  ),
                  if (_paused && !engine.gameOver)
                    Positioned.fill(
                      child: _PauseOverlay(
                        onResume: _togglePause,
                        onRestart: _restart,
                        onHome: _home,
                      ),
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
}

class _RawBundledImage extends StatelessWidget {
  const _RawBundledImage({
    required this.path,
    this.fit = BoxFit.contain,
    this.fallback,
  });

  final String path;
  final BoxFit fit;
  final Widget? fallback;

  static final Map<String, Future<Uint8List>> _cache =
      <String, Future<Uint8List>>{};

  Future<Uint8List> _load() {
    return _cache.putIfAbsent(path, () async {
      final data = await rootBundle.load(path);
      return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _load(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Image.memory(
            snapshot.data!,
            fit: fit,
            gaplessPlayback: true,
            filterQuality: FilterQuality.medium,
          );
        }
        if (snapshot.hasError) return fallback ?? const SizedBox.shrink();
        return fallback ?? const SizedBox.shrink();
      },
    );
  }
}

class _RealPlatform extends StatelessWidget {
  const _RealPlatform({required this.biomeId, required this.kind});

  final String biomeId;
  final PlatformKind kind;

  @override
  Widget build(BuildContext context) {
    final prefix = 'assets/platforms/$biomeId';
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SizedBox(
              width: 26,
              child: _RawBundledImage(
                path: '$prefix/normal_left.png',
                fit: BoxFit.fill,
              ),
            ),
            Expanded(
              child: _RawBundledImage(
                path: '$prefix/normal_mid.png',
                fit: BoxFit.fill,
              ),
            ),
            SizedBox(
              width: 26,
              child: _RawBundledImage(
                path: '$prefix/normal_right.png',
                fit: BoxFit.fill,
              ),
            ),
          ],
        ),
        if (kind != PlatformKind.normal)
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kind == PlatformKind.bounce
                    ? const Color(0xFF48E09C)
                    : const Color(0xFF63D9FF),
                border: Border.all(color: Colors.white70, width: 1),
              ),
            ),
          ),
      ],
    );
  }
}

class _GradientFallback extends StatelessWidget {
  const _GradientFallback({required this.biome});

  final _Biome biome;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[biome.top, biome.mid, biome.bottom],
        ),
      ),
    );
  }
}

class _RulerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFA72C).withValues(alpha: .85)
      ..strokeWidth = 1.5;
    for (double y = 8; y < size.height; y += 18) {
      final major = ((y / 18).round() % 5 == 0);
      canvas.drawLine(
        Offset(size.width - (major ? 20 : 11), y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RulerPainter oldDelegate) => false;
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
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xDD0E6895),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: const Color(0xFF4EE9FF)),
          ),
          child: Text(
            'x$combo',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
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
        child: Icon(
          paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
          color: Colors.white,
          size: 30,
        ),
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
        border: Border.all(
          color: const Color(0xFFFFD15A).withValues(alpha: .65),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            '$value',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 5),
          const SizedBox(
            width: 20,
            height: 20,
            child: _RawBundledImage(
              path: 'assets/powerups/coin_gold.png',
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}

class _PauseOverlay extends StatelessWidget {
  const _PauseOverlay({
    required this.onResume,
    required this.onRestart,
    required this.onHome,
  });

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
              const Text(
                'DURAKLATILDI',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
              _OverlayButton(
                label: 'DEVAM',
                icon: Icons.play_arrow_rounded,
                onTap: onResume,
                primary: true,
              ),
              const SizedBox(height: 8),
              _OverlayButton(
                label: 'YENİDEN BAŞLAT',
                icon: Icons.replay_rounded,
                onTap: onRestart,
              ),
              const SizedBox(height: 8),
              _OverlayButton(
                label: 'MENÜ',
                icon: Icons.home_rounded,
                onTap: onHome,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GameOverOverlay extends StatelessWidget {
  const _GameOverOverlay({
    required this.score,
    required this.best,
    required this.gold,
    required this.onRestart,
    required this.onHome,
  });

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
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text(
                'GAME OVER',
                style: TextStyle(
                  color: Color(0xFFFF8D3A),
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              _ResultRow(label: 'SCORE', value: '$score'),
              _ResultRow(label: 'BEST', value: '$best'),
              _ResultRow(label: 'GOLD', value: '+$gold'),
              const SizedBox(height: 16),
              _OverlayButton(
                label: 'TEKRAR',
                icon: Icons.replay_rounded,
                onTap: onRestart,
                primary: true,
              ),
              const SizedBox(height: 8),
              _OverlayButton(
                label: 'MENÜ',
                icon: Icons.home_rounded,
                onTap: onHome,
              ),
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
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white54,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverlayButton extends StatelessWidget {
  const _OverlayButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.primary = false,
  });

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
          backgroundColor:
              primary ? const Color(0xFF19AEEA) : const Color(0xFF152A43),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
        icon: Icon(icon),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _Biome {
  const _Biome(
    this.id,
    this.startFloor,
    this.top,
    this.mid,
    this.bottom,
  );

  final String id;
  final int startFloor;
  final Color top;
  final Color mid;
  final Color bottom;

  static const values = <_Biome>[
    _Biome('lava', 0, Color(0xFF6B170E), Color(0xFFB83316), Color(0xFF3A100D)),
    _Biome('crystal', 15, Color(0xFF173966), Color(0xFF4B72A7), Color(0xFF152441)),
    _Biome('gold', 30, Color(0xFF5D4215), Color(0xFFC28A22), Color(0xFF4D3210)),
    _Biome('soil', 45, Color(0xFF3E261D), Color(0xFF73513C), Color(0xFF251A16)),
    _Biome('ground', 65, Color(0xFF5D7E95), Color(0xFF95B8C7), Color(0xFF527064)),
    _Biome('mount', 85, Color(0xFF61798D), Color(0xFF9AB2C0), Color(0xFF45515B)),
    _Biome('iceberg', 107, Color(0xFF55BDF0), Color(0xFFB8EDFF), Color(0xFF76C7E3)),
    _Biome('sky', 130, Color(0xFF3298E6), Color(0xFF8CD4FF), Color(0xFFD9F3FF)),
    _Biome('atmosphere', 155, Color(0xFF183F76), Color(0xFF356CB4), Color(0xFF101F45)),
    _Biome('earth', 182, Color(0xFF071836), Color(0xFF0E3764), Color(0xFF050C20)),
    _Biome('moon', 210, Color(0xFF111429), Color(0xFF2E314A), Color(0xFF090B18)),
    _Biome('space', 237, Color(0xFF120A45), Color(0xFF382183), Color(0xFF0B0627)),
    _Biome('galaxy', 265, Color(0xFF17055D), Color(0xFF4821A9), Color(0xFF0A0330)),
  ];

  static _Biome forFloor(int floor) {
    var selected = values.first;
    for (final biome in values) {
      if (floor >= biome.startFloor) selected = biome;
    }
    return selected;
  }
}
