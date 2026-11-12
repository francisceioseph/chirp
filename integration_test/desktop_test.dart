// O desktop de verdade (no Linux, a bandeja pelo StatusNotifierItem do D-Bus): monta
// a bandeja, esconde e traz a janela, e tira a bandeja. O ícone aparece por um
// instante no painel. Não mexe no abrir com o computador, que grava na conta.
//
//   flutter test integration_test/desktop_test.dart -d linux
import 'dart:io';

import 'package:dbus/dbus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:psito_chirp/src/platform/background.dart';

/// Os ícones que o painel conhece (o StatusNotifierWatcher da sessão).
Future<List<String>> _registered() async {
  final bus = DBusClient.session();
  try {
    final value =
        await DBusRemoteObject(
          bus,
          name: 'org.kde.StatusNotifierWatcher',
          path: DBusObjectPath('/StatusNotifierWatcher'),
        ).getProperty(
          'org.kde.StatusNotifierWatcher',
          'RegisteredStatusNotifierItems',
        );
    return value.asStringArray().toList();
  } finally {
    await bus.close();
  }
}

/// Com a janela escondida não há quadros, e o `pump` esperaria para sempre.
Future<void> _wait() => Future<void>.delayed(const Duration(milliseconds: 300));

const BackgroundTexts _texts = (
  name: 'Psito Chirp',
  open: 'Abrir',
  quit: 'Sair',
  receiving: 'Recebendo mensagens',
  channel: 'Segundo plano',
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a bandeja e a janela', (_) async {
    final desktop = systemBackground();
    expect(desktop.supported, isTrue);
    await desktop.setup(keepRunning: true, texts: _texts);
    await _wait();
    // O ícone deste processo entrou no painel.
    expect(
      await _registered(),
      contains(contains('.StatusNotifierItem-$pid-')),
    );
    await desktop.hide();
    await _wait();
    await desktop.bringToFront();
    await _wait();
    await desktop.setup(keepRunning: false, texts: _texts);
  });
}
