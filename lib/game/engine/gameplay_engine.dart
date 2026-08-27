import 'dart:math' as math;

/// Central tuning source for gameplay values that were not recoverable from the
/// original repository. Recovered rules (score/combo/coin) live separately in
/// [ScoringRules] and must not be changed when feel-tuning these values.
class GameTuning {
  const GameTuning({
    this.worldWidth = 360,
    this.viewportHeight = 720,
    this.playerWidth = 42,
    this.playerHeight = 42,
    this.startPlayerY = 620,
    this.gravity = 1850,
    this.jumpVelocity = -760,
    this.horizontalAcceleration = 2200,
    this.horizontalDeceleration = 2800,
    this.maxHorizontalSpeed = 260,
    this.cameraThresholdY = 310,
    this.platformMinGapY = 82,
    this.platformMaxGapY = 126,
    this.platformWidth = 92,
    this.platformHeight = 14,
    this.maxPlatformOffsetX = 126,
    this.generationAhead = 520,
    this.cleanupBelow = 260,
  });

  final double worldWidth;
  final double viewportHeight;
  final double playerWidth;
  final double playerHeight;
  final double startPlayerY;
  final double gravity;
  final double jumpVelocity;
  final double horizontalAcceleration;
  final double horizontalDeceleration;
  final double maxHorizontalSpeed;
  final double cameraThresholdY;
  final double platformMinGapY;
  final double platformMaxGapY;
  final double platformWidth;
  final double platformHeight;
  final double maxPlatformOffsetX;
  final double generationAhead;
  final double cleanupBelow;
}

/// Rules recovered from the previous SkyJumper implementation notes.
class ScoringRules {
  const ScoringRules._();

  static const double coreMultiplier = 1.25;
  static const double heightPixelsPerPoint = 4;
  static const int coinScore = 4;
  static const int coinGold = 1;
  static const int landingBase = 10;
  static const int landingComboStep = 6;
  static const double progressionMinHeight = 10;
  static const double comboWindowSeconds = 1.35;
  static const int firstBounceBonus = 20;
  static const int bounceBonusStep = 12;
  static const int bounceBonusCap = 68;
}

enum PlatformKind { normal, moving, bounce }

class GamePlatform {
  GamePlatform({
    required this.id,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.kind = PlatformKind.normal,
    this.velocityX = 0,
    this.minX = 0,
    this.maxX = 0,
  });

  final int id;
  double x;
  final double y;
  final double width;
  final double height;
  final PlatformKind kind;
  double velocityX;
  final double minX;
  final double maxX;
}

class CoinState {
  CoinState({
    required this.id,
    required this.x,
    required this.y,
    this.radius = 8,
  });

  final int id;
  final double x;
  final double y;
  final double radius;
  bool collected = false;
}

class PlayerState {
  PlayerState({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  double x;
  double y;
  double vx = 0;
  double vy = 0;
  final double width;
  final double height;
}

class SkyJumperEngine {
  SkyJumperEngine({
    this.tuning = const GameTuning(),
    int randomSeed = 240326,
  }) : _random = math.Random(randomSeed) {
    reset();
  }

  final GameTuning tuning;
  final math.Random _random;

  late PlayerState player;
  final List<GamePlatform> platforms = <GamePlatform>[];
  final List<CoinState> coins = <CoinState>[];

  double inputAxis = 0;
  double cameraTop = 0;
  double elapsedSeconds = 0;
  double highestPlayerY = 0;
  double highestGeneratedPlatformY = 0;
  int score = 0;
  int runGold = 0;
  int combo = 1;
  int bounceChain = 0;
  bool gameOver = false;

  int _nextPlatformId = 1;
  int _nextCoinId = 1;
  int? _lastLandedPlatformId;
  double? _lastProgressionPlatformY;
  double? _lastProgressionLandingTime;

  void reset() {
    platforms.clear();
    coins.clear();
    inputAxis = 0;
    cameraTop = 0;
    elapsedSeconds = 0;
    score = 0;
    runGold = 0;
    combo = 1;
    bounceChain = 0;
    gameOver = false;
    _nextPlatformId = 1;
    _nextCoinId = 1;
    _lastLandedPlatformId = null;
    _lastProgressionPlatformY = null;
    _lastProgressionLandingTime = null;

    player = PlayerState(
      x: (tuning.worldWidth - tuning.playerWidth) / 2,
      y: tuning.startPlayerY,
      width: tuning.playerWidth,
      height: tuning.playerHeight,
    );
    highestPlayerY = player.y;

    final startPlatform = GamePlatform(
      id: _nextPlatformId++,
      x: (tuning.worldWidth - tuning.platformWidth) / 2,
      y: tuning.startPlayerY + tuning.playerHeight + 18,
      width: tuning.platformWidth,
      height: tuning.platformHeight,
    );
    platforms.add(startPlatform);
    highestGeneratedPlatformY = startPlatform.y;
    _lastProgressionPlatformY = startPlatform.y;

    // SkyJumper's recovered acceptance criteria require automatic jumping.
    player.vy = tuning.jumpVelocity;
    _generateAhead();
  }

  void setHorizontalInput(double axis) {
    inputAxis = axis.clamp(-1.0, 1.0).toDouble();
  }

  void update(double deltaSeconds) {
    if (gameOver || deltaSeconds <= 0) return;

    // Sub-step long frames to keep one-way collision reliable across frame rates.
    var remaining = deltaSeconds.clamp(0.0, 0.10).toDouble();
    const maxStep = 1 / 120;
    while (remaining > 0 && !gameOver) {
      final step = math.min(maxStep, remaining);
      _step(step);
      remaining -= step;
    }
  }

  void _step(double dt) {
    elapsedSeconds += dt;
    _updateMovingPlatforms(dt);
    _updateHorizontalMotion(dt);

    final previousBottom = player.y + player.height;
    player.vy += tuning.gravity * dt;
    final nextY = player.y + player.vy * dt;
    final nextBottom = nextY + player.height;

    GamePlatform? landing;
    if (player.vy > 0) {
      for (final platform in platforms) {
        if (!_horizontalOverlap(player.x, player.width, platform.x, platform.width)) {
          continue;
        }
        // One-way platform: only collide when crossing its top while descending.
        if (previousBottom <= platform.y + 0.01 && nextBottom >= platform.y) {
          if (landing == null || platform.y < landing.y) {
            landing = platform;
          }
        }
      }
    }

    if (landing != null) {
      player.y = landing.y - player.height;
      _handleLanding(landing);
      // Auto-jump immediately after each valid landing.
      player.vy = tuning.jumpVelocity;
    } else {
      player.y = nextY;
    }

    highestPlayerY = math.min(highestPlayerY, player.y);
    _updateHeightScore();
    _collectCoins();
    _updateCamera();
    _generateAhead();
    _cleanupBehindCamera();

    if (player.y - cameraTop > tuning.viewportHeight + 120) {
      gameOver = true;
      inputAxis = 0;
    }
  }

  void _updateHorizontalMotion(double dt) {
    if (inputAxis.abs() > 0.001) {
      player.vx += inputAxis * tuning.horizontalAcceleration * dt;
      player.vx = player.vx.clamp(
        -tuning.maxHorizontalSpeed,
        tuning.maxHorizontalSpeed,
      );
    } else {
      final amount = tuning.horizontalDeceleration * dt;
      if (player.vx.abs() <= amount) {
        player.vx = 0;
      } else {
        player.vx -= player.vx.sign * amount;
      }
    }

    player.x += player.vx * dt;
    // Keep the recovered no-rotation character fully on-screen horizontally.
    player.x = player.x.clamp(0.0, tuning.worldWidth - player.width);
  }

  void _handleLanding(GamePlatform platform) {
    if (_lastLandedPlatformId == platform.id) {
      bounceChain = 0;
      return;
    }
    _lastLandedPlatformId = platform.id;

    final previousProgressionY = _lastProgressionPlatformY;
    final isProgression = previousProgressionY == null ||
        platform.y <= previousProgressionY - ScoringRules.progressionMinHeight;

    if (!isProgression) {
      combo = 1;
      bounceChain = 0;
      return;
    }

    final previousTime = _lastProgressionLandingTime;
    if (previousTime != null &&
        elapsedSeconds - previousTime <= ScoringRules.comboWindowSeconds) {
      combo += 1;
    } else {
      combo = 1;
    }

    _lastProgressionLandingTime = elapsedSeconds;
    _lastProgressionPlatformY = platform.y;

    var bounceBonus = 0;
    if (platform.kind == PlatformKind.bounce) {
      bounceChain += 1;
      bounceBonus = math.min(
        ScoringRules.bounceBonusCap,
        ScoringRules.firstBounceBonus +
            (bounceChain - 1) * ScoringRules.bounceBonusStep,
      );
    } else {
      bounceChain = 0;
    }

    final landingBase = ScoringRules.landingBase +
        (combo - 1) * ScoringRules.landingComboStep;
    final landingAward =
        ((landingBase + bounceBonus) * ScoringRules.coreMultiplier).round();
    score += landingAward;
  }

  void _updateHeightScore() {
    final rawHeightScore = math.max(
      0,
      ((tuning.startPlayerY - highestPlayerY) /
              ScoringRules.heightPixelsPerPoint)
          .floor(),
    );
    final scaled = (rawHeightScore * ScoringRules.coreMultiplier).round();
    if (score < scaled) score = scaled;
  }

  void _collectCoins() {
    final playerCenterX = player.x + player.width / 2;
    final playerCenterY = player.y + player.height / 2;
    final playerRadius = math.min(player.width, player.height) * 0.38;

    for (final coin in coins) {
      if (coin.collected) continue;
      final dx = playerCenterX - coin.x;
      final dy = playerCenterY - coin.y;
      final maxDistance = playerRadius + coin.radius;
      if (dx * dx + dy * dy <= maxDistance * maxDistance) {
        coin.collected = true;
        score += ScoringRules.coinScore;
        runGold += ScoringRules.coinGold;
      }
    }
  }

  void _updateCamera() {
    final playerScreenY = player.y - cameraTop;
    if (playerScreenY < tuning.cameraThresholdY) {
      cameraTop = player.y - tuning.cameraThresholdY;
    }
  }

  void _updateMovingPlatforms(double dt) {
    for (final platform in platforms) {
      if (platform.kind != PlatformKind.moving || platform.velocityX == 0) {
        continue;
      }
      platform.x += platform.velocityX * dt;
      if (platform.x <= platform.minX) {
        platform.x = platform.minX;
        platform.velocityX = platform.velocityX.abs();
      } else if (platform.x >= platform.maxX) {
        platform.x = platform.maxX;
        platform.velocityX = -platform.velocityX.abs();
      }
    }
  }

  void _generateAhead() {
    final targetY = cameraTop - tuning.generationAhead;
    var safety = 0;
    while (highestGeneratedPlatformY > targetY && safety++ < 80) {
      final previous = platforms.reduce(
        (a, b) => a.y < b.y ? a : b,
      );
      final gap = tuning.platformMinGapY +
          _random.nextDouble() *
              (tuning.platformMaxGapY - tuning.platformMinGapY);
      final nextY = previous.y - gap;

      final center = previous.x + previous.width / 2;
      final offset = (_random.nextDouble() * 2 - 1) * tuning.maxPlatformOffsetX;
      final nextX = (center + offset - tuning.platformWidth / 2).clamp(
        8.0,
        tuning.worldWidth - tuning.platformWidth - 8,
      );

      final roll = _random.nextDouble();
      PlatformKind kind;
      if (roll < 0.08) {
        kind = PlatformKind.bounce;
      } else if (roll < 0.23) {
        kind = PlatformKind.moving;
      } else {
        kind = PlatformKind.normal;
      }

      var velocityX = 0.0;
      var minX = 0.0;
      var maxX = 0.0;
      if (kind == PlatformKind.moving) {
        velocityX = _random.nextBool() ? 52 : -52;
        minX = math.max(8, nextX - 58).toDouble();
        maxX = math.min(
          tuning.worldWidth - tuning.platformWidth - 8,
          nextX + 58,
        ).toDouble();
      }

      final next = GamePlatform(
        id: _nextPlatformId++,
        x: nextX.toDouble(),
        y: nextY,
        width: tuning.platformWidth,
        height: tuning.platformHeight,
        kind: kind,
        velocityX: velocityX,
        minX: minX,
        maxX: maxX,
      );
      platforms.add(next);
      highestGeneratedPlatformY = nextY;

      // Coin frequency is isolated here until the original spawn table is recovered.
      if (_random.nextDouble() < 0.28) {
        coins.add(CoinState(
          id: _nextCoinId++,
          x: next.x + next.width / 2,
          y: next.y - 28,
        ));
      }
    }
  }

  void _cleanupBehindCamera() {
    final cutoff = cameraTop + tuning.viewportHeight + tuning.cleanupBelow;
    platforms.removeWhere((platform) => platform.y > cutoff);
    coins.removeWhere((coin) => coin.collected || coin.y > cutoff);
  }

  bool _horizontalOverlap(double ax, double aw, double bx, double bw) {
    return ax + aw > bx + 2 && ax < bx + bw - 2;
  }
}
