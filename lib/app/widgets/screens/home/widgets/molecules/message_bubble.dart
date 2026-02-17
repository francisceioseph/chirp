import 'package:chirp/app/themes/chirp_panel_theme.dart';
import 'package:flutter/material.dart';
import 'package:chirp/domain/entities/message.dart';

class MessageBubble extends StatelessWidget {
  final ChirpMessage message;
  final bool showAuthor;
  final bool isFirstInGroup;
  final bool isLastInGroup;

  const MessageBubble({
    super.key,
    required this.message,
    this.showAuthor = true,
    this.isFirstInGroup = true,
    this.isLastInGroup = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isMe = message.isFromMe;

    final panelTheme = theme.extension<ChirpPanelTheme>();
    final baseRadius =
        panelTheme?.decoration?.borderRadius
            ?.resolve(Directionality.of(context))
            .topLeft
            .x ??
        18.0;

    return Padding(
      padding: EdgeInsets.only(
        bottom: isLastInGroup ? 12.0 : 2.5,
        top: isFirstInGroup ? 4.0 : 0,
      ),
      child: Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          if (!isMe && showAuthor) _buildAuthorName(theme),

          _buildBubbleContainer(context, theme, colorScheme, isMe, baseRadius),

          if (isLastInGroup) _buildFooter(theme, colorScheme, isMe),
        ],
      ),
    );
  }

  Widget _buildAuthorName(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 4),
      child: Text(
        message.author,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildBubbleContainer(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isMe,
    double baseRadius,
  ) {
    final isFlat = theme.extension<ChirpPanelTheme>()?.blurSigma == 0;

    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isMe
            ? colorScheme.primary
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: _getInstagramStyleRadius(
          isMe,
          isFirstInGroup,
          isLastInGroup,
          baseRadius,
        ),
        border: (isFlat && !isMe)
            ? null
            : Border.all(color: colorScheme.onSurface.withValues(alpha: 0.05)),
      ),
      child: SelectableText(
        message.body,
        style: theme.textTheme.bodyMedium?.copyWith(
          height: 1.4,
          color: isMe ? colorScheme.onPrimary : colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildFooter(ThemeData theme, ColorScheme colorScheme, bool isMe) {
    final timeStr =
        "${message.dateCreated.hour}:${message.dateCreated.minute.toString().padLeft(2, '0')}";

    return Padding(
      padding: const EdgeInsets.only(top: 4, left: 8, right: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isMe) _buildSecurityIcon(colorScheme.primary),
          Text(
            timeStr,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.4),
              fontSize: 10,
            ),
          ),
          if (!isMe) _buildSecurityIcon(colorScheme.secondary),
        ],
      ),
    );
  }

  Widget _buildSecurityIcon(Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Icon(
        Icons.lock_outline_rounded,
        size: 10,
        color: color.withValues(alpha: 0.5),
      ),
    );
  }

  BorderRadius _getInstagramStyleRadius(
    bool isMe,
    bool isFirst,
    bool isLast,
    double base,
  ) {
    final r = Radius.circular(base);
    final s = Radius.circular(base > 4 ? 4 : 0);

    if (isMe) {
      return BorderRadius.only(
        topLeft: r,
        bottomLeft: r,
        topRight: isFirst ? r : s,
        bottomRight: isLast ? r : s,
      );
    } else {
      return BorderRadius.only(
        topRight: r,
        bottomRight: r,
        topLeft: isFirst ? r : s,
        bottomLeft: isLast ? r : s,
      );
    }
  }
}
