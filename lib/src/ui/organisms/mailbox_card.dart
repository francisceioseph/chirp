// lib/src/ui/organisms/mailbox_card.dart
//
// A caixa postal (fase 7): um servidor de quem usa (o `chirp-mailbox`), que guarda o
// que os contatos mandam com o aparelho desligado, já cifrado, até o app abrir. Liga
// colando o código que o `chirp-mailbox pair` mostra; desligar pergunta antes, porque
// o que esperava nela se perde.
import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../../l10n/l10n.dart';
import '../../core/chirp_core.dart';
import '../failure_text.dart';
import '../time_format.dart';

class MailboxCard extends StatefulWidget {
  const MailboxCard({super.key, required this.store});

  final ProfileStore store;

  @override
  State<MailboxCard> createState() => _MailboxCardState();
}

class _MailboxCardState extends State<MailboxCard> {
  MailboxState? _mailbox;
  bool _loaded = false;
  bool _busy = false;
  final _link = TextEditingController();
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _refresh();
    // A leitura da caixa acontece sozinha: o estado acompanha.
    _poll = Timer.periodic(const Duration(seconds: 5), (_) => _refresh());
  }

  @override
  void dispose() {
    _poll?.cancel();
    _link.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final mailbox = await widget.store.mailbox();
      if (mounted) {
        setState(() {
          _mailbox = mailbox;
          _loaded = true;
        });
      }
    } on CoreException {
      // Fica o de antes.
    }
  }

  void _tell(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _pair() async {
    final link = _link.text.trim();
    if (link.isEmpty) return;
    setState(() => _busy = true);
    try {
      final mailbox = await widget.store.pairMailbox(link);
      _link.clear();
      if (mounted) setState(() => _mailbox = mailbox);
    } on CoreException catch (error) {
      if (mounted) {
        _tell(
          error.failure == CoreFailure.unreachable
              ? context.l10n.mailboxUnreachable
              : failureText(context.l10n, error.failure),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _unpair() async {
    final l10n = context.l10n;
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.link_off),
        title: Text(l10n.mailboxUnpairTitle),
        content: Text(l10n.mailboxUnpairBody),
        actions: [
          TextButton(
            autofocus: true,
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.mailboxUnpair),
          ),
        ],
      ),
    );
    if (sure != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await widget.store.unpairMailbox();
      if (mounted) setState(() => _mailbox = null);
    } on CoreException catch (error) {
      if (mounted) _tell(failureText(context.l10n, error.failure));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _status(ChirpLocalizations l10n, MailboxState mailbox) {
    if (mailbox.reachable == false) return l10n.mailboxStatusUnreachable;
    final last = mailbox.lastFetch;
    if (last == null) return l10n.mailboxStatusWaiting;
    return l10n.mailboxStatusChecked(messageTime(context, last));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    if (!_loaded) return const SizedBox.shrink();
    final mailbox = _mailbox;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.mailboxTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(l10n.mailboxHelp, style: muted),
            const SizedBox(height: 8),
            if (mailbox == null) ...[
              TextField(
                controller: _link,
                enabled: !_busy,
                keyboardType: TextInputType.url,
                autocorrect: false,
                enableSuggestions: false,
                enableIMEPersonalizedLearning: false,
                decoration: InputDecoration(
                  labelText: l10n.mailboxCode,
                  helperText: l10n.mailboxCodeHelp,
                  helperMaxLines: 3,
                ),
                onSubmitted: (_) => _pair(),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: FilledButton.tonal(
                  onPressed: _busy ? null : _pair,
                  child: Text(l10n.mailboxPair),
                ),
              ),
            ] else ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  mailbox.reachable == false
                      ? Icons.cloud_off_outlined
                      : Icons.markunread_mailbox_outlined,
                  color: mailbox.reachable == false
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary,
                ),
                title: Text(l10n.mailboxPaired),
                subtitle: Text(_status(l10n, mailbox)),
              ),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: _busy ? null : _unpair,
                  child: Text(l10n.mailboxUnpair),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
