import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'dart:math';
import 'tower.dart';
import 'status_effect.dart';
import '../enemy.dart';

// ArcTower (Tesla Coil) - Dano instantâneo em cadeia (anteriormente TorreEletrica)
class ArcTower extends Tower {
  ArcTower({required Vector2 position})
      : super(
          position: position,
          range: 130.0,
          damage: 8.0,
          fireRate: 1.2,
          cost: 150,
        );

  @override
  void shoot(Enemy target) {
    final bounceRange = 110.0;
    final maxBounces = 3;
    final targets = <Enemy>[];
    final visited = <Enemy>{};

    Enemy? current = target;
    while (current != null && targets.length < maxBounces) {
      targets.add(current);
      visited.add(current);
      current = _findNearestEnemy(current.position, visited, bounceRange);
    }

    // Calcula os danos com decaimento
    final damages = <double>[];
    double currentDamage = damage;
    for (int i = 0; i < targets.length; i++) {
      damages.add(currentDamage);
      currentDamage *= 0.8; // Decai 20% a cada ricochete
    }

    // Cria o efeito de raio no mundo com propagação
    game.add(LightningEffect(
      startPosition: position.clone() + Vector2(0, -10),
      targets: targets,
      damages: damages,
    ));
  }

  Enemy? _findNearestEnemy(Vector2 from, Set<Enemy> exclude, double maxDistance) {
    final enemies = game.children.whereType<Enemy>();
    Enemy? nearest;
    double minDistance = double.infinity;

    for (final enemy in enemies) {
      if (exclude.contains(enemy)) continue;
      final distance = (enemy.position - from).length;
      if (distance <= maxDistance && distance < minDistance) {
        minDistance = distance;
        nearest = enemy;
      }
    }
    return nearest;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // 1. DESENHAR BASE FIXA (Não rotaciona com a mira da torre)
    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);
    canvas.save();
    canvas.rotate(-angle); // Desfaz a rotação da mira para desenhar a base estática
    
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

    // Detalhes em ciano brilhante nos cantos (luzes de status da base)
    final cornerLightPaint = Paint()
      ..color = Colors.cyanAccent
      ..style = PaintingStyle.fill;
    
    final halfW = size.x * 1.1 / 2;
    final halfH = size.y * 1.1 / 2;
    canvas.drawCircle(Offset(-halfW + 4, -halfH + 4), 2.5, cornerLightPaint);
    canvas.drawCircle(Offset(halfW - 4, -halfH + 4), 2.5, cornerLightPaint);
    canvas.drawCircle(Offset(-halfW + 4, halfH - 4), 2.5, cornerLightPaint);
    canvas.drawCircle(Offset(halfW - 4, halfH - 4), 2.5, cornerLightPaint);

    canvas.restore(); // Restaura da rotação

    // 2. DESENHAR A BOBINA TESLA (Emissora em todas as direções)
    // Haste vertical
    final rodPaint = Paint()
      ..color = Colors.grey.shade800
      ..style = PaintingStyle.fill;
    final rodRect = Rect.fromCenter(center: const Offset(0, 4), width: 8, height: 24);
    canvas.drawRRect(RRect.fromRectAndRadius(rodRect, const Radius.circular(2)), rodPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(rodRect, const Radius.circular(2)), borderPaint);

    // Anéis da bobina
    final coilPaint = Paint()
      ..color = Colors.cyan.shade700
      ..style = PaintingStyle.fill;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: const Offset(0, 8), width: 14, height: 4), const Radius.circular(1)), coilPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: const Offset(0, 8), width: 14, height: 4), const Radius.circular(1)), borderPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: const Offset(0, 0), width: 12, height: 4), const Radius.circular(1)), coilPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: const Offset(0, 0), width: 12, height: 4), const Radius.circular(1)), borderPaint);

    // Esfera emissora de plasma no topo
    final spherePaint = Paint()
      ..color = Colors.grey.shade900
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(0, -10), 10, spherePaint);
    canvas.drawCircle(const Offset(0, -10), 10, borderPaint);

    // Núcleo de plasma ciano brilhante
    final plasmaGradient = RadialGradient(
      colors: [Colors.white, Colors.cyanAccent, Colors.cyan.shade900],
      stops: const [0.1, 0.6, 1.0],
    );
    final plasmaPaint = Paint()
      ..shader = plasmaGradient.createShader(Rect.fromCircle(center: const Offset(0, -10), radius: 7))
      ..style = PaintingStyle.fill;

    final plasmaGlowPaint = Paint()
      ..color = Colors.cyanAccent.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawCircle(const Offset(0, -10), 7, plasmaGlowPaint);
    canvas.drawCircle(const Offset(0, -10), 7, plasmaPaint);

    canvas.restore(); // Restaura a centralização
  }
}

// Efeito visual de raio zig-zag com propagação e dano sincronizado
class LightningEffect extends PositionComponent {
  final Vector2 startPosition;
  final List<Enemy> targets;
  final List<double> damages;
  
  final List<Vector2> _lastKnownPositions = [];
  final Set<int> _damagedIndices = {};
  
  double _elapsedTime = 0.0;
  final double segmentDuration = 0.08;
  final double fadeDuration = 0.15;
  late final double propagationTime;
  late final double maxLifespan;

  LightningEffect({
    required this.startPosition,
    required this.targets,
    required this.damages,
  }) {
    position = Vector2.zero();
    size = Vector2(3000, 3000);
    anchor = Anchor.topLeft;

    propagationTime = targets.length * segmentDuration;
    maxLifespan = propagationTime + fadeDuration;

    // Guarda posições iniciais
    _lastKnownPositions.add(startPosition);
    for (final enemy in targets) {
      _lastKnownPositions.add(enemy.position.clone());
    }
  }

  // Retorna os pontos atualizados (seguindo os inimigos se estiverem vivos)
  List<Vector2> get currentPoints {
    final list = <Vector2>[startPosition];
    for (int i = 0; i < targets.length; i++) {
      final enemy = targets[i];
      if (enemy.isMounted) {
        final pos = enemy.position.clone();
        _lastKnownPositions[i + 1] = pos;
        list.add(pos);
      } else {
        list.add(_lastKnownPositions[i + 1]);
      }
    }
    return list;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsedTime += dt;

    // Aplica o dano sincronizado quando a ponta do raio chega a cada alvo
    for (int i = 0; i < targets.length; i++) {
      if (!_damagedIndices.contains(i)) {
        final arrivalTime = (i + 1) * segmentDuration;
        if (_elapsedTime >= arrivalTime) {
          _damagedIndices.add(i);
          final enemy = targets[i];
          if (enemy.isMounted && enemy.hp > 0) {
            enemy.applyEffect(ShockEffect());
            enemy.takeDamage(damages[i]);
          }
        }
      }
    }

    if (_elapsedTime >= maxLifespan) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final pts = currentPoints;
    if (pts.length < 2) return;

    // Calcula a opacidade baseado no tempo de fadeout
    double opacity = 1.0;
    if (_elapsedTime > propagationTime) {
      final fadeProgress = (_elapsedTime - propagationTime) / fadeDuration;
      opacity = (1.0 - fadeProgress).clamp(0.0, 1.0);
    }

    final glowPaint = Paint()
      ..color = Colors.cyanAccent.withValues(alpha: opacity * 0.6)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    final boltPaint = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final random = Random();

    // Desenha cada segmento propagado
    for (int i = 0; i < pts.length - 1; i++) {
      final segmentStart = i * segmentDuration;
      if (_elapsedTime < segmentStart) break;

      final segmentEnd = (i + 1) * segmentDuration;
      
      final p1 = Offset(pts[i].x, pts[i].y);
      Offset p2;

      if (_elapsedTime >= segmentEnd) {
        p2 = Offset(pts[i + 1].x, pts[i + 1].y);
      } else {
        // Interpola a ponta do raio que está viajando
        final t = (_elapsedTime - segmentStart) / segmentDuration;
        final startPt = pts[i];
        final endPt = pts[i + 1];
        final interpPt = startPt + (endPt - startPt) * t;
        p2 = Offset(interpPt.x, interpPt.y);
      }

      final segments = _generateZigZag(p1, p2, random);

      final path = Path();
      if (segments.isNotEmpty) {
        path.moveTo(segments.first.dx, segments.first.dy);
        for (int j = 1; j < segments.length; j++) {
          path.lineTo(segments[j].dx, segments[j].dy);
        }
      }

      canvas.drawPath(path, glowPaint);
      canvas.drawPath(path, boltPaint);

      // Se este segmento ainda está se propagando, interrompe o desenho dos próximos
      if (_elapsedTime < segmentEnd) break;
    }
  }

  List<Offset> _generateZigZag(Offset from, Offset to, Random random) {
    final delta = to - from;
    final distance = delta.distance;
    if (distance < 10) return [from, to];

    final segmentsCount = (distance / 12).ceil();
    final points = [from];

    final dir = delta / distance;
    final perp = Offset(-dir.dy, dir.dx); // Vetor perpendicular

    for (int i = 1; i < segmentsCount; i++) {
      final fraction = i / segmentsCount;
      final basePoint = from + delta * fraction;
      // Adiciona ruído perpendicular à direção do segmento
      final offsetScale = (random.nextDouble() - 0.5) * 10.0;
      points.add(basePoint + perp * offsetScale);
    }
    points.add(to);
    return points;
  }
}
