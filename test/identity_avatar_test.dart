// O avatar gerado: espelhado, e o mesmo para a mesma semente.
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_chirp/src/ui/atoms/identity_avatar.dart';

void main() {
  test('a grade é espelhada', () {
    for (final seed in [0, 1, 0x5a5a5, 0x7fff, 0xdeadbeef]) {
      final cells = avatarCells(seed);
      expect(cells, hasLength(25));
      for (var row = 0; row < 5; row++) {
        expect(cells[row * 5], cells[row * 5 + 4]);
        expect(cells[row * 5 + 1], cells[row * 5 + 3]);
      }
    }
  });

  test('sementes diferentes dão desenhos diferentes', () {
    expect(avatarCells(0x1234), isNot(avatarCells(0x4321)));
    expect(avatarCells(0x1234), avatarCells(0x1234));
  });
}
