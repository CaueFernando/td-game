import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'enemy.dart';

// Sindicalista Boss (O Chefe) - Inimigo Elite das waves múltiplas de 8
class SindicalistaBoss extends Enemy {
  SindicalistaBoss({
    required List<Vector2> path,
    required double hp,
    double speedMultiplier = 1.0,
  }) : super(
          hp: hp,
          maxHp: hp,
          speed: 40 * speedMultiplier, // Lento, mas imponente e com muita vida
          reward: 150, // Recompensa grande
          damageToBase: 8, // Dano destrutivo à base
          path: path,
        ) {
    size = Vector2(48, 48); // Dimensões maiores
  }

  @override
  void onRemove() {
    game.activeBossesCount--;
    if (game.activeBossesCount <= 0) {
      game.activeBossesCount = 0;
      // Se o jogo ainda estiver rolando (sem Game Over ou Vitória), volta para a BGM padrão
      if (!game.gameState.isGameOver.value && !game.gameState.isVictory.value) {
        game.playBgm('bgm.mp3');
      }
    }
    super.onRemove();
  }

  @override
  void render(Canvas canvas) {
    final rect = size.toRect();

    // 1. Brilho neon de alerta ao redor do chefe (Alerta Vermelho)
    final glowPaint = Paint()
      ..color = Colors.redAccent.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x / 2 + 4, glowPaint);

    // 2. Corpo do Boss (RRect)
    final paint = Paint()
      ..color = isFlashing ? Colors.white : Colors.red.shade900
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(12)),
      paint,
    );

    // Borda preta grossa
    final borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(12)),
      borderPaint,
    );

    // 3. Olhos brilhantes amarelos e sobrancelhas muito bravas
    final eyePaint = Paint()..color = Colors.yellow;
    canvas.drawCircle(Offset(size.x * 0.3, size.y * 0.35), 4.5, eyePaint);
    canvas.drawCircle(Offset(size.x * 0.7, size.y * 0.35), 4.5, eyePaint);

    final browPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 3.0;
    canvas.drawLine(Offset(size.x * 0.18, size.y * 0.22), Offset(size.x * 0.45, size.y * 0.32), browPaint);
    canvas.drawLine(Offset(size.x * 0.82, size.y * 0.22), Offset(size.x * 0.55, size.y * 0.32), browPaint);

    // 4. Coroa de Ouro ("O Chefe")
    final crownPaint = Paint()
      ..color = Colors.amberAccent
      ..style = PaintingStyle.fill;
    final crownPath = Path()
      ..moveTo(size.x * 0.2, size.y * 0.15)
      ..lineTo(size.x * 0.15, size.y * -0.1) // Ponta esquerda
      ..lineTo(size.x * 0.35, size.y * 0.02)  // Vale esq
      ..lineTo(size.x * 0.5, size.y * -0.15)  // Ponta central
      ..lineTo(size.x * 0.65, size.y * 0.02)  // Vale dir
      ..lineTo(size.x * 0.85, size.y * -0.1)  // Ponta direita
      ..lineTo(size.x * 0.8, size.y * 0.15)
      ..close();
    canvas.drawPath(crownPath, crownPaint);
    canvas.drawPath(crownPath, borderPaint);

    // Detalhe de rubi vermelho na coroa
    final rubyPaint = Paint()..color = Colors.redAccent;
    canvas.drawCircle(Offset(size.x * 0.5, size.y * -0.05), 2.5, rubyPaint);

    // 5. Megafone Megalomaníaco (para dar ordens de protesto)
    final megaphonePaint = Paint()
      ..color = Colors.grey.shade400
      ..style = PaintingStyle.fill;
    final megaphonePath = Path()
      ..moveTo(size.x * 0.45, size.y * 0.65)
      ..lineTo(size.x * 0.25, size.y * 0.78)
      ..lineTo(size.x * 0.2, size.y * 0.68)
      ..lineTo(size.x * 0.45, size.y * 0.55)
      ..close();
    canvas.drawPath(megaphonePath, megaphonePaint);
    canvas.drawPath(megaphonePath, borderPaint);

    super.render(canvas);
  }
}
