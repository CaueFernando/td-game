import 'package:flame/components.dart';

class PathConfig {
  // Retorna os pontos do caminho baseado na fase
  static List<Vector2> getPoints(int level, Vector2 screenSize) {
    final w = screenSize.x;
    final h = screenSize.y;

    if (level == 2) {
      // Rota diferente e maior (com mais curvas)
      return [
        Vector2(-50, h * 0.20),        // Spawn fora do limite esquerdo
        Vector2(w * 0.18, h * 0.20),   // Checkpoint 1
        Vector2(w * 0.18, h * 0.80),   // Checkpoint 2
        Vector2(w * 0.40, h * 0.80),   // Checkpoint 3
        Vector2(w * 0.40, h * 0.35),   // Checkpoint 4
        Vector2(w * 0.70, h * 0.35),   // Checkpoint 5
        Vector2(w * 0.70, h * 0.80),   // Checkpoint 6
        Vector2(w + 50, h * 0.80),     // Fim do caminho (sai pela direita)
      ];
    }

    // Rota padrão da Fase 1 (Praça dos Três Podres)
    return [
      Vector2(-50, h * 0.30),          // Spawn fora do limite esquerdo
      Vector2(w * 0.23, h * 0.30),     // Checkpoint 1
      Vector2(w * 0.23, h * 0.85),     // Checkpoint 2
      Vector2(w * 0.65, h * 0.85),     // Checkpoint 3
      Vector2(w * 0.65, h * 0.50),     // Checkpoint 4
      Vector2(w + 50, h * 0.50),       // Fim do caminho (sai pela direita)
    ];
  }
}
