import 'package:flutter/material.dart';
import 'package:skyjumper/game/data/skin_catalog.dart';

/// Displays only character pixels extracted from the user-supplied original
/// SkyJumper APK. No procedural or generated character renderer exists here.
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

  static const List<String> _skinOrder = <String>[
    'classic', 'glacier', 'magma', 'neon', 'aurora', 'blaze', 'void',
    'custom_slot_01', 'custom_slot_02', 'custom_slot_03', 'custom_slot_04',
    'custom_slot_05', 'custom_slot_06', 'custom_slot_07', 'custom_slot_08',
    'custom_slot_09', 'custom_slot_10', 'custom_slot_11', 'custom_slot_12',
    'custom_slot_13', 'custom_slot_14', 'custom_slot_15', 'custom_slot_16',
    'custom_slot_17', 'custom_slot_18', 'custom_slot_19', 'custom_slot_20',
    'custom_slot_21', 'custom_slot_22', 'custom_slot_23', 'custom_slot_24',
    'custom_slot_25', 'custom_slot_26', 'custom_slot_27', 'custom_slot_28',
    'custom_slot_29', 'custom_slot_30',
  ];

  static const double _cellWidth = 24;
  static const double _cellHeight = 32;
  static const double _atlasWidth = _cellWidth * 37;
  static const double _atlasHeight = _cellHeight * 2;

  int get _column {
    final index = _skinOrder.indexOf(skin.id);
    return index < 0 ? 0 : index;
  }

  int get _row {
    final normalized = frame % 16;
    return normalized >= 3 && normalized <= 12 ? 1 : 0;
  }

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: fit,
      child: SizedBox(
        width: _cellWidth,
        height: _cellHeight,
        child: ClipRect(
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: <Widget>[
              Positioned(
                left: -_column * _cellWidth,
                top: -_row * _cellHeight,
                width: _atlasWidth,
                height: _atlasHeight,
                child: Image.asset(
                  'assets/original_skin_atlas.webp',
                  width: _atlasWidth,
                  height: _atlasHeight,
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.none,
                  gaplessPlayback: true,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
