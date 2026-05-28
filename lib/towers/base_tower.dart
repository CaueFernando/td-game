import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'tower.dart';
import '../enemies/enemies.dart';
import '../projectile.dart';

// BaseTower - A torre básica (anteriormente TorreTaokey)
class BaseTower extends Tower {
  static const String towerName = 'Taokey';
  static const int baseCost = 50;
  static const double baseRange = 130.0;

  BaseTower({required Vector2 position})
      : super(
          position: position,
          range: baseRange,
          damage: 10.0,
          fireRate: 0.8,
          cost: baseCost,
        );

  @override
  void shoot(Enemy target) {
    final projectile = ProjetilArgumento(
      startPosition: position,
      target: target,
      damage: damage,
    );
    game.add(projectile);
    game.playSfx('shoot.mp3');
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
