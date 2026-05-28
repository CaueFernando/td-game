import 'package:flutter/material.dart';
import '../enemies/enemies.dart';

enum EffectType { chill, shock, burning }

// Classe base abstrata para Efeitos de Status (debuffs/buffs)
abstract class StatusEffect {
  final EffectType type;
  double duration;
  final double maxDuration;

  StatusEffect({required this.type, required this.duration}) : maxDuration = duration;

  // Atualiza o efeito a cada frame. Retorna false se o efeito expirou.
  bool update(Enemy enemy, double dt);

  // Atualiza as propriedades ao re-aplicar o efeito
  void refresh(StatusEffect newEffect);

  // Renderiza o ícone do efeito de status acima do monstro
  void renderIcon(Canvas canvas, Offset offset, double size);
}

// Efeito de Lentidão (Chill) - Reduz a velocidade em 40%
class ChillEffect extends StatusEffect {
  final double speedReductionMultiplier = 0.6; // 40% de redução

  ChillEffect({double duration = 3.0}) : super(type: EffectType.chill, duration: duration);

  @override
  bool update(Enemy enemy, double dt) {
    duration -= dt;
    return duration > 0;
  }

  @override
  void refresh(StatusEffect newEffect) {
    duration = maxDuration;
  }

  @override
  void renderIcon(Canvas canvas, Offset offset, double size) {
    // Desenha círculo azul com floco de neve
    final paint = Paint()
      ..color = Colors.lightBlue.shade300
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = Colors.blue.shade900
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final center = offset + Offset(size / 2, size / 2);
    canvas.drawCircle(center, size / 2, paint);
    canvas.drawCircle(center, size / 2, borderPaint);

    // Cruz e X para representar o floco de neve
    final symbolPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final r = size / 2 - 2;
    canvas.drawLine(center - Offset(r, 0), center + Offset(r, 0), symbolPaint);
    canvas.drawLine(center - Offset(0, r), center + Offset(0, r), symbolPaint);
    canvas.drawLine(center - Offset(r * 0.7, r * 0.7), center + Offset(r * 0.7, r * 0.7), symbolPaint);
    canvas.drawLine(center - Offset(r * 0.7, -r * 0.7), center + Offset(r * 0.7, -r * 0.7), symbolPaint);
  }
}

// Efeito de Vulnerabilidade (Shock) - Aumenta dano recebido em 20%
class ShockEffect extends StatusEffect {
  final double damageMultiplier = 1.20; // 20% a mais de dano

  ShockEffect({double duration = 3.0}) : super(type: EffectType.shock, duration: duration);

  @override
  bool update(Enemy enemy, double dt) {
    duration -= dt;
    return duration > 0;
  }

  @override
  void refresh(StatusEffect newEffect) {
    duration = maxDuration;
  }

  @override
  void renderIcon(Canvas canvas, Offset offset, double size) {
    // Desenha círculo amarelo com um raio ciano/branco
    final paint = Paint()
      ..color = Colors.amberAccent
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = Colors.orange.shade900
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final center = offset + Offset(size / 2, size / 2);
    canvas.drawCircle(center, size / 2, paint);
    canvas.drawCircle(center, size / 2, borderPaint);

    // Símbolo de raio
    final symbolPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    final rayPath = Path()
      ..moveTo(center.dx + 1, center.dy - size / 2 + 2)
      ..lineTo(center.dx - size / 4, center.dy + 1)
      ..lineTo(center.dx + 1, center.dy)
      ..lineTo(center.dx - 1, center.dy + size / 2 - 2)
      ..lineTo(center.dx + size / 4, center.dy - 1)
      ..lineTo(center.dx - 1, center.dy)
      ..close();

    canvas.drawPath(rayPath, symbolPaint);
  }
}

// Efeito de Queimadura (Burning) - Dano contínuo por segundo (DoT)
class BurningEffect extends StatusEffect {
  double dps; // Dano por segundo (10% do dano inicial do ataque)
  double tickTimer = 1.0; // Tick a cada 1 segundo

  BurningEffect({required this.dps, double duration = 3.0}) : super(type: EffectType.burning, duration: duration);

  @override
  bool update(Enemy enemy, double dt) {
    duration -= dt;
    tickTimer -= dt;

    if (tickTimer <= 0) {
      enemy.takeDamage(dps, Colors.orangeAccent);
      tickTimer += 1.0;
    }

    return duration > 0;
  }

  @override
  void refresh(StatusEffect newEffect) {
    duration = maxDuration;
    // Se o novo efeito aplicar uma queimadura mais forte, atualiza o dps
    if (newEffect is BurningEffect && newEffect.dps > dps) {
      dps = newEffect.dps;
    }
  }

  @override
  void renderIcon(Canvas canvas, Offset offset, double size) {
    // Desenha círculo laranja com chama amarela
    final paint = Paint()
      ..color = Colors.orange.shade700
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = Colors.red.shade900
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final center = offset + Offset(size / 2, size / 2);
    canvas.drawCircle(center, size / 2, paint);
    canvas.drawCircle(center, size / 2, borderPaint);

    // Símbolo de chama
    final flamePaint = Paint()
      ..color = Colors.yellowAccent
      ..style = PaintingStyle.fill;

    final flamePath = Path()
      ..moveTo(center.dx, center.dy - size / 2 + 2)
      ..quadraticBezierTo(center.dx + size / 4, center.dy, center.dx, center.dy + size / 2 - 2)
      ..quadraticBezierTo(center.dx - size / 4, center.dy + size / 4, center.dx - size / 6, center.dy - size / 6)
      ..close();

    canvas.drawPath(flamePath, flamePaint);
  }
}
