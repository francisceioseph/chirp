// As notas de voz na tela: o microfone no lugar do enviar, gravar, descartar,
// mandar, curta demais, sem microfone, tocar e parar, com o núcleo falso.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_chirp/l10n/chirp_localizations.dart';
import 'package:psito_chirp/src/core/chirp_core.dart';

import 'helpers.dart';

void main() {
  final l10n = lookupChirpLocalizations(const Locale('pt'));

  Future<FakeStore> chat(WidgetTester tester) async {
    final (core, vault) = await withProfile();
    final store = core.store!..someoneJoined('Pérola');
    await pumpChirp(tester, core: core, vault: vault);
    await tester.tap(find.text('Pérola'));
    await tester.pumpAndSettle();
    return store;
  }

  Future<void> record(WidgetTester tester) async {
    await tester.tap(find.byTooltip(l10n.voiceRecord));
    await tester.pumpAndSettle();
  }

  testWidgets('o microfone aparece com o campo vazio, e o enviar com texto', (
    tester,
  ) async {
    await chat(tester);
    expect(find.byTooltip(l10n.voiceRecord), findsOneWidget);
    expect(find.byTooltip(l10n.send), findsNothing);
    await tester.enterText(find.byType(TextField), 'oi');
    await tester.pump();
    expect(find.byTooltip(l10n.voiceRecord), findsNothing);
    expect(find.byTooltip(l10n.send), findsOneWidget);
  });

  testWidgets('gravar mostra o tempo, e descartar não manda nada', (
    tester,
  ) async {
    final store = await chat(tester);
    await record(tester);
    expect(store.recordingVoice, isTrue);
    expect(find.text('${l10n.voiceRecording} 0:00'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    await tester.pump(const Duration(seconds: 2));
    expect(find.textContaining(l10n.voiceRecording), findsOneWidget);

    await tester.tap(find.byTooltip(l10n.voiceDiscard));
    await tester.pumpAndSettle();
    expect(store.recordingVoice, isFalse);
    expect(store.voicesSent, 0);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('mandar põe a nota na conversa, com o tempo, e na lista', (
    tester,
  ) async {
    final store = await chat(tester);
    await record(tester);
    await tester.tap(find.byTooltip(l10n.voiceSend));
    await tester.pumpAndSettle();
    expect(store.voicesSent, 1);
    expect(find.text('${l10n.voiceNote} · 0:03'), findsOneWidget);
    expect(find.text('voice.opus'), findsNothing);

    await tester.tap(find.byTooltip(l10n.voicePlay));
    await tester.pumpAndSettle();
    expect(store.playingVoice, isNotNull);
    expect(find.byTooltip(l10n.voiceStop), findsOneWidget);
    await tester.tap(find.byTooltip(l10n.voiceStop));
    await tester.pumpAndSettle();
    expect(store.playingVoice, isNull);
    expect(find.byTooltip(l10n.voicePlay), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.textContaining(l10n.voicePreview), findsOneWidget);
  });

  testWidgets('a nota que acaba de tocar volta ao começo', (tester) async {
    final store = await chat(tester);
    await record(tester);
    await tester.tap(find.byTooltip(l10n.voiceSend));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(l10n.voicePlay));
    await tester.pumpAndSettle();
    final id = store.playingVoice!;
    store.playback!.add(
      VoiceProgress(messageId: id, position: const Duration(seconds: 1)),
    );
    await tester.pumpAndSettle();
    expect(find.text('${l10n.voiceNote} · 0:01'), findsOneWidget);
    store.playback!.add(
      VoiceProgress(
        messageId: id,
        position: const Duration(seconds: 3),
        done: true,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byTooltip(l10n.voicePlay), findsOneWidget);
    expect(find.text('${l10n.voiceNote} · 0:03'), findsOneWidget);
  });

  testWidgets('curta demais avisa e não manda', (tester) async {
    final store = await chat(tester);
    store.recordedMs = 200;
    await record(tester);
    await tester.tap(find.byTooltip(l10n.voiceSend));
    await tester.pumpAndSettle();
    expect(store.voicesSent, 0);
    expect(find.text(l10n.voiceTooShort), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('sem microfone, avisa e o campo continua', (tester) async {
    final store = await chat(tester);
    store.audio = false;
    await record(tester);
    expect(find.text(l10n.audioUnavailable), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  for (final size in const [Size(240, 160), Size(320, 568)]) {
    testWidgets(
      'gravando, cabe em ${size.width.toInt()}×${size.height.toInt()}',
      (tester) async {
        setWindow(tester, size.width, size.height);
        await chat(tester);
        await record(tester);
        expect(tester.takeException(), isNull);
        expect(find.byTooltip(l10n.voiceDiscard), findsOneWidget);
        expect(find.byTooltip(l10n.voiceSend), findsOneWidget);
        await tester.tap(find.byTooltip(l10n.voiceDiscard));
        await tester.pumpAndSettle();
      },
    );
  }
}
