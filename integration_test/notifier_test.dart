// As notificações de verdade (no Linux, pelo D-Bus do servidor de notificações da
// sessão): prepara, mostra uma e tira. Aparece por um instante na tela.
//
//   flutter test integration_test/notifier_test.dart -d linux
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:psito_chirp/src/platform/notifier.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('mostra e tira uma notificação do sistema', (tester) async {
    final notifier = SystemNotifier();
    expect(await notifier.init(open: 'Abrir', channel: 'Mensagens'), isTrue);
    await notifier.show(contactId: 7, title: 'Psito Chirp', body: 'Teste');
    await Future<void>.delayed(const Duration(milliseconds: 500));
    await notifier.clear(7);
  });
}
