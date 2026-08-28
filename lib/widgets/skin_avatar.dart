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

  static const List<String> _skinOrder = <String>[
    'classic',
    'glacier',
    'magma',
    'neon',
    'aurora',
    'blaze',
    'void',
    'custom_slot_01',
    'custom_slot_02',
    'custom_slot_03',
    'custom_slot_04',
    'custom_slot_05',
    'custom_slot_06',
    'custom_slot_07',
    'custom_slot_08',
    'custom_slot_09',
    'custom_slot_10',
    'custom_slot_11',
    'custom_slot_12',
    'custom_slot_13',
    'custom_slot_14',
    'custom_slot_15',
    'custom_slot_16',
    'custom_slot_17',
    'custom_slot_18',
    'custom_slot_19',
    'custom_slot_20',
    'custom_slot_21',
    'custom_slot_22',
    'custom_slot_23',
    'custom_slot_24',
    'custom_slot_25',
    'custom_slot_26',
    'custom_slot_27',
    'custom_slot_28',
    'custom_slot_29',
    'custom_slot_30',
  ];

  static const double _cellWidth = 90;
  static const double _cellHeight = 120;
  static const double _atlasWidth = _cellWidth * 37;
  static const double _atlasHeight = _cellHeight * 2;
  static const String _atlasAsset = 'assets/original_skin_atlas.webp';

  bool get _jumping {
    final normalized = frame % 16;
    return normalized >= 3 && normalized <= 12;
  }

  String? get _customAsset => switch (skin.id) {
        'custom_slot_29' => 'assets/custom_skins/custom_slot_29.webp',
        'custom_slot_30' => 'assets/custom_skins/custom_slot_30.webp',
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final customAsset = _customAsset;
    if (customAsset != null) {
      return FittedBox(
        fit: fit,
        alignment: Alignment.center,
        child: SizedBox(
          width: 120,
          height: 160,
          child: Transform.translate(
            offset: Offset(0, _jumping ? -4 : 0),
            child: Transform.scale(
              scaleX: _jumping ? 0.97 : 1,
              scaleY: _jumping ? 1.03 : 1,
              child: Image.asset(
                customAsset,
                width: 120,
                height: 160,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                gaplessPlayback: true,
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
      );
    }

    final column = _skinOrder.indexOf(skin.id);
    if (column < 0) return const SizedBox.shrink();
    final row = _jumping ? 1 : 0;

    return FittedBox(
      fit: fit,
      alignment: Alignment.center,
      child: SizedBox(
        width: _cellWidth,
        height: _cellHeight,
        child: ClipRect(
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: <Widget>[
              Positioned(
                left: -column * _cellWidth,
                top: -row * _cellHeight,
                width: _atlasWidth,
                height: _atlasHeight,
                child: Image.asset(
                  _atlasAsset,
                  width: _atlasWidth,
                  height: _atlasHeight,
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.medium,
                  gaplessPlayback: true,
                  errorBuilder: (context, error, stackTrace) {
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
