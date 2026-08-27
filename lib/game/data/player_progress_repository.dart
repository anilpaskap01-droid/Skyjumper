import 'package:shared_preferences/shared_preferences.dart';
import 'package:skyjumper/game/data/skin_catalog.dart';

class DailyRewardResult {
  const DailyRewardResult({required this.gold, required this.gems, required this.day});

  final int gold;
  final int gems;
  final int day;
}

class PlayerProgressRepository {
  PlayerProgressRepository._(
    this._prefs, {
    required this.bestScore,
    required this.seasonStars,
    required this.dailyStreak,
    required this.lastDailyClaimDay,
    required this.soundEnabled,
    required this.vibrationEnabled,
    required this.cameraShakeEnabled,
    required this.reducedEffects,
    required this.equippedSkinId,
  });

  static const int unlimitedCurrency = 999999999;

  static const _bestScoreKey = 'best_score';
  static const _seasonStarsKey = 'season_stars';
  static const _dailyStreakKey = 'daily_streak';
  static const _lastDailyClaimDayKey = 'last_daily_claim_day';
  static const _soundEnabledKey = 'sound_enabled';
  static const _vibrationEnabledKey = 'vibration_enabled';
  static const _cameraShakeEnabledKey = 'camera_shake_enabled';
  static const _reducedEffectsKey = 'reduced_effects';
  static const _equippedSkinKey = 'equipped_skin_id';

  static const List<int> dailyGoldRewards = <int>[50, 100, 150, 200, 250, 350, 500];
  static const List<int> dailyGemRewards = <int>[0, 0, 5, 0, 10, 0, 20];

  final SharedPreferences _prefs;

  int bestScore;
  int seasonStars;
  int dailyStreak;
  String? lastDailyClaimDay;
  bool soundEnabled;
  bool vibrationEnabled;
  bool cameraShakeEnabled;
  bool reducedEffects;
  String equippedSkinId;

  /// This offline build intentionally has infinite soft and premium currency.
  int get gold => unlimitedCurrency;
  int get gems => unlimitedCurrency;

  /// Every original APK skin is unlocked in this build.
  Set<String> get ownedSkinIds => kSkinCatalog.map((skin) => skin.id).toSet();

  SkinDefinition get equippedSkin => skinById(equippedSkinId);

  static Future<PlayerProgressRepository> load() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEquipped = prefs.getString(_equippedSkinKey) ?? 'classic';
    final equipped = kSkinCatalog.any((skin) => skin.id == savedEquipped)
        ? savedEquipped
        : 'classic';

    return PlayerProgressRepository._(
      prefs,
      bestScore: _safeNonNegativeInt(prefs.get(_bestScoreKey)),
      seasonStars: _safeNonNegativeInt(prefs.get(_seasonStarsKey)),
      dailyStreak: _safeNonNegativeInt(prefs.get(_dailyStreakKey)).clamp(0, 7).toInt(),
      lastDailyClaimDay: prefs.getString(_lastDailyClaimDayKey),
      soundEnabled: prefs.getBool(_soundEnabledKey) ?? true,
      vibrationEnabled: prefs.getBool(_vibrationEnabledKey) ?? true,
      cameraShakeEnabled: prefs.getBool(_cameraShakeEnabledKey) ?? true,
      reducedEffects: prefs.getBool(_reducedEffectsKey) ?? false,
      equippedSkinId: equipped,
    );
  }

  bool ownsSkin(String id) => kSkinCatalog.any((skin) => skin.id == id);

  Future<void> commitRun({required int score, required int runGold}) async {
    if (score > bestScore) {
      bestScore = score;
      await _prefs.setInt(_bestScoreKey, bestScore);
    }
    // Currency is infinite, therefore earned runGold does not need persistence.
  }

  Future<bool> purchaseSkin(SkinDefinition skin) async {
    // All skins are already unlocked and purchases never reduce currency.
    return ownsSkin(skin.id);
  }

  Future<bool> equipSkin(String id) async {
    if (!ownsSkin(id)) return false;
    equippedSkinId = id;
    await _prefs.setString(_equippedSkinKey, id);
    return true;
  }

  bool canClaimDaily([DateTime? now]) {
    final today = _dayKey(now ?? DateTime.now());
    return lastDailyClaimDay != today;
  }

  Future<DailyRewardResult?> claimDailyReward([DateTime? now]) async {
    final current = now ?? DateTime.now();
    final today = _dayKey(current);
    if (lastDailyClaimDay == today) return null;

    final yesterday = _dayKey(current.subtract(const Duration(days: 1)));
    if (lastDailyClaimDay == yesterday) {
      dailyStreak = dailyStreak >= 7 ? 1 : dailyStreak + 1;
    } else {
      dailyStreak = 1;
    }

    final index = (dailyStreak - 1).clamp(0, 6).toInt();
    final rewardGold = dailyGoldRewards[index];
    final rewardGems = dailyGemRewards[index];
    lastDailyClaimDay = today;

    await Future.wait(<Future<bool>>[
      _prefs.setInt(_dailyStreakKey, dailyStreak),
      _prefs.setString(_lastDailyClaimDayKey, today),
    ]);

    return DailyRewardResult(gold: rewardGold, gems: rewardGems, day: dailyStreak);
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

  static String _dayKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  static int _safeNonNegativeInt(Object? value) {
    if (value is int && value >= 0) return value;
    if (value is num && value.isFinite) {
      return value.toInt().clamp(0, 1 << 31).toInt();
    }
    return 0;
  }
}
