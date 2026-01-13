import 'dart:async';

import 'package:peerdart/peerdart.dart';

abstract class FlockManager {
  Stream<String> get messages;

  void init();
  void dispose();
  void send(String target, String message);
}

class P2PFlockManager implements FlockManager {
  final Peer _peer;
  final _msgsCtrl = StreamController<String>.broadcast();

  final Map<String, DataConnection> _activeConnections = {};

  @override
  Stream<String> get messages => _msgsCtrl.stream;

  P2PFlockManager(String myId) : _peer = Peer(id: myId);

  @override
  void init() {
    _peer.on<DataConnection>("connection").listen((connection) {
      _setupConnectionListeners(connection);
    });
  }

  @override
  void send(String target, String message) {
    if (_activeConnections.containsKey(target)) {
      _activeConnections[target]!.send(message);
      return;
    }

    final conn = _peer.connect(target);
    _setupConnectionListeners(conn);

    conn.on("open").listen((_) {
      conn.send(message);
    });
  }

  void _setupConnectionListeners(DataConnection conn) {
    conn.on<dynamic>("data").listen((data) {
      _msgsCtrl.add(data.toString());
    });

    conn.on("open").listen((_) {
      _activeConnections[conn.peer] = conn;
    });

    conn.on("close").listen((_) {
      _activeConnections.remove(conn.peer);
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
