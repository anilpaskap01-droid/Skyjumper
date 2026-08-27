import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:skyjumper/game/data/skin_catalog.dart';

class SkinAvatar extends StatelessWidget {
  const SkinAvatar({
    super.key,
    required this.skin,
    this.frame = 0,
    this.fit = BoxFit.contain,
  });

  final SkinDefinition skin;
  final int frame;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    switch (skin.visualKind) {
      case SkinVisualKind.procedural:
        return _ProceduralAvatar(skin: skin, frame: frame);
      case SkinVisualKind.asset:
        if (skin.source.isEmpty) {
          return _ProceduralAvatar(skin: skin, frame: frame);
        }
        return Image.asset(
          skin.source,
          fit: fit,
          filterQuality: FilterQuality.high,
          errorBuilder: (_, __, ___) =>
              _ProceduralAvatar(skin: skin, frame: frame),
        );
      case SkinVisualKind.network:
        return Image.network(
          skin.source,
          fit: fit,
          filterQuality: FilterQuality.medium,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) =>
              _ProceduralAvatar(skin: skin, frame: frame),
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return _NetworkFallback(skin: skin);
          },
        );
      case SkinVisualKind.spriteSheet:
        if (skin.source.isEmpty) {
          return _ProceduralAvatar(skin: skin, frame: frame);
        }
        return SpriteSheetFrame(
          assetPath: skin.source,
          columns: skin.columns,
          rows: skin.rows,
          frame: frame.clamp(0, skin.frameCount - 1).toInt(),
          fallback: _ProceduralAvatar(skin: skin, frame: frame),
        );
    }
  }
}

class _ProceduralAvatar extends StatelessWidget {
  const _ProceduralAvatar({required this.skin, required this.frame});

  final SkinDefinition skin;
  final int frame;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SkyJumperSkinPainter(skin: skin, frame: frame),
      child: const SizedBox.expand(),
    );
  }
}

class SpriteSheetFrame extends StatelessWidget {
  const SpriteSheetFrame({
    super.key,
    required this.assetPath,
    required this.columns,
    required this.rows,
    required this.frame,
    required this.fallback,
  });

  final String assetPath;
  final int columns;
  final int rows;
  final int frame;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        if (!width.isFinite || !height.isFinite || width <= 0 || height <= 0) {
          return const SizedBox.shrink();
        }

        final safeFrame = frame.clamp(0, columns * rows - 1).toInt();
        final column = safeFrame % columns;
        final row = safeFrame ~/ columns;

        return ClipRect(
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                left: -column * width,
                top: -row * height,
                width: width * columns,
                height: height * rows,
                child: Image.asset(
                  assetPath,
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (_, __, ___) => SizedBox(
                    width: width * columns,
                    height: height * rows,
                    child: Align(
                      alignment: Alignment(
                        -1 + (column * 2 + 1) / columns,
                        -1 + (row * 2 + 1) / rows,
                      ),
                      child: SizedBox(
                        width: width,
                        height: height,
                        child: fallback,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NetworkFallback extends StatelessWidget {
  const _NetworkFallback({required this.skin});

  final SkinDefinition skin;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _ProceduralAvatar(skin: skin, frame: 0),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 1.8,
                color: Colors.white.withValues(alpha: 0.55),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SkyJumperSkinPainter extends CustomPainter {
  const _SkyJumperSkinPainter({required this.skin, required this.frame});

  final SkinDefinition skin;
  final int frame;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final scale = math.min(size.width / 100, size.height / 120);
    final origin = Offset(size.width / 2, size.height / 2);
    final pose = _poseForFrame();

    canvas.save();
    canvas.translate(origin.dx, origin.dy + pose.dy * scale);
    canvas.scale(scale, scale * pose.scaleY);

    switch (skin.id) {
      case 'pirate':
        _drawPirate(canvas);
        break;
      case 'king':
        _drawKing(canvas, pose.crownLift);
        break;
      case 'hotwheels':
        _drawHotWheels(canvas);
        break;
      case 'hacker':
        _drawHacker(canvas);
        break;
      case 'fener':
        _drawFener(canvas);
        break;
      default:
        _drawClassic(canvas, skin.accent);
    }

    canvas.restore();
  }

  _Pose _poseForFrame() {
    if (skin.id == 'pirate') {
      const dy = <double>[0, 5, -2, -7, -9, -5, 3, 5, 2, 0];
      const sy = <double>[1, .90, 1.04, 1.08, 1.10, 1.05, .92, .94, .98, 1];
      final i = frame.clamp(0, 9).toInt();
      return _Pose(dy: dy[i], scaleY: sy[i]);
    }
    if (skin.id == 'king') {
      const dy = <double>[
        0,
        4,
        1,
        -3,
        -7,
        -10,
        -11,
        -10,
        -7,
        -4,
        0,
        3,
        5,
        4,
        2,
        0,
      ];
      const crown = <double>[
        0,
        0,
        -2,
        -5,
        -9,
        -14,
        -17,
        -18,
        -18,
        -17,
        -15,
        -12,
        -8,
        -4,
        -1,
        0,
      ];
      final i = frame.clamp(0, 15).toInt();
      return _Pose(
        dy: dy[i],
        scaleY: i == 1 || i == 12 ? .93 : 1,
        crownLift: crown[i],
      );
    }
    return const _Pose(dy: 0, scaleY: 1);
  }

  Paint _fill(Color color) => Paint()
    ..color = color
    ..style = PaintingStyle.fill;

  Paint _stroke([Color color = const Color(0xFF1B1520)]) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3.1
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round;

  void _drawClassic(Canvas c, Color color) {
    _drawFeet(c, const Color(0xFF3C2A22));
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-29, -29, 58, 66),
        const Radius.circular(26),
      ),
      _fill(color),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-29, -29, 58, 66),
        const Radius.circular(26),
      ),
      _stroke(),
    );
    _drawFace(c, const Offset(0, -5), sleepy: true);
  }

  void _drawPirate(Canvas c) {
    _drawFeet(c, const Color(0xFF5C331C));
    _drawArms(c, const Color(0xFFFF9B35), y: 3);

    final torso = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-25, -7, 50, 42),
      const Radius.circular(13),
    );
    c.drawRRect(torso, _fill(const Color(0xFFC8262D)));
    c.save();
    c.clipRRect(torso);
    for (var y = -4.0; y < 35; y += 10) {
      c.drawRect(Rect.fromLTWH(-27, y, 54, 5), _fill(Colors.white));
    }
    c.restore();
    c.drawRRect(torso, _stroke());

    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-28, -9, 9, 45),
        const Radius.circular(5),
      ),
      _fill(const Color(0xFF17151A)),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(19, -9, 9, 45),
        const Radius.circular(5),
      ),
      _fill(const Color(0xFF17151A)),
    );
    c.drawRect(const Rect.fromLTWH(-24, 24, 48, 8), _fill(const Color(0xFF6E3C22)));
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-7, 22, 14, 12),
        const Radius.circular(3),
      ),
      _fill(const Color(0xFFFFC548)),
    );

    _drawHead(c, const Color(0xFFFF9B35), centerY: -27);
    _drawFace(c, const Offset(0, -27), sleepy: false, eyePatch: true);

    final hat = Path()
      ..moveTo(-36, -47)
      ..quadraticBezierTo(-26, -61, -12, -55)
      ..quadraticBezierTo(0, -70, 12, -55)
      ..quadraticBezierTo(26, -61, 36, -47)
      ..quadraticBezierTo(18, -40, 0, -44)
      ..quadraticBezierTo(-18, -40, -36, -47)
      ..close();
    c.drawPath(hat, _fill(const Color(0xFF15151A)));
    c.drawPath(hat, _stroke());
    c.drawCircle(const Offset(0, -51), 5, _fill(Colors.white));
    c.drawLine(const Offset(-7, -56), const Offset(7, -46), _stroke(Colors.white)..strokeWidth = 2);
    c.drawLine(const Offset(7, -56), const Offset(-7, -46), _stroke(Colors.white)..strokeWidth = 2);
  }

  void _drawKing(Canvas c, double crownLift) {
    final cape = Path()
      ..moveTo(-26, -4)
      ..lineTo(-37, 37)
      ..lineTo(0, 30)
      ..lineTo(37, 37)
      ..lineTo(26, -4)
      ..close();
    c.drawPath(cape, _fill(const Color(0xFFB11933)));
    c.drawPath(cape, _stroke());

    _drawFeet(c, const Color(0xFF9A2544));
    _drawArms(c, const Color(0xFFFFA33B), y: 2);
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-26, -8, 52, 45),
        const Radius.circular(14),
      ),
      _fill(const Color(0xFFD43B72)),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-26, -8, 52, 45),
        const Radius.circular(14),
      ),
      _stroke(),
    );
    c.drawCircle(const Offset(0, 6), 5, _fill(const Color(0xFFFFD34E)));

    _drawHead(c, const Color(0xFFFFA33B), centerY: -29);
    _drawFace(c, const Offset(0, -29), sleepy: false, smiling: true);

    canvasCrown(c, y: -58 + crownLift);
  }

  void canvasCrown(Canvas c, {required double y}) {
    final crown = Path()
      ..moveTo(-21, y + 13)
      ..lineTo(-18, y - 2)
      ..lineTo(-8, y + 7)
      ..lineTo(0, y - 7)
      ..lineTo(8, y + 7)
      ..lineTo(18, y - 2)
      ..lineTo(21, y + 13)
      ..close();
    c.drawPath(crown, _fill(const Color(0xFFFFD43E)));
    c.drawPath(crown, _stroke(const Color(0xFF7B4B00)));
    c.drawCircle(Offset(0, y + 7), 2.5, _fill(const Color(0xFFE84662)));
  }

  void _drawHotWheels(Canvas c) {
    _drawFeet(c, const Color(0xFFE8EDF2));
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-23, 17, 46, 22),
        const Radius.circular(7),
      ),
      _fill(const Color(0xFF17191F)),
    );
    _drawArms(c, const Color(0xFFF2B38C), y: 2);
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-26, -8, 52, 31),
        const Radius.circular(12),
      ),
      _fill(const Color(0xFF55D6E9)),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-26, -8, 52, 31),
        const Radius.circular(12),
      ),
      _stroke(),
    );
    _drawTinyText(c, 'HOT\nWHEELS', const Offset(0, 7), Colors.black87, 7.2);

    _drawHead(c, const Color(0xFFF2B38C), centerY: -31);
    final hair = Path()
      ..moveTo(-27, -37)
      ..quadraticBezierTo(-20, -60, -7, -50)
      ..quadraticBezierTo(1, -62, 8, -50)
      ..quadraticBezierTo(21, -58, 27, -38)
      ..lineTo(25, -30)
      ..quadraticBezierTo(10, -40, -2, -34)
      ..quadraticBezierTo(-16, -42, -27, -31)
      ..close();
    c.drawPath(hair, _fill(const Color(0xFF5B3527)));
    c.drawPath(hair, _stroke());
    _drawFace(c, const Offset(0, -31), sleepy: false, smiling: true);
  }

  void _drawHacker(Canvas c) {
    _drawFeet(c, const Color(0xFF0A0B0F));
    final hoodie = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-29, -17, 58, 56),
      const Radius.circular(20),
    );
    c.drawRRect(hoodie, _fill(const Color(0xFF11131A)));
    c.drawRRect(hoodie, _stroke(const Color(0xFF06070A)));
    c.drawLine(const Offset(-18, 10), const Offset(18, 10), _stroke(const Color(0xFF48FF85))..strokeWidth = 2.2);
    c.drawLine(const Offset(-16, 19), const Offset(13, 25), _stroke(const Color(0xFF8B4DFF))..strokeWidth = 2.1);
    c.drawCircle(const Offset(0, -23), 28, _fill(const Color(0xFF090A0E)));
    c.drawCircle(const Offset(0, -23), 28, _stroke(const Color(0xFF171B22)));
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-19, -31, 14, 7),
        const Radius.circular(2),
      ),
      _fill(const Color(0xFF4CFF85)),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(5, -31, 14, 7),
        const Radius.circular(2),
      ),
      _fill(const Color(0xFFAF69FF)),
    );
    c.drawRect(const Rect.fromLTWH(-11, -12, 22, 3), _fill(const Color(0xFF26303A)));
  }

  void _drawFener(Canvas c) {
    _drawFeet(c, const Color(0xFFFFD43B));
    _drawArms(c, const Color(0xFFFF8C2D), y: 2);
    final shirt = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-26, -9, 52, 46),
      const Radius.circular(14),
    );
    c.drawRRect(shirt, _fill(const Color(0xFFFFDA3E)));
    c.save();
    c.clipRRect(shirt);
    for (var x = -21.0; x < 24; x += 12) {
      c.drawRect(Rect.fromLTWH(x, -12, 6, 52), _fill(const Color(0xFF173A76)));
    }
    c.restore();
    c.drawRRect(shirt, _stroke());
    _drawHead(c, const Color(0xFFFF8C2D), centerY: -30);
    _drawFace(c, const Offset(0, -30), sleepy: true);

    final headphones = _stroke(const Color(0xFF182B55))..strokeWidth = 6;
    c.drawArc(const Rect.fromLTWH(-30, -58, 60, 52), math.pi, math.pi, false, headphones);
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-34, -38, 10, 23),
        const Radius.circular(5),
      ),
      _fill(const Color(0xFF173A76)),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(24, -38, 10, 23),
        const Radius.circular(5),
      ),
      _fill(const Color(0xFF173A76)),
    );
  }

  void _drawHead(Canvas c, Color color, {required double centerY}) {
    c.drawCircle(Offset(0, centerY), 28, _fill(color));
    c.drawCircle(Offset(0, centerY), 28, _stroke());
  }

  void _drawFace(
    Canvas c,
    Offset center, {
    required bool sleepy,
    bool eyePatch = false,
    bool smiling = false,
  }) {
    final eye = _fill(const Color(0xFF20191B));
    final left = center + const Offset(-9, -2);
    final right = center + const Offset(9, -2);
    c.drawOval(
      Rect.fromCenter(
        center: left,
        width: sleepy ? 8 : 6,
        height: sleepy ? 4 : 8,
      ),
      eye,
    );
    if (eyePatch) {
      c.drawCircle(right, 7, _fill(const Color(0xFF111115)));
      c.drawLine(center + const Offset(1, -12), center + const Offset(17, 2), _stroke(const Color(0xFF111115))..strokeWidth = 2.5);
    } else {
      c.drawOval(
        Rect.fromCenter(
          center: right,
          width: sleepy ? 8 : 6,
          height: sleepy ? 4 : 8,
        ),
        eye,
      );
    }

    final mouth = _stroke(const Color(0xFF20191B))..strokeWidth = 2.4;
    if (smiling) {
      final p = Path()
        ..moveTo(center.dx - 7, center.dy + 10)
        ..quadraticBezierTo(center.dx, center.dy + 16, center.dx + 8, center.dy + 9);
      c.drawPath(p, mouth);
    } else {
      c.drawLine(center + const Offset(-6, 11), center + const Offset(6, 11), mouth);
    }
  }

  void _drawFeet(Canvas c, Color color) {
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-22, 31, 18, 16),
        const Radius.circular(7),
      ),
      _fill(color),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(4, 31, 18, 16),
        const Radius.circular(7),
      ),
      _fill(color),
    );
  }

  void _drawArms(Canvas c, Color color, {required double y}) {
    c.drawCircle(Offset(-30, y), 9, _fill(color));
    c.drawCircle(Offset(30, y), 9, _fill(color));
    c.drawCircle(Offset(-30, y), 9, _stroke());
    c.drawCircle(Offset(30, y), 9, _stroke());
  }

  void _drawTinyText(
    Canvas c,
    String text,
    Offset center,
    Color color,
    double fontSize,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          height: .82,
          fontWeight: FontWeight.w900,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 36);
    painter.paint(
      c,
      Offset(center.dx - painter.width / 2, center.dy - painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _SkyJumperSkinPainter oldDelegate) {
    return oldDelegate.skin.id != skin.id ||
        oldDelegate.skin.accent != skin.accent ||
        oldDelegate.frame != frame;
  }
}

class _Pose {
  const _Pose({
    required this.dy,
    required this.scaleY,
    this.crownLift = 0,
  });

  final double dy;
  final double scaleY;
  final double crownLift;
}
