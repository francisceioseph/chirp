// lib/src/ui/organisms/background_card.dart
//
// O segundo plano no desktop (docs/PLANO.md, 7.5): continuar recebendo com a janela
// fechada (o ícone na bandeja) e abrir ao entrar no computador, já escondido. No
// celular, o cartão não aparece.
import 'dart:async';

import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../core/chirp_core.dart';
import '../../platform/desktop.dart';

/// Monta a bandeja (ou tira) conforme o que está gravado, com os textos do idioma.
Future<void> setUpDesktop(
  BuildContext context,
  ProfileStore store,
  Desktop desktop, {
  bool? keepRunning,
}) async {
  final l10n = context.l10n;
  final bool on;
  try {
    on = keepRunning ?? await store.keepRunning();
  } on CoreException {
    return;
  }
  await desktop.setup(
    keepRunning: on,
    tooltip: l10n.appName,
    open: l10n.trayOpen(l10n.appName),
    quit: l10n.trayQuit,
  );
}

class BackgroundCard extends StatefulWidget {
  const BackgroundCard({super.key, required this.store});

  final ProfileStore store;

  @override
  State<BackgroundCard> createState() => _BackgroundCardState();
}

class _BackgroundCardState extends State<BackgroundCard> {
  bool? _keepRunning;
  bool _atLogin = false;

  @override
  void initState() {
    super.initState();
    widget.store
        .keepRunning()
        .then((on) {
          if (mounted) setState(() => _keepRunning = on);
        })
        .catchError((Object _) {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _atLogin = DesktopScope.of(context).startsAtLogin;
  }

  Future<void> _setKeepRunning(bool on) async {
    final before = _keepRunning;
    setState(() => _keepRunning = on);
    try {
      await widget.store.setKeepRunning(on);
    } on CoreException {
      if (mounted) setState(() => _keepRunning = before);
      return;
    }
    if (!mounted) return;
    unawaited(
      setUpDesktop(
        context,
        widget.store,
        DesktopScope.of(context),
        keepRunning: on,
      ),
    );
  }

  void _setAtLogin(bool on) {
    final desktop = DesktopScope.of(context);
    desktop.setStartAtLogin(on);
    setState(() => _atLogin = desktop.startsAtLogin);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final desktop = DesktopScope.of(context);
    final keepRunning = _keepRunning;
    if (!desktop.supported || keepRunning == null) {
      return const SizedBox.shrink();
    }
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              l10n.backgroundTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          SwitchListTile(
            title: Text(l10n.keepRunning),
            subtitle: Text(l10n.keepRunningHelp),
            value: keepRunning,
            onChanged: _setKeepRunning,
          ),
          if (desktop.canStartAtLogin)
            SwitchListTile(
              title: Text(l10n.startAtLogin),
              subtitle: Text(l10n.startAtLoginHelp),
              value: _atLogin,
              onChanged: _setAtLogin,
            ),
        ],
      ),
    );
  }
}
