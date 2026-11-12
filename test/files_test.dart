// Os arquivos da fase 6 na tela: anexar, baixar (sozinho ou pedindo), o progresso,
// salvar, abrir a foto e o que falha, com o núcleo e o seletor falsos.
import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_chirp/l10n/chirp_localizations.dart';
import 'package:psito_chirp/src/core/chirp_core.dart';

import 'helpers.dart';

/// Um PNG de 1×1, para servir de miniatura e de foto.
final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
);

void main() {
  final l10n = lookupChirpLocalizations(const Locale('pt'));

  Future<(FakeStore, FakeFilePicker)> chat(
    WidgetTester tester, {
    FakeFilePicker? picker,
  }) async {
    final (core, vault) = await withProfile();
    final store = core.store!..someoneJoined('Pérola');
    final files = picker ?? FakeFilePicker();
    await pumpChirp(tester, core: core, vault: vault, filePicker: files);
    await tester.tap(find.text('Pérola'));
    await tester.pumpAndSettle();
    return (store, files);
  }

  testWidgets('anexar manda o arquivo; desistir não manda nada', (
    tester,
  ) async {
    final (store, picker) = await chat(tester);
    await tester.tap(find.byTooltip(l10n.attachFile));
    await tester.pumpAndSettle();
    expect(store.sent, isEmpty);

    picker.pick = '/home/eu/Documentos/relatorio.pdf';
    await tester.tap(find.byTooltip(l10n.attachFile));
    await tester.pumpAndSettle();
    expect(store.sent.single.kind, MessageKind.file);
    expect(find.text('relatorio.pdf'), findsOneWidget);
    expect(find.text('1,5 KB'), findsOneWidget);
  });

  testWidgets('um arquivo que não pode sair avisa por quê', (tester) async {
    final (store, picker) = await chat(
      tester,
      picker: FakeFilePicker(pick: '/tmp/estranho.bad'),
    );
    await tester.tap(find.byTooltip(l10n.attachFile));
    await tester.pumpAndSettle();
    expect(find.text(l10n.fileInvalid), findsOneWidget);
    expect(store.sent, isEmpty);
  });

  testWidgets('baixando: espera o contato, mostra o progresso e salva no fim', (
    tester,
  ) async {
    final (store, picker) = await chat(
      tester,
      picker: FakeFilePicker(save: '/home/eu/Downloads/notas.txt'),
    );
    final m = store.theySendFile(1, 'notas.txt', size: 3 * 1024 * 1024);
    await tester.pumpAndSettle();
    expect(find.text(l10n.fileWaiting), findsOneWidget);
    expect(find.text('3 MB'), findsOneWidget);
    expect(find.text(l10n.fileSave), findsNothing);

    store.fileProgress(m.id, 2);
    await tester.pumpAndSettle();
    expect(find.text(l10n.fileProgress(50)), findsOneWidget);

    store.fileProgress(m.id, 4);
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.fileSave));
    await tester.pumpAndSettle();
    expect(picker.suggested, ['notas.txt']);
    expect(store.savedFiles[m.id], '/home/eu/Downloads/notas.txt');
    expect(find.text(l10n.fileSaved), findsOneWidget);
  });

  testWidgets('um arquivo grande espera o "Baixar"; um que falhou, o de novo', (
    tester,
  ) async {
    final (store, _) = await chat(tester);
    store
      ..theySendFile(1, 'filme.mp4', size: 700 << 20, state: FileState.waiting)
      ..theySendFile(1, 'quebrado.zip', state: FileState.failed);
    await tester.pumpAndSettle();
    expect(find.text(l10n.fileFailed), findsOneWidget);
    await tester.tap(find.text(l10n.fileDownload));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.fileRetry));
    await tester.pumpAndSettle();
    expect(store.downloads, 2);
    expect(find.text(l10n.fileWaiting), findsNWidgets(2));
  });

  testWidgets('a foto inteira abre por cima, e fecha', (tester) async {
    final handle = tester.ensureSemantics();
    final (store, _) = await chat(tester);
    store.theySendFile(
      1,
      'praia.png',
      state: FileState.done,
      thumbnail: _png,
      content: _png,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel(l10n.fileView('praia.png')));
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: find.byType(Dialog), matching: find.byType(Image)),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip(l10n.close));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    handle.dispose();
  });

  testWidgets('sem onde salvar (o iOS), o botão não aparece', (tester) async {
    final (store, _) = await chat(
      tester,
      picker: FakeFilePicker(canSave: false),
    );
    store.theySendFile(1, 'notas.txt', state: FileState.done);
    await tester.pumpAndSettle();
    expect(find.text(l10n.fileSave), findsNothing);
  });

  testWidgets('a lista mostra que a última foi um arquivo', (tester) async {
    final (core, vault) = await withProfile();
    final store = core.store!..someoneJoined('Pérola');
    store.theySendFile(1, 'notas.txt');
    await pumpChirp(tester, core: core, vault: vault);
    expect(find.text(l10n.filePreview('notas.txt')), findsOneWidget);
  });

  for (final brightness in Brightness.values) {
    for (final (w, h) in [(240.0, 160.0), (320.0, 568.0)]) {
      testWidgets('arquivos cabem em ${w.toInt()}×${h.toInt()} no '
          '${brightness.name}', (tester) async {
        tester.platformDispatcher.platformBrightnessTestValue = brightness;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        setWindow(tester, w, h);
        final handle = tester.ensureSemantics();
        final (store, _) = await chat(tester);
        await store.sendFile(1, '/tmp/meu-arquivo-com-nome-comprido.pdf');
        store
          ..theySendFile(1, 'praia.png', state: FileState.done, thumbnail: _png)
          ..theySendFile(
            1,
            'filme.mp4',
            size: 700 << 20,
            state: FileState.waiting,
          );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        handle.dispose();
      });
    }
  }
}
