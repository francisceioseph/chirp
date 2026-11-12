// lib/src/ui/organisms/background_card.dart
//
// O segundo plano (docs/PLANO.md, 7.5): continuar recebendo com a janela fechada.
// No desktop, o ícone na bandeja e o abrir ao entrar no computador, já escondido; no
// Android, a notificação fixa do serviço e o pedido, opcional, para ficar fora da
// economia de bateria. No iOS, o cartão não aparece.
import 'dart:async';

import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../core/chirp_core.dart';
import '../../platform/background.dart';

/// Liga (ou desliga) o segundo plano conforme o que está gravado, com os textos do
/// idioma.
Future<void> setUpBackground(
  BuildContext context,
  ProfileStore store,
  Background background, {
  bool? keepRunning,
}) async {
  final l10n = context.l10n;
  final texts = (
    name: l10n.appName,
    open: l10n.trayOpen(l10n.appName),
    quit: l10n.trayQuit,
    receiving: l10n.receivingNow,
    channel: l10n.backgroundTitle,
  );
  final bool on;
  try {
    on = keepRunning ?? await store.keepRunning();
  } on CoreException {
    return;
  }
  await background.setup(keepRunning: on, texts: texts);
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
  bool _batteryRestricted = false;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    widget.store
        .keepRunning()
        .then((on) {
          if (mounted) setState(() => _keepRunning = on);
        })
        .catchError((Object _) {});
    // Quem volta dos ajustes do sistema pode ter liberado a bateria.
    _lifecycle = AppLifecycleListener(onResume: _checkBattery);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _atLogin = BackgroundScope.of(context).startsAtLogin;
    _checkBattery();
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _checkBattery() async {
    final restricted = await BackgroundScope.of(context).batteryRestricted();
    if (mounted && restricted != _batteryRestricted) {
      setState(() => _batteryRestricted = restricted);
    }
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
      setUpBackground(
        context,
        widget.store,
        BackgroundScope.of(context),
        keepRunning: on,
      ),
    );
  }

  void _setAtLogin(bool on) {
    final background = BackgroundScope.of(context);
    background.setStartAtLogin(on);
    setState(() => _atLogin = background.startsAtLogin);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final background = BackgroundScope.of(context);
    final keepRunning = _keepRunning;
    if (!background.supported || keepRunning == null) {
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
              style: theme.textTheme.titleMedium,
            ),
          ),
          SwitchListTile(
            title: Text(l10n.keepRunning),
            subtitle: Text(
              background.tray
                  ? l10n.keepRunningHelp
                  : l10n.keepRunningHelpMobile,
            ),
            value: keepRunning,
            onChanged: _setKeepRunning,
          ),
          if (background.canStartAtLogin)
            SwitchListTile(
              title: Text(l10n.startAtLogin),
              subtitle: Text(l10n.startAtLoginHelp),
              value: _atLogin,
              onChanged: _setAtLogin,
            ),
          if (keepRunning && _batteryRestricted)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.batteryTitle, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(
                    l10n.batteryHelp,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: FilledButton.tonal(
                      onPressed: background.askUnrestrictedBattery,
                      child: Text(l10n.batteryAllow),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
