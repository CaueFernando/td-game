import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame_audio/flame_audio.dart';

import 'path_config.dart';
import 'game_state.dart';
import 'enemies/enemies.dart';
import 'towers/towers.dart';

import 'screens/presentation_screen.dart';
import 'screens/login_screen.dart';
import 'screens/level_select_screen.dart';
import 'screens/game_play_screen.dart';

import 'dart:math';

// Classe principal do Motor do Jogo
class CloroquinildoGame extends FlameGame with TapCallbacks, DragCallbacks {
  final int level;
  final GameState gameState = GameState();
  late List<Vector2> enemyPath;
  late Vector2 worldSize;
  final Vector2 cameraOffset = Vector2.zero();
  bool isDraggingTower = false;
  final Map<String, DateTime> _lastPlayedSfx = {};
  final Map<String, AudioPool> _sfxPools = {};
  int activeBossesCount = 0;
  final ValueNotifier<Tower?> selectedTower = ValueNotifier<Tower?>(null);
  Sprite? grassTileSprite;
  Sprite? dirtTileSprite;
  final Set<String> level3PathTiles = {};

  CloroquinildoGame({this.level = 1});

  // Lógica de spawning de ondas
  int enemiesToSpawn = 0;
  int activeEnemiesCount = 0;
  double spawnTimer = 0.0;
  //double spawnInterval = 0.8;
  double enemyHpMultiplier = 1.0;
  double enemySpeedMultiplier = 1.0;
  double waveTimerValue = 30.0;

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Inicializa o gerenciador de BGM do FlameAudio
    await FlameAudio.bgm.initialize();

    // Inicializa os pools de áudio para efeitos sonoros repetitivos
    await _initSfxPools([
      'zap.mp3',
      'burn.mp3',
      'freeze.mp3',
      'rock.mp3',
      'stone_impact.mp3',
      'enemy_die.mp3',
      'shoot.mp3',
      'upgrade.mp3',
      'sell.mp3',
      'click.mp3',
    ]);


    // Configura o tamanho expandido do mapa (1.8x o tamanho da tela)
    worldSize = size * 1.8;

    // Inicializa a câmera centralizada horizontal/verticalmente nas margens iniciais
    final scaleFactor = zoomFactor;
    final centerOffset = (size - size * scaleFactor) / 2;
    cameraOffset.setValues(-centerOffset.x, -centerOffset.y);

    // Carrega a imagem do mapa para faturar os tiles da fase 3 se necessário
    await images.load('tile_world_sprite.png');
    final tileWorldImage = images.fromCache('tile_world_sprite.png');
    grassTileSprite = Sprite(tileWorldImage, srcPosition: Vector2(0, 0), srcSize: Vector2(512, 512));
    dirtTileSprite = Sprite(tileWorldImage, srcPosition: Vector2(1024, 0), srcSize: Vector2(512, 512));

    // Inicializa a grade de caminho para a fase 3
    if (level == 3) {
      _generateLevel3PathTiles();
    }

    // Configura o número máximo de waves de acordo com a fase
    if (level == 3) {
      gameState.maxWaves = 12; // 12 waves para o nível 3
    } else if (level == 2) {
      gameState.maxWaves = 16;
    } else {
      gameState.maxWaves = 8;
    }

    // Obtém o caminho dos inimigos baseado no worldSize
    enemyPath = PathConfig.getPoints(level, worldSize);

    // Registra ouvintes para mudanças de estado cruciais
    gameState.isGameOver.addListener(_onGameOverChanged);
    gameState.isVictory.addListener(_onVictoryChanged);

    // Inicializa o painel da Loja de Torres
    add(TowerShop());

    // Pré-carrega os arquivos de música de fundo (BGM)
    _preloadAudioSafe([
      'bgm.mp3',
      'boss_bgm.mp3',
    ]);

    // Toca a música de fundo do jogo
    playBgm('bgm.mp3');
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    worldSize = size * 1.8;
    enemyPath = PathConfig.getPoints(level, worldSize);
    _clampCameraOffset();
  }

  // Helper para spawnar texto flutuante de feedback
  void showFloatingText(String message, Vector2 pos, Color color) {
    add(FloatingText(message, pos, color));
  }

  // Helper para spawnar números de dano flutuantes (Damage Popups)
  void showDamageNumber(double amount, Vector2 pos, Color color) {
    final text = amount % 1 == 0 ? amount.toInt().toString() : amount.toStringAsFixed(1);
    add(DamageText(text, pos, color));
  }

  // Reproduz som com segurança contra arquivos ausentes e com controle de cooldown para não sobrecarregar a memória
  // Inicializa pools de áudio para reciclagem rápida e evitar vazamento de memória
  Future<void> _initSfxPools(List<String> files) async {
    for (final file in files) {
      try {
        final pool = await FlameAudio.createPool(
          file,
          minPlayers: 1,
          maxPlayers: 5, // Limita players simultâneos por som
        );
        _sfxPools[file] = pool;
      } catch (e) {
        print('Aviso: Não foi possível criar pool para o áudio $file: $e');
      }
    }
  }

  void playSfx(String fileName) {
    // Cooldown específico para cada tipo de som (evita sobreposição excessiva de players de áudio)
    double cooldown = 0.15;
    if (fileName == 'shoot.mp3') cooldown = 0.18;
    if (fileName == 'zap.mp3') cooldown = 0.22;
    if (fileName == 'freeze.mp3') cooldown = 0.35;
    if (fileName == 'rock.mp3') cooldown = 0.25;
    if (fileName == 'stone_impact.mp3') cooldown = 0.25;
    if (fileName == 'enemy_die.mp3') cooldown = 0.15;
    if (fileName == 'burn.mp3') cooldown = 0.40;
    if (fileName == 'upgrade.mp3') cooldown = 0.10;
    if (fileName == 'sell.mp3') cooldown = 0.10;
    if (fileName == 'click.mp3') cooldown = 0.10;

    final now = DateTime.now();
    final lastPlayed = _lastPlayedSfx[fileName];

    if (lastPlayed != null) {
      final difference = now.difference(lastPlayed).inMilliseconds / 1000.0;
      if (difference < cooldown) {
        return; // Ignora o som se estiver dentro do período de cooldown
      }
    }

    _lastPlayedSfx[fileName] = now;

    try {
      final pool = _sfxPools[fileName];
      if (pool != null) {
        pool.start();
      } else {
        FlameAudio.play(fileName);
      }
    } catch (e) {
      // Ignora silenciosamente para não quebrar o gameplay se o arquivo não estiver presente
      print('Aviso: Erro ao reproduzir áudio $fileName: $e');
    }
  }

  // Pré-carregamento seguro de áudios
  Future<void> _preloadAudioSafe(List<String> files) async {
    for (final file in files) {
      try {
        await FlameAudio.audioCache.load(file);
      } catch (e) {
        print('Aviso: Não foi possível pré-carregar o áudio $file: $e');
      }
    }
  }

  // Reproduz música de fundo em loop de forma segura
  void playBgm(String fileName) {
    try {
      FlameAudio.bgm.play(fileName, volume: 0.25); // Volume mais baixo para não cobrir SFX
    } catch (e) {
      print('Aviso: Música de fundo $fileName não encontrada: $e');
    }
  }

  // Interrompe a música de fundo de forma segura
  void stopBgm() {
    try {
      FlameAudio.bgm.stop();
    } catch (e) {
      print('Aviso: Erro ao parar a música de fundo: $e');
    }
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

    // Spawn do Boss Sindicalista no final do nível (waves múltiplas de 8) ou na wave 1 para teste temporário
    if (currentWave == 1 || currentWave % 8 == 0) {
      final double bossHp = (currentWave == 1) 
          ? 250.0 // HP menor para teste rápido na wave 1
          : (currentWave == 8) ? 800.0 : 1600.0;
      final boss = SindicalistaBoss(
        path: enemyPath,
        hp: bossHp,
        speedMultiplier: 1.0,
      );
      add(boss);
      activeEnemiesCount++;
      activeBossesCount++;
      playBgm('boss_bgm.mp3');
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Gerenciador de spawning de inimigos
    if (gameState.waveInProgress.value && enemiesToSpawn > 0) {
      spawnTimer -= dt;
      if (spawnTimer <= 0) {
        // Desloca levemente o caminho no eixo Y para cada inimigo nascer em faixas/corredores diferentes
        final yOffset = (Random().nextDouble() - 0.5) * 16.0; // Deslocamento entre -8 e +8 pixels
        final shiftedPath = enemyPath.map((p) => Vector2(p.x, p.y + yOffset)).toList();

        final goblin = GoblinSindicalista(
          path: shiftedPath,
          hpMultiplier: enemyHpMultiplier,
          speedMultiplier: enemySpeedMultiplier,
        );
        add(goblin);
        enemiesToSpawn--;
        activeEnemiesCount++;
        spawnTimer = 0.3 + Random().nextDouble() * 0.8;
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
      stopBgm();
    } else {
      overlays.remove('GameOver');
    }
  }

  // Evento ao alterar estado de Vitória
  void _onVictoryChanged() {
    if (gameState.isVictory.value) {
      overlays.add('Victory');
      stopBgm();
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
    selectedTower.value = null;
    activeEnemiesCount = 0;
    enemiesToSpawn = 0;
    activeBossesCount = 0;
    waveTimerValue = 30.0;
    gameState.waveTimer.value = 30.0;

    // Reseta offset da câmera para os limites iniciais do mapa
    final scaleFactor = zoomFactor;
    final centerOffset = (size - size * scaleFactor) / 2;
    cameraOffset.setValues(-centerOffset.x, -centerOffset.y);

    // Remove Overlays de fim de jogo
    overlays.remove('GameOver');
    overlays.remove('Victory');

    // Reinicia a música de fundo
    playBgm('bgm.mp3');
  }

  @override
  void render(Canvas canvas) {
    // Desenha o fundo tecnológico escuro do Bananil (independente da câmera)
    canvas.drawColor(const Color(0xFF0F172A), BlendMode.src);

    final scaleFactor = zoomFactor;
    final centerOffset = (size - size * scaleFactor) / 2;

    canvas.save();
    canvas.translate(centerOffset.x + cameraOffset.x, centerOffset.y + cameraOffset.y);
    canvas.scale(scaleFactor);

    if (level == 3 && grassTileSprite != null && dirtTileSprite != null) {
      final tileWidth = worldSize.x / 24;
      final tileHeight = worldSize.y / 14;
      for (int x = 0; x < 24; x++) {
        for (int y = 0; y < 14; y++) {
          final pos = Vector2(x * tileWidth, y * tileHeight);
          final size = Vector2(tileWidth + 0.5, tileHeight + 0.5); // Sobreposição sutil para evitar emendas
          final isPath = level3PathTiles.contains('$x,$y');
          final sprite = isPath ? dirtTileSprite! : grassTileSprite!;
          sprite.render(canvas, position: pos, size: size);
        }
      }
    } else {
      // Desenha uma grade cibernética sutil no fundo cobrindo todo o worldSize
      final gridPaint = Paint()
        ..color = const Color(0xFF1E293B)
        ..strokeWidth = 1.0;
      const gridSpacing = 40.0;
      for (double x = 0; x < worldSize.x; x += gridSpacing) {
        canvas.drawLine(Offset(x, 0), Offset(x, worldSize.y), gridPaint);
      }
      for (double y = 0; y < worldSize.y; y += gridSpacing) {
        canvas.drawLine(Offset(0, y), Offset(worldSize.x, y), gridPaint);
      }
    }

    // Desenha o caminho dos inimigos
    if (enemyPath.isNotEmpty) {
      final pathPaint = Paint()
        ..color = const Color(0xFFEF4444).withValues(alpha: 0.2) // Área de perigo vermelha
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
      ..color = Colors.greenAccent.withValues(alpha: 0.4)
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
    // Converte a posição local do mundo para coordenadas da tela para colisão com HUD
    final screenPos = convertLocalToScreenCoordinate(pos);

    // 1. Limites da tela para não sobrepor o HUD (usando coordenadas da tela)
    if (screenPos.x < 20 || screenPos.x > size.x - 20) return false;
    if (screenPos.y < 60 || screenPos.y > size.y - 85) return false;

    // Evita construir em cima do painel da loja (que agora tem largura 435, pos.x = size.x - 450)
    if (screenPos.x > size.x - 460 && screenPos.y > size.y - 200) return false;

    // Limites lógicos do mundo expandido (usando coordenadas locais)
    if (pos.x < 0 || pos.x > worldSize.x) return false;
    if (pos.y < 0 || pos.y > worldSize.y) return false;

    // 2. Evita construir muito perto da rota (danger zone do path)
    if (level == 3) {
      final col = (pos.x / worldSize.x * 24).floor().clamp(0, 23);
      final row = (pos.y / worldSize.y * 14).floor().clamp(0, 13);
      if (level3PathTiles.contains('$col,$row')) {
        return false;
      }
    } else {
      for (int i = 0; i < enemyPath.length - 1; i++) {
        final a = enemyPath[i];
        final b = enemyPath[i + 1];
        if (_distanceToSegment(pos, a, b) < 35.0) {
          return false;
        }
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

  double get zoomFactor => (level >= 2) ? 0.82 : 0.90;

  @override
  Vector2 convertGlobalToLocalCoordinate(Vector2 point) {
    final localPoint = super.convertGlobalToLocalCoordinate(point);
    final scaleFactor = zoomFactor;
    final centerOffset = (canvasSize - canvasSize * scaleFactor) / 2;
    return (localPoint - centerOffset - cameraOffset) / scaleFactor;
  }

  Vector2 convertLocalToScreenCoordinate(Vector2 localPos) {
    final scaleFactor = zoomFactor;
    final centerOffset = (size - size * scaleFactor) / 2;
    return centerOffset + cameraOffset + localPos * scaleFactor;
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    // Só move a câmera se não estiver arrastando uma torre da loja
    if (!isDraggingTower) {
      cameraOffset.add(event.canvasDelta / zoomFactor);
      _clampCameraOffset();
    }
  }

  void _clampCameraOffset() {
    final scaleFactor = zoomFactor;
    final centerOffset = (size - size * scaleFactor) / 2;

    // Margens extras de segurança para não esconder totalmente as bordas do mundo
    final minX = size.x - centerOffset.x - (worldSize.x * scaleFactor);
    final maxX = -centerOffset.x;
    
    final minY = size.y - centerOffset.y - (worldSize.y * scaleFactor);
    final maxY = -centerOffset.y;

    cameraOffset.x = cameraOffset.x.clamp(minX, maxX);
    cameraOffset.y = cameraOffset.y.clamp(minY, maxY);
  }

  void _generateLevel3PathTiles() {
    level3PathTiles.clear();
    final checkpoints = [
      const Point(0, 4),
      const Point(6, 4),
      const Point(6, 10),
      const Point(16, 10),
      const Point(16, 3),
      const Point(23, 3),
    ];

    for (int i = 0; i < checkpoints.length - 1; i++) {
      final p1 = checkpoints[i];
      final p2 = checkpoints[i + 1];

      final startX = min(p1.x, p2.x);
      final endX = max(p1.x, p2.x);
      final startY = min(p1.y, p2.y);
      final endY = max(p1.y, p2.y);

      for (int x = startX; x <= endX; x++) {
        for (int y = startY; y <= endY; y++) {
          level3PathTiles.add('$x,$y');
        }
      }
    }
  }

  @override
  void onRemove() {
    gameState.isGameOver.removeListener(_onGameOverChanged);
    gameState.isVictory.removeListener(_onVictoryChanged);
    stopBgm();
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

// Componente altamente otimizado para números de dano flutuantes (Damage Popups)
class DamageText extends PositionComponent {
  final String text;
  final Color color;
  double lifespan = 0.6; // Curta duração (600ms) para não acumular
  final double maxLifespan = 0.6;
  final double speed = 40.0; // Velocidade que sobe

  DamageText(this.text, Vector2 pos, this.color) {
    // Adiciona uma leve dispersão randômica no X e Y para evitar sobreposição perfeita
    final random = Random();
    final scatterX = (random.nextDouble() - 0.5) * 16.0;
    final scatterY = (random.nextDouble() - 0.5) * 6.0;
    position = pos + Vector2(scatterX, -16.0 + scatterY); // Spawna um pouco acima do centro do inimigo
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
    final progress = lifespan / maxLifespan;
    final opacity = progress.clamp(0.0, 1.0);

    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color.withValues(alpha: opacity),
          fontSize: 11,
          fontWeight: FontWeight.w900,
          shadows: [
            Shadow(blurRadius: 2.0, color: Colors.black.withValues(alpha: opacity * 0.8), offset: const Offset(1, 1))
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