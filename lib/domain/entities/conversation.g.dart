// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ConversationImpl _$$ConversationImplFromJson(Map<String, dynamic> json) =>
    _$ConversationImpl(
      id: json['id'] as String,
      targetId: json['targetId'] as String,
      type: $enumDecode(_$ConversationTypeEnumMap, json['type']),
      title: json['title'] as String,
      dateUpdated: DateTime.parse(json['dateUpdated'] as String),
      dateCreated: DateTime.parse(json['dateCreated'] as String),
      lastMessageText: json['lastMessageText'] as String?,
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$ConversationImplToJson(_$ConversationImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'targetId': instance.targetId,
      'type': _$ConversationTypeEnumMap[instance.type]!,
      'title': instance.title,
      'dateUpdated': instance.dateUpdated.toIso8601String(),
      'dateCreated': instance.dateCreated.toIso8601String(),
      'lastMessageText': instance.lastMessageText,
      'unreadCount': instance.unreadCount,
    };

const _$ConversationTypeEnumMap = {
  ConversationType.individual: 'individual',
  ConversationType.group: 'group',
};
