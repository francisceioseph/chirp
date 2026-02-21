// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'participant.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ParticipantImpl _$$ParticipantImplFromJson(Map<String, dynamic> json) =>
    _$ParticipantImpl(
      id: json['id'] as String,
      tielId: json['tielId'] as String,
      conversationId: json['conversationId'] as String,
      joinedAt: DateTime.parse(json['joinedAt'] as String),
      alias: json['alias'] as String?,
    );

Map<String, dynamic> _$$ParticipantImplToJson(_$ParticipantImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tielId': instance.tielId,
      'conversationId': instance.conversationId,
      'joinedAt': instance.joinedAt.toIso8601String(),
      'alias': instance.alias,
    };
