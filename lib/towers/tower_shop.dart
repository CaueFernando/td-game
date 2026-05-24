import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'tower.dart';
import 'base_tower.dart';
import 'arc_tower.dart';
import 'stone_tower.dart';
import 'ice_tower.dart';
import 'fire_tower.dart';
import '../main.dart';

enum TowerType { taokey, eletrica, pedra, gelo, fogo }

// Painel da Loja de Torres
class TowerShop extends PositionComponent with HasGameReference<CloroquinildoGame> {
  TowerShop() {
    size = Vector2(435, 120); // Expandido de 350 para 435 para caber cinco cards
    anchor = Anchor.topLeft;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    position = Vector2(size.x - 450, size.y - 190);
  }

  @override
  void update(double dt) {
    super.update(dt);
    final scaleFactor = game.zoomFactor;
    final centerOffset = (game.size - game.size * scaleFactor) / 2;
    final targetScreenPos = Vector2(game.size.x - 450, game.size.y - 190);
    position = (targetScreenPos - centerOffset - game.cameraOffset) / scaleFactor;
    scale = Vector2.all(1.0 / scaleFactor);
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    // Adiciona os cards lado a lado
    add(TowerShopItem(type: TowerType.taokey, position: Vector2(10, 30)));
    add(TowerShopItem(type: TowerType.eletrica, position: Vector2(95, 30)));
    add(TowerShopItem(type: TowerType.pedra, position: Vector2(180, 30)));
    add(TowerShopItem(type: TowerType.gelo, position: Vector2(265, 30)));
    add(TowerShopItem(type: TowerType.fogo, position: Vector2(350, 30)));
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Fundo do Painel (Sleek dark design com borda neon)
    final rect = size.toRect();
    final bgPaint = Paint()
      ..color = const Color(0xFF1E293B).withOpacity(0.85)
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = Colors.cyanAccent.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(16)), bgPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(16)), borderPaint);

    // Título do painel
    final titlePainter = TextPainter(
      text: const TextSpan(
        text: 'LOJA',
        style: TextStyle(
          color: Colors.cyanAccent,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    titlePainter.paint(canvas, Offset(size.x / 2 - titlePainter.width / 2, 8));
  }
}

// Item arrastável da loja para construir torres
class TowerShopItem extends PositionComponent with DragCallbacks, HasGameReference<CloroquinildoGame> {
  final TowerType type;
  TowerDragPreview? _preview;

  TowerShopItem({required this.type, required Vector2 position}) {
    this.position = position;
    size = Vector2(75, 80);
    anchor = Anchor.topLeft;
  }

  double get range {
    switch (type) {
      case TowerType.taokey:
        return BaseTower.baseRange;
      case TowerType.eletrica:
        return ArcTower.baseRange;
      case TowerType.pedra:
        return StoneTower.baseRange;
      case TowerType.gelo:
        return IceNovaTower.baseRange;
      case TowerType.fogo:
        return FireTower.baseRange;
    }
  }

  int get cost {
    switch (type) {
      case TowerType.taokey:
        return BaseTower.baseCost;
      case TowerType.eletrica:
        return ArcTower.baseCost;
      case TowerType.pedra:
        return StoneTower.baseCost;
      case TowerType.gelo:
        return IceNovaTower.baseCost;
      case TowerType.fogo:
        return FireTower.baseCost;
    }
  }

  String get name {
    switch (type) {
      case TowerType.taokey:
        return BaseTower.towerName;
      case TowerType.eletrica:
        return ArcTower.towerName;
      case TowerType.pedra:
        return StoneTower.towerName;
      case TowerType.gelo:
        return IceNovaTower.towerName;
      case TowerType.fogo:
        return FireTower.towerName;
    }
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    game.isDraggingTower = true;
    // Cria o preview de arrasto na posição atual do ponteiro
    _preview = TowerDragPreview(
      position: event.canvasPosition,
      range: range,
      type: type,
    );
    game.add(_preview!);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    if (_preview != null) {
      _preview!.position = event.canvasEndPosition;
      _preview!.isValid = game.isValidTowerPosition(event.canvasEndPosition);
    }
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    game.isDraggingTower = false;
    if (_preview != null) {
      final buildPos = _preview!.position.clone();
      final isValid = _preview!.isValid;
      
      _preview!.removeFromParent();
      _preview = null;

      if (isValid) {
        if (game.gameState.buy(cost)) {
          final Tower tower;
          switch (type) {
            case TowerType.taokey:
              tower = BaseTower(position: buildPos);
              break;
            case TowerType.eletrica:
              tower = ArcTower(position: buildPos);
              break;
            case TowerType.pedra:
              tower = StoneTower(position: buildPos);
              break;
            case TowerType.gelo:
              tower = IceNovaTower(position: buildPos);
              break;
            case TowerType.fogo:
              tower = FireTower(position: buildPos);
              break;
          }
          game.add(tower);
          game.showFloatingText('+Torre!', buildPos, Colors.greenAccent);
        } else {
          game.showFloatingText('Sem Pixcoins!', buildPos, Colors.redAccent);
        }
      } else {
        game.showFloatingText('Local inválido!', buildPos, Colors.redAccent);
      }
    }
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    game.isDraggingTower = false;
    if (_preview != null) {
      _preview!.removeFromParent();
      _preview = null;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // 1. Fundo do Card (Visual Glassmorphism)
    final bgRect = size.toRect();
    final bgPaint = Paint()
      ..color = Colors.black.withOpacity(0.6)
      ..style = PaintingStyle.fill;
    
    // Contorno temático
    Color borderColor;
    if (type == TowerType.taokey) {
      borderColor = Colors.cyanAccent;
    } else if (type == TowerType.eletrica) {
      borderColor = Colors.blueAccent;
    } else if (type == TowerType.pedra) {
      borderColor = Colors.orangeAccent;
    } else if (type == TowerType.gelo) {
      borderColor = Colors.lightBlueAccent;
    } else {
      borderColor = Colors.redAccent;
    }

    final borderPaint = Paint()
      ..color = borderColor.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawRRect(RRect.fromRectAndRadius(bgRect, const Radius.circular(12)), bgPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(bgRect, const Radius.circular(12)), borderPaint);

    // 2. Miniatura da Torre
    canvas.save();
    canvas.translate(size.x / 2, size.y / 2 - 10);
    
    if (type == TowerType.taokey) {
      // Cano mini
      final barrelPaint = Paint()..color = Colors.grey.shade600;
      canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-3, -4, 15, 8), const Radius.circular(2)), barrelPaint);
      
      // Corpo mini
      final bodyPaint = Paint()..color = Colors.grey.shade800;
      canvas.drawCircle(Offset.zero, 8, bodyPaint);
      
      // Core mini
      final corePaint = Paint()..color = Colors.greenAccent;
      canvas.drawCircle(Offset.zero, 5, corePaint);
    } else if (type == TowerType.eletrica) {
      // Bobina mini (Tesla)
      final rodPaint = Paint()..color = Colors.grey.shade600;
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: const Offset(0, 4), width: 3, height: 12), const Radius.circular(1)), rodPaint);
      
      final ringPaint = Paint()..color = Colors.cyan.shade600;
      canvas.drawCircle(const Offset(0, -4), 4, ringPaint);
      
      final corePaint = Paint()..color = Colors.white;
      canvas.drawCircle(const Offset(0, -4), 2.5, corePaint);
    } else if (type == TowerType.pedra) {
      // Miniatura da StoneTower (marrom)
      final barrelPaint = Paint()..color = Colors.brown.shade600;
      canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-3, -4, 15, 8), const Radius.circular(2)), barrelPaint);
      
      final bodyPaint = Paint()..color = Colors.brown.shade800;
      canvas.drawCircle(Offset.zero, 8, bodyPaint);
      
      final corePaint = Paint()..color = Colors.orangeAccent;
      canvas.drawCircle(Offset.zero, 5, corePaint);
    } else if (type == TowerType.gelo) {
      // Miniatura da IceTower (azul claro / cristal)
      final crystalPaint = Paint()..color = Colors.lightBlueAccent;
      final crystalPath = Path()
        ..moveTo(0, -9)
        ..lineTo(5, -3)
        ..lineTo(5, 3)
        ..lineTo(0, 9)
        ..lineTo(-5, 3)
        ..lineTo(-5, -3)
        ..close();
      canvas.drawPath(crystalPath, crystalPaint);
      
      final bodyPaint = Paint()..color = Colors.blue.shade900.withOpacity(0.5);
      canvas.drawCircle(Offset.zero, 5, bodyPaint);
    } else {
      // Miniatura da FireTower (vermelha / bocal)
      final barrelPaint = Paint()..color = Colors.grey.shade700;
      canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-3, -4, 15, 8), const Radius.circular(2)), barrelPaint);
      
      final bodyPaint = Paint()..color = Colors.red.shade900;
      canvas.drawCircle(Offset.zero, 8, bodyPaint);
      
      final corePaint = Paint()..color = Colors.orangeAccent;
      canvas.drawCircle(Offset.zero, 5, corePaint);
    }
    canvas.restore();

    // 3. Nome
    final namePainter = TextPainter(
      text: TextSpan(
        text: name,
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    namePainter.paint(canvas, Offset(size.x / 2 - namePainter.width / 2, size.y - 32));

    // 4. Custo
    Color priceColor;
    if (type == TowerType.taokey) {
      priceColor = Colors.amberAccent;
    } else if (type == TowerType.eletrica) {
      priceColor = Colors.cyanAccent;
    } else if (type == TowerType.pedra) {
      priceColor = Colors.orangeAccent;
    } else if (type == TowerType.gelo) {
      priceColor = Colors.lightBlueAccent;
    } else {
      priceColor = Colors.redAccent;
    }

    final pricePainter = TextPainter(
      text: TextSpan(
        text: '$cost PX',
        style: TextStyle(
          color: priceColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    pricePainter.paint(canvas, Offset(size.x / 2 - pricePainter.width / 2, size.y - 18));
  }
}

// Preview semi-transparente durante o arrasto com feedback de área válida (verde/vermelho)
class TowerDragPreview extends PositionComponent {
  final double range;
  final TowerType type;
  bool isValid = true;

  TowerDragPreview({
    required Vector2 position,
    required this.range,
    required this.type,
  }) {
    this.position = position.clone();
    size = Vector2(40, 40);
    anchor = Anchor.center;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final color = isValid ? Colors.greenAccent : Colors.redAccent;

    // 1. Círculo de Alcance
    final rangePaint = Paint()
      ..color = color.withOpacity(0.15)
      ..style = PaintingStyle.fill;
    final rangeBorderPaint = Paint()
      ..color = color.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);
    canvas.drawCircle(Offset.zero, range, rangePaint);
    canvas.drawCircle(Offset.zero, range, rangeBorderPaint);

    // 2. Silhueta da Torre
    final basePaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    final baseBorderPaint = Paint()
      ..color = color.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final baseRect = Rect.fromCenter(center: Offset.zero, width: size.x * 1.1, height: size.y * 1.1);
    canvas.drawRRect(RRect.fromRectAndRadius(baseRect, const Radius.circular(8)), basePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(baseRect, const Radius.circular(8)), baseBorderPaint);

    if (type == TowerType.taokey) {
      final barrelPaint = Paint()..color = color.withOpacity(0.4);
      final barrelRect = Rect.fromLTWH(-4, -6, 22, 12);
      canvas.drawRRect(RRect.fromRectAndRadius(barrelRect, const Radius.circular(3)), barrelPaint);
      canvas.drawRRect(RRect.fromRectAndRadius(barrelRect, const Radius.circular(3)), baseBorderPaint);

      canvas.drawCircle(Offset.zero, 8, basePaint);
      canvas.drawCircle(Offset.zero, 8, baseBorderPaint);
    } else if (type == TowerType.eletrica) {
      final rodRect = Rect.fromCenter(center: const Offset(0, 4), width: 6, height: 20);
      canvas.drawRRect(RRect.fromRectAndRadius(rodRect, const Radius.circular(2)), basePaint);
      canvas.drawRRect(RRect.fromRectAndRadius(rodRect, const Radius.circular(2)), baseBorderPaint);

      canvas.drawCircle(const Offset(0, -8), 8, basePaint);
      canvas.drawCircle(const Offset(0, -8), 8, baseBorderPaint);
    } else if (type == TowerType.pedra) {
      final barrelPaint = Paint()..color = color.withOpacity(0.4);
      final barrelRect = Rect.fromLTWH(-4, -6, 22, 12);
      canvas.drawRRect(RRect.fromRectAndRadius(barrelRect, const Radius.circular(3)), barrelPaint);
      canvas.drawRRect(RRect.fromRectAndRadius(barrelRect, const Radius.circular(3)), baseBorderPaint);

      canvas.drawCircle(Offset.zero, 8, basePaint);
      canvas.drawCircle(Offset.zero, 8, baseBorderPaint);
    } else if (type == TowerType.gelo) {
      final rodRect = Rect.fromCenter(center: const Offset(0, 0), width: 12, height: 24);
      canvas.drawRRect(RRect.fromRectAndRadius(rodRect, const Radius.circular(3)), basePaint);
      canvas.drawRRect(RRect.fromRectAndRadius(rodRect, const Radius.circular(3)), baseBorderPaint);
      
      canvas.drawCircle(const Offset(0, 0), 6, basePaint);
      canvas.drawCircle(const Offset(0, 0), 6, baseBorderPaint);
    } else {
      // Drag preview para FireTower
      final barrelPaint = Paint()..color = color.withOpacity(0.4);
      final barrelRect = Rect.fromLTWH(-4, -6, 22, 12);
      canvas.drawRRect(RRect.fromRectAndRadius(barrelRect, const Radius.circular(3)), barrelPaint);
      canvas.drawRRect(RRect.fromRectAndRadius(barrelRect, const Radius.circular(3)), baseBorderPaint);

      canvas.drawCircle(Offset.zero, 8, basePaint);
      canvas.drawCircle(Offset.zero, 8, baseBorderPaint);
    }

    canvas.restore();
  }
}
