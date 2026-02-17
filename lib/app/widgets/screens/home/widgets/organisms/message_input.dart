import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:chirp/app/themes/chirp_panel_theme.dart';

class MessageInput extends StatefulWidget {
  final Function(String) onSend;
  final VoidCallback? onAttachFile;
  final bool isEnabled;

  const MessageInput({
    super.key,
    required this.onSend,
    this.onAttachFile,
    this.isEnabled = true,
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _showEmojiPicker = false;

  void _submit() {
    final text = _controller.text.trim();
    if (text.isNotEmpty && widget.isEnabled) {
      widget.onSend(text);
      _controller.clear();
      _focusNode.requestFocus();
    }
  }

  void _onEmojiSelected(Category? category, Emoji emoji) {
    _controller
      ..text += emoji.emoji
      ..selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final panelTheme = theme.extension<ChirpPanelTheme>();
    final isFlat = panelTheme?.blurSigma == 0;

    return WillPopScope(
      onWillPop: () {
        if (_showEmojiPicker) {
          setState(() => _showEmojiPicker = false);
          return Future.value(false);
        }
        return Future.value(true);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: panelTheme?.blurSigma ?? 10,
                sigmaY: panelTheme?.blurSigma ?? 10,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surface.withValues(
                    alpha: isFlat ? 1.0 : 0.1,
                  ),
                  border: Border(
                    top: BorderSide(
                      color: colorScheme.onSurface.withValues(alpha: 0.1),
                      width: 0.5,
                    ),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildTextField(theme, colorScheme),
                      const SizedBox(width: 8),
                      _buildAttachButton(colorScheme),
                      _buildSendButton(colorScheme),
                    ],
                  ),
                ),
              ),
            ),
          ),

          if (_showEmojiPicker)
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: _showEmojiPicker
                  ? SizedBox(
                      height: 256,
                      child: EmojiPicker(
                        onEmojiSelected: _onEmojiSelected,
                        config: Config(
                          checkPlatformCompatibility: true,
                          emojiViewConfig: EmojiViewConfig(
                            emojiSizeMax:
                                28 *
                                (foundation.defaultTargetPlatform ==
                                        TargetPlatform.iOS
                                    ? 1.2
                                    : 1.0),
                            backgroundColor: colorScheme.surface,
                            noRecents: Center(
                              child: Text(
                                'Sem recentes',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                          categoryViewConfig: CategoryViewConfig(
                            backgroundColor: colorScheme.surface,
                            indicatorColor: colorScheme.primary,
                            iconColorSelected: colorScheme.primary,
                            iconColor: colorScheme.onSurfaceVariant,
                            dividerColor: colorScheme.outlineVariant,
                          ),
                          bottomActionBarConfig: BottomActionBarConfig(
                            backgroundColor: colorScheme.surface,
                            buttonIconColor: colorScheme.primary,
                          ),
                          searchViewConfig: SearchViewConfig(
                            backgroundColor: colorScheme.surface,
                            buttonIconColor: colorScheme.primary,
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField(ThemeData theme, ColorScheme colorScheme) {
    return Expanded(
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        enabled: widget.isEnabled,
        onSubmitted: (_) => _submit(),
        onTap: () => setState(() => _showEmojiPicker = false),
        maxLines: 5,
        minLines: 1,
        decoration: InputDecoration(
          prefixIcon: IconButton(
            icon: Icon(
              _showEmojiPicker
                  ? Icons.keyboard
                  : Icons.sentiment_satisfied_alt_rounded,
              color: colorScheme.primary,
            ),
            onPressed: () {
              setState(() => _showEmojiPicker = !_showEmojiPicker);
              if (_showEmojiPicker) _focusNode.unfocus();
            },
          ),
          hintText: widget.isEnabled
              ? "Envie um chirp..."
              : "Tiel fora de alcance...",
          filled: true,
          fillColor: colorScheme.onSurface.withValues(alpha: 0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
        ),
      ),
    );
  }

  Widget _buildAttachButton(ColorScheme colorScheme) {
    return IconButton(
      onPressed: widget.isEnabled ? widget.onAttachFile : null,
      icon: const Icon(Icons.attach_file_rounded),
      color: colorScheme.primary,
    );
  }

  Widget _buildSendButton(ColorScheme colorScheme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 4, left: 4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: widget.isEnabled
            ? [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                ),
              ]
            : null,
      ),
      child: IconButton.filled(
        onPressed: widget.isEnabled ? _submit : null,
        icon: const Icon(Icons.send_rounded),
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
