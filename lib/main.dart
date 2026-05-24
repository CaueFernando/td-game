import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';

import 'path_config.dart';
import 'game_state.dart';
import 'enemy.dart';
import 'tower.dart';

import 'screens/presentation_screen.dart';
import 'screens/login_screen.dart';
import 'screens/level_select_screen.dart';
import 'screens/game_play_screen.dart';

// Classe principal do Motor do Jogo
class CloroquinildoGame extends FlameGame with TapCallbacks, DragCallbacks {
  final int level;
  final GameState gameState = GameState();
  late List<Vector2> enemyPath;

  CloroquinildoGame({this.level = 1});

  // Lógica de spawning de ondas
  int enemiesToSpawn = 0;
  int activeEnemiesCount = 0;
  double spawnTimer = 0.0;
  double spawnInterval = 0.8;
  double enemyHpMultiplier = 1.0;
  double enemySpeedMultiplier = 1.0;
  double waveTimerValue = 30.0;

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Configura o número máximo de waves de acordo com a fase
    gameState.maxWaves = (level == 2) ? 7 : 5;

    // Obtém o caminho dos inimigos
    enemyPath = PathConfig.getPoints(level, size);

    // Registra ouvintes para mudanças de estado cruciais
    gameState.isGameOver.addListener(_onGameOverChanged);
    gameState.isVictory.addListener(_onVictoryChanged);

    // Inicializa o painel da Loja de Torres
    add(TowerShop());
  }

  // Helper para spawnar texto flutuante de feedback
  void showFloatingText(String message, Vector2 pos, Color color) {
    add(FloatingText(message, pos, color));
  }

  // Inicia a próxima wave
  void startNextWave() {
    if (gameState.waveInProgress.value) return;

    gameState.startNextWave();
    waveTimerValue = 30.0;
    gameState.waveTimer.value = 30.0;
    
    final currentWave = gameState.wave.value;
    // Dificuldade progressiva: 10% a mais de HP por wave
    enemiesToSpawn = 5 + (currentWave - 1) * 3;
    enemyHpMultiplier = 1.0 + (currentWave - 1) * 0.10;
    enemySpeedMultiplier = 1.0 + (currentWave - 1) * 0.15;
    spawnTimer = 0.0;
    activeEnemiesCount = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Gerenciador de spawning de inimigos
    if (gameState.waveInProgress.value && enemiesToSpawn > 0) {
      spawnTimer -= dt;
      if (spawnTimer <= 0) {
        final goblin = GoblinSindicalista(
          path: enemyPath,
          hpMultiplier: enemyHpMultiplier,
          speedMultiplier: enemySpeedMultiplier,
        );
        add(goblin);
        enemiesToSpawn--;
        activeEnemiesCount++;
        spawnTimer = spawnInterval;
      }
    }

    // Gerenciador de auto-start da wave (a cada 30 segundos)
    if (!gameState.waveInProgress.value && gameState.wave.value < gameState.maxWaves && !gameState.isGameOver.value && !gameState.isVictory.value) {
      waveTimerValue -= dt;
      if (waveTimerValue <= 0) {
        startNextWave();
      } else {
        gameState.waveTimer.value = waveTimerValue;
      }
    } else {
      waveTimerValue = 30.0;
      gameState.waveTimer.value = 30.0;
    }
  }

  // Verifica se todos os inimigos foram derrotados para finalizar a wave
  void checkWaveCompletion() {
    activeEnemiesCount--;
    if (enemiesToSpawn == 0 && activeEnemiesCount <= 0 && gameState.waveInProgress.value) {
      activeEnemiesCount = 0;
      gameState.endWave();
    }
  }

  // Evento ao alterar estado de Game Over
  void _onGameOverChanged() {
    if (gameState.isGameOver.value) {
      overlays.add('GameOver');
    } else {
      overlays.remove('GameOver');
    }
  }

  // Evento ao alterar estado de Vitória
  void _onVictoryChanged() {
    if (gameState.isVictory.value) {
      overlays.add('Victory');
    } else {
      overlays.remove('Victory');
    }
  }

  // Reseta todo o jogo para jogar novamente
  void restartGame() {
    // Remove inimigos, projéteis e torres
    children.whereType<Enemy>().forEach((e) => e.removeFromParent());
    children.whereType<Tower>().forEach((t) => t.removeFromParent());
    children.whereType<FloatingText>().forEach((f) => f.removeFromParent());

    // Reseta estado
    gameState.reset();
    activeEnemiesCount = 0;
    enemiesToSpawn = 0;
    waveTimerValue = 30.0;
    gameState.waveTimer.value = 30.0;

    // Remove Overlays de fim de jogo
    overlays.remove('GameOver');
    overlays.remove('Victory');
  }

  @override
  void render(Canvas canvas) {
    final scaleFactor = zoomFactor;
    final centerOffset = (size - size * scaleFactor) / 2;

    canvas.save();
    canvas.translate(centerOffset.x, centerOffset.y);
    canvas.scale(scaleFactor);

    // Desenha o fundo tecnológico escuro do Bananil
    canvas.drawColor(const Color(0xFF0F172A), BlendMode.src);

    // Desenha uma grade cibernética sutil no fundo
    final gridPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..strokeWidth = 1.0;
    const gridSpacing = 40.0;
    for (double x = 0; x < size.x; x += gridSpacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.y), gridPaint);
    }
    for (double y = 0; y < size.y; y += gridSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.x, y), gridPaint);
    }

    // Desenha o caminho dos inimigos
    if (enemyPath.isNotEmpty) {
      final pathPaint = Paint()
        ..color = const Color(0xFFEF4444).withOpacity(0.2) // Área de perigo vermelha
        ..strokeWidth = 32.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final neonPaint = Paint()
        ..color = const Color(0xFFF87171) // Linha neon centralizada
        ..strokeWidth = 4.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      // Desenha o trajeto baseado nos checkpoints
      final path = Path();
      path.moveTo(enemyPath[0].x, enemyPath[0].y);
      for (int i = 1; i < enemyPath.length; i++) {
        path.lineTo(enemyPath[i].x, enemyPath[i].y);
      }
      canvas.drawPath(path, pathPaint);
      canvas.drawPath(path, neonPaint);
    }

    // Desenha o "Cercadinho" no final do caminho
    final lastPoint = enemyPath.last;
    final basePaint = Paint()
      ..color = Colors.greenAccent
      ..style = PaintingStyle.fill;
    
    // Brilho do Cercadinho
    final baseGlowPaint = Paint()
      ..color = Colors.greenAccent.withOpacity(0.4)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    
    canvas.drawCircle(Offset(lastPoint.x, lastPoint.y), 32, baseGlowPaint);
    canvas.drawCircle(Offset(lastPoint.x, lastPoint.y), 24, basePaint);

    // Contorno do Cercadinho
    final baseBorderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawCircle(Offset(lastPoint.x, lastPoint.y), 24, baseBorderPaint);

    // Texto descritivo no Cercadinho
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'Cercadinho',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Colors.black, blurRadius: 4)],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(lastPoint.x - textPainter.width / 2, lastPoint.y - textPainter.height / 2));

    super.render(canvas);

    canvas.restore();
  }

  // Fecha menus de upgrade abertos ao clicar no chão
  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    if (event.handled) return;

    for (final tower in children.whereType<Tower>()) {
      tower.showRange = false;
    }
  }

  // Valida se o local tocado é apropriado para construir uma torre
  bool isValidTowerPosition(Vector2 pos) {
    // 1. Limites da tela para não sobrepor o HUD
    if (pos.x < 20 || pos.x > size.x - 20) return false;
    if (pos.y < 60 || pos.y > size.y - 85) return false;

    // Evita construir em cima do painel da loja
    if (pos.x > size.x - 120 && pos.y > size.y - 200) return false;

    // 2. Evita construir muito perto da rota (danger zone do path)
    for (int i = 0; i < enemyPath.length - 1; i++) {
      final a = enemyPath[i];
      final b = enemyPath[i + 1];
      if (_distanceToSegment(pos, a, b) < 35.0) {
        return false;
      }
    }

    // 3. Evita construir muito perto do Cercadinho
    if (enemyPath.isNotEmpty) {
      final lastPoint = enemyPath.last;
      if ((pos - lastPoint).length < 44.0) {
        return false;
      }
    }

    // 4. Evita construir em cima de outras torres (colisão de 40px)
    final existingTowers = children.whereType<Tower>();
    for (final tower in existingTowers) {
      if ((pos - tower.position).length < 40.0) {
        return false;
      }
    }

    return true;
  }

  double _distanceToSegment(Vector2 p, Vector2 a, Vector2 b) {
    final ab = b - a;
    final ap = p - a;
    final abLenSq = ab.length2;
    if (abLenSq == 0.0) return (p - a).length;
    
    final t = (ap.dot(ab) / abLenSq).clamp(0.0, 1.0);
    final closestPoint = a + ab * t;
    return (p - closestPoint).length;
  }

  double get zoomFactor => (level == 2) ? 0.82 : 0.90;

  @override
  Vector2 convertGlobalToLocalCoordinate(Vector2 point) {
    final localPoint = super.convertGlobalToLocalCoordinate(point);
    final scaleFactor = zoomFactor;
    final centerOffset = (canvasSize - canvasSize * scaleFactor) / 2;
    return (localPoint - centerOffset) / scaleFactor;
  }

  @override
  void onRemove() {
    gameState.isGameOver.removeListener(_onGameOverChanged);
    gameState.isVictory.removeListener(_onVictoryChanged);
    super.onRemove();
  }
}

// Componente para desenhar texto flutuante (Ex: "+15 PX", "Sem Pixcoins!")
class FloatingText extends PositionComponent {
  final String text;
  final Color color;
  double lifespan = 1.0;
  double speed = 50.0;

  FloatingText(this.text, Vector2 pos, this.color) {
    position = pos.clone();
    anchor = Anchor.center;
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.y -= speed * dt;
    lifespan -= dt;
    if (lifespan <= 0) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color.withOpacity(lifespan.clamp(0.0, 1.0)),
          fontSize: 14,
          fontWeight: FontWeight.bold,
          shadows: const [
            Shadow(blurRadius: 3, color: Colors.black, offset: Offset(1, 1))
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
  }
}

// Inicialização do Flutter
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Força orientação em paisagem (Landscape) para melhor experiência de gameplay
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Desativa a barra de navegação/status para tela cheia
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'Roboto', // Usa fonte moderna padrão
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const PresentationScreen(),
        '/login': (context) => const LoginScreen(),
        '/level_select': (context) => const LevelSelectScreen(),
        '/game_play': (context) => const GamePlayScreen(),
      },
    ),
  );
}