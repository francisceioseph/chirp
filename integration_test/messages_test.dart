// A fase 3 de ponta a ponta pela ponte: dois bancos de verdade no mesmo processo, cada
// um com o nó dele na rede local, viram contatos e conversam. Confere os tipos novos
// da ponte (mensagens, conversas, eventos) com o núcleo em Rust.
//
//   flutter test integration_test/messages_test.dart -d linux
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:psito_chirp/src/core/chirp_core.dart';

/// Espera até [ok] dizer que sim (a rede é de verdade).
Future<T> _until<T>(Future<T> Function() read, bool Function(T) ok) async {
  for (var i = 0; i < 100; i++) {
    final value = await read();
    if (ok(value)) return value;
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  fail('timed out');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('dois aparelhos conversam pela ponte', (tester) async {
    final tmp = await Directory.systemTemp.createTemp('chirp-messages-');
    addTearDown(() => tmp.delete(recursive: true));
    final alice = await BridgeCore.open(dir: '${tmp.path}/alice');
    final bob = await BridgeCore.open(dir: '${tmp.path}/bob');
    expect(alice.info, isNotNull);

    final a = await alice.openWithKey(alice.newStoreKey());
    final b = await bob.openWithKey(bob.newStoreKey());
    await a.createProfile('Alice');
    await b.createProfile('Bob');
    await a.startNetwork();
    await b.startNetwork();
    final aliceEvents = <CoreEvent>[];
    final subscription = a.events().listen(aliceEvents.add);
    addTearDown(subscription.cancel);

    // Bob lê o link de Alice.
    final link = await a.createInvite(qr: false);
    final aliceAtBob = await b.addContact(link, scanned: false);
    expect(aliceAtBob.displayName, 'Alice');
    expect(aliceAtBob.verified, isFalse);
    final bobAtAlice = (await _until(
      a.conversations,
      (list) => list.isNotEmpty,
    )).single.contact;
    expect(bobAtAlice.displayName, 'Bob');

    // Bob escreve; chega em Alice, não lida, e volta como entregue.
    final sent = await b.sendText(aliceAtBob.id, '  Oi, Alice!  ');
    expect(sent.text, 'Oi, Alice!');
    expect(sent.outgoing, isTrue);
    final atAlice = await _until(
      () => a.messages(bobAtAlice.id),
      (list) => list.isNotEmpty,
    );
    expect(atAlice.single.text, 'Oi, Alice!');
    expect(atAlice.single.unread, isTrue);
    expect(
      aliceEvents.any(
        (e) => e.kind == CoreEventKind.messages && e.contactId == bobAtAlice.id,
      ),
      isTrue,
    );
    expect((await a.conversations()).single.unread, 1);
    await _until(
      () => b.messages(aliceAtBob.id),
      (list) => list.single.status == MessageStatus.delivered,
    );

    // Alice lê e responde citando: o recibo e a resposta chegam a Bob.
    await a.markRead(bobAtAlice.id);
    await a.sendText(bobAtAlice.id, 'Oi, Bob', replyTo: atAlice.single.id);
    final atBob = await _until(
      () => b.messages(aliceAtBob.id),
      (list) => list.length == 2 && list.first.status == MessageStatus.read,
    );
    expect(atBob.last.text, 'Oi, Bob');
    expect(atBob.last.replyTo, atBob.first.id);

    // Reação, edição, chamar atenção e busca.
    await b.react(atBob.last.id, 2);
    await b.editMessage(atBob.first.id, 'Oi, Alice! Tudo bem?');
    await expectLater(
      b.sendNudge(aliceAtBob.id).then((_) => b.sendNudge(aliceAtBob.id)),
      throwsA(
        isA<CoreException>().having(
          (e) => e.failure,
          'failure',
          CoreFailure.tooSoon,
        ),
      ),
    );
    final updated = await _until(
      () => a.messages(bobAtAlice.id),
      (list) =>
          list.length == 3 &&
          list.first.edited &&
          list[1].theirReaction == 2 &&
          list.last.kind == MessageKind.nudge,
    );
    expect(updated.first.text, 'Oi, Alice! Tudo bem?');
    final found = await a.search('tudo');
    expect(found.single.id, updated.first.id);
    expect(await a.search('periquito'), isEmpty);

    final settings = await a.chatSettings();
    expect(settings.readReceipts, isTrue);
    await a.setChatSettings(
      const ChatSettings(readReceipts: false, typing: true),
    );
    expect((await a.chatSettings()).readReceipts, isFalse);

    await a.stopNetwork();
    await b.stopNetwork();
  });
}
