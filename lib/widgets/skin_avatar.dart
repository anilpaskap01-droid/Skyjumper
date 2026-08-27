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

  static const int _columns = 8;
  static const int _rows = 5;

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

  bool get _jumping {
    final normalized = frame % 16;
    return normalized >= 3 && normalized <= 12;
  }

  String get _atlasAsset => _jumping
      ? 'assets/original_skins/front_jump_atlas.webp'
      : 'assets/original_skins/front_idle_atlas.webp';

  @override
  Widget build(BuildContext context) {
    final index = _skinOrder.indexOf(skin.id);
    if (index < 0) return const SizedBox.shrink();

    final column = index % _columns;
    final row = index ~/ _columns;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth =
            constraints.maxWidth.isFinite ? constraints.maxWidth : 80.0;
        final availableHeight =
            constraints.maxHeight.isFinite ? constraints.maxHeight : 80.0;
        final size = availableWidth < availableHeight
            ? availableWidth
            : availableHeight;

        return Center(
          child: SizedBox(
            width: size,
            height: size,
            child: ClipRect(
              child: OverflowBox(
                alignment: Alignment.topLeft,
                minWidth: size * _columns,
                maxWidth: size * _columns,
                minHeight: size * _rows,
                maxHeight: size * _rows,
                child: Transform.translate(
                  offset: Offset(-column * size, -row * size),
                  child: Image.asset(
                    _atlasAsset,
                    width: size * _columns,
                    height: size * _rows,
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.high,
                    gaplessPlayback: true,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
