// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chirp_member.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$ChirpMember {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get avatar => throw _privateConstructorUsedError;
  bool get isMe => throw _privateConstructorUsedError;

  /// Create a copy of ChirpMember
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ChirpMemberCopyWith<ChirpMember> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChirpMemberCopyWith<$Res> {
  factory $ChirpMemberCopyWith(
    ChirpMember value,
    $Res Function(ChirpMember) then,
  ) = _$ChirpMemberCopyWithImpl<$Res, ChirpMember>;
  @useResult
  $Res call({String id, String name, String? avatar, bool isMe});
}

/// @nodoc
class _$ChirpMemberCopyWithImpl<$Res, $Val extends ChirpMember>
    implements $ChirpMemberCopyWith<$Res> {
  _$ChirpMemberCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ChirpMember
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? avatar = freezed,
    Object? isMe = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            avatar: freezed == avatar
                ? _value.avatar
                : avatar // ignore: cast_nullable_to_non_nullable
                      as String?,
            isMe: null == isMe
                ? _value.isMe
                : isMe // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ChirpMemberImplCopyWith<$Res>
    implements $ChirpMemberCopyWith<$Res> {
  factory _$$ChirpMemberImplCopyWith(
    _$ChirpMemberImpl value,
    $Res Function(_$ChirpMemberImpl) then,
  ) = __$$ChirpMemberImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String name, String? avatar, bool isMe});
}

/// @nodoc
class __$$ChirpMemberImplCopyWithImpl<$Res>
    extends _$ChirpMemberCopyWithImpl<$Res, _$ChirpMemberImpl>
    implements _$$ChirpMemberImplCopyWith<$Res> {
  __$$ChirpMemberImplCopyWithImpl(
    _$ChirpMemberImpl _value,
    $Res Function(_$ChirpMemberImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ChirpMember
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? avatar = freezed,
    Object? isMe = null,
  }) {
    return _then(
      _$ChirpMemberImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        avatar: freezed == avatar
            ? _value.avatar
            : avatar // ignore: cast_nullable_to_non_nullable
                  as String?,
        isMe: null == isMe
            ? _value.isMe
            : isMe // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc

class _$ChirpMemberImpl implements _ChirpMember {
  const _$ChirpMemberImpl({
    required this.id,
    required this.name,
    this.avatar,
    this.isMe = false,
  });

  @override
  final String id;
  @override
  final String name;
  @override
  final String? avatar;
  @override
  @JsonKey()
  final bool isMe;

  @override
  String toString() {
    return 'ChirpMember(id: $id, name: $name, avatar: $avatar, isMe: $isMe)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChirpMemberImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.avatar, avatar) || other.avatar == avatar) &&
            (identical(other.isMe, isMe) || other.isMe == isMe));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, name, avatar, isMe);

  /// Create a copy of ChirpMember
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ChirpMemberImplCopyWith<_$ChirpMemberImpl> get copyWith =>
      __$$ChirpMemberImplCopyWithImpl<_$ChirpMemberImpl>(this, _$identity);
}

abstract class _ChirpMember implements ChirpMember {
  const factory _ChirpMember({
    required final String id,
    required final String name,
    final String? avatar,
    final bool isMe,
  }) = _$ChirpMemberImpl;

  @override
  String get id;
  @override
  String get name;
  @override
  String? get avatar;
  @override
  bool get isMe;

  /// Create a copy of ChirpMember
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ChirpMemberImplCopyWith<_$ChirpMemberImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
