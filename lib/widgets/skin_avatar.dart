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
    if (skin.visualKind == SkinVisualKind.network && skin.source.isNotEmpty) {
      return Image.network(
        skin.source,
        fit: fit,
        filterQuality: FilterQuality.high,
        gaplessPlayback: true,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return _ProceduralSkin(skin: skin, frame: frame);
        },
        errorBuilder: (_, __, ___) => _ProceduralSkin(skin: skin, frame: frame),
      );
    }
    return _ProceduralSkin(skin: skin, frame: frame);
  }
}

class _ProceduralSkin extends StatelessWidget {
  const _ProceduralSkin({required this.skin, required this.frame});

  final SkinDefinition skin;
  final int frame;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SkinPainter(skin: skin, frame: frame),
      child: const SizedBox.expand(),
    );
  }
}

class _SkinPainter extends CustomPainter {
  const _SkinPainter({required this.skin, required this.frame});

  final SkinDefinition skin;
  final int frame;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final s = math.min(size.width / 120, size.height / 160);
    final x = size.width / 2;
    final y = size.height / 2 + 8 * s;
    final slot = skin.customSlot;
    final pose = _pose(frame, skin.hasCrownAnimation);

    canvas.save();
    canvas.translate(x, y + pose.y * s);
    canvas.scale(s, s * pose.scaleY);

    if (slot == null) {
      _drawClassic(canvas, skin.accent);
    } else {
      _drawSlot(canvas, slot);
      if (skin.hasCrownAnimation) {
        _drawCrown(canvas, -70 + pose.crownLift);
      }
    }
    canvas.restore();
  }

  _Pose _pose(int frame, bool crown) {
    final phase = (frame % 16) / 15.0;
    final arc = math.sin(phase * math.pi);
    return _Pose(
      y: -10 * arc,
      scaleY: 1 + 0.06 * arc,
      crownLift: crown ? -18 * math.sin(math.min(1, phase * 1.12) * math.pi) : 0,
    );
  }

  Paint _fill(Color color) => Paint()..color = color;

  Paint _line([Color color = const Color(0xFF1F1621), double width = 3]) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  void _drawClassic(Canvas c, Color accent) {
    _feet(c, const Color(0xFF53351F));
    final body = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-34, -45, 68, 82),
      const Radius.circular(31),
    );
    c.drawRRect(body, _fill(accent));
    c.drawRRect(body, _line());
    _face(c, centerY: -15, skinTone: accent, smile: false);
  }

  void _drawSlot(Canvas c, int slot) {
    switch (slot) {
      case 1:
        _astronaut(c);
      case 2:
        _king(c);
      case 3:
        _coolBoy(c);
      case 4:
        _darkLord(c);
      case 5:
        _arctic(c);
      case 6:
        _pirate(c);
      case 7:
        _zombie(c);
      case 8:
        _relic(c);
      case 9:
        _spaceRanger(c);
      case 10:
        _commando(c);
      case 11:
        _voidKnight(c);
      case 12:
        _boss(c);
      case 13:
        _crystal(c);
      case 14:
        _engineer(c);
      case 15:
        _caveman(c);
      case 16:
        _gubi(c);
      case 17:
        _street(c);
      case 18:
        _princess(c);
      case 19:
        _football(c, const Color(0xFFD92F2F), const Color(0xFFFFD430));
      case 20:
        _football(c, const Color(0xFFF2D52D), const Color(0xFF132B76));
      case 21:
        _football(c, Colors.white, const Color(0xFF171717));
      case 22:
        _football(c, const Color(0xFF7C2545), const Color(0xFF4F80CC));
      case 23:
        _hacker(c);
      case 24:
        _wizard(c);
      case 25:
      case 26:
      case 27:
      case 28:
      case 29:
        _frost(c, slot);
      case 30:
        _frostBot(c);
      default:
        _drawClassic(c, skin.accent);
    }
  }

  void _baseHuman(
    Canvas c, {
    Color skinTone = const Color(0xFFF2B27C),
    required Color shirt,
    Color pants = const Color(0xFF252B35),
    bool smile = true,
  }) {
    _feet(c, const Color(0xFF20242B));
    c.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-25, 17, 50, 27), const Radius.circular(9)),
      _fill(pants),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-30, -21, 60, 46), const Radius.circular(16)),
      _fill(shirt),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-30, -21, 60, 46), const Radius.circular(16)),
      _line(),
    );
    c.drawCircle(const Offset(-34, -3), 9, _fill(skinTone));
    c.drawCircle(const Offset(34, -3), 9, _fill(skinTone));
    _head(c, skinTone, -43);
    _face(c, centerY: -43, skinTone: skinTone, smile: smile);
  }

  void _head(Canvas c, Color tone, double y) {
    c.drawCircle(Offset(0, y), 29, _fill(tone));
    c.drawCircle(Offset(0, y), 29, _line());
  }

  void _face(
    Canvas c, {
    required double centerY,
    required Color skinTone,
    bool smile = true,
    bool eyePatch = false,
    Color eyeColor = const Color(0xFF241B18),
  }) {
    if (eyePatch) {
      c.drawOval(Rect.fromCenter(center: Offset(-10, centerY - 2), width: 15, height: 10), _fill(Colors.black));
      c.drawLine(Offset(-27, centerY - 11), Offset(5, centerY + 1), _line(Colors.black, 2));
    } else {
      c.drawCircle(Offset(-10, centerY - 2), 3.4, _fill(eyeColor));
    }
    c.drawCircle(Offset(10, centerY - 2), 3.4, _fill(eyeColor));
    final mouth = Path()..moveTo(-8, centerY + 11);
    if (smile) {
      mouth.quadraticBezierTo(0, centerY + 18, 8, centerY + 11);
    } else {
      mouth.lineTo(8, centerY + 11);
    }
    c.drawPath(mouth, _line(const Color(0xFF4A2319), 2.2));
  }

  void _feet(Canvas c, Color color) {
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-25, 40, 22, 12), const Radius.circular(6)), _fill(color));
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(3, 40, 22, 12), const Radius.circular(6)), _fill(color));
  }

  void _hair(Canvas c, Color color, {double y = -66}) {
    final path = Path()
      ..moveTo(-28, y + 20)
      ..quadraticBezierTo(-23, y - 3, -8, y + 5)
      ..quadraticBezierTo(0, y - 8, 8, y + 5)
      ..quadraticBezierTo(23, y - 3, 28, y + 20)
      ..quadraticBezierTo(9, y + 10, 0, y + 17)
      ..quadraticBezierTo(-9, y + 10, -28, y + 20)
      ..close();
    c.drawPath(path, _fill(color));
    c.drawPath(path, _line());
  }

  void _astronaut(Canvas c) {
    _baseHuman(c, skinTone: const Color(0xFFEEF4F7), shirt: const Color(0xFFE9EFF4), pants: const Color(0xFFB9C8D4));
    c.drawCircle(const Offset(0, -43), 35, _line(const Color(0xFF7A99AB), 6));
    c.drawOval(const Rect.fromLTWH(-20, -58, 40, 26), _fill(const Color(0xAA5BC9ED)));
    c.drawRect(const Rect.fromLTWH(-16, -13, 32, 16), _fill(const Color(0xFF7CA8BA)));
  }

  void _king(Canvas c) {
    final cape = Path()
      ..moveTo(-30, -18)
      ..lineTo(-43, 45)
      ..lineTo(0, 34)
      ..lineTo(43, 45)
      ..lineTo(30, -18)
      ..close();
    c.drawPath(cape, _fill(const Color(0xFFB82438)));
    c.drawPath(cape, _line());
    _baseHuman(c, shirt: const Color(0xFFF2F0EA), pants: const Color(0xFFD22E55));
    c.drawRect(const Rect.fromLTWH(-27, 4, 54, 8), _fill(const Color(0xFFD6A12A)));
    c.drawCircle(const Offset(0, 8), 4, _fill(const Color(0xFFE93C5A)));
  }

  void _drawCrown(Canvas c, double y) {
    final p = Path()
      ..moveTo(-22, y + 16)
      ..lineTo(-19, y)
      ..lineTo(-9, y + 8)
      ..lineTo(0, y - 7)
      ..lineTo(9, y + 8)
      ..lineTo(19, y)
      ..lineTo(22, y + 16)
      ..close();
    c.drawPath(p, _fill(const Color(0xFFFFD439)));
    c.drawPath(p, _line(const Color(0xFF8B5900), 2.4));
    c.drawCircle(Offset(0, y + 10), 3, _fill(const Color(0xFFE33A51)));
  }

  void _coolBoy(Canvas c) {
    _baseHuman(c, shirt: const Color(0xFF15161B), pants: const Color(0xFF292D35));
    c.drawArc(const Rect.fromLTWH(-30, -76, 60, 48), math.pi, math.pi, true, _fill(const Color(0xFF252A31)));
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-23, -51, 46, 13), const Radius.circular(6)), _fill(Colors.black));
  }

  void _darkLord(Canvas c) {
    _baseHuman(c, skinTone: const Color(0xFF17181D), shirt: const Color(0xFF151820), pants: const Color(0xFF0D0E13), smile: false);
    c.drawArc(const Rect.fromLTWH(-35, -79, 70, 62), math.pi, math.pi, true, _fill(const Color(0xFF0A0C12)));
    c.drawCircle(const Offset(-10, -45), 3, _fill(const Color(0xFFFF3B34)));
    c.drawCircle(const Offset(10, -45), 3, _fill(const Color(0xFFFF3B34)));
  }

  void _arctic(Canvas c) {
    _baseHuman(c, shirt: const Color(0xFFE7EFF4), pants: const Color(0xFF6E8A98));
    c.drawCircle(const Offset(0, -43), 34, _line(const Color(0xFFF7FBFF), 10));
  }

  void _pirate(Canvas c) {
    _baseHuman(c, shirt: const Color(0xFFC62E32), pants: const Color(0xFF70401F));
    for (var y = -18.0; y < 16; y += 10) {
      c.drawRect(Rect.fromLTWH(-27, y, 54, 5), _fill(Colors.white));
    }
    _face(c, centerY: -43, skinTone: const Color(0xFFF2B27C), smile: true, eyePatch: true);
    final hat = Path()
      ..moveTo(-36, -67)
      ..quadraticBezierTo(-25, -82, -11, -74)
      ..quadraticBezierTo(0, -89, 11, -74)
      ..quadraticBezierTo(25, -82, 36, -67)
      ..quadraticBezierTo(14, -58, 0, -62)
      ..quadraticBezierTo(-14, -58, -36, -67)
      ..close();
    c.drawPath(hat, _fill(const Color(0xFF15171B)));
    c.drawPath(hat, _line());
  }

  void _zombie(Canvas c) {
    _baseHuman(c, skinTone: const Color(0xFF70B46A), shirt: const Color(0xFF8D3F4B), pants: const Color(0xFF403E36), smile: false);
    c.drawLine(const Offset(-18, -58), const Offset(-3, -50), _line(const Color(0xFF763A3A), 2));
  }

  void _relic(Canvas c) {
    _baseHuman(c, skinTone: const Color(0xFF9A7651), shirt: const Color(0xFF8A643A), pants: const Color(0xFF4F4334));
    c.drawCircle(const Offset(0, -43), 34, _line(const Color(0xFF6F5331), 7));
    c.drawCircle(const Offset(0, -43), 18, _line(const Color(0xFF79C8CF), 4));
  }

  void _spaceRanger(Canvas c) {
    _baseHuman(c, skinTone: const Color(0xFF8EDCEF), shirt: const Color(0xFF374D95), pants: const Color(0xFF1C2858));
    c.drawOval(const Rect.fromLTWH(-25, -63, 50, 28), _fill(const Color(0x8859F1FF)));
  }

  void _commando(Canvas c) {
    _baseHuman(c, shirt: const Color(0xFF617043), pants: const Color(0xFF39402E));
    c.drawRect(const Rect.fromLTWH(-30, -71, 60, 12), _fill(const Color(0xFF3D492C)));
    c.drawLine(const Offset(-26, -6), const Offset(26, 15), _line(const Color(0xFF201E18), 5));
  }

  void _voidKnight(Canvas c) {
    _baseHuman(c, skinTone: const Color(0xFF4C3564), shirt: const Color(0xFF3D245A), pants: const Color(0xFF1D1530), smile: false);
    c.drawCircle(const Offset(0, -43), 32, _line(const Color(0xFFA65EFF), 6));
    c.drawCircle(const Offset(-10, -45), 3, _fill(const Color(0xFFFF4358)));
    c.drawCircle(const Offset(10, -45), 3, _fill(const Color(0xFFFF4358)));
  }

  void _boss(Canvas c) {
    _baseHuman(c, shirt: const Color(0xFF20242B), pants: const Color(0xFF111318));
    c.drawPath(Path()..moveTo(-8, -20)..lineTo(0, 6)..lineTo(8, -20)..close(), _fill(const Color(0xFFE83A3A)));
  }

  void _crystal(Canvas c) {
    _baseHuman(c, skinTone: const Color(0xFF99F2FF), shirt: const Color(0xFF9D6AF0), pants: const Color(0xFF514589));
    final gem = Path()..moveTo(0, -78)..lineTo(20, -52)..lineTo(0, -28)..lineTo(-20, -52)..close();
    c.drawPath(gem, _fill(const Color(0xAA65F3FF)));
    c.drawPath(gem, _line(const Color(0xFFDBFCFF), 2));
  }

  void _engineer(Canvas c) {
    _baseHuman(c, shirt: const Color(0xFFC78637), pants: const Color(0xFF4E5A67));
    c.drawRect(const Rect.fromLTWH(-26, -72, 52, 10), _fill(const Color(0xFFFFA52D)));
    c.drawCircle(const Offset(0, -66), 8, _fill(const Color(0xFFC46E20)));
  }

  void _caveman(Canvas c) {
    _baseHuman(c, shirt: const Color(0xFF8D5B35), pants: const Color(0xFF684326));
    _hair(c, const Color(0xFF4D2F1D), y: -68);
    c.drawLine(const Offset(-24, -12), const Offset(24, 13), _line(const Color(0xFFE5C190), 4));
  }

  void _gubi(Canvas c) {
    _baseHuman(c, shirt: const Color(0xFF6EBD43), pants: const Color(0xFF303139));
    _hair(c, const Color(0xFFFF8C2F), y: -69);
  }

  void _street(Canvas c) {
    _baseHuman(c, shirt: const Color(0xFFF1F2F5), pants: const Color(0xFF404652));
    c.drawArc(const Rect.fromLTWH(-33, -76, 66, 50), math.pi, math.pi, true, _fill(const Color(0xFFE8E9EE)));
  }

  void _princess(Canvas c) {
    _feet(c, const Color(0xFFFFB0CF));
    final dress = Path()
      ..moveTo(-22, -12)
      ..lineTo(-36, 43)
      ..quadraticBezierTo(0, 55, 36, 43)
      ..lineTo(22, -12)
      ..close();
    c.drawPath(dress, _fill(const Color(0xFFFF8FC1)));
    c.drawPath(dress, _line());
    _head(c, const Color(0xFFF5B985), -43);
    _hair(c, const Color(0xFFF6D24C), y: -68);
    _face(c, centerY: -43, skinTone: const Color(0xFFF5B985), smile: true);
    _drawCrown(c, -78);
  }

  void _football(Canvas c, Color a, Color b) {
    _baseHuman(c, shirt: a, pants: const Color(0xFF202631));
    for (var x = -26.0; x < 27; x += 13) {
      c.drawRect(Rect.fromLTWH(x, -18, 7, 39), _fill(b));
    }
    c.drawCircle(const Offset(0, 4), 8, _fill(Colors.white.withValues(alpha: 0.85)));
  }

  void _hacker(Canvas c) {
    _baseHuman(c, skinTone: const Color(0xFF1B211C), shirt: const Color(0xFF111613), pants: const Color(0xFF0A0D0B), smile: false);
    c.drawArc(const Rect.fromLTWH(-34, -78, 68, 58), math.pi, math.pi, true, _fill(const Color(0xFF101813)));
    c.drawCircle(const Offset(-10, -45), 3, _fill(const Color(0xFF4AFF79)));
    c.drawCircle(const Offset(10, -45), 3, _fill(const Color(0xFF4AFF79)));
    c.drawRect(const Rect.fromLTWH(-23, 2, 46, 13), _fill(const Color(0xFF17351F)));
    for (var i = 0; i < 5; i++) {
      c.drawRect(Rect.fromLTWH(-19 + i * 9, 6, 4, 4), _fill(const Color(0xFF4AFF79)));
    }
  }

  void _wizard(Canvas c) {
    _baseHuman(c, skinTone: const Color(0xFFD2A06D), shirt: const Color(0xFF655090), pants: const Color(0xFF393052));
    final hat = Path()
      ..moveTo(-32, -64)
      ..lineTo(2, -108)
      ..lineTo(13, -69)
      ..lineTo(34, -61)
      ..quadraticBezierTo(0, -50, -32, -64)
      ..close();
    c.drawPath(hat, _fill(const Color(0xFF514171)));
    c.drawPath(hat, _line());
    c.drawLine(const Offset(31, 21), const Offset(43, -36), _line(const Color(0xFF6C4825), 5));
    c.drawCircle(const Offset(43, -41), 7, _fill(const Color(0xFF55CFFF)));
  }

  void _frost(Canvas c, int slot) {
    final t = (slot - 25) / 4.0;
    final accent = Color.lerp(const Color(0xFFB8EEFF), const Color(0xFF5EBDF0), t)!;
    _baseHuman(c, skinTone: const Color(0xFFD7F6FF), shirt: accent, pants: const Color(0xFF53758D));
    c.drawCircle(const Offset(0, -43), 33, _line(Colors.white.withValues(alpha: 0.9), 5));
  }

  void _frostBot(Canvas c) {
    _feet(c, const Color(0xFF385871));
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-30, -24, 60, 68), const Radius.circular(16)), _fill(const Color(0xFF70CFF5)));
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-30, -24, 60, 68), const Radius.circular(16)), _line(const Color(0xFF275372), 4));
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-31, -72, 62, 50), const Radius.circular(17)), _fill(const Color(0xFFD7F7FF)));
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-31, -72, 62, 50), const Radius.circular(17)), _line(const Color(0xFF275372), 4));
    c.drawCircle(const Offset(-11, -48), 5, _fill(const Color(0xFF245D86)));
    c.drawCircle(const Offset(11, -48), 5, _fill(const Color(0xFF245D86)));
  }

  @override
  bool shouldRepaint(covariant _SkinPainter oldDelegate) =>
      oldDelegate.skin.id != skin.id || oldDelegate.frame != frame;
}

class _Pose {
  const _Pose({required this.y, required this.scaleY, required this.crownLift});

  final double y;
  final double scaleY;
  final double crownLift;
}
