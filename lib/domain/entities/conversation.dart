import 'package:chirp/domain/entities/nest_entity.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'conversation.freezed.dart';
part 'conversation.g.dart';

enum ConversationType { individual, group }

@freezed
class Conversation with _$Conversation implements NestEntity {
  const Conversation._();

  const factory Conversation({
    required String id,
    required String targetId,
    required ConversationType type,
    required String title,
    required DateTime dateUpdated,
    required DateTime dateCreated,
    String? lastMessageText,
    @Default(0) int unreadCount,
  }) = _Conversation;

  factory Conversation.fromJson(Map<String, dynamic> json) =>
      _$ConversationFromJson(json);

  String get avatar => type == ConversationType.individual
      ? "https://api.dicebear.com/7.x/adventurer/png?seed=$title"
      : "https://api.dicebear.com/7.x/identicon/png?seed=$id&backgroundColor=ffdf00";
}
