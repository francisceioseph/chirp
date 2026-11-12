// lib/chirp_app.dart
//
// O app inteiro, recebendo o núcleo e o cofre de fora (como o PlayerView do Psito
// Player): o main.dart passa os de verdade, e os testes os falsos.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/l10n.dart';
import 'src/application/appearance_controller.dart';
import 'src/application/startup_controller.dart';
import 'src/core/chirp_core.dart';
import 'src/platform/desktop.dart';
import 'src/platform/file_picker.dart';
import 'src/platform/key_vault.dart';
import 'src/platform/notifier.dart';
import 'src/ui/pages/startup_page.dart';
import 'src/ui/theme/chirp_theme.dart';

class ChirpApp extends StatefulWidget {
  const ChirpApp({
    super.key,
    required this.core,
    required this.vault,
    this.systemAccent,
    this.filePicker = const SystemFilePicker(),
    this.notifier,
    this.desktop = const NoDesktop(),
    this.startHidden = false,
  });

  final ChirpCore core;
  final KeyVault vault;

  /// Lê a cor de destaque do sistema, para o tema "Cor do sistema" (sem isso, ou
  /// sem cor, ele não aparece).
  final Future<Color?> Function()? systemAccent;

  /// O seletor de arquivos (os testes passam um falso).
  final FilePicker filePicker;

  /// As notificações do sistema; sem ele (os testes de integração), nenhuma.
  final Notifier? notifier;

  /// A bandeja, fechar sem sair e abrir com o computador (no celular, nada).
  final Desktop desktop;

  /// Aberto com o computador: a janela começa escondida, e só aparece se a abertura
  /// precisar de quem usa (a senha, o perfil novo, um problema).
  final bool startHidden;

  @override
  State<ChirpApp> createState() => _ChirpAppState();
}

class _ChirpAppState extends State<ChirpApp> {
  late final _startup = StartupController(
    core: widget.core,
    vault: widget.vault,
  );
  final _appearance = AppearanceController();

  @override
  void initState() {
    super.initState();
    _startup.addListener(_followStore);
    if (widget.startHidden && widget.desktop.supported) {
      _startup.addListener(_showIfNeeded);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_startup.state is! StartupLoading &&
            _startup.state is! StartupReady) {
          return;
        }
        widget.desktop.hide();
      });
    }
    _startup.start();
    widget.systemAccent?.call().then(_appearance.setAccent);
  }

  /// A aparência mora no banco: segue o que a abertura abriu (ou apagou).
  void _followStore() => _appearance.attach(_startup.store);

  /// Escondida, a janela volta se a abertura parar esperando por quem usa.
  void _showIfNeeded() {
    final state = _startup.state;
    if (state is StartupLoading || state is StartupReady) return;
    _startup.removeListener(_showIfNeeded);
    widget.desktop.bringToFront();
  }

  @override
  void dispose() {
    _startup.removeListener(_followStore);
    _startup.removeListener(_showIfNeeded);
    _startup.dispose();
    _appearance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _appearance,
      builder: (context, _) {
        final appearance = _appearance.value;
        final spec = chirpThemeById(
          appearance.theme,
          accent: _appearance.accent,
        );
        return MaterialApp(
          onGenerateTitle: (context) => context.l10n.appName,
          debugShowCheckedModeBanner: false,
          theme: chirpTheme(
            Brightness.light,
            spec: spec,
            glass: appearance.glass,
          ),
          darkTheme: chirpTheme(
            Brightness.dark,
            spec: spec,
            glass: appearance.glass,
          ),
          themeMode: switch (appearance.mode) {
            AppearanceMode.system => ThemeMode.system,
            AppearanceMode.light => ThemeMode.light,
            AppearanceMode.dark => ThemeMode.dark,
          },
          localizationsDelegates: const [
            ChirpLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: ChirpLocalizations.supportedLocales,
          builder: (context, child) => FilePickerScope(
            picker: widget.filePicker,
            child: NotifierScope(
              notifier: widget.notifier,
              child: DesktopScope(desktop: widget.desktop, child: child!),
            ),
          ),
          home: StartupPage(controller: _startup, appearance: _appearance),
        );
      },
    );
  }
}
