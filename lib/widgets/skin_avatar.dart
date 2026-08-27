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
        return CustomPaint(
          painter: _ClassicSkinPainter(accent: skin.accent),
          child: const SizedBox.expand(),
        );
      case SkinVisualKind.asset:
        return Image.asset(
          skin.source,
          fit: fit,
          filterQuality: FilterQuality.high,
        );
      case SkinVisualKind.network:
        return Image.network(
          skin.source,
          fit: fit,
          filterQuality: FilterQuality.medium,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => _NetworkFallback(skin: skin),
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return _NetworkFallback(skin: skin, loading: true);
          },
        );
      case SkinVisualKind.spriteSheet:
        return SpriteSheetFrame(
          assetPath: skin.source,
          columns: skin.columns,
          rows: skin.rows,
          frame: frame.clamp(0, skin.frameCount - 1).toInt(),
        );
    }
  }
}

class SpriteSheetFrame extends StatelessWidget {
  const SpriteSheetFrame({
    super.key,
    required this.assetPath,
    required this.columns,
    required this.rows,
    required this.frame,
  });

  final String assetPath;
  final int columns;
  final int rows;
  final int frame;

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
  const _NetworkFallback({required this.skin, this.loading = false});

  final SkinDefinition skin;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: skin.accent.withValues(alpha: 0.92),
        border: Border.all(color: Colors.white24, width: 2),
      ),
      child: Center(
        child: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                Icons.person_rounded,
                color: Colors.black.withValues(alpha: 0.55),
              ),
      ),
    );
  }
}

class _ClassicSkinPainter extends CustomPainter {
  const _ClassicSkinPainter({required this.accent});

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final bodyRadius = size.shortestSide * 0.32;
    final bodyPaint = Paint()..color = accent;
    final outline = Paint()
      ..color = const Color(0xFF2A1A12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.035;

    canvas.drawCircle(center, bodyRadius, bodyPaint);
    canvas.drawCircle(center, bodyRadius, outline);

    final eyePaint = Paint()..color = const Color(0xFF21150F);
    final eyeY = center.dy - bodyRadius * 0.18;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx - bodyRadius * 0.28, eyeY),
        width: bodyRadius * 0.16,
        height: bodyRadius * 0.28,
      ),
      eyePaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx + bodyRadius * 0.28, eyeY),
        width: bodyRadius * 0.16,
        height: bodyRadius * 0.28,
      ),
      eyePaint,
    );

    final mouth = Paint()
      ..color = const Color(0xFF21150F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.025
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(
        center.dx - bodyRadius * 0.12,
        center.dy + bodyRadius * 0.22,
      ),
      Offset(
        center.dx + bodyRadius * 0.12,
        center.dy + bodyRadius * 0.22,
      ),
      mouth,
    );
  }

  @override
  bool shouldRepaint(covariant _ClassicSkinPainter oldDelegate) =>
      oldDelegate.accent != accent;
}
