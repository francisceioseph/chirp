// lib/src/ui/pages/conversation_page.dart
//
// Uma conversa: as mensagens (as mais novas embaixo, carregando as antigas ao subir),
// o campo de escrever, o "digitando…" no título e o chamar atenção, que treme a tela
// de quem recebe. O título abre os detalhes do contato (o número de segurança).
import 'dart:async';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../../../l10n/l10n.dart';
import '../../application/contacts_controller.dart';
import '../../application/conversation_controller.dart';
import '../../core/chirp_core.dart';
import '../atoms/chirp_app_bar.dart';
import '../atoms/reach_avatar.dart';
import '../failure_text.dart';
import '../molecules/conversation_tile.dart';
import '../molecules/message_bubble.dart';
import '../organisms/composer.dart';
import '../organisms/message_actions.dart';
import '../../platform/file_picker.dart';
import '../../platform/microphone.dart';
import '../reach_text.dart';
import 'contact_page.dart';

class ConversationPage extends StatefulWidget {
  const ConversationPage({
    super.key,
    required this.contacts,
    required this.contactId,
    this.onOpenDetails,
  });

  final ContactsController contacts;
  final int contactId;

  /// Abre os detalhes do contato no painel ao lado; sem isso, abrem por cima.
  final VoidCallback? onOpenDetails;

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

  /// Atualiza o tempo da gravação, de segundo em segundo.
  Timer? _recordingTick;

  @override
  void initState() {
    super.initState();
    _conversation.open();
    _conversation.nudges.addListener(_nudged);
    _scroll.addListener(_maybeLoadOlder);
  }

  @override
  void dispose() {
    _recordingTick?.cancel();
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
    final choice = await showMessageActions(
      context,
      message,
      reactions: !(_conversation.contact?.isGroup ?? false),
    );
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

  Future<void> _record() async {
    final l10n = context.l10n;
    if (!await askMicrophone()) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(l10n.microphoneDenied)));
      }
      return;
    }
    await _run(() async {
      await _conversation.startVoice();
      _recordingTick?.cancel();
      _recordingTick = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    });
  }

  Future<void> _discardRecording() async {
    _recordingTick?.cancel();
    await _run(_conversation.cancelVoice);
  }

  Future<void> _sendRecording() async {
    _recordingTick?.cancel();
    final l10n = context.l10n;
    try {
      await _conversation.sendVoice();
    } on CoreException catch (error) {
      if (error.failure != CoreFailure.invalidMessage) {
        return _show(error.failure);
      }
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(l10n.voiceTooShort)));
      }
    }
  }

  Future<void> _attach() async {
    final path = await FilePickerScope.of(context).pickFile();
    if (path == null) return;
    await _run(() => _conversation.sendFile(path));
  }

  Future<void> _save(ChatMessage message) async {
    final picker = FilePickerScope.of(context);
    final path = await picker.saveLocation(message.file!.name);
    if (path == null || !mounted) return;
    final saved = context.l10n.fileSaved;
    await _run(() async {
      await _conversation.saveFile(message, path);
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(saved)));
      }
    });
  }

  Future<void> _view(ChatMessage message) async {
    final bytes = _conversation.fileBytes(message);
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              tooltip: context.l10n.close,
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close),
            ),
            Flexible(
              child: FutureBuilder(
                future: bytes,
                builder: (context, snapshot) => switch (snapshot.data) {
                  final data? => InteractiveViewer(
                    child: Image.memory(
                      data,
                      semanticLabel: message.file!.name,
                    ),
                  ),
                  null => const Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _cancelComposer() {
    if (_conversation.editing != null) _text.clear();
    _conversation.cancelComposer();
  }

  void _openDetails() {
    if (widget.onOpenDetails case final open?) return open();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ContactPage(
          controller: widget.contacts,
          contactId: widget.contactId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    // Ao lado da lista, sem o botão de voltar (o desktop, em duas colunas).
    final wide = ModalRoute.of(context)?.impliesAppBarDismissal != true;
    return ListenableBuilder(
      listenable: _conversation,
      builder: (context, _) {
        final contact = _conversation.contact;
        if (contact == null) return Scaffold(appBar: AppBar());
        final name = contactName(l10n, contact);
        final messages = _conversation.messages;
        final replyTo = _conversation.replyTo;
        final group = contact.isGroup;
        final subtitle = group
            ? (contact.groupClosed ? l10n.groupClosed : l10n.groupLabel)
            : _conversation.theyAreTyping
            ? l10n.typing
            : !contact.established
            ? l10n.contactPending
            : contact.verified
            ? l10n.contactVerified
            : l10n.contactUnverified;
        final body = !_conversation.loaded
            ? const Center(child: CircularProgressIndicator())
            : messages.isEmpty
            ? _EmptyConversation(
                name: name,
                contact: contact,
                onVerify: _openDetails,
                onNudge: contact.established && !group
                    ? () => _run(_conversation.nudge)
                    : null,
              )
            : ListView.builder(
                controller: _scroll,
                reverse: true,
                padding: EdgeInsets.only(
                  top: ChirpAppBar.topInset(context) + 8,
                  bottom: 8,
                  // Ao lado da lista (desktop), as bolhas não encostam na divisa.
                  left: wide ? 8 : 0,
                  right: wide ? 8 : 0,
                ),
                // Depois da mensagem mais antiga, a nota de segurança da conversa.
                itemCount: messages.length + (_conversation.hasOlder ? 0 : 1),
                itemBuilder: (context, i) {
                  if (i == messages.length) {
                    return _SecurityNote(
                      verified: contact.verified,
                      group: group,
                      onVerify: _openDetails,
                    );
                  }
                  final message = messages[messages.length - 1 - i];
                  return MessageBubble(
                    key: ValueKey(message.id),
                    message: message,
                    contactName: name,
                    quoted: _conversation.byId(message.replyTo),
                    onOptions: () => _options(message),
                    onDownload: () =>
                        _run(() => _conversation.downloadFile(message)),
                    onSave: FilePickerScope.of(context).canSave
                        ? () => _save(message)
                        : null,
                    onView: () => _view(message),
                    voiceDuration: _conversation.voiceDuration(message),
                    voicePosition: _conversation.playingId == message.id
                        ? _conversation.playingPosition
                        : null,
                    onPlay: () => _run(() => _conversation.playVoice(message)),
                    onStop: _conversation.stopVoice,
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
            extendBodyBehindAppBar: ChirpAppBar.extendsBody(context),
            appBar: ChirpAppBar(
              // Sem o botão de voltar (ao lado da lista), o avatar não encosta na
              // borda.
              titleSpacing: wide ? 16 : 0,
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
                        ReachAvatar(
                          seed: contact.avatarSeed,
                          reach: contact.reach,
                          size: 40,
                          photo: contact.photo,
                        ),
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
                if (!group)
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
                // Só com algo meu esperando: um contato desligado sem nada na
                // fila não precisa de aviso.
                // Numa janela muito baixa, o aviso não cabe com o campo: o porquê
                // continua nos detalhes do contato.
                if (MediaQuery.sizeOf(context).height >= 220 &&
                    contact.reach == ContactReach.unreachable &&
                    messages.any(
                      (m) => m.outgoing && m.status == MessageStatus.pending,
                    ))
                  _ReachNotice(
                    text: unreachableText(l10n, widget.contacts.network),
                  ),
                Composer(
                  text: _text,
                  focusNode: _focus,
                  enabled: contact.established && !contact.groupClosed,
                  replyTo: replyTo,
                  replyName: replyTo == null
                      ? null
                      : replyTo.outgoing
                      ? l10n.you
                      : (replyTo.authorName ?? name),
                  editing: _conversation.editing,
                  onCancel: _cancelComposer,
                  // Num grupo, ainda sem "digitando", arquivos e notas de voz.
                  onChanged: group ? null : (_) => _conversation.typed(),
                  onAttach: group ? null : _attach,
                  onRecord: group ? null : _record,
                  recording: switch (_conversation.recordingSince) {
                    null => null,
                    final since => DateTime.now().difference(since),
                  },
                  onDiscardRecording: _discardRecording,
                  onSendRecording: _sendRecording,
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

/// No começo da conversa: cifrada de ponta a ponta, e se vocês já conferiram o código.
class _SecurityNote extends StatelessWidget {
  const _SecurityNote({
    required this.verified,
    required this.onVerify,
    this.group = false,
  });

  final bool verified;
  final VoidCallback onVerify;

  /// Num grupo, cada membro recebe cifrado; o código se confere com cada contato.
  final bool group;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final (background, foreground) = verified
        ? (scheme.tertiaryContainer, scheme.onTertiaryContainer)
        : (scheme.surfaceContainerHigh, scheme.onSurface);
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Material(
            color: background,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
              child: Row(
                children: [
                  Icon(
                    verified || group ? Icons.lock : Icons.gpp_maybe_outlined,
                    size: 18,
                    color: foreground,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      group
                          ? l10n.groupHelp
                          : verified
                          ? l10n.e2eVerified
                          : l10n.e2eUnverified,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (!verified && !group)
                    TextButton(
                      onPressed: onVerify,
                      child: Text(l10n.checkCode),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A conversa sem mensagens: um oi, e o que fazer primeiro.
class _EmptyConversation extends StatelessWidget {
  const _EmptyConversation({
    required this.name,
    required this.contact,
    required this.onVerify,
    this.onNudge,
  });

  final String name;
  final Contact contact;
  final VoidCallback onVerify;
  final VoidCallback? onNudge;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeSemantics(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Icon(
                    contact.established
                        ? Icons.waving_hand_outlined
                        : Icons.hourglass_top,
                    size: 32,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                contact.established ? l10n.sayHi(name) : l10n.contactPending,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge,
              ),
              if (contact.isGroup) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.groupHelp,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ] else if (contact.established) ...[
                const SizedBox(height: 8),
                Text(
                  contact.verified ? l10n.e2eVerified : l10n.sayHiUnverified,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (!contact.verified)
                      FilledButton.tonalIcon(
                        onPressed: onVerify,
                        icon: const Icon(Icons.verified_user_outlined),
                        label: Text(l10n.checkCode),
                      ),
                    TextButton.icon(
                      onPressed: onNudge,
                      icon: const Icon(Icons.vibration),
                      label: Text(l10n.nudge),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Por que o contato não foi alcançado, logo acima do campo: as mensagens esperam.
class _ReachNotice extends StatelessWidget {
  const _ReachNotice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      liveRegion: true,
      child: ColoredBox(
        color: scheme.surfaceContainerHigh,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                reachIcon(ContactReach.unreachable),
                size: 18,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  // Numa janela baixa, uma linha: a conversa precisa do espaço.
                  maxLines: MediaQuery.sizeOf(context).height < 360 ? 1 : 4,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
