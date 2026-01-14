import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:chirp/utils/app_logger.dart';

abstract class FlockDiscovery {
  Future<void> advertise(String id, String name);
  Future<void> discover(
    Function(String id, String name, String address) onChirpFound,
  );
  Future<void> stop();
}

class FlockDiscoveryService implements FlockDiscovery {
  final _identityPrefix = "chirp_identity";
  final _discoveryPort = 4545;
  final _advertisePort = 0;
  final _advertiseAddress = "255.255.255.255";

  RawDatagramSocket? _socket;
  RawDatagramSocket? _receiver;
  StreamSubscription? _advertiseTimer;

  @override
  Future<void> advertise(String id, String name) async {
    _socket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      _advertisePort,
    );
    _socket!.broadcastEnabled = true;

    _advertiseTimer = Stream.periodic(const Duration(seconds: 5)).listen((_) {
      _emitFlockCall(id, name);
    });
  }

  @override
  Future<void> discover(
    Function(String id, String name, String address) onFound,
  ) async {
    _receiver = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      _discoveryPort,
    );

    log.i("🦜🔍 Looking for my flock at port: $_discoveryPort");

    _receiver!.listen((event) {
      if (event != RawSocketEvent.read || _receiver == null) {
        return;
      }

      final datagram = _receiver!.receive();

      if (datagram == null) {
        return;
      }

      final String message = utf8.decode(datagram.data);

      if (message.startsWith(_identityPrefix)) {
        final String parts = message.split(":")[1];
        if (parts.length < 2) return;

        final identity = parts.split("|");
        if (identity.length < 2) return;

        final peerId = identity[0];
        final peerName = identity[1];
        final String peerIp = datagram.address.address;

        onFound(peerId, peerName, peerIp);
      }
    });
  }

  @override
  Future<void> stop() async {
    _socket?.close();
    _socket = null;

    _receiver?.close();
    _receiver = null;

    await _advertiseTimer?.cancel();
    _advertiseTimer = null;

    log.i('🦜🛑 Network services halted.');
  }

  void _emitFlockCall(String id, String name) {
    final message = "$_identityPrefix:$id|$name";

    _socket?.send(
      utf8.encode(message),
      InternetAddress(_advertiseAddress),
      _discoveryPort,
    );

    log.i("🦜📣 Calling my flock with : $name");
  }
}
