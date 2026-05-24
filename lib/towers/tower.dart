import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'dart:math';
import '../enemy.dart';
import 'upgrade_button.dart';
import '../main.dart';

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

    // Instancia 4 botões em leque acima da torre
    final db = UpgradeButton(
      type: UpgradeType.damage,
      parentTower: this,
      position: position + Vector2(-54, -30),
    );
    final rb = UpgradeButton(
      type: UpgradeType.range,
      parentTower: this,
      position: position + Vector2(-18, -50),
    );
    final sb = UpgradeButton(
      type: UpgradeType.speed,
      parentTower: this,
      position: position + Vector2(18, -50),
    );
    final sellB = UpgradeButton(
      type: UpgradeType.sell,
      parentTower: this,
      position: position + Vector2(54, -30),
    );

    game.add(db);
    game.add(rb);
    game.add(sb);
    game.add(sellB);

    activeUpgradeButtons.addAll([db, rb, sb, sellB]);
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
