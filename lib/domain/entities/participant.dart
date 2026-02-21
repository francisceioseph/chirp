import 'package:chirp/domain/entities/nest_entity.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'participant.freezed.dart';
part 'participant.g.dart';

@freezed
class Participant with _$Participant implements NestEntity {
  const factory Participant({
    required String id,
    required String tielId,
    required String conversationId,
    required DateTime joinedAt,
    String? alias,
  }) = _Participant;

  factory Participant.fromJson(Map<String, dynamic> json) =>
      _$ParticipantFromJson(json);
}
