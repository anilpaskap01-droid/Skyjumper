import 'package:flutter/material.dart';

class SkinDefinition {
  const SkinDefinition({
    required this.id,
    required this.name,
    required this.price,
    required this.accent,
    this.defaultOwned = false,
    this.hasCrownAnimation = false,
    this.special = false,
    this.customSlot,
  });

  final String id;
  final String name;
  final int price;
  final Color accent;
  final bool defaultOwned;
  final bool hasCrownAnimation;
  final bool special;
  final int? customSlot;
}

const List<SkinDefinition> kSkinCatalog = <SkinDefinition>[
  SkinDefinition(id: 'classic', name: 'Classic', price: 0, accent: Color(0xFFFF7A22), defaultOwned: true),
  SkinDefinition(id: 'glacier', name: 'Glacier', price: 500, accent: Color(0xFF6DDCFF)),
  SkinDefinition(id: 'magma', name: 'Magma', price: 1100, accent: Color(0xFFFF542E)),
  SkinDefinition(id: 'neon', name: 'Neon', price: 2250, accent: Color(0xFF32F7C2)),
  SkinDefinition(id: 'aurora', name: 'Aurora', price: 4500, accent: Color(0xFF82A0FF)),
  SkinDefinition(id: 'blaze', name: 'Blaze', price: 7800, accent: Color(0xFFFFA526)),
  SkinDefinition(id: 'void', name: 'Void', price: 10500, accent: Color(0xFF9D63FF)),
  SkinDefinition(id: 'custom_slot_01', name: 'Astronaut', price: 190, accent: Color(0xFF74D9FF), special: true, customSlot: 1),
  SkinDefinition(id: 'custom_slot_02', name: 'TheKing', price: 4800, accent: Color(0xFFFFD84D), special: true, customSlot: 2, hasCrownAnimation: true),
  SkinDefinition(id: 'custom_slot_03', name: 'CoolBoy', price: 70, accent: Color(0xFF727A92), special: true, customSlot: 3),
  SkinDefinition(id: 'custom_slot_04', name: 'Dark Lord', price: 120, accent: Color(0xFF7D8599), special: true, customSlot: 4),
  SkinDefinition(id: 'custom_slot_05', name: 'Arctic', price: 75, accent: Color(0xFFE9F4FF), special: true, customSlot: 5),
  SkinDefinition(id: 'custom_slot_06', name: 'Pirate', price: 530, accent: Color(0xFFFFBD39), special: true, customSlot: 6),
  SkinDefinition(id: 'custom_slot_07', name: 'Zombie', price: 240, accent: Color(0xFF78C85E), special: true, customSlot: 7),
  SkinDefinition(id: 'custom_slot_08', name: 'Relic', price: 150, accent: Color(0xFFC5A76E), special: true, customSlot: 8),
  SkinDefinition(id: 'custom_slot_09', name: 'Space Ranger', price: 1100, accent: Color(0xFF72E5F5), special: true, customSlot: 9),
  SkinDefinition(id: 'custom_slot_10', name: 'Commando', price: 520, accent: Color(0xFF8D9863), special: true, customSlot: 10),
  SkinDefinition(id: 'custom_slot_11', name: 'Void Knight', price: 4900, accent: Color(0xFFB35EFF), special: true, customSlot: 11),
  SkinDefinition(id: 'custom_slot_12', name: 'Boss', price: 790, accent: Color(0xFF2C313B), special: true, customSlot: 12),
  SkinDefinition(id: 'custom_slot_13', name: 'Crystal', price: 2100, accent: Color(0xFF81F4FF), special: true, customSlot: 13),
  SkinDefinition(id: 'custom_slot_14', name: 'Engineer', price: 500, accent: Color(0xFFC18A4C), special: true, customSlot: 14),
  SkinDefinition(id: 'custom_slot_15', name: 'Caveman', price: 600, accent: Color(0xFFC98645), special: true, customSlot: 15),
  SkinDefinition(id: 'custom_slot_16', name: 'Gubi', price: 2300, accent: Color(0xFFFF8F32), special: true, customSlot: 16),
  SkinDefinition(id: 'custom_slot_17', name: 'Street', price: 80, accent: Color(0xFFF3EFF8), special: true, customSlot: 17),
  SkinDefinition(id: 'custom_slot_18', name: 'Princess', price: 520, accent: Color(0xFFFF96C6), special: true, customSlot: 18),
  SkinDefinition(id: 'custom_slot_19', name: 'Lions', price: 320, accent: Color(0xFFFFB02E), special: true, customSlot: 19),
  SkinDefinition(id: 'custom_slot_20', name: 'Canary', price: 320, accent: Color(0xFFF9DE33), special: true, customSlot: 20),
  SkinDefinition(id: 'custom_slot_21', name: 'Black White', price: 320, accent: Color(0xFFECECEC), special: true, customSlot: 21),
  SkinDefinition(id: 'custom_slot_22', name: 'Burgundy Blue', price: 320, accent: Color(0xFF8F315B), special: true, customSlot: 22),
  SkinDefinition(id: 'custom_slot_23', name: 'Hacker', price: 350, accent: Color(0xFF48F37D), special: true, customSlot: 23),
  SkinDefinition(id: 'custom_slot_24', name: 'Wizard', price: 450, accent: Color(0xFF9B68F5), special: true, customSlot: 24),
  SkinDefinition(id: 'custom_slot_25', name: 'Frost I', price: 2200, accent: Color(0xFF8DDFFF), special: true, customSlot: 25),
  SkinDefinition(id: 'custom_slot_26', name: 'Frost II', price: 2200, accent: Color(0xFF81D9FF), special: true, customSlot: 26),
  SkinDefinition(id: 'custom_slot_27', name: 'Frost III', price: 2200, accent: Color(0xFF78D2FF), special: true, customSlot: 27),
  SkinDefinition(id: 'custom_slot_28', name: 'Frost IV', price: 2200, accent: Color(0xFF74CDF9), special: true, customSlot: 28),
  SkinDefinition(id: 'custom_slot_29', name: 'Phone Boy', price: 2200, accent: Color(0xFFFFA13D), special: true, customSlot: 29),
  SkinDefinition(id: 'custom_slot_30', name: 'Hot Wheels', price: 3200, accent: Color(0xFF58CFFF), special: true, customSlot: 30),
];

SkinDefinition skinById(String id) => kSkinCatalog.firstWhere(
      (skin) => skin.id == id,
      orElse: () => kSkinCatalog.first,
    );

Set<String> get defaultOwnedSkinIds => kSkinCatalog
    .where((skin) => skin.defaultOwned)
    .map((skin) => skin.id)
    .toSet();
