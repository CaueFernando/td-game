import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'tower.dart';
import 'status_effect.dart';
import '../enemies/enemies.dart';

// IceNovaTower - Torre de congelamento em área radial (Ice Nova)
class IceNovaTower extends Tower {
  static const String towerName = 'Frost';
  static const int baseCost = 150;
  static const double baseRange = 160.0;

  @override
  String get name => towerName;

  IceNovaTower({required Vector2 position})
      : super(
          position: position,
          range: baseRange,
          damage: 7.0,  // Dano ligeiramente inferior à BaseTower
          fireRate: 1.6,
          cost: baseCost,
        );

  @override
  void shoot(Enemy target) {
    // Onda congelante radial a partir do centro da própria torre
    game.add(IceNovaEffect(position: position.clone(), maxRadius: range));
    game.playSfx('freeze.mp3');

    // Aplica dano congelante em área a todos os inimigos no alcance e ativa Chill
    final enemies = game.children.whereType<Enemy>();
    for (final enemy in enemies) {
      final dist = (enemy.position - position).length;
      if (dist <= range) {
        enemy.applyEffect(ChillEffect());
        enemy.takeDamage(damage, Colors.lightBlueAccent);
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
    canvas.rotate(-angle); // Desfaz a rotação da mira para desenhar a base
    
    final baseRect = Rect.fromCenter(center: Offset.zero, width: size.x * 1.1, height: size.y * 1.1);
    
    final baseGradient = LinearGradient(
      colors: [Colors.blue.shade900, Colors.cyan.shade800, Colors.cyan.shade700],
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

    // Luzes nos cantos em azul glaciar
    final cornerLightPaint = Paint()
      ..color = Colors.lightBlueAccent
      ..style = PaintingStyle.fill;
    
    final halfW = size.x * 1.1 / 2;
    final halfH = size.y * 1.1 / 2;
    canvas.drawCircle(Offset(-halfW + 4, -halfH + 4), 2.5, cornerLightPaint);
    canvas.drawCircle(Offset(halfW - 4, -halfH + 4), 2.5, cornerLightPaint);
    canvas.drawCircle(Offset(-halfW + 4, halfH - 4), 2.5, cornerLightPaint);
    canvas.drawCircle(Offset(halfW - 4, halfH - 4), 2.5, cornerLightPaint);

    canvas.restore(); // Restaura da rotação

    // 2. DESENHAR O CRISTAL ROTATÓRIO (Segue o ângulo)
    // Suporte circular da gema
    final ringPaint = Paint()
      ..color = Colors.cyan.shade900
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, 11, ringPaint);
    canvas.drawCircle(Offset.zero, 11, borderPaint);

    // Cristal hexagonal no topo (procedural 3D)
    final crystalPaint = Paint()
      ..color = Colors.lightBlueAccent.shade100
      ..style = PaintingStyle.fill;
    
    final crystalPath = Path()
      ..moveTo(0, -15) // Ponta do topo
      ..lineTo(8, -5)
      ..lineTo(8, 5)
      ..lineTo(0, 15) // Ponta da base
      ..lineTo(-8, 5)
      ..lineTo(-8, -5)
      ..close();

    canvas.drawPath(crystalPath, crystalPaint);

    // Facetas internas do cristal (simulação de refração de luz)
    final facetPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;
    final rightFacet = Path()
      ..moveTo(0, -15)
      ..lineTo(8, -5)
      ..lineTo(8, 5)
      ..lineTo(0, 15)
      ..close();
    canvas.drawPath(rightFacet, facetPaint);

    canvas.drawPath(crystalPath, borderPaint);

    // Núcleo gelado de energia
    final crystalGlowPaint = Paint()
      ..color = Colors.lightBlueAccent.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(Offset.zero, 6, crystalGlowPaint);

    canvas.restore(); // Restaura a centralização
  }
}

// Efeito visual expansivo da Ice Nova
class IceNovaEffect extends PositionComponent {
  final double maxRadius;
  double lifespan = 0.35;
  final double maxLifespan = 0.35;

  IceNovaEffect({required Vector2 position, required this.maxRadius}) {
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

    // Onda de choque congelante expansiva com gradiente azul/ciano
    final icePaint = Paint()
      ..color = Colors.lightBlueAccent.withValues(alpha: opacity * 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    final fillPaint = Paint()
      ..color = Colors.cyan.withValues(alpha: opacity * 0.12)
      ..style = PaintingStyle.fill;

    // Onda de choque interna de gelo secundária (profundidade)
    final secondaryPaint = Paint()
      ..color = Colors.white.withValues(alpha: opacity * 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(Offset.zero, currentRadius, fillPaint);
    canvas.drawCircle(Offset.zero, currentRadius, icePaint);
    canvas.drawCircle(Offset.zero, currentRadius * 0.85, secondaryPaint);
  }
}
