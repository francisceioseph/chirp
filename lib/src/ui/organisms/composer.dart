// lib/src/ui/organisms/composer.dart
//
// Onde se escreve: a barra de "respondendo a" ou "editando", o campo e o enviar. No
// computador, Enter envia e Shift+Enter quebra a linha; no celular, o botão envia.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/l10n.dart';
import '../../core/chirp_core.dart';

/// O texto mais comprido de uma mensagem (o mesmo limite do núcleo).
const maxMessageChars = 4000;

bool get _enterSends => switch (defaultTargetPlatform) {
  TargetPlatform.linux ||
  TargetPlatform.windows ||
  TargetPlatform.macOS => true,
  _ => false,
};

class Composer extends StatefulWidget {
  const Composer({
    super.key,
    required this.text,
    required this.onSend,
    this.focusNode,
    this.replyTo,
    this.replyName,
    this.editing,
    this.onCancel,
    this.onChanged,
    this.enabled = true,
  });

  final TextEditingController text;
  final FocusNode? focusNode;
  final VoidCallback onSend;
  final ChatMessage? replyTo;

  /// O nome de quem escreveu a mensagem respondida.
  final String? replyName;
  final ChatMessage? editing;
  final VoidCallback? onCancel;
  final ValueChanged<String>? onChanged;
  final bool enabled;

  @override
  State<Composer> createState() => _ComposerState();
}

class _ComposerState extends State<Composer> {
  late final FocusNode _focus = widget.focusNode ?? FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.onKeyEvent = _onKey;
    widget.text.addListener(_changed);
  }

  @override
  void dispose() {
    widget.text.removeListener(_changed);
    if (widget.focusNode == null) _focus.dispose();
    super.dispose();
  }

  void _changed() => setState(() {});

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (!_enterSends || event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey != LogicalKeyboardKey.enter &&
        event.logicalKey != LogicalKeyboardKey.numpadEnter) {
      return KeyEventResult.ignored;
    }
    if (HardwareKeyboard.instance.isShiftPressed) return KeyEventResult.ignored;
    if (_canSend) widget.onSend();
    return KeyEventResult.handled;
  }

  bool get _canSend => widget.enabled && widget.text.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final editing = widget.editing;
    final replyTo = widget.replyTo;
    final banner = editing != null
        ? (Icons.edit, l10n.editingMessage, editing.text)
        : replyTo != null
        ? (
            Icons.reply,
            l10n.replyingTo(widget.replyName ?? ''),
            replyTo.deleted ? l10n.messageDeleted : replyTo.text,
          )
        : null;
    return Material(
      color: scheme.surfaceContainer,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (banner != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(banner.$1, size: 18, color: scheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              banner.$2,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: scheme.primary,
                              ),
                            ),
                            Text(
                              banner.$3,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: l10n.cancel,
                        onPressed: widget.onCancel,
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: widget.text,
                      focusNode: _focus,
                      enabled: widget.enabled,
                      minLines: 1,
                      maxLines: 6,
                      maxLength: maxMessageChars,
                      maxLengthEnforcement: MaxLengthEnforcement.enforced,
                      buildCounter:
                          (
                            context, {
                            required currentLength,
                            required isFocused,
                            required maxLength,
                          }) => currentLength > maxMessageChars - 200
                          ? Text('$currentLength / $maxLength')
                          : null,
                      keyboardType: TextInputType.multiline,
                      textCapitalization: TextCapitalization.sentences,
                      enableIMEPersonalizedLearning: false,
                      enableSuggestions: false,
                      autocorrect: false,
                      onChanged: widget.onChanged,
                      decoration: InputDecoration(
                        hintText: l10n.messageHint,
                        filled: true,
                        fillColor: scheme.surfaceContainerHighest,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton.filled(
                    tooltip: editing != null ? l10n.save : l10n.send,
                    onPressed: _canSend ? widget.onSend : null,
                    icon: Icon(editing != null ? Icons.check : Icons.send),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
