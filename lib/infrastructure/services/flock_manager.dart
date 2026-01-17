import 'dart:async';
import 'dart:convert';
import 'package:chirp/domain/models/chirp_packet.dart';

import 'package:chirp/domain/entities/identity.dart';
import 'package:chirp/utils/app_logger.dart';
import 'package:peerdart/peerdart.dart';

abstract class FlockManager {
  Stream<dynamic> get packets;

  void init();
  void dispose();
  void sendPacket(String target, ChirpPacket packet);
}

class P2PFlockManager implements FlockManager {
  final Peer _peer;
  final Identity _me;

  final _packetCtrl = StreamController<dynamic>.broadcast();
  final Map<String, DataConnection> _activeConnections = {};

  @override
  Stream<dynamic> get packets => _packetCtrl.stream;

  P2PFlockManager(this._me) : _peer = Peer(id: _me.id);

  @override
  void init() {
    _peer.on<DataConnection>("connection").listen((connection) {
      _setupConnectionListeners(connection);
    });
  }

  @override
  void sendPacket(String target, ChirpPacket packet) {
    final rawData = jsonEncode(packet.toJson());
    _send(target, rawData);
  }

  void _send(String target, String data) {
    DataConnection? conn = _activeConnections[target];

    if (conn != null && conn.open) {
      conn.send(data);
      return;
    }

    conn = _peer.connect(target);
    _setupConnectionListeners(conn);

    conn.on("open").listen((_) {
      if (conn != null && conn.open) {
        conn.send(data);
        log.i("🦜✨ Pacote enviado para $target");
      }
    });
  }

  void _setupConnectionListeners(DataConnection conn) {
    conn.on<dynamic>("data").listen((rawData) {
      _packetCtrl.add(rawData);
    });

    conn.on("open").listen((_) {
      log.i("🦜✅ Conexão aberta com: ${conn.peer}");
      _activeConnections[conn.peer] = conn;
    });

    conn.on("close").listen((_) {
      _activeConnections.remove(conn.peer);
    });

    conn.on("error").listen((err) {
      log.e("🦜❌ Erro na conexão: $err");
    });
  }

  @override
  void dispose() {
    for (var conn in _activeConnections.values) {
      conn.close();
    }

    _peer.dispose();
    _packetCtrl.close();
  }
}
