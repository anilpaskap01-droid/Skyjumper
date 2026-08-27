import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skyjumper/game/data/player_progress_repository.dart';
import 'package:skyjumper/game/data/skin_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('catalog preserves recovered market prices', () {
    expect(skinById('glacier').price, 500);
    expect(skinById('magma').price, 1100);
    expect(skinById('neon').price, 2250);
    expect(skinById('aurora').price, 4500);
    expect(skinById('blaze').price, 7800);
    expect(skinById('void').price, 10500);
  });

  test('gold and gems are unlimited and never deducted', () async {
    final progress = await PlayerProgressRepository.load();
    final beforeGold = progress.gold;
    final beforeGems = progress.gems;

    expect(beforeGold, PlayerProgressRepository.unlimitedCurrency);
    expect(beforeGems, PlayerProgressRepository.unlimitedCurrency);
    expect(await progress.purchaseSkin(skinById('void')), isTrue);
    expect(progress.gold, beforeGold);
    expect(progress.gems, beforeGems);
  });

  test('every catalog skin is unlocked', () async {
    final progress = await PlayerProgressRepository.load();
    for (final skin in kSkinCatalog) {
      expect(progress.ownsSkin(skin.id), isTrue, reason: skin.id);
    }
    expect(progress.ownedSkinIds.length, kSkinCatalog.length);
  });

  test('any original skin can be equipped and persists', () async {
    final progress = await PlayerProgressRepository.load();

    expect(await progress.equipSkin('custom_slot_02'), isTrue);
    expect(progress.equippedSkinId, 'custom_slot_02');

    final reloaded = await PlayerProgressRepository.load();
    expect(reloaded.equippedSkinId, 'custom_slot_02');
  });

  test('run commit updates high score without changing unlimited currency', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{'best_score': 250});
    final progress = await PlayerProgressRepository.load();

    await progress.commitRun(score: 900, runGold: 9999);
    expect(progress.bestScore, 900);
    expect(progress.gold, PlayerProgressRepository.unlimitedCurrency);
    expect(progress.gems, PlayerProgressRepository.unlimitedCurrency);
  });
}
