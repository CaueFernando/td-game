import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'tower.dart';
import 'main.dart';

class TowerSlot extends PositionComponent with TapCallbacks, HasGameReference<CloroquinildoGame> {
  bool hasTower = false;
  Tower? tower;

  TowerSlot({required Vector2 position}) {
    this.position = position.clone();
    size = Vector2(44, 44);
    anchor = Anchor.center;
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);

    if (!hasTower) {
      // Tenta comprar a Torre Taokey (custo 100 Pixcoins)
      const cost = 100;
      if (game.gameState.buy(cost)) {
        final newTower = TorreTaokey(position: position);
        game.add(newTower);
        tower = newTower;
        hasTower = true;
      } else {
        // Feedback visual ou sonoro de moedas insuficientes
        game.showFloatingText('Sem Pixcoins!', position, Colors.redAccent);
      }
    } else {
      // Toggle alcance e botões de upgrade
      if (tower != null) {
        // Desativa o alcance de todas as outras torres antes
        final allTowers = game.children.whereType<Tower>();
        for (final t in allTowers) {
          if (t != tower) {
            t.showRange = false;
          }
        }
        tower!.showRange = !tower!.showRange;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Se já tiver uma torre, não desenha o slot (a torre desenha a si mesma)
    if (hasTower) return;

    final rect = size.toRect();
    
    // Desenha o slot de construção vazio estilizado
    final fillPaint = Paint()
      ..color = Colors.blueGrey.shade900.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
    
    final borderPaint = Paint()
      ..color = Colors.cyanAccent.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Desenha o quadrado com cantos arredondados
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      fillPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      borderPaint,
    );

    // Desenha um sinal de "+" no meio
    final plusPaint = Paint()
      ..color = Colors.cyanAccent.withValues(alpha: 0.7)
      ..strokeWidth = 2.0;
    
    final center = Offset(size.x / 2, size.y / 2);
    const lineLen = 6.0;
    // Linha horizontal
    canvas.drawLine(Offset(center.dx - lineLen, center.dy), Offset(center.dx + lineLen, center.dy), plusPaint);
    // Linha vertical
    canvas.drawLine(Offset(center.dx, center.dy - lineLen), Offset(center.dx, center.dy + lineLen), plusPaint);
  }
}
