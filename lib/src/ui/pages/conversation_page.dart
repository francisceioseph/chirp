// lib/src/ui/pages/conversation_page.dart
//
// Uma conversa: as mensagens (as mais novas embaixo, carregando as antigas ao subir),
// o campo de escrever, o "digitando…" no título e o chamar atenção, que treme a tela
// de quem recebe. O título abre os detalhes do contato (o número de segurança).
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/l10n.dart';
import '../../application/contacts_controller.dart';
import '../../application/conversation_controller.dart';
import '../../core/chirp_core.dart';
import '../atoms/identity_avatar.dart';
import '../atoms/panel_text.dart';
import '../failure_text.dart';
import '../molecules/conversation_tile.dart';
import '../molecules/message_bubble.dart';
import '../organisms/composer.dart';
import '../organisms/message_actions.dart';
import 'contact_page.dart';

class ConversationPage extends StatefulWidget {
  const ConversationPage({
    super.key,
    required this.contacts,
    required this.contactId,
  });

  final ContactsController contacts;
  final int contactId;

  @override
  State<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends State<ConversationPage>
    with SingleTickerProviderStateMixin {
  late final _conversation = ConversationController(
    widget.contacts,
    widget.contactId,
  );
  final _text = TextEditingController();
  final _focus = FocusNode();
  final _scroll = ScrollController();
  late final _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );

  @override
  void initState() {
    super.initState();
    _conversation.open();
    _conversation.nudges.addListener(_nudged);
    _scroll.addListener(_maybeLoadOlder);
  }

  @override
  void dispose() {
    _conversation.nudges.removeListener(_nudged);
    _conversation.dispose();
    _text.dispose();
    _focus.dispose();
    _scroll.dispose();
    _shake.dispose();
    super.dispose();
  }

  void _nudged() {
    HapticFeedback.heavyImpact();
    _shake.forward(from: 0);
  }

  void _maybeLoadOlder() {
    // A lista é invertida: o fim do rolar é o topo, as mensagens antigas.
    if (_scroll.position.extentAfter < 400) _conversation.loadOlder();
  }

  void _show(CoreFailure failure) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(failureText(context.l10n, failure))),
      );
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } on CoreException catch (error) {
      _show(error.failure);
    }
  }

  Future<void> _send() async {
    final text = _text.text;
    if (text.trim().isEmpty) return;
    await _run(() async {
      await _conversation.send(text);
      _text.clear();
    });
    _focus.requestFocus();
  }

  Future<void> _options(ChatMessage message) async {
    final choice = await showMessageActions(context, message);
    if (choice == null || !mounted) return;
    final reaction = choice.reaction;
    if (reaction != null) {
      await _run(() => _conversation.react(message, reaction));
      return;
    }
    switch (choice.action) {
      case MessageAction.reply:
        _conversation.startReply(message);
        _focus.requestFocus();
      case MessageAction.copy:
        await Clipboard.setData(ClipboardData(text: message.text));
        if (mounted) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(context.l10n.textCopied)));
        }
      case MessageAction.edit:
        _conversation.startEdit(message);
        _text.text = message.text;
        _text.selection = TextSelection.collapsed(offset: message.text.length);
        _focus.requestFocus();
      case MessageAction.deleteForMe:
        await _run(() => _conversation.deleteForMe(message));
      case MessageAction.deleteForEveryone:
        await _run(() => _conversation.deleteForEveryone(message));
      case null:
        break;
    }
  }

  void _cancelComposer() {
    if (_conversation.editing != null) _text.clear();
    _conversation.cancelComposer();
  }

  void _openDetails() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) =>
          ContactPage(controller: widget.contacts, contactId: widget.contactId),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: _conversation,
      builder: (context, _) {
        final contact = _conversation.contact;
        if (contact == null) return Scaffold(appBar: AppBar());
        final name = contactName(l10n, contact);
        final messages = _conversation.messages;
        final replyTo = _conversation.replyTo;
        final subtitle = _conversation.theyAreTyping
            ? l10n.typing
            : !contact.established
            ? l10n.contactPending
            : contact.verified
            ? l10n.contactVerified
            : l10n.contactUnverified;
        final body = !_conversation.loaded
            ? const Center(child: CircularProgressIndicator())
            : messages.isEmpty
            ? Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: PanelBody(
                    contact.established
                        ? l10n.conversationEmpty
                        : l10n.contactPending,
                  ),
                ),
              )
            : ListView.builder(
                controller: _scroll,
                reverse: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: messages.length,
                itemBuilder: (context, i) {
                  final message = messages[messages.length - 1 - i];
                  return MessageBubble(
                    key: ValueKey(message.id),
                    message: message,
                    contactName: name,
                    quoted: _conversation.byId(message.replyTo),
                    onOptions: () => _options(message),
                  );
                },
              );
        return AnimatedBuilder(
          animation: _shake,
          builder: (context, child) {
            final t = _shake.value;
            final dx = t == 0 || t == 1
                ? 0.0
                : math.sin(t * math.pi * 8) * 12 * (1 - t);
            return Transform.translate(offset: Offset(dx, 0), child: child);
          },
          child: Scaffold(
            appBar: AppBar(
              titleSpacing: 0,
              title: Semantics(
                button: true,
                label: '${l10n.contactDetails}: $name',
                excludeSemantics: true,
                child: InkWell(
                  onTap: _openDetails,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        IdentityAvatar(seed: contact.avatarSeed, size: 36),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: _conversation.theyAreTyping
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  tooltip: l10n.nudge,
                  onPressed: contact.established
                      ? () => _run(_conversation.nudge)
                      : null,
                  icon: const Icon(Icons.vibration),
                ),
                const SizedBox(width: 4),
              ],
            ),
            body: Column(
              children: [
                Expanded(child: body),
                Composer(
                  text: _text,
                  focusNode: _focus,
                  enabled: contact.established,
                  replyTo: replyTo,
                  replyName: replyTo == null
                      ? null
                      : replyTo.outgoing
                      ? l10n.you
                      : name,
                  editing: _conversation.editing,
                  onCancel: _cancelComposer,
                  onChanged: (_) => _conversation.typed(),
                  onSend: _send,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
