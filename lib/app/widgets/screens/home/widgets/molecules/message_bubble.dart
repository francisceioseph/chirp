import 'package:chirp/models/message.dart';
import 'package:flutter/material.dart';

class MessageBubble extends StatelessWidget {
  final ChirpMessage message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isMe = message.isFromMe;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          if (!isMe) _buildAuthorName(theme),
          _buildGlassBubble(context, theme, colorScheme, isMe),
          _buildFooter(theme, colorScheme, isMe),
        ],
      ),
    );
  }

  Widget _buildAuthorName(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Text(
        message.author,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildGlassBubble(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isMe,
  ) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.7,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isMe
            ? colorScheme.primary.withValues(alpha: 0.15)
            : colorScheme.onSurface.withValues(alpha: 0.08),
        borderRadius: _getBorderRadius(isMe),
        border: Border.all(
          color: isMe
              ? colorScheme.primary.withValues(alpha: 0.15)
              : colorScheme.onSurface.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: isMe
                ? colorScheme.primary.withValues(alpha: 0.2)
                : colorScheme.onSurface.withValues(alpha: 0.05),
            blurRadius: 8,
            spreadRadius: 1,
            offset: Offset.zero,
          ),
        ],
      ),
      child: Text(
        message.body,
        style: theme.textTheme.bodyMedium?.copyWith(height: 1.3),
      ),
    );
  }

  Widget _buildFooter(ThemeData theme, ColorScheme colorScheme, bool isMe) {
    final securityColor = isMe ? colorScheme.primary : colorScheme.secondary;
    final timeStr =
        "${message.dateCreated.hour}:${message.dateCreated.minute.toString().padLeft(2, '0')}";

    return Padding(
      padding: const EdgeInsets.only(top: 4, left: 6, right: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isMe) ...[
            Icon(
              Icons.security_rounded,
              size: 10,
              color: securityColor.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            timeStr,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          if (!isMe) ...[
            const SizedBox(width: 4),
            Icon(
              Icons.security_rounded,
              size: 10,
              color: securityColor.withValues(alpha: 0.5),
            ),
          ],
        ],
      ),
    );
  }

  BorderRadius _getBorderRadius(bool isMe) {
    return BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: Radius.circular(isMe ? 16 : 4),
      bottomRight: Radius.circular(isMe ? 4 : 16),
    );
  }
}
