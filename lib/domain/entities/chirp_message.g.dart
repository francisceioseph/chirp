// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chirp_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ChirpMessageImpl _$$ChirpMessageImplFromJson(Map<String, dynamic> json) =>
    _$ChirpMessageImpl(
      id: json['id'] as String,
      senderId: json['senderId'] as String,
      conversationId: json['conversationId'] as String,
      author: json['author'] as String,
      body: json['body'] as String,
      dateCreated: DateTime.parse(json['dateCreated'] as String),
      isFromMe: json['isFromMe'] as bool? ?? false,
    );

Map<String, dynamic> _$$ChirpMessageImplToJson(_$ChirpMessageImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'senderId': instance.senderId,
      'conversationId': instance.conversationId,
      'author': instance.author,
      'body': instance.body,
      'dateCreated': instance.dateCreated.toIso8601String(),
      'isFromMe': instance.isFromMe,
    };
