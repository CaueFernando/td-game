import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import '../towers/towers.dart';
import '../main.dart';

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

  void takeDamage(double amount, [Color color = const Color(0xFFE2E8F0)]) {
    if (hp <= 0) return;

    double damageToApply = amount;
    for (final effect in activeEffects) {
      if (effect is ShockEffect) {
        damageToApply *= effect.damageMultiplier;
      }
    }

    hp -= damageToApply;
    flashTimer = 0.1; // Flash branco por 100ms
    
    // Spawna o popup do número de dano
    game.showDamageNumber(damageToApply, position, color);

    if (hp <= 0) {
      die();
    }
  }

  void die() {
    game.gameState.addPixcoins(reward);
    game.playSfx('enemy_die.mp3');
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
