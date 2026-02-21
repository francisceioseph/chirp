// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chirp_message.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ChirpMessage _$ChirpMessageFromJson(Map<String, dynamic> json) {
  return _ChirpMessage.fromJson(json);
}

/// @nodoc
mixin _$ChirpMessage {
  String get id => throw _privateConstructorUsedError;
  String get senderId => throw _privateConstructorUsedError;
  String get conversationId => throw _privateConstructorUsedError;
  String get author => throw _privateConstructorUsedError;
  String get body => throw _privateConstructorUsedError;
  DateTime get dateCreated => throw _privateConstructorUsedError;
  bool get isFromMe => throw _privateConstructorUsedError;

  /// Serializes this ChirpMessage to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ChirpMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ChirpMessageCopyWith<ChirpMessage> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChirpMessageCopyWith<$Res> {
  factory $ChirpMessageCopyWith(
    ChirpMessage value,
    $Res Function(ChirpMessage) then,
  ) = _$ChirpMessageCopyWithImpl<$Res, ChirpMessage>;
  @useResult
  $Res call({
    String id,
    String senderId,
    String conversationId,
    String author,
    String body,
    DateTime dateCreated,
    bool isFromMe,
  });
}

/// @nodoc
class _$ChirpMessageCopyWithImpl<$Res, $Val extends ChirpMessage>
    implements $ChirpMessageCopyWith<$Res> {
  _$ChirpMessageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ChirpMessage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? senderId = null,
    Object? conversationId = null,
    Object? author = null,
    Object? body = null,
    Object? dateCreated = null,
    Object? isFromMe = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            senderId: null == senderId
                ? _value.senderId
                : senderId // ignore: cast_nullable_to_non_nullable
                      as String,
            conversationId: null == conversationId
                ? _value.conversationId
                : conversationId // ignore: cast_nullable_to_non_nullable
                      as String,
            author: null == author
                ? _value.author
                : author // ignore: cast_nullable_to_non_nullable
                      as String,
            body: null == body
                ? _value.body
                : body // ignore: cast_nullable_to_non_nullable
                      as String,
            dateCreated: null == dateCreated
                ? _value.dateCreated
                : dateCreated // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            isFromMe: null == isFromMe
                ? _value.isFromMe
                : isFromMe // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ChirpMessageImplCopyWith<$Res>
    implements $ChirpMessageCopyWith<$Res> {
  factory _$$ChirpMessageImplCopyWith(
    _$ChirpMessageImpl value,
    $Res Function(_$ChirpMessageImpl) then,
  ) = __$$ChirpMessageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String senderId,
    String conversationId,
    String author,
    String body,
    DateTime dateCreated,
    bool isFromMe,
  });
}

/// @nodoc
class __$$ChirpMessageImplCopyWithImpl<$Res>
    extends _$ChirpMessageCopyWithImpl<$Res, _$ChirpMessageImpl>
    implements _$$ChirpMessageImplCopyWith<$Res> {
  __$$ChirpMessageImplCopyWithImpl(
    _$ChirpMessageImpl _value,
    $Res Function(_$ChirpMessageImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ChirpMessage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? senderId = null,
    Object? conversationId = null,
    Object? author = null,
    Object? body = null,
    Object? dateCreated = null,
    Object? isFromMe = null,
  }) {
    return _then(
      _$ChirpMessageImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        senderId: null == senderId
            ? _value.senderId
            : senderId // ignore: cast_nullable_to_non_nullable
                  as String,
        conversationId: null == conversationId
            ? _value.conversationId
            : conversationId // ignore: cast_nullable_to_non_nullable
                  as String,
        author: null == author
            ? _value.author
            : author // ignore: cast_nullable_to_non_nullable
                  as String,
        body: null == body
            ? _value.body
            : body // ignore: cast_nullable_to_non_nullable
                  as String,
        dateCreated: null == dateCreated
            ? _value.dateCreated
            : dateCreated // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        isFromMe: null == isFromMe
            ? _value.isFromMe
            : isFromMe // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ChirpMessageImpl extends _ChirpMessage {
  const _$ChirpMessageImpl({
    required this.id,
    required this.senderId,
    required this.conversationId,
    required this.author,
    required this.body,
    required this.dateCreated,
    this.isFromMe = false,
  }) : super._();

  factory _$ChirpMessageImpl.fromJson(Map<String, dynamic> json) =>
      _$$ChirpMessageImplFromJson(json);

  @override
  final String id;
  @override
  final String senderId;
  @override
  final String conversationId;
  @override
  final String author;
  @override
  final String body;
  @override
  final DateTime dateCreated;
  @override
  @JsonKey()
  final bool isFromMe;

  @override
  String toString() {
    return 'ChirpMessage(id: $id, senderId: $senderId, conversationId: $conversationId, author: $author, body: $body, dateCreated: $dateCreated, isFromMe: $isFromMe)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChirpMessageImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.senderId, senderId) ||
                other.senderId == senderId) &&
            (identical(other.conversationId, conversationId) ||
                other.conversationId == conversationId) &&
            (identical(other.author, author) || other.author == author) &&
            (identical(other.body, body) || other.body == body) &&
            (identical(other.dateCreated, dateCreated) ||
                other.dateCreated == dateCreated) &&
            (identical(other.isFromMe, isFromMe) ||
                other.isFromMe == isFromMe));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    senderId,
    conversationId,
    author,
    body,
    dateCreated,
    isFromMe,
  );

  /// Create a copy of ChirpMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ChirpMessageImplCopyWith<_$ChirpMessageImpl> get copyWith =>
      __$$ChirpMessageImplCopyWithImpl<_$ChirpMessageImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ChirpMessageImplToJson(this);
  }
}

abstract class _ChirpMessage extends ChirpMessage {
  const factory _ChirpMessage({
    required final String id,
    required final String senderId,
    required final String conversationId,
    required final String author,
    required final String body,
    required final DateTime dateCreated,
    final bool isFromMe,
  }) = _$ChirpMessageImpl;
  const _ChirpMessage._() : super._();

  factory _ChirpMessage.fromJson(Map<String, dynamic> json) =
      _$ChirpMessageImpl.fromJson;

  @override
  String get id;
  @override
  String get senderId;
  @override
  String get conversationId;
  @override
  String get author;
  @override
  String get body;
  @override
  DateTime get dateCreated;
  @override
  bool get isFromMe;

  /// Create a copy of ChirpMessage
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ChirpMessageImplCopyWith<_$ChirpMessageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
