import 'package:flutter_test/flutter_test.dart';
import 'package:cloroquinildo_td/main.dart';

void main() {
  test('Smoke test - CloroquinildoGame instantiation', () {
    final game = CloroquinildoGame();
    expect(game, isNotNull);
  });
}
