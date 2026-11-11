// As conversas da fase 3, com o núcleo falso: mandar e receber, os recibos, o
// "digitando", responder, editar, apagar, reagir, chamar atenção, a busca e os ajustes.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_chirp/l10n/chirp_localizations.dart';
import 'package:psito_chirp/src/core/chirp_core.dart';
import 'package:psito_chirp/src/ui/atoms/reaction_icon.dart';
import 'package:psito_chirp/src/ui/molecules/message_bubble.dart';

import 'helpers.dart';

void main() {
  final l10n = lookupChirpLocalizations(const Locale('pt'));

  setUp(() {
    // O Clipboard e o tremor do chamar atenção falam com a plataforma.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
  });

  /// O app aberto, com um contato e a conversa dele aberta.
  Future<(FakeStore, Contact)> chat(
    WidgetTester tester, {
    bool open = true,
  }) async {
    final (core, vault) = await withProfile();
    final contact = core.store!.befriend('Pérola');
    await pumpChirp(tester, core: core, vault: vault);
    if (open) {
      await tester.tap(find.text('Pérola'));
      await tester.pumpAndSettle();
    }
    return (core.store!, contact);
  }

  Future<void> write(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField), text);
    await tester.pump();
    await tester.tap(find.byTooltip(l10n.send));
    await tester.pumpAndSettle();
  }

  Future<void> options(WidgetTester tester, String text) async {
    await tester.longPress(find.text(text));
    await tester.pumpAndSettle();
  }

  testWidgets('mandar uma mensagem, e ver entregue e lida', (tester) async {
    final (store, contact) = await chat(tester);
    expect(find.text(l10n.conversationEmpty), findsOneWidget);
    await write(tester, '  Oi, Pérola!  ');
    expect(store.sent.single.text, 'Oi, Pérola!');
    expect(find.text('Oi, Pérola!'), findsOneWidget);
    expect(find.byIcon(Icons.schedule), findsOneWidget);

    store.deliver(contact.id);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.done), findsOneWidget);
    store.deliver(contact.id, read: true);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.done_all), findsOneWidget);

    // Na lista, a última mensagem aparece com o "Você".
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('${l10n.you}: Oi, Pérola!'), findsOneWidget);
  });

  testWidgets('o que chega fica não lido até abrir a conversa', (tester) async {
    final handle = tester.ensureSemantics();
    final (store, contact) = await chat(tester, open: false);
    store.incoming(contact.id, 'Tem alpiste?');
    store.incoming(contact.id, 'Responde!');
    await tester.pumpAndSettle();
    expect(find.text('Responde!'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp(RegExp.escape(l10n.unreadCount(2)))),
      findsOneWidget,
    );

    await tester.tap(find.text('Pérola'));
    await tester.pumpAndSettle();
    expect(find.text('Tem alpiste?'), findsOneWidget);
    expect(store.sent.every((m) => !m.unread), isTrue);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(
      find.bySemanticsLabel(RegExp(RegExp.escape(l10n.unreadCount(2)))),
      findsNothing,
    );

    // Com a conversa aberta, o que chega já entra lido.
    await tester.tap(find.text('Pérola'));
    await tester.pumpAndSettle();
    store.incoming(contact.id, 'Agora sim');
    await tester.pumpAndSettle();
    expect(find.text('Agora sim'), findsOneWidget);
    expect(store.sent.last.unread, isFalse);
    handle.dispose();
  });

  testWidgets('o digitando aparece e some', (tester) async {
    final (store, contact) = await chat(tester, open: false);
    store.theyType(contact.id);
    await tester.pump();
    await tester.pump();
    expect(find.text(l10n.typing), findsOneWidget);
    await tester.pump(const Duration(seconds: 7));
    expect(find.text(l10n.typing), findsNothing);

    await tester.tap(find.text('Pérola'));
    await tester.pumpAndSettle();
    store.theyType(contact.id);
    await tester.pump();
    await tester.pump();
    expect(find.text(l10n.typing), findsOneWidget);
    // A mensagem chegou: parou de digitar.
    store.incoming(contact.id, 'pronto');
    await tester.pumpAndSettle();
    expect(find.text(l10n.typing), findsNothing);

    // Eu digitando avisa, mas não a cada tecla.
    await tester.enterText(find.byType(TextField), 'a');
    await tester.enterText(find.byType(TextField), 'ab');
    await tester.enterText(find.byType(TextField), 'abc');
    await tester.pump();
    expect(store.typingCalls, 1);
  });

  testWidgets('responder cita a mensagem', (tester) async {
    final (store, contact) = await chat(tester, open: false);
    final question = store.incoming(contact.id, 'Qual a cor?');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pérola'));
    await tester.pumpAndSettle();
    await options(tester, 'Qual a cor?');
    await tester.tap(find.text(l10n.reply));
    await tester.pumpAndSettle();
    expect(find.text(l10n.replyingTo('Pérola')), findsOneWidget);
    await write(tester, 'Amarela');
    expect(store.sent.last.replyTo, question.id);
    expect(find.text(l10n.replyingTo('Pérola')), findsNothing);
    // A citação aparece na bolha da resposta, com a original em cima.
    expect(find.text('Qual a cor?'), findsNWidgets(2));
  });

  testWidgets('Esc larga a resposta e a edição', (tester) async {
    final (store, contact) = await chat(tester);
    store.incoming(contact.id, 'Qual a cor?');
    await tester.pumpAndSettle();
    await options(tester, 'Qual a cor?');
    await tester.tap(find.text(l10n.reply));
    await tester.pumpAndSettle();
    expect(find.text(l10n.replyingTo('Pérola')), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text(l10n.replyingTo('Pérola')), findsNothing);

    await write(tester, 'calopsta');
    await options(tester, 'calopsta');
    await tester.tap(find.text(l10n.editMessage));
    await tester.pumpAndSettle();
    expect(find.text(l10n.editingMessage), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text(l10n.editingMessage), findsNothing);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '',
    );
  });

  testWidgets('editar e apagar para todos as minhas', (tester) async {
    final (store, _) = await chat(tester);
    await write(tester, 'calopsta');
    await options(tester, 'calopsta');
    await tester.tap(find.text(l10n.editMessage));
    await tester.pumpAndSettle();
    expect(find.text(l10n.editingMessage), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'calopsita');
    await tester.pump();
    await tester.tap(find.byTooltip(l10n.save));
    await tester.pumpAndSettle();
    expect(store.sent.single.text, 'calopsita');
    expect(find.text(l10n.messageEdited), findsOneWidget);

    await options(tester, 'calopsita');
    await tester.tap(find.text(l10n.deleteForEveryone));
    await tester.pumpAndSettle();
    expect(store.sent.single.deleted, isTrue);
    expect(find.text(l10n.messageDeleted), findsOneWidget);
    // Uma apagada não tem mais o que editar, só apagar daqui.
    await options(tester, l10n.messageDeleted);
    expect(find.text(l10n.editMessage), findsNothing);
    expect(find.text(l10n.reply), findsNothing);
    await tester.tap(find.text(l10n.deleteForMe));
    await tester.pumpAndSettle();
    expect(store.sent, isEmpty);
  });

  testWidgets('a mensagem do contato não se edita', (tester) async {
    final (store, contact) = await chat(tester, open: false);
    store.incoming(contact.id, 'minha não');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pérola'));
    await tester.pumpAndSettle();
    await options(tester, 'minha não');
    expect(find.text(l10n.editMessage), findsNothing);
    expect(find.text(l10n.deleteForEveryone), findsNothing);
    expect(find.text(l10n.deleteForMe), findsOneWidget);
  });

  testWidgets('reagir e tirar a reação', (tester) async {
    final (store, contact) = await chat(tester, open: false);
    final hi = store.incoming(contact.id, 'Bom dia');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pérola'));
    await tester.pumpAndSettle();
    await options(tester, 'Bom dia');
    await tester.tap(find.byTooltip(reactionLabel(l10n, 2)));
    await tester.pumpAndSettle();
    expect(store.sent.single.myReaction, 2);
    expect(find.byIcon(reactionIcon(2)), findsOneWidget);
    // A mesma de novo tira.
    await options(tester, 'Bom dia');
    await tester.tap(find.byTooltip(reactionLabel(l10n, 2)));
    await tester.pumpAndSettle();
    expect(store.sent.single.myReaction, 0);

    store.theyReact(hi.id, 5);
    await tester.pumpAndSettle();
    expect(find.byIcon(reactionIcon(5)), findsOneWidget);
  });

  testWidgets('chamar atenção, com o limite de 10 segundos', (tester) async {
    final (store, contact) = await chat(tester);
    await tester.tap(find.byTooltip(l10n.nudge));
    await tester.pumpAndSettle();
    expect(find.textContaining(l10n.nudgeSent('Pérola')), findsOneWidget);
    await tester.tap(find.byTooltip(l10n.nudge));
    await tester.pumpAndSettle();
    expect(find.text(l10n.messageTooSoon), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));

    store.theyNudge(contact.id);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining(l10n.nudgeReceived('Pérola')), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('no computador, Enter manda e Shift+Enter quebra a linha', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final (store, _) = await chat(tester);
    await tester.showKeyboard(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'linha');
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
    expect(store.sent, isEmpty);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(store.sent.single.text, 'linha');
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('as opções de uma mensagem abrem pelo teclado', (tester) async {
    final (store, contact) = await chat(tester, open: false);
    store.incoming(contact.id, 'Pelo teclado');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pérola'));
    await tester.pumpAndSettle();
    // O foco do teclado na mensagem (o Tab chega nela do mesmo jeito).
    final inside = tester.element(
      find
          .descendant(
            of: find.byType(MessageBubble),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    Focus.of(inside).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text(l10n.reply), findsOneWidget);
  });

  testWidgets('a busca acha em todas as conversas e abre a certa', (
    tester,
  ) async {
    final (store, contact) = await chat(tester, open: false);
    final other = store.befriend('Canela');
    store.incoming(contact.id, 'O alpiste acabou');
    store.incoming(other.id, 'Comprei painço');
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(l10n.searchMessages));
    await tester.pumpAndSettle();
    expect(find.text(l10n.searchHelp), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'painço');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.text('Canela'), findsOneWidget);
    expect(find.text('Comprei painço'), findsOneWidget);
    expect(find.text('O alpiste acabou'), findsNothing);
    await tester.tap(find.text('Comprei painço'));
    await tester.pumpAndSettle();
    expect(find.byTooltip(l10n.nudge), findsOneWidget);
    expect(find.text('Comprei painço'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'periquito');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.text(l10n.searchNothing), findsOneWidget);
  });

  testWidgets('os recibos e o digitando se desligam no perfil', (tester) async {
    final (store, _) = await chat(tester, open: false);
    await tester.tap(find.byTooltip(l10n.profileTitle));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text(l10n.readReceipts));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.readReceipts));
    await tester.pumpAndSettle();
    expect(store.settings.readReceipts, isFalse);
    expect(store.settings.typing, isTrue);
    await tester.ensureVisible(find.text(l10n.typingIndicator));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.typingIndicator));
    await tester.pumpAndSettle();
    expect(store.settings.typing, isFalse);
  });

  // As telas novas na janela mínima e num celular pequeno, nos dois temas, com
  // contraste e rótulos.
  final screens =
      <String, Future<void> Function(WidgetTester, FakeStore, Contact)>{
        'lista com mensagens': (tester, store, contact) async {
          store.incoming(
            contact.id,
            'Uma mensagem bem comprida para caber mal',
          );
          await tester.pumpAndSettle();
        },
        'conversa': (tester, store, contact) async {
          final first = store.incoming(contact.id, 'Oi! Tudo bem por aí?');
          await tester.pumpAndSettle();
          await tester.tap(find.text('Pérola'));
          await tester.pumpAndSettle();
          await store.sendText(contact.id, 'Tudo, e aí?', replyTo: first.id);
          await store.react(first.id, 1);
          store.theyNudge(contact.id);
          await tester.pumpAndSettle();
        },
        'opções': (tester, store, contact) async {
          store.incoming(contact.id, 'Segura aqui');
          await tester.pumpAndSettle();
          await tester.tap(find.text('Pérola'));
          await tester.pumpAndSettle();
          await options(tester, 'Segura aqui');
        },
        'busca': (tester, store, contact) async {
          store.incoming(contact.id, 'alpiste');
          await tester.pumpAndSettle();
          await tester.tap(find.byTooltip(l10n.searchMessages));
          await tester.pumpAndSettle();
          await tester.enterText(find.byType(TextField), 'alp');
          await tester.pump(const Duration(milliseconds: 300));
          await tester.pumpAndSettle();
        },
        'perfil': (tester, store, contact) async {
          await tester.tap(find.byTooltip(l10n.profileTitle));
          await tester.pumpAndSettle();
        },
      };
  for (final MapEntry(key: name, value: open) in screens.entries) {
    for (final brightness in Brightness.values) {
      for (final (w, h) in [(240.0, 160.0), (320.0, 568.0)]) {
        testWidgets('$name cabe em ${w.toInt()}×${h.toInt()} no tema '
            '${brightness.name}', (tester) async {
          tester.platformDispatcher.platformBrightnessTestValue = brightness;
          addTearDown(
            tester.platformDispatcher.clearPlatformBrightnessTestValue,
          );
          setWindow(tester, w, h);
          final (store, contact) = await chat(tester, open: false);
          await open(tester, store, contact);
          expect(tester.takeException(), isNull);
        });
      }
    }

    testWidgets('$name passa no contraste e tem rótulos', (tester) async {
      final handle = tester.ensureSemantics();
      final (store, contact) = await chat(tester, open: false);
      await open(tester, store, contact);
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });
  }
}
