import 'package:chirp/domain/entities/identity.dart';
import 'package:chirp/domain/entities/tiel.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'chirp_member.freezed.dart';

@freezed
class ChirpMember with _$ChirpMember {
  const factory ChirpMember({
    required String id,
    required String name,
    String? avatar,
    @Default(false) bool isMe,
  }) = _ChirpMember;

  factory ChirpMember.fromIdentity(Identity identity) => ChirpMember(
    id: identity.id,
    name: identity.name,
    avatar: "https://api.dicebear.com/7.x/adventurer/png?seed=${identity.name}",
    isMe: true,
  );

  factory ChirpMember.fromTiel(Tiel tiel) => ChirpMember(
    id: tiel.id,
    name: tiel.name,
    avatar: tiel.avatar,
    isMe: false,
  );
}
