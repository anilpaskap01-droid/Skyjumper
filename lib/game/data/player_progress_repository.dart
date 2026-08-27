import 'package:shared_preferences/shared_preferences.dart';
import 'package:skyjumper/game/data/skin_catalog.dart';

class PlayerProgressRepository {
  PlayerProgressRepository._(
    this._prefs, {
    required this.bestScore,
    required this.gold,
    required this.soundEnabled,
    required this.vibrationEnabled,
    required this.cameraShakeEnabled,
    required this.reducedEffects,
    required Set<String> ownedSkinIds,
    required this.equippedSkinId,
  }) : ownedSkinIds = ownedSkinIds;

  static const _bestScoreKey = 'best_score';
  static const _goldKey = 'gold';
  static const _soundEnabledKey = 'sound_enabled';
  static const _vibrationEnabledKey = 'vibration_enabled';
  static const _cameraShakeEnabledKey = 'camera_shake_enabled';
  static const _reducedEffectsKey = 'reduced_effects';
  static const _ownedSkinsKey = 'owned_skin_ids';
  static const _equippedSkinKey = 'equipped_skin_id';

  final SharedPreferences _prefs;

  int bestScore;
  int gold;
  bool soundEnabled;
  bool vibrationEnabled;
  bool cameraShakeEnabled;
  bool reducedEffects;
  final Set<String> ownedSkinIds;
  String equippedSkinId;

  SkinDefinition get equippedSkin => skinById(equippedSkinId);

  static Future<PlayerProgressRepository> load() async {
    final prefs = await SharedPreferences.getInstance();
    final bestScore = _safeNonNegativeInt(prefs.get(_bestScoreKey));
    final gold = _safeNonNegativeInt(prefs.get(_goldKey));

    final owned = <String>{
      ...defaultOwnedSkinIds,
      ...?prefs.getStringList(_ownedSkinsKey),
    };
    owned.removeWhere((id) => !kSkinCatalog.any((skin) => skin.id == id));

    final savedEquipped = prefs.getString(_equippedSkinKey) ?? 'classic';
    final equipped = owned.contains(savedEquipped) ? savedEquipped : 'classic';

    return PlayerProgressRepository._(
      prefs,
      bestScore: bestScore,
      gold: gold,
      soundEnabled: prefs.getBool(_soundEnabledKey) ?? true,
      vibrationEnabled: prefs.getBool(_vibrationEnabledKey) ?? true,
      cameraShakeEnabled: prefs.getBool(_cameraShakeEnabledKey) ?? true,
      reducedEffects: prefs.getBool(_reducedEffectsKey) ?? false,
      ownedSkinIds: owned,
      equippedSkinId: equipped,
    );
  }

  bool ownsSkin(String id) => ownedSkinIds.contains(id);

  Future<void> commitRun({required int score, required int runGold}) async {
    var dirtyBest = false;
    var dirtyGold = false;
    if (score > bestScore) {
      bestScore = score;
      dirtyBest = true;
    }
    if (runGold > 0) {
      gold += runGold;
      dirtyGold = true;
    }
    if (dirtyBest) await _prefs.setInt(_bestScoreKey, bestScore);
    if (dirtyGold) await _prefs.setInt(_goldKey, gold);
  }

  Future<bool> purchaseSkin(SkinDefinition skin) async {
    if (ownsSkin(skin.id)) return true;
    if (skin.price <= 0) {
      ownedSkinIds.add(skin.id);
      await _saveOwnedSkins();
      return true;
    }
    if (gold < skin.price) return false;

    gold -= skin.price;
    ownedSkinIds.add(skin.id);
    await Future.wait([
      _prefs.setInt(_goldKey, gold),
      _saveOwnedSkins(),
    ]);
    return true;
  }

  Future<bool> equipSkin(String id) async {
    if (!ownsSkin(id)) return false;
    if (!kSkinCatalog.any((skin) => skin.id == id)) return false;
    equippedSkinId = id;
    await _prefs.setString(_equippedSkinKey, id);
    return true;
  }

  Future<void> setSoundEnabled(bool enabled) async {
    soundEnabled = enabled;
    await _prefs.setBool(_soundEnabledKey, enabled);
  }

  Future<void> setVibrationEnabled(bool enabled) async {
    vibrationEnabled = enabled;
    await _prefs.setBool(_vibrationEnabledKey, enabled);
  }

  Future<void> setCameraShakeEnabled(bool enabled) async {
    cameraShakeEnabled = enabled;
    await _prefs.setBool(_cameraShakeEnabledKey, enabled);
  }

  Future<void> setReducedEffects(bool enabled) async {
    reducedEffects = enabled;
    await _prefs.setBool(_reducedEffectsKey, enabled);
  }

  Future<void> _saveOwnedSkins() async {
    final ids = ownedSkinIds.toList()..sort();
    await _prefs.setStringList(_ownedSkinsKey, ids);
  }

  static int _safeNonNegativeInt(Object? value) {
    if (value is int && value >= 0) return value;
    if (value is num && value.isFinite) {
      return value.toInt().clamp(0, 1 << 31).toInt();
    }
    return 0;
  }
}
