import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'towers/towers.dart';
import 'main.dart';

class Enemy extends PositionComponent with HasGameReference<CloroquinildoGame> {
  double hp;
  double maxHp;
  double speed;
  int reward;
  int damageToBase;

  final List<Vector2> path;
  int currentPathIndex = 0;

  double flashTimer = 0.0;
  bool get isFlashing => flashTimer > 0.0;

  // Active status effects (buffs/debuffs)
  final List<StatusEffect> activeEffects = [];

  void applyEffect(StatusEffect effect) {
    for (final active in activeEffects) {
      if (active.type == effect.type) {
        active.refresh(effect);
        return;
      }
    }
    activeEffects.add(effect);
  }

  double get currentSpeed {
    double speedMod = speed;
    for (final effect in activeEffects) {
      if (effect is ChillEffect) {
        speedMod *= effect.speedReductionMultiplier;
      }
    }
    return speedMod;
  }

  Enemy({
    required this.hp,
    required this.maxHp,
    required this.speed,
    required this.reward,
    required this.damageToBase,
    required this.path,
  }) {
    size = Vector2(32, 32);
    anchor = Anchor.center;
    if (path.isNotEmpty) {
      position = path[0].clone();
      currentPathIndex = 1;
    }
  }

  void takeDamage(double amount) {
    if (hp <= 0) return;

    double damageToApply = amount;
    for (final effect in activeEffects) {
      if (effect is ShockEffect) {
        damageToApply *= effect.damageMultiplier;
      }
    }

    hp -= damageToApply;
    flashTimer = 0.1; // Flash branco por 100ms
    if (hp <= 0) {
      die();
    }
  }

  void die() {
    game.gameState.addPixcoins(reward);
    removeFromParent();
    game.checkWaveCompletion();
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (flashTimer > 0) {
      flashTimer -= dt;
    }

    // Atualiza os efeitos de status ativos
    final expiredEffects = <StatusEffect>[];
    for (final effect in activeEffects) {
      final keep = effect.update(this, dt);
      if (!keep) {
        expiredEffects.add(effect);
      }
    }
    activeEffects.removeWhere((e) => expiredEffects.contains(e));

    if (currentPathIndex >= path.length) {
      // Chegou ao fim do caminho (Cercadinho)
      game.gameState.takeBaseDamage(damageToBase);
      removeFromParent();
      game.checkWaveCompletion();
      return;
    }

    // Movimentação em direção ao próximo checkpoint
    final target = path[currentPathIndex];
    final toTarget = target - position;
    final distance = toTarget.length;

    final step = currentSpeed * dt;
    if (distance <= step) {
      position = target.clone();
      currentPathIndex++;
    } else {
      position += toTarget.normalized() * step;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Barra de Vida
    final hpBarWidth = size.x;
    final hpBarHeight = 4.0;
    final hpPercent = (hp / maxHp).clamp(0.0, 1.0);
    
    // Fundo da barra (cinza/vermelho escuro)
    canvas.drawRect(
      Rect.fromLTWH(0, -10, hpBarWidth, hpBarHeight),
      Paint()..color = Colors.black45,
    );
    // Vida atual (verde se alta, amarela se média, vermelha se baixa)
    Color hpColor = Colors.green;
    if (hpPercent < 0.3) {
      hpColor = Colors.red;
    } else if (hpPercent < 0.6) {
      hpColor = Colors.orange;
    }
    
    canvas.drawRect(
      Rect.fromLTWH(0, -10, hpBarWidth * hpPercent, hpBarHeight),
      Paint()..color = hpColor,
    );

    // Desenha ícones de debuff acima da barra de vida
    if (activeEffects.isNotEmpty) {
      final iconSize = 10.0;
      final spacing = 2.0;
      
      // Centraliza a fileira de ícones sobre o inimigo
      final totalWidth = activeEffects.length * iconSize + (activeEffects.length - 1) * spacing;
      double startX = (size.x - totalWidth) / 2;
      double startY = -22.0;

      for (final effect in activeEffects) {
        effect.renderIcon(canvas, Offset(startX, startY), iconSize);
        startX += iconSize + spacing;
      }
    }
  }
}

// Goblin Sindicalista - Inimigo Básico
class GoblinSindicalista extends Enemy {
  GoblinSindicalista({required List<Vector2> path, double speedMultiplier = 1.0, double hpMultiplier = 1.0})
      : super(
          hp: 30 * hpMultiplier,
          maxHp: 30 * hpMultiplier,
          speed: 80 * speedMultiplier,
          reward: 15,
          damageToBase: 1,
          path: path,
        );

  @override
  void render(Canvas canvas) {
    // Desenha o corpo do Goblin
    final rect = size.toRect();
    final paint = Paint()
      ..color = isFlashing ? Colors.white : Colors.red.shade700
      ..style = PaintingStyle.fill;
    
    // Desenha corpo circular caricato
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      paint,
    );

    // Borda do goblin
    final borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      borderPaint,
    );

    // Olhos bravos do "Sindicalista"
    final eyePaint = Paint()..color = Colors.yellow;
    canvas.drawCircle(Offset(size.x * 0.3, size.y * 0.4), 3, eyePaint);
    canvas.drawCircle(Offset(size.x * 0.7, size.y * 0.4), 3, eyePaint);

    // Sobrancelha brava (linhas pretas inclinadas)
    final browPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.0;
    canvas.drawLine(Offset(size.x * 0.2, size.y * 0.25), Offset(size.x * 0.45, size.y * 0.35), browPaint);
    canvas.drawLine(Offset(size.x * 0.8, size.y * 0.25), Offset(size.x * 0.55, size.y * 0.35), browPaint);

    // Faixa ou gravatinha de protesto vermelha
    final tiePaint = Paint()..color = Colors.red.shade900;
    final pathTie = Path()
      ..moveTo(size.x * 0.5, size.y * 0.6)
      ..lineTo(size.x * 0.4, size.y * 0.9)
      ..lineTo(size.x * 0.5, size.y * 0.85)
      ..lineTo(size.x * 0.6, size.y * 0.9)
      ..close();
    canvas.drawPath(pathTie, tiePaint);

    super.render(canvas);
  }
}
