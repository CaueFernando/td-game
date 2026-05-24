import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'dart:math';
import 'enemy.dart';
import 'projectile.dart';
import 'upgrade_button.dart';
import 'main.dart';

class Tower extends PositionComponent with TapCallbacks, HasGameReference<CloroquinildoGame> {
  double range;
  double damage;
  double fireRate;
  final int cost;
  
  double cooldownTimer = 0.0;
  Enemy? currentTarget;

  // Upgrade Levels
  int damageLevel = 1;
  int rangeLevel = 1;
  int speedLevel = 1;

  // Cost tracking
  int damageUpgradeCost = 60;
  int rangeUpgradeCost = 60;
  int speedUpgradeCost = 60;

  // Active overlay buttons
  final List<UpgradeButton> activeUpgradeButtons = [];

  bool _showRange = false;
  bool get showRange => _showRange;
  set showRange(bool val) {
    if (_showRange == val) return;
    _showRange = val;
    if (_showRange) {
      _showUpgradeButtons();
    } else {
      _hideUpgradeButtons();
    }
  }

  Tower({
    required Vector2 position,
    required this.range,
    required this.damage,
    required this.fireRate,
    required this.cost,
  }) {
    this.position = position.clone();
    size = Vector2(40, 40);
    anchor = Anchor.center;
  }

  void _showUpgradeButtons() {
    _hideUpgradeButtons(); // Safety clear

    // Instancia 3 botões em arco acima da torre
    final db = UpgradeButton(
      type: UpgradeType.damage,
      parentTower: this,
      position: position + Vector2(-36, -44),
    );
    final rb = UpgradeButton(
      type: UpgradeType.range,
      parentTower: this,
      position: position + Vector2(0, -56),
    );
    final sb = UpgradeButton(
      type: UpgradeType.speed,
      parentTower: this,
      position: position + Vector2(36, -44),
    );

    game.add(db);
    game.add(rb);
    game.add(sb);

    activeUpgradeButtons.addAll([db, rb, sb]);
  }

  void _hideUpgradeButtons() {
    for (final btn in activeUpgradeButtons) {
      if (btn.isMounted) {
        btn.removeFromParent();
      }
    }
    activeUpgradeButtons.clear();
  }

  @override
  void onRemove() {
    _hideUpgradeButtons();
    super.onRemove();
  }

  // Encontra o inimigo mais próximo/avançado dentro do alcance
  Enemy? acquireTarget() {
    final enemies = game.children.whereType<Enemy>();
    Enemy? bestTarget;
    double maxProgress = -1.0;

    for (final enemy in enemies) {
      final distance = (enemy.position - position).length;
      if (distance <= range) {
        final progress = enemy.currentPathIndex.toDouble() * 1000 - (enemy.position - enemy.path[enemy.currentPathIndex - 1]).length;
        if (progress > maxProgress) {
          maxProgress = progress;
          bestTarget = enemy;
        }
      }
    }
    return bestTarget;
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (cooldownTimer > 0) {
      cooldownTimer -= dt;
    }

    // Procura ou atualiza alvo
    currentTarget = acquireTarget();

    if (currentTarget != null) {
      // Rotaciona em direção ao alvo
      final angleToTarget = atan2(
        currentTarget!.position.y - position.y,
        currentTarget!.position.x - position.x,
      );
      angle = angleToTarget;

      // Dispara se pronto
      if (cooldownTimer <= 0) {
        shoot(currentTarget!);
        cooldownTimer = fireRate;
      }
    }
  }

  void shoot(Enemy target) {
    // A ser sobrescrito por subclasses
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    event.handled = true; // Impede que o clique crie uma nova torre no mesmo local
    
    // Toggle alcance e botões de upgrade
    final allTowers = game.children.whereType<Tower>();
    for (final t in allTowers) {
      if (t != this) {
        t.showRange = false;
      }
    }
    showRange = !showRange;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Se estiver selecionado, desenha o indicador de alcance
    if (showRange) {
      final rangePaint = Paint()
        ..color = Colors.blueAccent.withValues(alpha: 0.15)
        ..style = PaintingStyle.fill;
      final rangeBorderPaint = Paint()
        ..color = Colors.blueAccent.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      canvas.save();
      canvas.translate(size.x / 2, size.y / 2); // Centraliza no pivot da torre
      canvas.rotate(-angle); // Desenha o alcance fixo (sem rotação)
      canvas.drawCircle(Offset.zero, range, rangePaint);
      canvas.drawCircle(Offset.zero, range, rangeBorderPaint);
      canvas.restore();
    }
  }
}

// Torre Taokey - A torre básica
class TorreTaokey extends Tower {
  TorreTaokey({required Vector2 position})
      : super(
          position: position,
          range: 130.0,
          damage: 10.0,
          fireRate: 0.8,
          cost: 100,
        );

  @override
  void shoot(Enemy target) {
    final projectile = ProjetilArgumento(
      startPosition: position,
      target: target,
      damage: damage,
    );
    game.add(projectile);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    canvas.save();
    canvas.translate(size.x / 2, size.y / 2); // Centraliza no pivot da torre

    // 1. DESENHAR BASE FIXA (Não rotaciona com a mira da torre)
    canvas.save();
    canvas.rotate(-angle); // Desfaz a rotação para desenhar a base
    
    final baseRect = Rect.fromCenter(center: Offset.zero, width: size.x * 1.1, height: size.y * 1.1);
    
    final baseGradient = LinearGradient(
      colors: [Colors.grey.shade900, Colors.grey.shade800, Colors.grey.shade700],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    final basePaint = Paint()
      ..shader = baseGradient.createShader(baseRect)
      ..style = PaintingStyle.fill;
    
    final borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRRect(
      RRect.fromRectAndRadius(baseRect, const Radius.circular(8)),
      basePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(baseRect, const Radius.circular(8)),
      borderPaint,
    );

    // Detalhes em verde brilhante nos cantos (luzes de status da base)
    final cornerLightPaint = Paint()
      ..color = Colors.greenAccent
      ..style = PaintingStyle.fill;
    
    final halfW = size.x * 1.1 / 2;
    final halfH = size.y * 1.1 / 2;
    canvas.drawCircle(Offset(-halfW + 4, -halfH + 4), 2.5, cornerLightPaint);
    canvas.drawCircle(Offset(halfW - 4, -halfH + 4), 2.5, cornerLightPaint);
    canvas.drawCircle(Offset(-halfW + 4, halfH - 4), 2.5, cornerLightPaint);
    canvas.drawCircle(Offset(halfW - 4, halfH - 4), 2.5, cornerLightPaint);

    canvas.restore(); // Restaura a rotação da base (continua centralizado)

    // 2. DESENHAR O CANHÃO ROTATÓRIO (Segue o ângulo)
    // Cano do canhão
    final barrelPaint = Paint()
      ..color = Colors.grey.shade800
      ..style = PaintingStyle.fill;

    final barrelRect = Rect.fromLTWH(-4, -6, 22, 12);
    canvas.drawRRect(
      RRect.fromRectAndRadius(barrelRect, const Radius.circular(3)),
      barrelPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(barrelRect, const Radius.circular(3)),
      borderPaint,
    );

    // Bocal do canhão (Anel da ponta)
    final nozzleRect = Rect.fromLTWH(18, -8, 4, 16);
    canvas.drawRRect(
      RRect.fromRectAndRadius(nozzleRect, const Radius.circular(2)),
      Paint()..color = Colors.green.shade800,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(nozzleRect, const Radius.circular(2)),
      borderPaint,
    );

    // Corpo circular do meio da torre (onde fica o núcleo)
    final coreBodyPaint = Paint()
      ..color = Colors.grey.shade900
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, 12, coreBodyPaint);
    canvas.drawCircle(Offset.zero, 12, borderPaint);

    // Núcleo verde brilhante ("Argumento/Zap Core")
    final coreGradient = RadialGradient(
      colors: [Colors.greenAccent, Colors.green.shade900],
      stops: const [0.3, 1.0],
    );
    final corePaint = Paint()
      ..shader = coreGradient.createShader(Rect.fromCircle(center: Offset.zero, radius: 8))
      ..style = PaintingStyle.fill;

    final coreGlowPaint = Paint()
      ..color = Colors.greenAccent.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    canvas.drawCircle(Offset.zero, 8, coreGlowPaint);
    canvas.drawCircle(Offset.zero, 8, corePaint);

    canvas.restore(); // Restaura a centralização
  }
}

// Painel da Loja de Torres
class TowerShop extends PositionComponent with HasGameReference<CloroquinildoGame> {
  TowerShop() {
    size = Vector2(95, 120);
    anchor = Anchor.topLeft;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    // Posiciona no canto inferior direito, deixando margem para não interferir com barras do sistema
    position = Vector2(size.x - 110, size.y - 190);
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    // Adiciona o card da única torre atualmente disponível
    add(TowerShopItem(position: Vector2(10, 30)));
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Fundo do Painel (Sleek dark design com borda neon)
    final rect = size.toRect();
    final bgPaint = Paint()
      ..color = const Color(0xFF1E293B).withOpacity(0.85)
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = Colors.cyanAccent.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(16)), bgPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(16)), borderPaint);

    // Título do painel
    final titlePainter = TextPainter(
      text: const TextSpan(
        text: 'LOJA',
        style: TextStyle(
          color: Colors.cyanAccent,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    titlePainter.paint(canvas, Offset(size.x / 2 - titlePainter.width / 2, 8));
  }
}

// Item arrastável da loja para construir a Torre Taokey
class TowerShopItem extends PositionComponent with DragCallbacks, HasGameReference<CloroquinildoGame> {
  TowerDragPreview? _preview;

  TowerShopItem({required Vector2 position}) {
    this.position = position;
    size = Vector2(75, 80);
    anchor = Anchor.topLeft;
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    // Cria o preview de arrasto na posição atual do ponteiro
    _preview = TowerDragPreview(
      position: event.canvasPosition,
      range: 130.0, // Alcance padrão da Torre Taokey
    );
    game.add(_preview!);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    if (_preview != null) {
      _preview!.position = event.canvasEndPosition;
      _preview!.isValid = game.isValidTowerPosition(event.canvasEndPosition);
    }
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    if (_preview != null) {
      final buildPos = _preview!.position.clone();
      final isValid = _preview!.isValid;
      
      _preview!.removeFromParent();
      _preview = null;

      if (isValid) {
        const cost = 100;
        if (game.gameState.buy(cost)) {
          final tower = TorreTaokey(position: buildPos);
          game.add(tower);
          game.showFloatingText('+Torre!', buildPos, Colors.greenAccent);
        } else {
          game.showFloatingText('Sem Pixcoins!', buildPos, Colors.redAccent);
        }
      } else {
        game.showFloatingText('Local inválido!', buildPos, Colors.redAccent);
      }
    }
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    if (_preview != null) {
      _preview!.removeFromParent();
      _preview = null;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // 1. Fundo do Card (Visual Glassmorphism)
    final bgRect = size.toRect();
    final bgPaint = Paint()
      ..color = Colors.black.withOpacity(0.6)
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = Colors.cyanAccent.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawRRect(RRect.fromRectAndRadius(bgRect, const Radius.circular(12)), bgPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(bgRect, const Radius.circular(12)), borderPaint);

    // 2. Miniatura da Torre
    canvas.save();
    canvas.translate(size.x / 2, size.y / 2 - 10);
    
    // Cano mini
    final barrelPaint = Paint()..color = Colors.grey.shade600;
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-3, -4, 15, 8), const Radius.circular(2)), barrelPaint);
    
    // Corpo mini
    final bodyPaint = Paint()..color = Colors.grey.shade800;
    canvas.drawCircle(Offset.zero, 8, bodyPaint);
    
    // Core mini
    final corePaint = Paint()..color = Colors.greenAccent;
    canvas.drawCircle(Offset.zero, 5, corePaint);
    canvas.restore();

    // 3. Nome
    final namePainter = TextPainter(
      text: const TextSpan(
        text: 'Taokey',
        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    namePainter.paint(canvas, Offset(size.x / 2 - namePainter.width / 2, size.y - 32));

    // 4. Custo
    final pricePainter = TextPainter(
      text: const TextSpan(
        text: '100 PX',
        style: TextStyle(color: Colors.amberAccent, fontSize: 10, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    pricePainter.paint(canvas, Offset(size.x / 2 - pricePainter.width / 2, size.y - 18));
  }
}

// Preview semi-transparente durante o arrasto com feedback de área válida (verde/vermelho)
class TowerDragPreview extends PositionComponent {
  final double range;
  bool isValid = true;

  TowerDragPreview({
    required Vector2 position,
    required this.range,
  }) {
    this.position = position.clone();
    size = Vector2(40, 40);
    anchor = Anchor.center;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final color = isValid ? Colors.greenAccent : Colors.redAccent;

    // 1. Círculo de Alcance
    final rangePaint = Paint()
      ..color = color.withOpacity(0.15)
      ..style = PaintingStyle.fill;
    final rangeBorderPaint = Paint()
      ..color = color.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);
    canvas.drawCircle(Offset.zero, range, rangePaint);
    canvas.drawCircle(Offset.zero, range, rangeBorderPaint);

    // 2. Silhueta da Torre
    final basePaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    final baseBorderPaint = Paint()
      ..color = color.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final baseRect = Rect.fromCenter(center: Offset.zero, width: size.x * 1.1, height: size.y * 1.1);
    canvas.drawRRect(RRect.fromRectAndRadius(baseRect, const Radius.circular(8)), basePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(baseRect, const Radius.circular(8)), baseBorderPaint);

    final barrelPaint = Paint()..color = color.withOpacity(0.4);
    final barrelRect = Rect.fromLTWH(-4, -6, 22, 12);
    canvas.drawRRect(RRect.fromRectAndRadius(barrelRect, const Radius.circular(3)), barrelPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(barrelRect, const Radius.circular(3)), baseBorderPaint);

    canvas.drawCircle(Offset.zero, 8, basePaint);
    canvas.drawCircle(Offset.zero, 8, baseBorderPaint);

    canvas.restore();
  }
}
