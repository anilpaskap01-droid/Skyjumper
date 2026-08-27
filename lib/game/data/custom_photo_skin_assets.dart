import 'dart:convert';
import 'dart:typed_data';

import 'custom_slot_29_front_idle.dart';
import 'custom_slot_29_front_jump.dart';
import 'custom_slot_30_front_idle.dart';
import 'custom_slot_30_front_jump.dart';

Uint8List? customPhotoSkinBytes(String skinId, {required bool jumping}) {
  final encoded = switch ((skinId, jumping)) {
    ('custom_slot_29', false) => kCustomSlot29FrontIdle,
    ('custom_slot_29', true) => kCustomSlot29FrontJump,
    ('custom_slot_30', false) => kCustomSlot30FrontIdle,
    ('custom_slot_30', true) => kCustomSlot30FrontJump,
    _ => null,
  };
  return encoded == null ? null : base64Decode(encoded);
}
