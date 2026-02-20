import 'package:chirp/domain/entities/tiel.dart';
import 'package:chirp/domain/models/chirp_packet.dart';
import 'package:chirp/domain/usecases/friendship/accept_friendship_use_case.dart';
import 'package:chirp/domain/usecases/friendship/request_friendship_use_case.dart';
import 'package:chirp/infrastructure/data/tiels_store.dart';
import 'package:chirp/utils/app_logger.dart';
import 'package:flutter/foundation.dart';

class FriendshipController extends ChangeNotifier {
  final RequestFriendshipUseCase _requestFriendshipUseCase;
  final AcceptFriendshipUseCase _acceptFriendshipUseCase;
  final TielsStore _store;

  final List<ChirpRequestPacket> _pendingRequests = [];

  FriendshipController({
    required RequestFriendshipUseCase requestFriendshipUseCase,
    required AcceptFriendshipUseCase acceptFriendshipUseCase,
    required TielsStore store,
  }) : _requestFriendshipUseCase = requestFriendshipUseCase,
       _acceptFriendshipUseCase = acceptFriendshipUseCase,
       _store = store;

  List<ChirpRequestPacket> get pendingRequests {
    return _pendingRequests
        .where((packet) => _store.contains(packet.fromId))
        .toList();
  }

  int get notificationCount => pendingRequests.length;

  Future<void> requestFriendship(Tiel target) async {
    log.d("🤝 [Amizade] Solicitando conexão com ${target.name}...");

    try {
      await _requestFriendshipUseCase.execute(target);
      notifyListeners();

      log.i("📩 [Amizade] Convite enviado com sucesso para ${target.name}");
    } catch (e) {
      log.e(
        "⚠️ [Amizade] Erro ao solicitar amizade com ${target.name}",
        error: e,
      );
    }
  }

  void handlePendingRequest(ChirpRequestPacket request) {
    log.d("📩 [Amizade] Nova solicitação de amizade de ${request.fromName}");
    _pendingRequests.add(request);
    notifyListeners();
  }

  Future<void> handleAcceptRequest(ChirpRequestPacket request) async {
    log.d(
      "🤝 [Amizade] Aceitando solicitação de amizade de ${request.fromName}...",
    );

    try {
      final tiel = _store.getById(request.fromId);

      if (tiel != null) {
        await _acceptFriendshipUseCase.execute(tiel, request);
        _pendingRequests.removeWhere((req) => req.fromId == request.fromId);

        notifyListeners();
      }
    } catch (e) {
      log.e("Falha ao aceitar amizade: $e");
    }
  }
}
