import 'package:flame/components.dart';

class PathConfig {
  // Retorna os pontos do caminho para o mapa "Praça dos Três Podres"
  static List<Vector2> getPoints(Vector2 screenSize) {
    // Definimos pontos proporcionais ao tamanho lógico da tela (ex: 800 x 600)
    // Se a tela for diferente, podemos escalar. Mas para garantir precisão,
    // usaremos coordenadas baseadas em uma tela virtual de 800x600.
    final List<Vector2> basePoints = [
      Vector2(-50, 150),    // Spawn fora da tela à esquerda
      Vector2(200, 150),   // Primeiro checkpoint (vai pra direita)
      Vector2(200, 450),   // Segundo checkpoint (vai pra baixo)
      Vector2(550, 450),   // Terceiro checkpoint (vai pra direita)
      Vector2(550, 250),   // Quarto checkpoint (vai pra cima)
      Vector2(850, 250),   // Fim do caminho (sai pela direita da tela)
    ];

    return basePoints;
  }
}
