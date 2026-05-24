import 'package:flame/components.dart';

class PathConfig {
  // Retorna os pontos do caminho baseado na fase
  static List<Vector2> getPoints(int level, Vector2 screenSize) {
    if (level == 2) {
      // Rota diferente e maior (com mais curvas)
      return [
        Vector2(-50, 100),   // Spawn fora da tela à esquerda
        Vector2(150, 100),   // Primeiro checkpoint (vai pra direita)
        Vector2(150, 500),   // Segundo checkpoint (vai pra baixo)
        Vector2(350, 500),   // Terceiro checkpoint (vai pra direita)
        Vector2(350, 200),   // Quarto checkpoint (vai pra cima)
        Vector2(600, 200),   // Quinto checkpoint (vai pra direita)
        Vector2(600, 500),   // Sexto checkpoint (vai pra baixo)
        Vector2(850, 500),   // Fim do caminho (sai pela direita)
      ];
    }

    // Rota padrão da Fase 1 (Praça dos Três Podres)
    return [
      Vector2(-50, 150),    // Spawn fora da tela à esquerda
      Vector2(200, 150),   // Primeiro checkpoint (vai pra direita)
      Vector2(200, 450),   // Segundo checkpoint (vai pra baixo)
      Vector2(550, 450),   // Terceiro checkpoint (vai pra direita)
      Vector2(550, 250),   // Quarto checkpoint (vai pra cima)
      Vector2(850, 250),   // Fim do caminho (sai pela direita da tela)
    ];
  }
}
