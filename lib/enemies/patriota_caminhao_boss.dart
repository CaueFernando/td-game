import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'enemy.dart';

class PatriotaCaminhaoBoss extends Enemy {
  late final SpriteAnimation frenteIdle;
  late final SpriteAnimation frenteStruggling;
  late final SpriteAnimation frenteReact;
  
  late final SpriteAnimation esquerdaIdle;
  late final SpriteAnimation esquerdaStruggling;
  late final SpriteAnimation esquerdaReact;

  late final SpriteAnimation traseiraIdle;
  late final SpriteAnimation traseiraStruggling;
  late final SpriteAnimation traseiraReact;

  SpriteAnimation? _currentAnimation;
  SpriteAnimationTicker? _currentTicker;
  String _currentDirection = 'frente';

  // Cache de tickers para evitar recriar objetos a cada frame
  final Map<SpriteAnimation, SpriteAnimationTicker> _tickers = {};

  SpriteAnimationTicker _getTicker(SpriteAnimation animation) {
    return _tickers.putIfAbsent(animation, () => SpriteAnimationTicker(animation));
  }

  PatriotaCaminhaoBoss({
    required List<Vector2> path,
    required double hp,
    double speedMultiplier = 1.0,
  }) : super(
          hp: hp,
          maxHp: hp,
          speed: 38 * speedMultiplier, // Lento, mas imponente e com muita vida
          reward: 250, // Recompensa grande
          damageToBase: 10, // Dano pesado à base se passar
          path: path,
        ) {
    size = Vector2(88, 88); // Dimensões imponentes de caminhão
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Carrega as imagens do cache
    final imgHorizontal = game.images.fromCache('patriot_truck_horizontal.png');
    final imgVertical = game.images.fromCache('patriot_truck_vertical.png');

    // 1. Frente (Vertical, colunas 0 a 5)
    frenteIdle = _createVerticalFrenteAnim(imgVertical, 0);
    frenteStruggling = _createVerticalFrenteAnim(imgVertical, 1);
    frenteReact = _createVerticalFrenteAnim(imgVertical, 2);

    // 2. Esquerda (Horizontal, colunas 0 a 7 - face esquerda)
    esquerdaIdle = _createHorizontalAnim(imgHorizontal, 0);
    esquerdaStruggling = _createHorizontalAnim(imgHorizontal, 1);
    esquerdaReact = _createHorizontalAnim(imgHorizontal, 2);

    // 3. Traseira (Vertical, colunas 6 a 11)
    traseiraIdle = _createVerticalTraseiraAnim(imgVertical, 0);
    traseiraStruggling = _createVerticalTraseiraAnim(imgVertical, 1);
    traseiraReact = _createVerticalTraseiraAnim(imgVertical, 2);

    _updateAnimation();
  }

  // Cria animação horizontal (8 frames de 192x256)
  SpriteAnimation _createHorizontalAnim(dynamic image, int row) {
    return SpriteAnimation.fromFrameData(
      image,
      SpriteAnimationData.sequenced(
        amount: 8,
        stepTime: 0.12,
        textureSize: Vector2(192, 256),
        texturePosition: Vector2(0, row * 256.0),
      ),
    );
  }

  // Cria animação vertical de Frente (6 frames de 128x133 nas colunas 0-5)
  SpriteAnimation _createVerticalFrenteAnim(dynamic image, int row) {
    return SpriteAnimation.fromFrameData(
      image,
      SpriteAnimationData.sequenced(
        amount: 6,
        stepTime: 0.12,
        textureSize: Vector2(128, 133),
        texturePosition: Vector2(0, row * 133.0),
      ),
    );
  }

  // Cria animação vertical de Traseira (6 frames de 128x133 nas colunas 6-11)
  SpriteAnimation _createVerticalTraseiraAnim(dynamic image, int row) {
    return SpriteAnimation.fromFrameData(
      image,
      SpriteAnimationData.sequenced(
        amount: 6,
        stepTime: 0.12,
        textureSize: Vector2(128, 133),
        texturePosition: Vector2(768.0, row * 133.0),
      ),
    );
  }

  void _updateAnimation() {
    // 1. Determina direção de acordo com o próximo checkpoint
    if (currentPathIndex < path.length) {
      final target = path[currentPathIndex];
      final toTarget = target - position;
      if (toTarget.x.abs() > toTarget.y.abs()) {
        _currentDirection = toTarget.x > 0 ? 'direita' : 'esquerda';
      } else {
        _currentDirection = toTarget.y > 0 ? 'frente' : 'traseira';
      }
    }

    // 2. Determina o estado da animação
    // Se estiver lento ou acabou de tomar dano, usa animação de balançar/instabilidade
    final bool isStruggling = currentSpeed < speed || isFlashing;

    if (_currentDirection == 'frente') {
      _currentAnimation = isStruggling ? frenteStruggling : frenteIdle;
    } else if (_currentDirection == 'esquerda' || _currentDirection == 'direita') {
      // Ambas as direções horizontais usam a animação de esquerda (a direita é espelhada no render)
      _currentAnimation = isStruggling ? esquerdaStruggling : esquerdaIdle;
    } else {
      _currentAnimation = isStruggling ? traseiraStruggling : traseiraIdle;
    }

    if (_currentAnimation != null) {
      _currentTicker = _getTicker(_currentAnimation!);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _updateAnimation();
    if (_currentTicker != null) {
      _currentTicker!.update(dt);
    }
  }

  @override
  void die() {
    game.gameState.addPixcoins(reward);
    game.playSfx('enemy_die.mp3');

    // Instancia o Patriota Fugitivo que cai e engatinha para longe
    game.add(PatriotaFugitivo(
      position: position.clone(),
      direction: _currentDirection,
    ));

    removeFromParent();
    game.checkWaveCompletion();
  }

  @override
  void onRemove() {
    game.activeBossesCount--;
    if (game.activeBossesCount <= 0) {
      game.activeBossesCount = 0;
      if (!game.gameState.isGameOver.value && !game.gameState.isVictory.value) {
        game.playBgm('bgm.mp3');
      }
    }
    super.onRemove();
  }

  @override
  void render(Canvas canvas) {
    if (_currentTicker != null) {
      final sprite = _currentTicker!.getSprite();
      
      // Se estiver movendo para a direita, espelha horizontalmente via canvas transform
      final bool flipX = _currentDirection == 'direita';
      
      void drawSprite(Canvas c) {
        if (flipX) {
          c.save();
          c.translate(size.x / 2, size.y / 2);
          c.scale(-1, 1);
          c.translate(-size.x / 2, -size.y / 2);
          sprite.render(c, position: Vector2.zero(), size: size);
          c.restore();
        } else {
          sprite.render(c, position: Vector2.zero(), size: size);
        }
      }

      if (isFlashing) {
        final flashPaint = Paint()..colorFilter = const ColorFilter.mode(Colors.white, BlendMode.srcATop);
        canvas.saveLayer(size.toRect(), flashPaint);
        drawSprite(canvas);
        canvas.restore();
      } else {
        drawSprite(canvas);
      }
    }

    super.render(canvas); // Renderiza a barra de vida e debuffs
  }
}

// Componente decorativo que aparece ao derrotar o boss
// O patriota cai do caminhão e foge engatinhando
class PatriotaFugitivo extends PositionComponent with HasGameReference {
  final String direction;
  late final SpriteAnimation crawlingAnimation;
  late final SpriteAnimationTicker crawlingTicker;
  double lifespan = 2.5; // Duração da fuga
  late final Vector2 velocity;

  PatriotaFugitivo({
    required Vector2 position,
    required this.direction,
  }) {
    this.position = position.clone();
    size = Vector2(88, 88);
    anchor = Anchor.center;

    // Define velocidade e sentido do movimento de fuga
    double runSpeed = 55.0;
    if (direction == 'direita') {
      velocity = Vector2(runSpeed, 0);
    } else if (direction == 'esquerda') {
      velocity = Vector2(-runSpeed, 0);
    } else if (direction == 'frente') {
      velocity = Vector2(0, runSpeed);
    } else {
      velocity = Vector2(0, -runSpeed);
    }
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();

    if (direction == 'esquerda' || direction == 'direita') {
      final image = game.images.fromCache('patriot_truck_horizontal.png');
      crawlingAnimation = SpriteAnimation.fromFrameData(
        image,
        SpriteAnimationData.sequenced(
          amount: 8,
          stepTime: 0.10,
          textureSize: Vector2(192, 256),
          texturePosition: Vector2(0, 3 * 256.0), // Linha 3 (quarta linha)
        ),
      );
    } else if (direction == 'frente') {
      final image = game.images.fromCache('patriot_truck_vertical.png');
      crawlingAnimation = SpriteAnimation.fromFrameData(
        image,
        SpriteAnimationData.sequenced(
          amount: 6,
          stepTime: 0.10,
          textureSize: Vector2(128, 133),
          texturePosition: Vector2(0, 3 * 133.0), // Linha 3, colunas 0-5
        ),
      );
    } else {
      // Traseira
      final image = game.images.fromCache('patriot_truck_vertical.png');
      crawlingAnimation = SpriteAnimation.fromFrameData(
        image,
        SpriteAnimationData.sequenced(
          amount: 6,
          stepTime: 0.10,
          textureSize: Vector2(128, 133),
          texturePosition: Vector2(768.0, 3 * 133.0), // Linha 3, colunas 6-11
        ),
      );
    }
    
    crawlingTicker = SpriteAnimationTicker(crawlingAnimation);
  }

  @override
  void update(double dt) {
    super.update(dt);
    crawlingTicker.update(dt);
    position += velocity * dt;
    lifespan -= dt;

    if (lifespan <= 0) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Efeito de fade-out no final da vida útil
    double opacity = 1.0;
    if (lifespan < 0.6) {
      opacity = (lifespan / 0.6).clamp(0.0, 1.0);
    }

    final paint = Paint()..color = Colors.white.withValues(alpha: opacity);
    final bool flipX = direction == 'direita';

    canvas.saveLayer(size.toRect(), paint);
    
    if (flipX) {
      canvas.save();
      canvas.translate(size.x / 2, size.y / 2);
      canvas.scale(-1, 1);
      canvas.translate(-size.x / 2, -size.y / 2);
      crawlingTicker.getSprite().render(canvas, position: Vector2.zero(), size: size);
      canvas.restore();
    } else {
      crawlingTicker.getSprite().render(canvas, position: Vector2.zero(), size: size);
    }
    
    canvas.restore();
  }
}
