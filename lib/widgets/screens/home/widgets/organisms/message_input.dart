import 'dart:ui'; // Necessário para o BackdropFilter
import 'package:flutter/material.dart';

class MessageInput extends StatefulWidget {
  final Function(String) onSend;
  final bool isEnabled;

  const MessageInput({super.key, required this.onSend, this.isEnabled = true});

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  void _submit() {
    final text = _controller.text.trim();

    if (text.isNotEmpty && widget.isEnabled) {
      widget.onSend(text);
      _controller.clear();
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.1),
            border: Border(
              top: BorderSide(
                color: colorScheme.primary.withValues(alpha: 0.1),
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    enabled: widget.isEnabled,
                    onSubmitted: (_) => _submit(),
                    maxLines: 5,
                    minLines: 1,
                    style: theme.textTheme.bodyMedium,
                    decoration: InputDecoration(
                      hintText: widget.isEnabled
                          ? "Envie um chirp..."
                          : "Tiel fora de alcance...",
                      hintStyle: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.4),
                        fontSize: 14,
                      ),
                      filled: true,
                      // Cor do campo de texto mais sutil
                      fillColor: colorScheme.onSurface.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: colorScheme.primary.withValues(alpha: 0.05),
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: widget.isEnabled
                          ? [
                              BoxShadow(
                                color: colorScheme.primary.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: IconButton.filled(
                      onPressed: widget.isEnabled ? _submit : null,
                      icon: const Icon(Icons.send_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        disabledBackgroundColor: colorScheme.onSurface
                            .withValues(alpha: 0.1),
                      ),
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

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
