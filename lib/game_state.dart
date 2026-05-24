import 'package:flutter/foundation.dart';

class GameState {
  final ValueNotifier<int> pixcoins = ValueNotifier<int>(250);
  final ValueNotifier<int> cercadinhoHp = ValueNotifier<int>(20);
  final ValueNotifier<int> wave = ValueNotifier<int>(0);
  final ValueNotifier<bool> waveInProgress = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isGameOver = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isVictory = ValueNotifier<bool>(false);

  final int maxWaves = 5;
  final int maxCercadinhoHp = 20;

  void reset() {
    pixcoins.value = 250;
    cercadinhoHp.value = 20;
    wave.value = 0;
    waveInProgress.value = false;
    isGameOver.value = false;
    isVictory.value = false;
  }

  void addPixcoins(int amount) {
    pixcoins.value += amount;
  }

  bool buy(int cost) {
    if (pixcoins.value >= cost) {
      pixcoins.value -= cost;
      return true;
    }
    return false;
  }

  void takeBaseDamage(int damage) {
    if (isGameOver.value || isVictory.value) return;
    
    cercadinhoHp.value = (cercadinhoHp.value - damage).clamp(0, maxCercadinhoHp);
    if (cercadinhoHp.value <= 0) {
      isGameOver.value = true;
      waveInProgress.value = false;
    }
  }

  void startNextWave() {
    if (wave.value < maxWaves && !waveInProgress.value) {
      wave.value += 1;
      waveInProgress.value = true;
    }
  }

  void endWave() {
    waveInProgress.value = false;
    if (wave.value >= maxWaves && cercadinhoHp.value > 0) {
      isVictory.value = true;
    }
  }
}
