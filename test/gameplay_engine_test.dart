import 'package:flutter_test/flutter_test.dart';
import 'package:skyjumper/game/engine/gameplay_engine.dart';

void main() {
  group('SkyJumperEngine', () {
    test('one-way platform lands only while descending and auto-jumps', () {
      final engine = SkyJumperEngine(
        tuning: const GameTuning(
          gravity: 0,
          jumpVelocity: -120,
          platformMinGapY: 100,
          platformMaxGapY: 100,
        ),
      );
      engine.platforms
        ..clear()
        ..add(GamePlatform(
          id: 900,
          x: 80,
          y: 300,
          width: 120,
          height: 14,
        ));
      engine.coins.clear();
      engine.player.x = 100;
      engine.player.y = 252;
      engine.player.vy = 100;

      engine.update(0.10);

      expect(engine.player.vy, lessThan(0));
      expect(engine.player.y, lessThanOrEqualTo(300 - engine.player.height));
    });

    test('ascending player passes upward through one-way platform', () {
      final engine = SkyJumperEngine(
        tuning: const GameTuning(
          gravity: 0,
          jumpVelocity: -120,
          platformMinGapY: 100,
          platformMaxGapY: 100,
        ),
      );
      engine.platforms
        ..clear()
        ..add(GamePlatform(
          id: 901,
          x: 80,
          y: 300,
          width: 120,
          height: 14,
        ));
      engine.coins.clear();
      engine.player.x = 100;
      engine.player.y = 305;
      engine.player.vy = -100;

      engine.update(0.05);

      expect(engine.player.vy, equals(-100));
      expect(engine.player.y, lessThan(305));
    });

    test('coin gives recovered +4 score and +1 runGold', () {
      final engine = SkyJumperEngine(
        tuning: const GameTuning(
          gravity: 0,
          jumpVelocity: 0,
          platformMinGapY: 100,
          platformMaxGapY: 100,
        ),
      );
      engine.platforms.clear();
      engine.coins
        ..clear()
        ..add(CoinState(
          id: 700,
          x: engine.player.x + engine.player.width / 2,
          y: engine.player.y + engine.player.height / 2,
        ));
      final before = engine.score;

      engine.update(0.001);

      expect(engine.score, equals(before + ScoringRules.coinScore));
      expect(engine.runGold, equals(ScoringRules.coinGold));
      expect(engine.coins, isEmpty);
    });

    test('height-derived score never decreases', () {
      final engine = SkyJumperEngine(
        tuning: const GameTuning(
          gravity: 0,
          jumpVelocity: -300,
          platformMinGapY: 100,
          platformMaxGapY: 100,
        ),
      );
      engine.platforms.clear();
      engine.coins.clear();
      final initial = engine.score;

      engine.update(0.20);
      final climbedScore = engine.score;
      engine.player.vy = 300;
      engine.update(0.10);

      expect(climbedScore, greaterThanOrEqualTo(initial));
      expect(engine.score, greaterThanOrEqualTo(climbedScore));
    });
  });
}
