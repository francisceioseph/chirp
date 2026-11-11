// lib/chirp_app.dart
//
// O app inteiro, recebendo o núcleo de fora (como o PlayerView do Psito Player): o
// main.dart passa o de verdade, e os testes um falso.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/l10n.dart';
import 'src/core/chirp_core.dart';
import 'src/ui/pages/welcome_page.dart';
import 'src/ui/theme/chirp_theme.dart';

class ChirpApp extends StatelessWidget {
  const ChirpApp({super.key, required this.core});

  final ChirpCore core;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => context.l10n.appName,
      debugShowCheckedModeBanner: false,
      theme: chirpTheme(Brightness.light),
      darkTheme: chirpTheme(Brightness.dark),
      localizationsDelegates: const [
        ChirpLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: ChirpLocalizations.supportedLocales,
      home: WelcomePage(core: core),
    );
  }
}
