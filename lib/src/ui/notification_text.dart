// lib/src/ui/notification_text.dart
//
// A prévia de uma mensagem (na lista e na notificação) e o que a notificação mostra
// em cada modo: só "Nova mensagem", o nome, ou o nome e o texto.
import '../../l10n/l10n.dart';
import '../core/chirp_core.dart';
import 'molecules/conversation_tile.dart';

/// A mensagem numa linha.
String messagePreview(ChirpLocalizations l10n, ChatMessage message) =>
    switch (message) {
      ChatMessage(kind: MessageKind.nudge) => l10n.nudgePreview,
      ChatMessage(
        kind: MessageKind.file,
        deleted: false,
        file: ChatFile(voice: true),
      ) =>
        l10n.voicePreview,
      ChatMessage(kind: MessageKind.file, deleted: false) => l10n.filePreview(
        message.text,
      ),
      ChatMessage(deleted: true) => l10n.messageDeleted,
      _ => message.text.replaceAll('\n', ' '),
    };

/// O título e o texto da notificação de [conversation]; `null` com elas desligadas.
({String title, String body})? notificationText(
  ChirpLocalizations l10n,
  NotificationMode mode,
  Conversation conversation,
) {
  final last = conversation.last;
  if (last == null) return null;
  return switch (mode) {
    NotificationMode.off => null,
    NotificationMode.hidden => (
      title: l10n.appName,
      body: l10n.notificationNewMessage,
    ),
    NotificationMode.sender => (
      title: contactName(l10n, conversation.contact),
      body: l10n.notificationNewMessage,
    ),
    NotificationMode.full => (
      title: contactName(l10n, conversation.contact),
      body: messagePreview(l10n, last),
    ),
  };
}
