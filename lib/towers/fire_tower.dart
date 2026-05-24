import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'dart:math';
import 'tower.dart';
import 'status_effect.dart';
import '../enemy.dart';
import '../main.dart';

// FireTower - Torre incineradora (cospidora de fogo em cone)
class FireTower extends Tower {
  static const String towerName = 'Pyro';
  static const int baseCost = 150;
  static const double baseRange = 120.0;

  double damageTimer = 0.0;
  final double damageInterval = 0.15; // Frequência do tick de dano em cone

  FireTower({required Vector2 position})
      : super(
          position: position,
          range: baseRange,
          damage: 25.0,  // Representa o Dano por Segundo (DPS)
          fireRate: 0.05, // Intervalo ultra-rápido para spawnar partículas constantemente
          cost: baseCost,
        );

  @override
  void update(double dt) {
    super.update(dt);

    if (currentTarget != null) {
      damageTimer -= dt;
      if (damageTimer <= 0) {
        _dealConeDamage();
        damageTimer = damageInterval;
      }
    } else {
      damageTimer = 0.0;
    }
  }

  @override
  void shoot(Enemy target) {
    // Spawna flutuações de partículas de fogo constantemente na direção do alvo
    final random = Random();
    final nozzleOffset = Vector2(cos(angle), sin(angle)) * 20; // 20px à frente do centro
    final particlePos = position + nozzleOffset;

    // Dispersão do cone de fogo: +- 12 graus (~0.21 radianos)
    final dispersion = (random.nextDouble() - 0.5) * 0.24;
    final particleAngle = angle + dispersion;

    // Velocidade das chamas: 180 a 240 px/s
    final particleSpeed = 180.0 + random.nextDouble() * 60.0;
    final velocity = Vector2(cos(particleAngle), sin(particleAngle)) * particleSpeed;

    game.add(FireParticle(position: particlePos, velocity: velocity));
  }

  // Aplica dano contínuo e status Burning nos inimigos dentro de um cone de 40 graus
  void _dealConeDamage() {
    final enemies = game.children.whereType<Enemy>();
    final coneHalfAngle = 0.35; // ~20 graus para cada lado

    for (final enemy in enemies) {
      final toEnemy = enemy.position - position;
      final dist = toEnemy.length;

      if (dist <= range) {
        final enemyAngle = atan2(toEnemy.y, toEnemy.x);
        double diff = (enemyAngle - angle).abs();
        if (diff > pi) {
          diff = 2 * pi - diff;
        }

        if (diff <= coneHalfAngle) {
          final tickDamage = damage * damageInterval; // Dano fracionado pelo tempo do tick
          enemy.applyEffect(BurningEffect(dps: damage * 0.1)); // Queimadura contínua (10% do DPS)
          enemy.takeDamage(tickDamage, Colors.orangeAccent);
        }
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    canvas.save();
    canvas.translate(size.x / 2, size.y / 2); // Centraliza no pivot da torre

    // 1. DESENHAR BASE FIXA (Estática)
    canvas.save();
    canvas.rotate(-angle); // Desfaz a rotação para desenhar a base
    
    final baseRect = Rect.fromCenter(center: Offset.zero, width: size.x * 1.1, height: size.y * 1.1);
    
    final baseGradient = LinearGradient(
      colors: [Colors.grey.shade900, Colors.red.shade900, Colors.grey.shade900],
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

    // Luzes nos cantos em vermelho brilhante (alerta térmico)
    final cornerLightPaint = Paint()
      ..color = Colors.redAccent
      ..style = PaintingStyle.fill;
    
    final halfW = size.x * 1.1 / 2;
    final halfH = size.y * 1.1 / 2;
    canvas.drawCircle(Offset(-halfW + 4, -halfH + 4), 2.5, cornerLightPaint);
    canvas.drawCircle(Offset(halfW - 4, -halfH + 4), 2.5, cornerLightPaint);
    canvas.drawCircle(Offset(-halfW + 4, halfH - 4), 2.5, cornerLightPaint);
    canvas.drawCircle(Offset(halfW - 4, halfH - 4), 2.5, cornerLightPaint);

    canvas.restore(); // Restaura a rotação da base (continua centralizado)

    // 2. DESENHAR O LANÇA-CHAMAS (Segue o ângulo)
    // Cano do canhão reforçado térmico
    final barrelPaint = Paint()
      ..color = Colors.grey.shade800
      ..style = PaintingStyle.fill;

    final barrelRect = Rect.fromLTWH(-4, -6, 24, 12);
    canvas.drawRRect(
      RRect.fromRectAndRadius(barrelRect, const Radius.circular(3)),
      barrelPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(barrelRect, const Radius.circular(3)),
      borderPaint,
    );

    // Bocal emissor (Brilha quando atira)
    final nozzlePaint = Paint()
      ..color = currentTarget != null ? Colors.deepOrangeAccent : Colors.grey.shade700
      ..style = PaintingStyle.fill;

    final nozzleRect = Rect.fromLTWH(18, -8, 6, 16);
    canvas.drawRRect(
      RRect.fromRectAndRadius(nozzleRect, const Radius.circular(2)),
      nozzlePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(nozzleRect, const Radius.circular(2)),
      borderPaint,
    );

    // Brilho do calor do bocal
    if (currentTarget != null) {
      final nozzleGlow = Paint()
        ..color = Colors.orangeAccent.withOpacity(0.5)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      canvas.drawCircle(const Offset(21, 0), 8, nozzleGlow);
    }

    // Corpo central
    final coreBodyPaint = Paint()
      ..color = Colors.grey.shade900
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, 12, coreBodyPaint);
    canvas.drawCircle(Offset.zero, 12, borderPaint);

    // Núcleo de fusão térmica (glowing orange/red)
    final coreGradient = RadialGradient(
      colors: [Colors.orangeAccent, Colors.red.shade900],
      stops: const [0.3, 1.0],
    );
    final corePaint = Paint()
      ..shader = coreGradient.createShader(Rect.fromCircle(center: Offset.zero, radius: 8))
      ..style = PaintingStyle.fill;

    final coreGlowPaint = Paint()
      ..color = Colors.deepOrangeAccent.withOpacity(0.5)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    canvas.drawCircle(Offset.zero, 8, coreGlowPaint);
    canvas.drawCircle(Offset.zero, 8, corePaint);

    canvas.restore(); // Restaura a centralização
  }
}

// Partícula individual de chama
class FireParticle extends PositionComponent with HasGameReference<CloroquinildoGame> {
  final Vector2 velocity;
  double lifespan = 0.4;
  final double maxLifespan = 0.4;
  final double startSize = 4.0;
  final double endSize = 16.0;

  FireParticle({required Vector2 position, required this.velocity}) {
    this.position = position.clone();
    size = Vector2.all(startSize);
    anchor = Anchor.center;
  }

  @override
  void update(double dt) {
    super.update(dt);
    lifespan -= dt;

    if (lifespan <= 0) {
      removeFromParent();
      return;
    }

    position += velocity * dt;

    // A partícula expande à medida que se distancia
    final progress = (1.0 - (lifespan / maxLifespan)).clamp(0.0, 1.0);
    final currentScale = startSize + (endSize - startSize) * progress;
    size = Vector2.all(currentScale);
  }

  @override
  void render(Canvas canvas) {
    final progress = (1.0 - (lifespan / maxLifespan)).clamp(0.0, 1.0);
    final opacity = (lifespan / maxLifespan).clamp(0.0, 1.0);

    // Gradiente dinâmico de cores (Amarelo -> Laranja -> Vermelho)
    Color color;
    if (progress < 0.3) {
      color = Colors.yellowAccent;
    } else if (progress < 0.7) {
      color = Colors.orangeAccent;
    } else {
      color = Colors.redAccent;
    }

    final paint = Paint()
      ..color = color.withOpacity(opacity * 0.6)
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, progress * 4 + 1);

    canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x / 2, paint);
  }
}
