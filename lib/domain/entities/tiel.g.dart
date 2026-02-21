// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tiel.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TielImpl _$$TielImplFromJson(Map<String, dynamic> json) => _$TielImpl(
  id: json['id'] as String,
  name: json['name'] as String,
  address: json['address'] as String,
  lastSeen: DateTime.parse(json['lastSeen'] as String),
  publicKey: json['publicKey'] as String?,
  status:
      $enumDecodeNullable(_$TielStatusEnumMap, json['status']) ??
      TielStatus.discovered,
);

Map<String, dynamic> _$$TielImplToJson(_$TielImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'address': instance.address,
      'lastSeen': instance.lastSeen.toIso8601String(),
      'publicKey': instance.publicKey,
      'status': _$TielStatusEnumMap[instance.status]!,
    };

const _$TielStatusEnumMap = {
  TielStatus.discovered: 'discovered',
  TielStatus.pending: 'pending',
  TielStatus.connected: 'connected',
  TielStatus.away: 'away',
  TielStatus.blocked: 'blocked',
  TielStatus.error: 'error',
};
