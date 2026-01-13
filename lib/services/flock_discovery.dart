import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:chirp/utils/app_logger.dart';

abstract class FlockDiscovery {
  Future<void> advertise(String name);
  Future<void> discover(Function(String name, String address) onChirpFound);
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
  Future<void> advertise(String name) async {
    _socket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      _advertisePort,
    );
    _socket!.broadcastEnabled = true;

    _advertiseTimer = Stream.periodic(const Duration(seconds: 5)).listen((_) {
      _emitFlockCall(name);
    });
  }

  @override
  Future<void> discover(Function(String name, String address) onFound) async {
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
        final String peerName = message.split(":")[1];
        final String peerIp = datagram.address.address;
        onFound(peerName, peerIp);
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

  void _emitFlockCall(String name) {
    final message = _buildFlockCallMessage(name);

    _socket?.send(
      utf8.encode(message),
      InternetAddress(_advertiseAddress),
      _discoveryPort,
    );

    log.i("🦜📣 Calling my flock with : $name");
  }

  String _buildFlockCallMessage(String name) {
    return "$_identityPrefix:$name";
  }
}
