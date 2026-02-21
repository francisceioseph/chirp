import 'package:chirp/domain/entities/nest_entity.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'chirp_message.freezed.dart';
part 'chirp_message.g.dart';

@freezed
class ChirpMessage with _$ChirpMessage implements NestEntity {
  const ChirpMessage._();

  const factory ChirpMessage({
    required String id,
    required String senderId,
    required String conversationId,
    required String author,
    required String body,
    required DateTime dateCreated,
    @Default(false) bool isFromMe,
  }) = _ChirpMessage;

  factory ChirpMessage.fromJson(Map<String, dynamic> json) =>
      _$ChirpMessageFromJson(json);

  String get timeSent =>
      "${dateCreated.hour}:${dateCreated.minute.toString().padLeft(2, '0')}";
}
