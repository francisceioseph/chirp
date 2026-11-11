// lib/src/ui/molecules/message_bubble.dart
//
// Uma mensagem da conversa: a bolha (as minhas à direita), a citação, o texto, a hora,
// o "editada", o estado e as reações embaixo. A chamada de atenção é uma linha no meio.
// Segurar, o botão direito ou Enter com o foco nela abre as opções.
import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../core/chirp_core.dart';
import '../atoms/message_status_icon.dart';
import '../atoms/reaction_icon.dart';
import '../time_format.dart';
import '../theme/chirp_style.dart';

/// O foco do teclado numa mensagem: Enter ou espaço abrem as opções, e um contorno
/// mostra onde o foco está.
class _Focusable extends StatefulWidget {
  const _Focusable({required this.onActivate, required this.child});

  final VoidCallback? onActivate;
  final Widget child;

  @override
  State<_Focusable> createState() => _FocusableState();
}

class _FocusableState extends State<_Focusable> {
  bool _highlight = false;

  @override
  Widget build(BuildContext context) => FocusableActionDetector(
    enabled: widget.onActivate != null,
    onShowFocusHighlight: (value) => setState(() => _highlight = value),
    actions: {
      ActivateIntent: CallbackAction<ActivateIntent>(
        onInvoke: (_) {
          widget.onActivate?.call();
          return null;
        },
      ),
    },
    child: DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          ChirpStyle.of(context).bubbleRadius,
        ),
        border: _highlight
            ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
            : null,
      ),
      child: widget.child,
    ),
  );
}

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.contactName,
    this.quoted,
    this.onOptions,
    this.now,
  });

  final ChatMessage message;

  /// O nome do contato, para a chamada de atenção e a citação.
  final String contactName;

  /// A mensagem citada, se esta é uma resposta e a citada existe aqui.
  final ChatMessage? quoted;
  final VoidCallback? onOptions;

  /// O "agora", para os testes.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    if (message.kind == MessageKind.nudge) return _nudge(context);
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final mine = message.outgoing;
    final background = mine
        ? scheme.primaryContainer
        : scheme.surfaceContainerHighest;
    final foreground = mine ? scheme.onPrimaryContainer : scheme.onSurface;
    final muted = foreground.withValues(alpha: 0.72);
    final time = messageTime(context, message.sentAt, now: now);
    final text = message.deleted ? l10n.messageDeleted : message.text;
    final sender = mine ? l10n.you : contactName;
    final semantics = [
      sender,
      text,
      if (message.edited) l10n.messageEdited,
      time,
      if (mine) statusLabel(l10n, message.status),
      if (message.myReaction > 0)
        '${l10n.you}: ${reactionLabel(l10n, message.myReaction)}',
      if (message.theirReaction > 0)
        '$contactName: ${reactionLabel(l10n, message.theirReaction)}',
    ].join(', ');

    final bubble = Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: ChirpStyle.of(context).bubble(mine: mine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (message.replyTo != null || quoted != null)
            _Quote(
              quoted: quoted,
              name: quoted == null || quoted!.outgoing ? l10n.you : contactName,
              color: foreground,
            ),
          Text(
            text,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: message.deleted ? muted : foreground,
              fontStyle: message.deleted ? FontStyle.italic : null,
            ),
          ),
          const SizedBox(height: 2),
          Wrap(
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            children: [
              if (message.edited)
                Text(
                  l10n.messageEdited,
                  style: theme.textTheme.labelSmall?.copyWith(color: muted),
                ),
              Text(
                time,
                style: theme.textTheme.labelSmall?.copyWith(color: muted),
              ),
              if (mine)
                MessageStatusIcon(
                  status: message.status,
                  size: 14,
                  color: muted,
                ),
            ],
          ),
        ],
      ),
    );

    final reactions = [
      if (message.theirReaction > 0) message.theirReaction,
      if (message.myReaction > 0) message.myReaction,
    ];

    return Semantics(
      container: true,
      label: semantics,
      onLongPressHint: l10n.messageOptions,
      onLongPress: onOptions,
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Align(
          alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
          child: LayoutBuilder(
            builder: (context, constraints) => ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: (constraints.maxWidth * 0.82).clamp(120, 560),
              ),
              child: _Focusable(
                onActivate: onOptions,
                child: GestureDetector(
                  onLongPress: onOptions,
                  onSecondaryTap: onOptions,
                  child: Column(
                    crossAxisAlignment: mine
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      bubble,
                      if (reactions.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainer,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: scheme.outlineVariant),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                for (final kind in reactions)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 1,
                                    ),
                                    child: ReactionIcon(kind: kind, size: 16),
                                  ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _nudge(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final text = message.outgoing
        ? l10n.nudgeSent(contactName)
        : l10n.nudgeReceived(contactName);
    final time = messageTime(context, message.sentAt, now: now);
    return Semantics(
      container: true,
      label: '$text, $time',
      onLongPressHint: l10n.messageOptions,
      onLongPress: onOptions,
      excludeSemantics: true,
      child: _Focusable(
        onActivate: onOptions,
        child: GestureDetector(
          onLongPress: onOptions,
          onSecondaryTap: onOptions,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.vibration,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    '$text · $time',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Quote extends StatelessWidget {
  const _Quote({required this.quoted, required this.name, required this.color});

  final ChatMessage? quoted;
  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final quoted = this.quoted;
    final text = quoted == null
        ? l10n.quotedMissing
        : quoted.deleted
        ? l10n.messageDeleted
        : quoted.text;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: theme.colorScheme.primary, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (quoted != null)
            Text(
              name,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color.withValues(alpha: 0.8),
              fontStyle: quoted == null || quoted.deleted
                  ? FontStyle.italic
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
