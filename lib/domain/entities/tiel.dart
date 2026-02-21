import 'package:chirp/domain/entities/nest_entity.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/material.dart';

part 'tiel.freezed.dart';
part 'tiel.g.dart';

enum TielStatus { discovered, pending, connected, away, blocked, error }

@freezed
class Tiel with _$Tiel implements NestEntity {
  const Tiel._();

  const factory Tiel({
    required String id,
    required String name,
    required String address,
    required DateTime lastSeen,
    String? publicKey,
    @Default(TielStatus.discovered) TielStatus status,
  }) = _Tiel;

  factory Tiel.fromJson(Map<String, dynamic> json) => _$TielFromJson(json);

  String get avatar => "https://api.dicebear.com/7.x/adventurer/png?seed=$name";

  bool get isSecure => publicKey != null && status == TielStatus.connected;

  String get statusText => switch (status) {
    TielStatus.discovered => "Pousou por perto",
    TielStatus.pending => "Enviando pio...",
    TielStatus.connected => "Voando juntos",
    TielStatus.away => "Soneca...",
    TielStatus.blocked => "Fora do bando",
    TielStatus.error => "Asas tropeçaram!",
  };

  Color getStatusColor(ColorScheme colorScheme) => switch (status) {
    TielStatus.discovered => Colors.tealAccent,
    TielStatus.pending => Colors.orangeAccent,
    TielStatus.connected => colorScheme.primary,
    TielStatus.away => Colors.blueGrey.shade300,
    TielStatus.blocked => Colors.redAccent,
    TielStatus.error => colorScheme.error,
  };
}
