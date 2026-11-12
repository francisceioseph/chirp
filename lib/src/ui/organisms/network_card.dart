// lib/src/ui/organisms/network_card.dart
//
// A rede (docs/PLANO.md, 7.3): a local sempre ligada, a internet e os servidores de
// retransmissão, cada um com o que revela. Mudar religa a rede com o novo; um
// retransmissor que o núcleo recusa volta com o aviso.
import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../../l10n/l10n.dart';
import '../../core/chirp_core.dart';
import '../failure_text.dart';

class NetworkCard extends StatefulWidget {
  const NetworkCard({super.key, required this.store});

  final ProfileStore store;

  @override
  State<NetworkCard> createState() => _NetworkCardState();
}

class _NetworkCardState extends State<NetworkCard> {
  NetworkSettings? _settings;
  NetworkStatus _status = const NetworkStatus();
  final _relay = TextEditingController();
  bool _busy = false;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    widget.store
        .networkSettings()
        .then((s) {
          if (mounted) setState(() => _settings = s);
        })
        .catchError((Object _) {});
    _refresh();
    // O retransmissor responde quando quer: a linha de estado acompanha.
    _poll = Timer.periodic(const Duration(seconds: 3), (_) => _refresh());
  }

  @override
  void dispose() {
    _poll?.cancel();
    _relay.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final status = await widget.store.networkStatus();
      if (mounted) setState(() => _status = status);
    } on CoreException {
      // Fica o de antes.
    }
  }

  Future<bool> _save(NetworkSettings next) async {
    setState(() => _busy = true);
    try {
      final saved = await widget.store.setNetworkSettings(next);
      if (mounted) setState(() => _settings = saved);
      await _refresh();
      return true;
    } on CoreException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(failureText(context.l10n, error.failure))),
          );
      }
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addRelay(NetworkSettings settings) async {
    final text = _relay.text.trim();
    if (text.isEmpty) return;
    if (await _save(settings.copyWith(relays: [...settings.relays, text]))) {
      _relay.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final settings = _settings;
    if (settings == null) return const SizedBox.shrink();
    final status = !settings.internet
        ? null
        : settings.relays.isEmpty
        ? l10n.relayStatusNone
        : _status.relayConnected
        ? l10n.relayStatusConnected
        : l10n.relayStatusWaiting;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.networkTitle, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    l10n.networkLocalAlways,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            SwitchListTile(
              title: Text(l10n.internetToggle),
              subtitle: Text(l10n.internetHelp),
              value: settings.internet,
              onChanged: _busy
                  ? null
                  : (internet) => _save(settings.copyWith(internet: internet)),
            ),
            if (settings.internet)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    Text(l10n.relaysTitle, style: theme.textTheme.labelLarge),
                    const SizedBox(height: 4),
                    Text(
                      l10n.relaysHelp,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    for (final relay in settings.relays)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.dns_outlined),
                        title: Text(
                          relay,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          tooltip: '${l10n.relayRemove}: $relay',
                          onPressed: _busy
                              ? null
                              : () => _save(
                                  settings.copyWith(
                                    relays: [
                                      for (final r in settings.relays)
                                        if (r != relay) r,
                                    ],
                                  ),
                                ),
                          icon: const Icon(Icons.close),
                        ),
                      ),
                    if (settings.relays.length < maxRelays) ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: _relay,
                        enabled: !_busy,
                        keyboardType: TextInputType.url,
                        autocorrect: false,
                        enableSuggestions: false,
                        enableIMEPersonalizedLearning: false,
                        decoration: InputDecoration(
                          labelText: l10n.relayAddress,
                          helperText: l10n.relayAddressHelp,
                        ),
                        onSubmitted: (_) => _addRelay(settings),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: FilledButton.tonal(
                          onPressed: _busy ? null : () => _addRelay(settings),
                          child: Text(l10n.relayAdd),
                        ),
                      ),
                    ],
                    if (status != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        status,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: _status.relayConnected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
