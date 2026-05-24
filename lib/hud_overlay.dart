import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'main.dart';

class GameHud extends StatelessWidget {
  final CloroquinildoGame game;

  const GameHud({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final state = game.gameState;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Stack(
        children: [
          // Painel Superior (Recursos e Status)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Botão de Voltar para Seleção de Fases
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.cyanAccent, size: 18),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withOpacity(0.5),
                    padding: const EdgeInsets.all(10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.cyanAccent.withOpacity(0.3)),
                    ),
                  ),
                ),
                // Pixcoins
                ValueListenableBuilder<int>(
                  valueListenable: state.pixcoins,
                  builder: (context, coins, _) {
                    return _buildStatChip(
                      icon: Icons.monetization_on,
                      iconColor: Colors.amberAccent,
                      text: '$coins PX',
                      bgColor: Colors.amber.shade900.withOpacity(0.3),
                      borderColor: Colors.amberAccent,
                    );
                  },
                ),
                // Wave counter
                ValueListenableBuilder<int>(
                  valueListenable: state.wave,
                  builder: (context, waveVal, _) {
                    return _buildStatChip(
                      icon: Icons.grid_view_rounded,
                      iconColor: Colors.cyanAccent,
                      text: 'Wave $waveVal/${state.maxWaves}',
                      bgColor: Colors.cyan.shade900.withOpacity(0.3),
                      borderColor: Colors.cyanAccent,
                    );
                  },
                ),
                // Cercadinho HP
                ValueListenableBuilder<int>(
                  valueListenable: state.cercadinhoHp,
                  builder: (context, hp, _) {
                    return _buildStatChip(
                      icon: Icons.shield,
                      iconColor: Colors.redAccent,
                      text: '$hp/${state.maxCercadinhoHp} HP',
                      bgColor: Colors.red.shade900.withOpacity(0.3),
                      borderColor: Colors.redAccent,
                    );
                  },
                ),
              ],
            ),
          ),

          // Painel Inferior (Botão de Start Wave e Info de Compra)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Info do Custo da Torre
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blueAccent.withOpacity(0.4)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_circle_outline, color: Colors.cyanAccent, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Torre Taokey: 100 PX (Clique nos slots + para construir)',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                
                // Botão de Próxima Wave
                ValueListenableBuilder2<bool, int>(
                  first: state.waveInProgress,
                  second: state.wave,
                  builder: (context, inProgress, waveVal, _) {
                    final isLastWave = waveVal >= state.maxWaves;
                    final buttonText = isLastWave ? 'Última Wave!' : 'Soltar Goblins! (Wave ${waveVal + 1})';
                    final canStart = !inProgress && !isLastWave;

                    return AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: canStart ? 1.0 : 0.5,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.greenAccent, Colors.teal],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.greenAccent.withOpacity(0.4),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: canStart ? () => game.startNextWave() : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Text(
                            inProgress ? 'Wave em Andamento...' : buttonText,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required Color iconColor,
    required String text,
    required Color bgColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor.withOpacity(0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: borderColor.withOpacity(0.15),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

// Overlay de Fim de Jogo
class GameOverOverlay extends StatelessWidget {
  final CloroquinildoGame game;

  const GameOverOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.85),
      child: Center(
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.grey.shade900.withOpacity(0.9),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.redAccent, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.redAccent.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.gavel_rounded, size: 64, color: Colors.redAccent),
              const SizedBox(height: 16),
              const Text(
                'FIM DE JOGO!',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'O Cercadinho caiu! Os sindicalistas confiscaram seus Pixcoins e estatizaram suas torres!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => game.restartGame(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Tentar de Novo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Overlay de Vitória
class VictoryOverlay extends StatelessWidget {
  final CloroquinildoGame game;

  const VictoryOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.85),
      child: Center(
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.grey.shade900.withOpacity(0.9),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.greenAccent, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.greenAccent.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.thumb_up_alt_rounded, size: 64, color: Colors.greenAccent),
              const SizedBox(height: 16),
              const Text(
                'VITÓRIA TAOKEY!',
                style: TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Você defendeu o Cercadinho com maestria e os Pixcoins estão seguros! O Bananil respira aliviado por enquanto.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => game.restartGame(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Jogar Novamente',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget auxiliar para escutar dois ValueNotifiers simultaneamente
class ValueListenableBuilder2<A, B> extends StatelessWidget {
  final ValueListenable<A> first;
  final ValueListenable<B> second;
  final Widget Function(BuildContext context, A a, B b, Widget? child) builder;
  final Widget? child;

  const ValueListenableBuilder2({
    super.key,
    required this.first,
    required this.second,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<A>(
      valueListenable: first,
      builder: (context, a, _) {
        return ValueListenableBuilder<B>(
          valueListenable: second,
          builder: (context, b, _) {
            return builder(context, a, b, child);
          },
        );
      },
    );
  }
}
