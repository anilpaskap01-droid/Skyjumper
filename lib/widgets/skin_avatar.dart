import 'package:flutter/material.dart';
import 'package:skyjumper/game/data/skin_catalog.dart';

/// Renders only the original character PNGs recovered from the SkyJumper APK.
/// There is deliberately no procedural/model-generated character fallback.
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

  String get _pose {
    final normalized = frame % 16;
    return normalized >= 3 && normalized <= 12 ? 'front_jump' : 'front_idle';
  }

  String get _assetPath =>
      'assets/original_skins/${skin.id}_$_pose.png';

  String get _idleAssetPath =>
      'assets/original_skins/${skin.id}_front_idle.png';

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      _assetPath,
      fit: fit,
      filterQuality: FilterQuality.high,
      gaplessPlayback: true,
      errorBuilder: (context, error, stackTrace) {
        return Image.asset(
          _idleAssetPath,
          fit: fit,
          filterQuality: FilterQuality.high,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        );
      },
    );
  }
}
