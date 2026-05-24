import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'tower.dart';
import '../enemy.dart';
import '../projectile.dart';

// StoneTower - Torre de dano físico em área (Stone Tower)
class StoneTower extends Tower {
  static const String towerName = 'Stone';
  static const int baseCost = 100;
  static const double baseRange = 110.0;

  StoneTower({required Vector2 position})
      : super(
          position: position,
          range: baseRange,
          damage: 15.0,
          fireRate: 1.5,
          cost: baseCost,
        );

  @override
  void shoot(Enemy target) {
    final projectile = ProjetilPedra(
      startPosition: position.clone(),
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
      colors: [Colors.brown.shade900, Colors.brown.shade800, Colors.brown.shade700],
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

    // Detalhes em laranja brilhante nos cantos (luzes de status da base de pedra)
    final cornerLightPaint = Paint()
      ..color = Colors.orangeAccent
      ..style = PaintingStyle.fill;
    
    final halfW = size.x * 1.1 / 2;
    final halfH = size.y * 1.1 / 2;
    canvas.drawCircle(Offset(-halfW + 4, -halfH + 4), 2.5, cornerLightPaint);
    canvas.drawCircle(Offset(halfW - 4, -halfH + 4), 2.5, cornerLightPaint);
    canvas.drawCircle(Offset(-halfW + 4, halfH - 4), 2.5, cornerLightPaint);
    canvas.drawCircle(Offset(halfW - 4, halfH - 4), 2.5, cornerLightPaint);

    canvas.restore(); // Restaura a rotação da base (continua centralizado)

    // 2. DESENHAR O CANHÃO ROTATÓRIO (Segue o ângulo)
    // Cano do canhão feito de pedra escura
    final barrelPaint = Paint()
      ..color = Colors.brown.shade800
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

    // Bocal do canhão (Anel da ponta em laranja/bronze)
    final nozzleRect = Rect.fromLTWH(18, -8, 4, 16);
    canvas.drawRRect(
      RRect.fromRectAndRadius(nozzleRect, const Radius.circular(2)),
      Paint()..color = Colors.orange.shade800,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(nozzleRect, const Radius.circular(2)),
      borderPaint,
    );

    // Corpo circular do meio da torre
    final coreBodyPaint = Paint()
      ..color = Colors.brown.shade900
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, 12, coreBodyPaint);
    canvas.drawCircle(Offset.zero, 12, borderPaint);

    // Núcleo de energia magmática ("Magma Core")
    final coreGradient = RadialGradient(
      colors: [Colors.orangeAccent, Colors.orange.shade900],
      stops: const [0.3, 1.0],
    );
    final corePaint = Paint()
      ..shader = coreGradient.createShader(Rect.fromCircle(center: Offset.zero, radius: 8))
      ..style = PaintingStyle.fill;

    final coreGlowPaint = Paint()
      ..color = Colors.orangeAccent.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    canvas.drawCircle(Offset.zero, 8, coreGlowPaint);
    canvas.drawCircle(Offset.zero, 8, corePaint);

    canvas.restore(); // Restaura a centralização
  }
}

// Projétil da Torre de Pedra: Lançamento de pedra com dano em área (Splash)
class ProjetilPedra extends Projectile {
  final double splashRadius = 70.0;

  ProjetilPedra({
    required Vector2 startPosition,
    required Enemy target,
    required double damage,
  }) : super(
          startPosition: startPosition,
          target: target,
          damage: damage,
        );

  @override
  void update(double dt) {
    // Não chamamos super.update para interceptar o impacto e aplicar dano em área
    if (!target.isMounted || target.hp <= 0) {
      removeFromParent();
      return;
    }

    final direction = target.position - position;
    final distance = direction.length;

    final step = speed * dt;
    if (distance <= step) {
      // Impacto!
      _applySplashDamage();
      removeFromParent();
    } else {
      position += direction.normalized() * step;
    }
  }

  void _applySplashDamage() {
    // Cria o efeito visual de poeira e impacto
    game.add(SplashExplosionEffect(position: position.clone(), maxRadius: splashRadius));

    // Aplica o dano a todos os inimigos dentro do raio
    final enemies = game.children.whereType<Enemy>();
    for (final enemy in enemies) {
      final dist = (enemy.position - position).length;
      if (dist <= splashRadius) {
        enemy.takeDamage(damage, Colors.orange);
      }
    }
  }

  @override
  void render(Canvas canvas) {
    // Desenha uma pedra redonda rústica marrom/cinza
    final paint = Paint()
      ..color = Colors.brown.shade600
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Sombra/Brilho inferior
    final shadowPaint = Paint()
      ..color = Colors.brown.shade800.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x / 2 + 1, shadowPaint);
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x / 2, paint);
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x / 2, borderPaint);

    // Detalhe de ranhura de pedra
    final detailPaint = Paint()
      ..color = Colors.brown.shade400
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.x * 0.35, size.y * 0.35), 1.5, detailPaint);
  }
}

// Efeito visual de poeira/onda de choque no impacto da pedra
class SplashExplosionEffect extends PositionComponent {
  final double maxRadius;
  double lifespan = 0.25;
  final double maxLifespan = 0.25;

  SplashExplosionEffect({required Vector2 position, required this.maxRadius}) {
    this.position = position.clone();
    anchor = Anchor.center;
    size = Vector2.zero();
  }

  @override
  void update(double dt) {
    super.update(dt);
    lifespan -= dt;
    if (lifespan <= 0) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final progress = (1.0 - (lifespan / maxLifespan)).clamp(0.0, 1.0);
    final currentRadius = maxRadius * progress;
    final opacity = (1.0 - progress).clamp(0.0, 1.0);

    // Brilho alaranjado expansivo e preenchimento terroso opaco
    final shockwavePaint = Paint()
      ..color = Colors.orangeAccent.withValues(alpha: opacity * 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final fillPaint = Paint()
      ..color = Colors.brown.withValues(alpha: opacity * 0.15)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset.zero, currentRadius, fillPaint);
    canvas.drawCircle(Offset.zero, currentRadius, shockwavePaint);
  }
}
