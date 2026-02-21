// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'identity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$IdentityImpl _$$IdentityImplFromJson(Map<String, dynamic> json) =>
    _$IdentityImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      publicKey: json['publicKey'] as String,
      nickname: json['nickname'] as String?,
      email: json['email'] as String?,
      privateKey: json['privateKey'] as String?,
    );

Map<String, dynamic> _$$IdentityImplToJson(_$IdentityImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'publicKey': instance.publicKey,
      'nickname': instance.nickname,
      'email': instance.email,
      'privateKey': instance.privateKey,
    };
