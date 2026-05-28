import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'enemy.dart';

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
