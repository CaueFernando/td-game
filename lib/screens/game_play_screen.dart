import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import '../main.dart';
import '../hud_overlay.dart';

class GamePlayScreen extends StatefulWidget {
  const GamePlayScreen({super.key});

  @override
  State<GamePlayScreen> createState() => _GamePlayScreenState();
}

class _GamePlayScreenState extends State<GamePlayScreen> {
  late CloroquinildoGame _game;

  @override
  void initState() {
    super.initState();
    _game = CloroquinildoGame();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WillPopScope(
        onWillPop: () async {
          // Previne pop acidental e limpa recursos se necessário
          return true;
        },
        child: GameWidget(
          game: _game,
          overlayBuilderMap: {
            'HUD': (context, CloroquinildoGame game) => GameHud(game: game),
            'GameOver': (context, CloroquinildoGame game) => GameOverOverlay(game: game),
            'Victory': (context, CloroquinildoGame game) => VictoryOverlay(game: game),
          },
          initialActiveOverlays: const ['HUD'],
        ),
      ),
    );
  }
}
