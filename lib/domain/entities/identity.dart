import 'package:freezed_annotation/freezed_annotation.dart';

part 'identity.freezed.dart';
part 'identity.g.dart';

@freezed
class Identity with _$Identity {
  const Identity._();

  const factory Identity({
    required String id,
    required String name,
    required String publicKey,
    String? nickname,
    String? email,
    String? privateKey,
  }) = _Identity;

  factory Identity.fromJson(Map<String, dynamic> json) =>
      _$IdentityFromJson(json);

  String get displayName => nickname ?? name;

  Identity toPublic() => copyWith(privateKey: null);
}
