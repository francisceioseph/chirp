import 'package:chirp/models/message.dart';
import 'package:flutter/material.dart';

class MessageBubble extends StatelessWidget {
  final ChirpMessage message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMe = message.isFromMe;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          // Nome do remetente
          if (!isMe)
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 4),
              child: Text(
                message.author,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

          // Bolha de Vidro
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isMe
                  ? theme.colorScheme.primary.withValues(alpha: 0.15)
                  : theme.colorScheme.onSurface.withValues(alpha: 0.08),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMe ? 16 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 16),
              ),
              border: Border.all(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
              ),
            ),
            child: Text(
              message.body,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.3),
            ),
          ),

          // Rodapé: Hora + Ícone Secure Chirp™
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 6, right: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isMe) ...[
                  Icon(
                    Icons.security_rounded,
                    size: 10,
                    color: theme.colorScheme.primary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 4),
                ],
                Text(
                  "${message.dateCreated.hour}:${message.dateCreated.minute.toString().padLeft(2, '0')}",
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                if (!isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.security_rounded,
                    size: 10,
                    color: theme.colorScheme.secondary.withValues(alpha: 0.5),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
