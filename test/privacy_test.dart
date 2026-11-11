// O Chirp não fala com ninguém além dos contatos: nada de pacote que busca coisas na
// rede por conta própria, nem endereço de serviço no código. E as cores vêm do tema.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

List<File> _dart(String dir) => [
  for (final file in Directory(dir).listSync(recursive: true))
    if (file is File &&
        file.path.endsWith('.dart') &&
        !file.path.contains(
          '${Platform.pathSeparator}bridge${Platform.pathSeparator}',
        ))
      file,
];

void main() {
  test('nenhuma dependência que chama a rede sozinha', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    for (final package in const [
      'google_fonts',
      'http:',
      'dio:',
      'peerdart',
      'firebase',
      'sentry',
      'cached_network_image',
    ]) {
      expect(pubspec, isNot(contains(package)), reason: package);
    }
  });

  test('nenhum endereço da web no código', () {
    final url = RegExp(r'''['"]https?://''');
    final found = [
      for (final file in _dart('lib'))
        if (url.hasMatch(file.readAsStringSync())) file.path,
    ];
    expect(found, isEmpty);
  });

  test('os widgets pegam as cores do tema', () {
    final found = [
      for (final file in _dart('lib/src/ui'))
        if (!file.path.contains(
              '${Platform.pathSeparator}theme${Platform.pathSeparator}',
            ) &&
            RegExp(r'Colors\.|Color\(0x').hasMatch(file.readAsStringSync()))
          file.path,
    ];
    expect(found, isEmpty);
  });

  test('o botão secundário é o tonal, e o terciário o de texto', () {
    final found = [
      for (final file in _dart('lib/src/ui'))
        if (RegExp(r'OutlinedButton|ElevatedButton')
            .hasMatch(file.readAsStringSync()))
          file.path,
    ];
    expect(found, isEmpty);
  });
}
