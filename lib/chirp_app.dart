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
import 'src/platform/key_vault.dart';
import 'src/ui/pages/startup_page.dart';
import 'src/ui/theme/chirp_theme.dart';

class ChirpApp extends StatefulWidget {
  const ChirpApp({super.key, required this.core, required this.vault});

  final ChirpCore core;
  final KeyVault vault;

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
    _startup.start();
  }

  /// A aparência mora no banco: segue o que a abertura abriu (ou apagou).
  void _followStore() => _appearance.attach(_startup.store);

  @override
  void dispose() {
    _startup.removeListener(_followStore);
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
        final spec = chirpThemeById(appearance.theme);
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
          home: StartupPage(controller: _startup, appearance: _appearance),
        );
      },
    );
  }
}
