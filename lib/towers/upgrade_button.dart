import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'tower.dart';
import '../main.dart';

enum UpgradeType { damage, range, speed, sell }

class UpgradeButton extends PositionComponent with TapCallbacks, HasGameReference<CloroquinildoGame> {
  final UpgradeType type;
  final Tower parentTower;

  UpgradeButton({
    required this.type,
    required this.parentTower,
    required Vector2 position,
  }) {
    this.position = position.clone();
    size = Vector2(32, 32);
    anchor = Anchor.center;
  }

  int get cost {
    switch (type) {
      case UpgradeType.damage:
        return parentTower.damageUpgradeCost;
      case UpgradeType.range:
        return parentTower.rangeUpgradeCost;
      case UpgradeType.speed:
        return parentTower.speedUpgradeCost;
      case UpgradeType.sell:
        return parentTower.cost ~/ 2;
    }
  }

  Color get color {
    switch (type) {
      case UpgradeType.damage:
        return Colors.redAccent;
      case UpgradeType.range:
        return Colors.blueAccent;
      case UpgradeType.speed:
        return Colors.greenAccent;
      case UpgradeType.sell:
        return Colors.orangeAccent;
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);

    if (type == UpgradeType.sell) {
      final refund = cost;
      game.gameState.addPixcoins(refund);
      game.showFloatingText('+$refund PX!', parentTower.position, Colors.greenAccent);
      game.playSfx('sell.mp3');
      parentTower.removeFromParent();
      return;
    }

    final currentCost = cost;
    if (game.gameState.buy(currentCost)) {
      game.playSfx('upgrade.mp3');
      switch (type) {
        case UpgradeType.damage:
          parentTower.damage += 4;
          parentTower.damageLevel++;
          parentTower.damageUpgradeCost = (parentTower.damageUpgradeCost * 1.5).toInt();
          game.showFloatingText('+Dano!', parentTower.position, Colors.redAccent);
          break;
        case UpgradeType.range:
          parentTower.range += 15.0;
          parentTower.rangeLevel++;
          parentTower.rangeUpgradeCost = (parentTower.rangeUpgradeCost * 1.5).toInt();
          game.showFloatingText('+Alcance!', parentTower.position, Colors.blueAccent);
          break;
        case UpgradeType.speed:
          parentTower.fireRate = (parentTower.fireRate * 0.85).clamp(0.15, 3.0);
          parentTower.speedLevel++;
          parentTower.speedUpgradeCost = (parentTower.speedUpgradeCost * 1.5).toInt();
          game.showFloatingText('+Velocidade!', parentTower.position, Colors.greenAccent);
          break;
        case UpgradeType.sell:
          break;
      }
    } else {
      game.showFloatingText('Sem Pixcoins!', position, Colors.redAccent);
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final radius = size.x / 2;
    final center = Offset(radius, radius);

    // 1. Fundo do Botão (Glassmorphism)
    final bgPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.75)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    // 2. Borda Neon
    final borderPaint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    // Brilho da borda
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    canvas.drawCircle(center, radius, glowPaint);
    canvas.drawCircle(center, radius, borderPaint);

    // 3. Desenhar Ícone
    final iconPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    switch (type) {
      case UpgradeType.damage:
        // Desenha uma Espada
        final swordPath = Path()
          ..moveTo(radius - 6, radius + 6)   // Punho
          ..lineTo(radius + 6, radius - 6)   // Ponta da lâmina
          ..moveTo(radius - 4, radius + 2)   // Guarda esquerda
          ..lineTo(radius - 2, radius + 4)
          ..moveTo(radius + 2, radius - 4)   // Guarda direita
          ..lineTo(radius + 4, radius - 2);
        canvas.drawPath(swordPath, iconPaint);
        break;

      case UpgradeType.range:
        // Desenha uma Mira
        canvas.drawCircle(center, 5, iconPaint);
        canvas.drawLine(Offset(center.dx - 9, center.dy), Offset(center.dx - 3, center.dy), iconPaint);
        canvas.drawLine(Offset(center.dx + 3, center.dy), Offset(center.dx + 9, center.dy), iconPaint);
        canvas.drawLine(Offset(center.dx, center.dy - 9), Offset(center.dx, center.dy - 3), iconPaint);
        canvas.drawLine(Offset(center.dx, center.dy + 3), Offset(center.dx, center.dy + 9), iconPaint);
        break;

      case UpgradeType.speed:
        // Desenha um Projétil
        final bulletPath = Path()
          ..moveTo(radius - 5, radius + 4)
          ..lineTo(radius + 3, radius - 4)
          ..quadraticBezierTo(radius + 6, radius - 7, radius + 7, radius - 4)
          ..lineTo(radius - 1, radius + 8)
          ..close();
        canvas.drawPath(bulletPath, iconPaint..style = PaintingStyle.fill);
        
        // Rastros de velocidade
        final trailPaint = Paint()
          ..color = Colors.white70
          ..strokeWidth = 1.0;
        canvas.drawLine(Offset(radius - 7, radius + 1), Offset(radius - 3, radius - 3), trailPaint);
        canvas.drawLine(Offset(radius - 5, radius + 4), Offset(radius - 1, radius), trailPaint);
        break;

      case UpgradeType.sell:
        // Desenha uma Lixeira
        final lidPath = Path()
          ..moveTo(radius - 8, radius - 6)
          ..lineTo(radius + 8, radius - 6)
          ..moveTo(radius - 3, radius - 6)
          ..lineTo(radius - 3, radius - 9)
          ..lineTo(radius + 3, radius - 9)
          ..lineTo(radius + 3, radius - 6);
        
        final binPath = Path()
          ..moveTo(radius - 6, radius - 4)
          ..lineTo(radius - 5, radius + 8)
          ..quadraticBezierTo(radius - 5, radius + 9, radius - 4, radius + 9)
          ..lineTo(radius + 4, radius + 9)
          ..quadraticBezierTo(radius + 5, radius + 9, radius + 5, radius + 8)
          ..lineTo(radius + 6, radius - 4)
          ..close();

        canvas.drawPath(lidPath, iconPaint);
        canvas.drawPath(binPath, iconPaint);
        
        // Linhas verticais dentro do cesto
        canvas.drawLine(Offset(radius - 2, radius - 1), Offset(radius - 2, radius + 6), iconPaint);
        canvas.drawLine(Offset(radius + 2, radius - 1), Offset(radius + 2, radius + 6), iconPaint);
        break;
    }

    // 4. Desenha o Custo/Reembolso abaixo do botão
    final textPainter = TextPainter(
      text: TextSpan(
        text: type == UpgradeType.sell ? '+$cost PX' : '$cost PX',
        style: TextStyle(
          color: type == UpgradeType.sell ? Colors.greenAccent : Colors.amberAccent,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          shadows: const [Shadow(color: Colors.black, blurRadius: 3)],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(radius - textPainter.width / 2, radius * 2 + 3),
    );
  }
}
