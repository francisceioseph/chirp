// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tiel.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Tiel _$TielFromJson(Map<String, dynamic> json) {
  return _Tiel.fromJson(json);
}

/// @nodoc
mixin _$Tiel {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get address => throw _privateConstructorUsedError;
  DateTime get lastSeen => throw _privateConstructorUsedError;
  String? get publicKey => throw _privateConstructorUsedError;
  TielStatus get status => throw _privateConstructorUsedError;

  /// Serializes this Tiel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Tiel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TielCopyWith<Tiel> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TielCopyWith<$Res> {
  factory $TielCopyWith(Tiel value, $Res Function(Tiel) then) =
      _$TielCopyWithImpl<$Res, Tiel>;
  @useResult
  $Res call({
    String id,
    String name,
    String address,
    DateTime lastSeen,
    String? publicKey,
    TielStatus status,
  });
}

/// @nodoc
class _$TielCopyWithImpl<$Res, $Val extends Tiel>
    implements $TielCopyWith<$Res> {
  _$TielCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Tiel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? address = null,
    Object? lastSeen = null,
    Object? publicKey = freezed,
    Object? status = null,
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
            address: null == address
                ? _value.address
                : address // ignore: cast_nullable_to_non_nullable
                      as String,
            lastSeen: null == lastSeen
                ? _value.lastSeen
                : lastSeen // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            publicKey: freezed == publicKey
                ? _value.publicKey
                : publicKey // ignore: cast_nullable_to_non_nullable
                      as String?,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as TielStatus,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TielImplCopyWith<$Res> implements $TielCopyWith<$Res> {
  factory _$$TielImplCopyWith(
    _$TielImpl value,
    $Res Function(_$TielImpl) then,
  ) = __$$TielImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String address,
    DateTime lastSeen,
    String? publicKey,
    TielStatus status,
  });
}

/// @nodoc
class __$$TielImplCopyWithImpl<$Res>
    extends _$TielCopyWithImpl<$Res, _$TielImpl>
    implements _$$TielImplCopyWith<$Res> {
  __$$TielImplCopyWithImpl(_$TielImpl _value, $Res Function(_$TielImpl) _then)
    : super(_value, _then);

  /// Create a copy of Tiel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? address = null,
    Object? lastSeen = null,
    Object? publicKey = freezed,
    Object? status = null,
  }) {
    return _then(
      _$TielImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        address: null == address
            ? _value.address
            : address // ignore: cast_nullable_to_non_nullable
                  as String,
        lastSeen: null == lastSeen
            ? _value.lastSeen
            : lastSeen // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        publicKey: freezed == publicKey
            ? _value.publicKey
            : publicKey // ignore: cast_nullable_to_non_nullable
                  as String?,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as TielStatus,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TielImpl extends _Tiel {
  const _$TielImpl({
    required this.id,
    required this.name,
    required this.address,
    required this.lastSeen,
    this.publicKey,
    this.status = TielStatus.discovered,
  }) : super._();

  factory _$TielImpl.fromJson(Map<String, dynamic> json) =>
      _$$TielImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String address;
  @override
  final DateTime lastSeen;
  @override
  final String? publicKey;
  @override
  @JsonKey()
  final TielStatus status;

  @override
  String toString() {
    return 'Tiel(id: $id, name: $name, address: $address, lastSeen: $lastSeen, publicKey: $publicKey, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TielImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.lastSeen, lastSeen) ||
                other.lastSeen == lastSeen) &&
            (identical(other.publicKey, publicKey) ||
                other.publicKey == publicKey) &&
            (identical(other.status, status) || other.status == status));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, name, address, lastSeen, publicKey, status);

  /// Create a copy of Tiel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TielImplCopyWith<_$TielImpl> get copyWith =>
      __$$TielImplCopyWithImpl<_$TielImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TielImplToJson(this);
  }
}

abstract class _Tiel extends Tiel {
  const factory _Tiel({
    required final String id,
    required final String name,
    required final String address,
    required final DateTime lastSeen,
    final String? publicKey,
    final TielStatus status,
  }) = _$TielImpl;
  const _Tiel._() : super._();

  factory _Tiel.fromJson(Map<String, dynamic> json) = _$TielImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get address;
  @override
  DateTime get lastSeen;
  @override
  String? get publicKey;
  @override
  TielStatus get status;

  /// Create a copy of Tiel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TielImplCopyWith<_$TielImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
