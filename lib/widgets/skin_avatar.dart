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
    final fallback = CustomPaint(
      painter: _SkinPainter(skin: skin, frame: frame),
      child: const SizedBox.expand(),
    );

    if (skin.visualKind != SkinVisualKind.network || skin.source.isEmpty) {
      return fallback;
    }

    return Image.network(
      skin.source,
      fit: fit,
      filterQuality: FilterQuality.high,
      gaplessPlayback: true,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : fallback,
      errorBuilder: (_, __, ___) => fallback,
    );
  }
}

class _SkinPainter extends CustomPainter {
  const _SkinPainter({required this.skin, required this.frame});

  final SkinDefinition skin;
  final int frame;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final scale = math.min(size.width / 120, size.height / 160);
    final phase = (frame % 16) / 15.0;
    final jumpArc = math.sin(phase * math.pi);

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2 + (8 - jumpArc * 10) * scale);
    canvas.scale(scale, scale * (1 + jumpArc * 0.05));

    final slot = skin.customSlot;
    if (slot == null) {
      _classic(canvas, skin.accent);
    } else {
      _slot(canvas, slot);
      if (skin.hasCrownAnimation) {
        final delayedPhase = (phase * 0.88).clamp(0.0, 1.0);
        final crownLift = -18 * math.sin(delayedPhase * math.pi);
        _crown(canvas, -73 + crownLift);
      }
    }
    canvas.restore();
  }

  Paint fill(Color color) => Paint()..color = color;

  Paint line([Color color = const Color(0xFF201822), double width = 3]) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  void _classic(Canvas c, Color color) {
    _feet(c, const Color(0xFF553821));
    final body = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-34, -46, 68, 88),
      const Radius.circular(32),
    );
    c.drawRRect(body, fill(color));
    c.drawRRect(body, line());
    _simpleFace(c, -14);
  }

  void _slot(Canvas c, int slot) {
    if (slot == 1) return _astronaut(c);
    if (slot == 2) return _king(c);
    if (slot == 3) return _coolBoy(c);
    if (slot == 4) return _darkLord(c);
    if (slot == 5) return _arctic(c);
    if (slot == 6) return _pirate(c);
    if (slot == 7) return _zombie(c);
    if (slot == 8) return _relic(c);
    if (slot == 9) return _spaceRanger(c);
    if (slot == 10) return _commando(c);
    if (slot == 11) return _voidKnight(c);
    if (slot == 12) return _boss(c);
    if (slot == 13) return _crystal(c);
    if (slot == 14) return _engineer(c);
    if (slot == 15) return _caveman(c);
    if (slot == 16) return _gubi(c);
    if (slot == 17) return _street(c);
    if (slot == 18) return _princess(c);
    if (slot == 19) {
      return _football(c, const Color(0xFFD92F2F), const Color(0xFFFFD430));
    }
    if (slot == 20) {
      return _football(c, const Color(0xFFF2D52D), const Color(0xFF132B76));
    }
    if (slot == 21) return _football(c, Colors.white, const Color(0xFF171717));
    if (slot == 22) {
      return _football(c, const Color(0xFF7C2545), const Color(0xFF4F80CC));
    }
    if (slot == 23) return _hacker(c);
    if (slot == 24) return _wizard(c);
    if (slot >= 25 && slot <= 29) return _frost(c, slot);
    if (slot == 30) return _frostBot(c);
    _classic(c, skin.accent);
  }

  void _human(
    Canvas c, {
    required Color shirt,
    Color skin = const Color(0xFFF2B27C),
    Color pants = const Color(0xFF29303B),
    bool smile = true,
  }) {
    _feet(c, const Color(0xFF20242B));
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-25, 18, 50, 26),
        const Radius.circular(9),
      ),
      fill(pants),
    );
    final torso = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-30, -22, 60, 48),
      const Radius.circular(16),
    );
    c.drawRRect(torso, fill(shirt));
    c.drawRRect(torso, line());
    c.drawCircle(const Offset(-34, -3), 9, fill(skin));
    c.drawCircle(const Offset(34, -3), 9, fill(skin));
    c.drawCircle(const Offset(0, -44), 29, fill(skin));
    c.drawCircle(const Offset(0, -44), 29, line());
    _face(c, -44, smile: smile);
  }

  void _face(Canvas c, double y, {bool smile = true, bool patch = false}) {
    if (patch) {
      c.drawOval(
        Rect.fromCenter(center: Offset(-10, y - 2), width: 15, height: 10),
        fill(Colors.black),
      );
      c.drawLine(Offset(-27, y - 11), Offset(5, y + 1), line(Colors.black, 2));
    } else {
      c.drawCircle(Offset(-10, y - 2), 3.4, fill(const Color(0xFF251B18)));
    }
    c.drawCircle(Offset(10, y - 2), 3.4, fill(const Color(0xFF251B18)));
    final mouth = Path()..moveTo(-8, y + 11);
    if (smile) {
      mouth.quadraticBezierTo(0, y + 18, 8, y + 11);
    } else {
      mouth.lineTo(8, y + 11);
    }
    c.drawPath(mouth, line(const Color(0xFF4B251C), 2));
  }

  void _simpleFace(Canvas c, double y) {
    c.drawCircle(Offset(-10, y), 3, fill(const Color(0xFF251B18)));
    c.drawCircle(Offset(10, y), 3, fill(const Color(0xFF251B18)));
    c.drawLine(const Offset(-6, 0), const Offset(6, 0), line(const Color(0xFF4B251C), 2));
  }

  void _feet(Canvas c, Color color) {
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-25, 40, 22, 12),
        const Radius.circular(6),
      ),
      fill(color),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(3, 40, 22, 12),
        const Radius.circular(6),
      ),
      fill(color),
    );
  }

  void _hair(Canvas c, Color color) {
    final p = Path()
      ..moveTo(-28, -50)
      ..quadraticBezierTo(-24, -76, -9, -67)
      ..quadraticBezierTo(0, -80, 9, -67)
      ..quadraticBezierTo(24, -76, 28, -50)
      ..quadraticBezierTo(11, -57, 0, -52)
      ..quadraticBezierTo(-11, -57, -28, -50)
      ..close();
    c.drawPath(p, fill(color));
    c.drawPath(p, line());
  }

  void _crown(Canvas c, double y) {
    final p = Path()
      ..moveTo(-22, y + 16)
      ..lineTo(-19, y)
      ..lineTo(-9, y + 8)
      ..lineTo(0, y - 7)
      ..lineTo(9, y + 8)
      ..lineTo(19, y)
      ..lineTo(22, y + 16)
      ..close();
    c.drawPath(p, fill(const Color(0xFFFFD439)));
    c.drawPath(p, line(const Color(0xFF8B5900), 2.4));
    c.drawCircle(Offset(0, y + 10), 3, fill(const Color(0xFFE33A51)));
  }

  void _astronaut(Canvas c) {
    _human(c, shirt: const Color(0xFFEAF1F5), skin: const Color(0xFFEAF1F5), pants: const Color(0xFFB9C9D4));
    c.drawCircle(const Offset(0, -44), 35, line(const Color(0xFF7899AA), 6));
    c.drawOval(const Rect.fromLTWH(-21, -59, 42, 27), fill(const Color(0x885CD3F2)));
  }

  void _king(Canvas c) {
    final cape = Path()
      ..moveTo(-30, -18)
      ..lineTo(-43, 45)
      ..lineTo(0, 34)
      ..lineTo(43, 45)
      ..lineTo(30, -18)
      ..close();
    c.drawPath(cape, fill(const Color(0xFFB82438)));
    c.drawPath(cape, line());
    _human(c, shirt: const Color(0xFFF4EFE8), pants: const Color(0xFFD22E55));
    c.drawRect(const Rect.fromLTWH(-27, 4, 54, 8), fill(const Color(0xFFD6A12A)));
  }

  void _coolBoy(Canvas c) {
    _human(c, shirt: const Color(0xFF17191E), pants: const Color(0xFF333944));
    c.drawArc(const Rect.fromLTWH(-31, -78, 62, 50), math.pi, math.pi, true, fill(const Color(0xFF272D35)));
    c.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-23, -52, 46, 13), const Radius.circular(6)),
      fill(Colors.black),
    );
  }

  void _darkLord(Canvas c) {
    _human(c, shirt: const Color(0xFF13161D), skin: const Color(0xFF181A20), pants: const Color(0xFF090B10), smile: false);
    c.drawArc(const Rect.fromLTWH(-35, -82, 70, 65), math.pi, math.pi, true, fill(const Color(0xFF080A10)));
    c.drawCircle(const Offset(-10, -46), 3, fill(const Color(0xFFFF3B35)));
    c.drawCircle(const Offset(10, -46), 3, fill(const Color(0xFFFF3B35)));
  }

  void _arctic(Canvas c) {
    _human(c, shirt: const Color(0xFFE9F2F7), pants: const Color(0xFF718A98));
    c.drawCircle(const Offset(0, -44), 35, line(const Color(0xFFF9FCFF), 10));
  }

  void _pirate(Canvas c) {
    _human(c, shirt: const Color(0xFFC82D33), pants: const Color(0xFF70401F));
    for (var y = -18.0; y < 17; y += 10) {
      c.drawRect(Rect.fromLTWH(-27, y, 54, 5), fill(Colors.white));
    }
    _face(c, -44, patch: true);
    final p = Path()
      ..moveTo(-36, -68)
      ..quadraticBezierTo(-25, -83, -11, -75)
      ..quadraticBezierTo(0, -90, 11, -75)
      ..quadraticBezierTo(25, -83, 36, -68)
      ..quadraticBezierTo(14, -59, 0, -63)
      ..quadraticBezierTo(-14, -59, -36, -68)
      ..close();
    c.drawPath(p, fill(const Color(0xFF15171B)));
    c.drawPath(p, line());
  }

  void _zombie(Canvas c) {
    _human(c, shirt: const Color(0xFF8D3F4B), skin: const Color(0xFF70B46A), pants: const Color(0xFF413F37), smile: false);
  }

  void _relic(Canvas c) {
    _human(c, shirt: const Color(0xFF8A643A), skin: const Color(0xFF9A7651), pants: const Color(0xFF4F4334));
    c.drawCircle(const Offset(0, -44), 34, line(const Color(0xFF715331), 7));
    c.drawCircle(const Offset(0, -44), 18, line(const Color(0xFF79C8CF), 4));
  }

  void _spaceRanger(Canvas c) {
    _human(c, shirt: const Color(0xFF354E99), skin: const Color(0xFF8EDCEF), pants: const Color(0xFF1B285D));
    c.drawOval(const Rect.fromLTWH(-25, -64, 50, 29), fill(const Color(0x8859F1FF)));
  }

  void _commando(Canvas c) {
    _human(c, shirt: const Color(0xFF617043), pants: const Color(0xFF39402E));
    c.drawRect(const Rect.fromLTWH(-30, -73, 60, 12), fill(const Color(0xFF3D492C)));
    c.drawLine(const Offset(-26, -6), const Offset(26, 15), line(const Color(0xFF201E18), 5));
  }

  void _voidKnight(Canvas c) {
    _human(c, shirt: const Color(0xFF3D245A), skin: const Color(0xFF4C3564), pants: const Color(0xFF1D1530), smile: false);
    c.drawCircle(const Offset(0, -44), 32, line(const Color(0xFFA65EFF), 6));
    c.drawCircle(const Offset(-10, -46), 3, fill(const Color(0xFFFF4358)));
    c.drawCircle(const Offset(10, -46), 3, fill(const Color(0xFFFF4358)));
  }

  void _boss(Canvas c) {
    _human(c, shirt: const Color(0xFF20242B), pants: const Color(0xFF111318));
    final tie = Path()..moveTo(-7, -18)..lineTo(0, 7)..lineTo(7, -18)..close();
    c.drawPath(tie, fill(const Color(0xFFE83A3A)));
  }

  void _crystal(Canvas c) {
    _human(c, shirt: const Color(0xFF9D6AF0), skin: const Color(0xFF99F2FF), pants: const Color(0xFF514589));
    final gem = Path()..moveTo(0, -80)..lineTo(20, -53)..lineTo(0, -29)..lineTo(-20, -53)..close();
    c.drawPath(gem, fill(const Color(0xAA65F3FF)));
    c.drawPath(gem, line(const Color(0xFFDBFCFF), 2));
  }

  void _engineer(Canvas c) {
    _human(c, shirt: const Color(0xFFC78637), pants: const Color(0xFF4E5A67));
    c.drawRect(const Rect.fromLTWH(-27, -73, 54, 11), fill(const Color(0xFFFFA52D)));
  }

  void _caveman(Canvas c) {
    _human(c, shirt: const Color(0xFF8D5B35), pants: const Color(0xFF684326));
    _hair(c, const Color(0xFF4D2F1D));
    c.drawLine(const Offset(-24, -12), const Offset(24, 13), line(const Color(0xFFE5C190), 4));
  }

  void _gubi(Canvas c) {
    _human(c, shirt: const Color(0xFF6EBD43), pants: const Color(0xFF303139));
    _hair(c, const Color(0xFFFF8C2F));
  }

  void _street(Canvas c) {
    _human(c, shirt: const Color(0xFFF1F2F5), pants: const Color(0xFF404652));
    c.drawArc(const Rect.fromLTWH(-33, -78, 66, 52), math.pi, math.pi, true, fill(const Color(0xFFE8E9EE)));
  }

  void _princess(Canvas c) {
    _feet(c, const Color(0xFFFFB0CF));
    final dress = Path()
      ..moveTo(-22, -12)
      ..lineTo(-36, 43)
      ..quadraticBezierTo(0, 55, 36, 43)
      ..lineTo(22, -12)
      ..close();
    c.drawPath(dress, fill(const Color(0xFFFF8FC1)));
    c.drawPath(dress, line());
    c.drawCircle(const Offset(0, -44), 29, fill(const Color(0xFFF5B985)));
    c.drawCircle(const Offset(0, -44), 29, line());
    _hair(c, const Color(0xFFF6D24C));
    _face(c, -44);
    _crown(c, -79);
  }

  void _football(Canvas c, Color a, Color b) {
    _human(c, shirt: a, pants: const Color(0xFF202631));
    for (var x = -26.0; x < 27; x += 13) {
      c.drawRect(Rect.fromLTWH(x, -18, 7, 39), fill(b));
    }
    c.drawCircle(const Offset(0, 4), 8, fill(Colors.white.withValues(alpha: 0.85)));
  }

  void _hacker(Canvas c) {
    _human(c, shirt: const Color(0xFF111613), skin: const Color(0xFF1B211C), pants: const Color(0xFF0A0D0B), smile: false);
    c.drawArc(const Rect.fromLTWH(-34, -80, 68, 60), math.pi, math.pi, true, fill(const Color(0xFF101813)));
    c.drawCircle(const Offset(-10, -46), 3, fill(const Color(0xFF4AFF79)));
    c.drawCircle(const Offset(10, -46), 3, fill(const Color(0xFF4AFF79)));
  }

  void _wizard(Canvas c) {
    _human(c, shirt: const Color(0xFF655090), skin: const Color(0xFFD2A06D), pants: const Color(0xFF393052));
    final hat = Path()
      ..moveTo(-32, -65)
      ..lineTo(2, -108)
      ..lineTo(13, -70)
      ..lineTo(34, -62)
      ..quadraticBezierTo(0, -51, -32, -65)
      ..close();
    c.drawPath(hat, fill(const Color(0xFF514171)));
    c.drawPath(hat, line());
    c.drawLine(const Offset(31, 21), const Offset(43, -36), line(const Color(0xFF6C4825), 5));
    c.drawCircle(const Offset(43, -41), 7, fill(const Color(0xFF55CFFF)));
  }

  void _frost(Canvas c, int slot) {
    final t = (slot - 25) / 4.0;
    final accent = Color.lerp(const Color(0xFFB8EEFF), const Color(0xFF5EBDF0), t)!;
    _human(c, shirt: accent, skin: const Color(0xFFD7F6FF), pants: const Color(0xFF53758D));
    c.drawCircle(const Offset(0, -44), 33, line(Colors.white.withValues(alpha: 0.9), 5));
  }

  void _frostBot(Canvas c) {
    _feet(c, const Color(0xFF385871));
    final body = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-30, -24, 60, 68),
      const Radius.circular(16),
    );
    c.drawRRect(body, fill(const Color(0xFF70CFF5)));
    c.drawRRect(body, line(const Color(0xFF275372), 4));
    final head = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-31, -73, 62, 50),
      const Radius.circular(17),
    );
    c.drawRRect(head, fill(const Color(0xFFD7F7FF)));
    c.drawRRect(head, line(const Color(0xFF275372), 4));
    c.drawCircle(const Offset(-11, -49), 5, fill(const Color(0xFF245D86)));
    c.drawCircle(const Offset(11, -49), 5, fill(const Color(0xFF245D86)));
  }

  @override
  bool shouldRepaint(covariant _SkinPainter oldDelegate) =>
      oldDelegate.skin.id != skin.id || oldDelegate.frame != frame;
}
