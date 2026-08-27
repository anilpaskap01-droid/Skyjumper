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

  test('purchase cannot make gold negative', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{'gold': 499});
    final progress = await PlayerProgressRepository.load();

    final bought = await progress.purchaseSkin(skinById('glacier'));

    expect(bought, isFalse);
    expect(progress.gold, 499);
    expect(progress.ownsSkin('glacier'), isFalse);
  });

  test('purchase and equip persist after reload', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{'gold': 1600});
    final progress = await PlayerProgressRepository.load();

    expect(await progress.purchaseSkin(skinById('glacier')), isTrue);
    expect(progress.gold, 1100);
    expect(await progress.equipSkin('glacier'), isTrue);

    final reloaded = await PlayerProgressRepository.load();
    expect(reloaded.gold, 1100);
    expect(reloaded.ownsSkin('glacier'), isTrue);
    expect(reloaded.equippedSkinId, 'glacier');
  });

  test('only owned skin can be equipped', () async {
    final progress = await PlayerProgressRepository.load();

    expect(await progress.equipSkin('void'), isFalse);
    expect(progress.equippedSkinId, 'classic');
    expect(await progress.equipSkin('king'), isTrue);
    expect(progress.equippedSkinId, 'king');
  });

  test('run commit keeps high score and adds earned gold', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'best_score': 250,
      'gold': 30,
    });
    final progress = await PlayerProgressRepository.load();

    await progress.commitRun(score: 180, runGold: 7);
    expect(progress.bestScore, 250);
    expect(progress.gold, 37);

    await progress.commitRun(score: 900, runGold: 3);
    expect(progress.bestScore, 900);
    expect(progress.gold, 40);
  });
}
