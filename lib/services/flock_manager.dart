import 'dart:async';
import 'dart:convert';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:crypton/crypton.dart';

import 'package:chirp/models/identity.dart';
import 'package:chirp/models/message.dart';
import 'package:chirp/utils/app_logger.dart';
import 'package:flutter/scheduler.dart';
import 'package:peerdart/peerdart.dart';

abstract class FlockManager {
  Stream<String> get messages;

  void init();
  void dispose();
  void chirp(String target, ChirpMessage message);
}

class P2PFlockManager implements FlockManager {
  final Peer _peer;
  final Identity _me;
  final Map<String, String> _pubKeys;

  final _msgsCtrl = StreamController<String>.broadcast();

  final Map<String, DataConnection> _activeConnections = {};

  @override
  Stream<String> get messages => _msgsCtrl.stream;

  P2PFlockManager(this._me, this._pubKeys) : _peer = Peer(id: _me.id);

  @override
  void init() {
    _peer.on<DataConnection>("connection").listen((connection) {
      _setupConnectionListeners(connection);
    });
  }

  @override
  void chirp(String target, ChirpMessage message) {
    final targetPubKey = _pubKeys[target];

    if (targetPubKey == null) {
      log.e("🦜❌ Não tenho a chave pública de $target para envio seguro.");
      return;
    }

    final aesKey = enc.Key.fromSecureRandom(32);
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(aesKey));

    final payload = encrypter.encrypt(jsonEncode(message.toJson()), iv: iv);

    final rsaPubKey = RSAPublicKey.fromString(targetPubKey);
    final encKey = rsaPubKey.encrypt(aesKey.base64);

    final envelope = {
      'payload': payload.base64,
      'key': encKey,
      'iv': iv.base64,
    };

    _send(target, jsonEncode(envelope));
  }

  void _send(String target, String message) {
    DataConnection? conn = _activeConnections[target];

    if (conn != null && conn.open) {
      conn.send(message);
      return;
    }

    conn = _peer.connect(target);
    _setupConnectionListeners(conn);

    conn.on("open").listen((_) {
      if (conn != null && conn.open) {
        conn.send(message);
        log.i("🦜✨ Chirp enviado após abrir conexão com $target");
      }
    });
  }

  void _setupConnectionListeners(DataConnection conn) {
    conn.on<dynamic>("data").listen((rawData) {
      try {
        final envelope = jsonDecode(rawData);

        final rsaPrivKey = RSAPrivateKey.fromString(_me.privateKey!);
        final aesKeyBase64 = rsaPrivKey.decrypt(envelope['key']);

        final aesKey = enc.Key.fromBase64(aesKeyBase64);
        final iv = enc.IV.fromBase64(envelope['iv']);
        final encrypter = enc.Encrypter(enc.AES(aesKey));

        final decriptedJson = encrypter.decrypt64(envelope['payload'], iv: iv);

        SchedulerBinding.instance.addPostFrameCallback((_) {
          _msgsCtrl.add(decriptedJson);
        });
      } catch (e) {
        log.w("🦜🛡️ Zero Trust: Bloqueado pacote suspeito ou mal formatado.");
      }
    });

    conn.on("open").listen((_) {
      log.i("🦜✅ Conexão aberta com: ${conn.peer}");

      SchedulerBinding.instance.addPostFrameCallback((_) {
        _activeConnections[conn.peer] = conn;
      });
    });

    conn.on("error").listen((err) {
      log.e("🦜❌ Erro na conexão: $err");
    });

    conn.on("close").listen((_) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _activeConnections.remove(conn.peer);
      });
    });
  }

  @override
  void dispose() {
    for (var conn in _activeConnections.values) {
      conn.close();
    }

    _peer.dispose();
    _msgsCtrl.close();
  }
}
