import 'package:flutter/material.dart';

enum SkinVisualKind { procedural, asset, network, spriteSheet }

class SkinDefinition {
  const SkinDefinition({
    required this.id,
    required this.name,
    required this.price,
    required this.visualKind,
    required this.source,
    required this.accent,
    this.defaultOwned = false,
    this.columns = 1,
    this.rows = 1,
    this.hasCrownAnimation = false,
    this.special = false,
  });

  final String id;
  final String name;
  final int price;
  final SkinVisualKind visualKind;
  final String source;
  final Color accent;
  final bool defaultOwned;
  final int columns;
  final int rows;
  final bool hasCrownAnimation;
  final bool special;

  int get frameCount => columns * rows;
}

const String _cdn =
    'https://raw.githubusercontent.com/hanxgames/skyjumper-cdn/main/skins';

const List<SkinDefinition> kSkinCatalog = <SkinDefinition>[
  SkinDefinition(
    id: 'classic',
    name: 'CLASSIC',
    price: 0,
    visualKind: SkinVisualKind.procedural,
    source: '',
    accent: Color(0xFFFF8A32),
    defaultOwned: true,
  ),
  SkinDefinition(
    id: 'glacier',
    name: 'GLACIER',
    price: 500,
    visualKind: SkinVisualKind.network,
    source: '$_cdn/glacier.png',
    accent: Color(0xFF7EE7FF),
  ),
  SkinDefinition(
    id: 'magma',
    name: 'MAGMA',
    price: 1100,
    visualKind: SkinVisualKind.network,
    source: '$_cdn/magma.png',
    accent: Color(0xFFFF6A32),
  ),
  SkinDefinition(
    id: 'neon',
    name: 'NEON',
    price: 2250,
    visualKind: SkinVisualKind.network,
    source: '$_cdn/neon.png',
    accent: Color(0xFF5CFFB1),
  ),
  SkinDefinition(
    id: 'aurora',
    name: 'AURORA',
    price: 4500,
    visualKind: SkinVisualKind.network,
    source: '$_cdn/aurora.png',
    accent: Color(0xFF8D7CFF),
  ),
  SkinDefinition(
    id: 'blaze',
    name: 'BLAZE',
    price: 7800,
    visualKind: SkinVisualKind.network,
    source: '$_cdn/blaze.png',
    accent: Color(0xFFFFB23D),
  ),
  SkinDefinition(
    id: 'void',
    name: 'VOID',
    price: 10500,
    visualKind: SkinVisualKind.network,
    source: '$_cdn/void.png',
    accent: Color(0xFFB864FF),
  ),
  SkinDefinition(
    id: 'pirate',
    name: 'PIRATE',
    price: 0,
    visualKind: SkinVisualKind.spriteSheet,
    source: '',
    accent: Color(0xFFFFC34D),
    defaultOwned: true,
    columns: 5,
    rows: 2,
    special: true,
  ),
  SkinDefinition(
    id: 'king',
    name: 'KING',
    price: 0,
    visualKind: SkinVisualKind.spriteSheet,
    source: '',
    accent: Color(0xFFFFD34E),
    defaultOwned: true,
    columns: 4,
    rows: 4,
    hasCrownAnimation: true,
    special: true,
  ),
  SkinDefinition(
    id: 'hotwheels',
    name: 'HOT WHEELS',
    price: 0,
    visualKind: SkinVisualKind.procedural,
    source: '',
    accent: Color(0xFF54D9F4),
    defaultOwned: true,
    special: true,
  ),
  SkinDefinition(
    id: 'hacker',
    name: 'HACKER',
    price: 0,
    visualKind: SkinVisualKind.procedural,
    source: '',
    accent: Color(0xFF50FF88),
    defaultOwned: true,
    special: true,
  ),
  SkinDefinition(
    id: 'fener',
    name: 'FENER',
    price: 0,
    visualKind: SkinVisualKind.procedural,
    source: '',
    accent: Color(0xFFFFE04F),
    defaultOwned: true,
    special: true,
  ),
];

SkinDefinition skinById(String id) {
  return kSkinCatalog.firstWhere(
    (skin) => skin.id == id,
    orElse: () => kSkinCatalog.first,
  );
}

Set<String> get defaultOwnedSkinIds => kSkinCatalog
    .where((skin) => skin.defaultOwned)
    .map((skin) => skin.id)
    .toSet();
