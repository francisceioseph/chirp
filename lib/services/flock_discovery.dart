import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:chirp/models/chirp_packet.dart';
import 'package:chirp/utils/app_logger.dart';

abstract class FlockDiscovery {
  Map<String, String> get knownPublicKeys;

  Future<void> advertise(String id, String name);
  Future<void> discover(
    Function(String id, String name, String address) onChirpFound,
  );
  Future<void> stop();
}

class FlockDiscoveryService implements FlockDiscovery {
  final _discoveryPort = 4545;
  final _advertisePort = 0;
  final _advertiseAddress = "255.255.255.255";
  final Map<String, String> _knownPublicKeys = {};

  RawDatagramSocket? _socket;
  RawDatagramSocket? _receiver;
  StreamSubscription? _advertiseTimer;

  @override
  Map<String, String> get knownPublicKeys => _knownPublicKeys;

  @override
  Future<void> advertise(String id, String name) async {
    _socket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      _advertisePort,
    );

    _socket!.broadcastEnabled = true;

    _advertiseTimer = Stream.periodic(const Duration(seconds: 10)).listen((_) {
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

      try {
        final String rawMessage = utf8.decode(datagram.data);
        final Map<String, dynamic> rawJson = jsonDecode(rawMessage);
        final packet = ChirpPacket.fromJson(rawJson);

        if (packet is ChirpIdentityPacket) {
          onFound(packet.fromId, packet.fromName, datagram.address.address);
        }
      } catch (e) {
        log.w("🦜⚠️ Recebido pacote inválido ou de outro app: $e");
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
    final identity = ChirpIdentityPacket(fromId: id, fromName: name);
    final rawJson = jsonEncode(identity.toJson());

    _socket?.send(
      utf8.encode(rawJson),
      InternetAddress(_advertiseAddress),
      _discoveryPort,
    );

    log.i("🦜📣 Calling my flock with : $name");
  }
}
