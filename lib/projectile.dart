import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'enemies/enemies.dart';
import 'main.dart';

class Projectile extends PositionComponent with HasGameReference<CloroquinildoGame> {
  final double speed;
  final double damage;
  final Enemy target;

  Projectile({
    required Vector2 startPosition,
    required this.target,
    required this.damage,
    this.speed = 300.0,
  }) {
    position = startPosition.clone();
    size = Vector2(10, 10);
    anchor = Anchor.center;
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Se o alvo morreu ou saiu do jogo, remove o projétil
    if (!target.isMounted || target.hp <= 0) {
      removeFromParent();
      return;
    }

    // Persegue o inimigo
    final direction = target.position - position;
    final distance = direction.length;

    final step = speed * dt;
    if (distance <= step) {
      // Impacto!
      target.takeDamage(damage);
      removeFromParent();
    } else {
      position += direction.normalized() * step;
    }
  }
}

// Projétil da Torre Taokey: "Argumento Confuso"
class ProjetilArgumento extends Projectile {
  ProjetilArgumento({
    required Vector2 startPosition,
    required Enemy target,
    required double damage,
  }) : super(startPosition: startPosition, target: target, damage: damage);

  @override
  void render(Canvas canvas) {
    // Desenha um pequeno balão de diálogo brilhante
    final paint = Paint()
      ..color = Colors.amberAccent
      ..style = PaintingStyle.fill;
    
    // Brilho externo (glow)
    final shadowPaint = Paint()
      ..color = Colors.orange.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x / 2 + 2, shadowPaint);
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x / 2, paint);

    // Contorno
    final borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x / 2, borderPaint);
  }
}
