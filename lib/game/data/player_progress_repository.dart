import 'package:shared_preferences/shared_preferences.dart';

class PlayerProgressRepository {
  PlayerProgressRepository._(
    this._prefs, {
    required this.bestScore,
    required this.gold,
    required this.soundEnabled,
  });

  static const _bestScoreKey = 'best_score';
  static const _goldKey = 'gold';
  static const _soundEnabledKey = 'sound_enabled';

  final SharedPreferences _prefs;

  int bestScore;
  int gold;
  bool soundEnabled;

  static Future<PlayerProgressRepository> load() async {
    final prefs = await SharedPreferences.getInstance();
    final bestScore = _safeNonNegativeInt(prefs.get(_bestScoreKey));
    final gold = _safeNonNegativeInt(prefs.get(_goldKey));
    final sound = prefs.get(_soundEnabledKey);

    return PlayerProgressRepository._(
      prefs,
      bestScore: bestScore,
      gold: gold,
      soundEnabled: sound is bool ? sound : true,
    );
  }

  Future<void> commitRun({required int score, required int runGold}) async {
    if (score > bestScore) {
      bestScore = score;
      await _prefs.setInt(_bestScoreKey, bestScore);
    }
    if (runGold > 0) {
      gold += runGold;
      await _prefs.setInt(_goldKey, gold);
    }
  }

  Future<void> setSoundEnabled(bool enabled) async {
    soundEnabled = enabled;
    await _prefs.setBool(_soundEnabledKey, enabled);
  }

  static int _safeNonNegativeInt(Object? value) {
    if (value is int && value >= 0) return value;
    if (value is num && value.isFinite) return value.toInt().clamp(0, 1 << 31);
    return 0;
  }
}
