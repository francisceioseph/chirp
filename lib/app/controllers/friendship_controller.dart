import 'package:chirp/domain/entities/tiel.dart';
import 'package:chirp/domain/models/chirp_packet.dart';
import 'package:chirp/domain/usecases/friendship/complete_handshake_use_case.dart';
import 'package:chirp/domain/usecases/friendship/confirm_friendship_use_case.dart';
import 'package:chirp/domain/usecases/friendship/request_friendship_use_case.dart';
import 'package:chirp/infrastructure/repositories/tiel_nest_repository.dart';
import 'package:chirp/utils/app_logger.dart';
import 'package:flutter/foundation.dart';

class FriendshipController extends ChangeNotifier {
  final RequestFriendshipUseCase _requestFriendshipUseCase;
  final ConfirmFriendshipUseCase _confirmFriendshipUseCase;
  final CompleteHandshakeUseCase _completeHandshakeUseCase;
  final TielNestRepository _tielsRepo;

  final List<ChirpRequestPacket> _pendingRequests = [];

  FriendshipController({
    required RequestFriendshipUseCase requestFriendshipUseCase,
    required ConfirmFriendshipUseCase confirmFriendshipUseCase,
    required CompleteHandshakeUseCase completeHandshakeUseCase,
    required TielNestRepository tielsRepo,
  }) : _requestFriendshipUseCase = requestFriendshipUseCase,
       _confirmFriendshipUseCase = confirmFriendshipUseCase,
       _completeHandshakeUseCase = completeHandshakeUseCase,
       _tielsRepo = tielsRepo {
    _tielsRepo.addListener(notifyListeners);
  }

  List<ChirpRequestPacket> get pendingRequests {
    return _pendingRequests
        .where((packet) => _tielsRepo.cached.containsKey(packet.fromId))
        .toList();
  }

  List<Tiel> get nearbyTiels => _tielsRepo.cached.values
      .where(
        (tiel) =>
            tiel.status == TielStatus.discovered ||
            tiel.status == TielStatus.pending,
      )
      .toList();

  int get notificationCount => pendingRequests.length;

  void handlePendingFriendship(ChirpRequestPacket packet) {
    log.d("📩 [Amizade] Nova solicitação de amizade de ${packet.fromName}");

    _pendingRequests.add(packet);
    notifyListeners();
  }

  Future<void> handleCompleteHandshake(ChirpAcceptPacket packet) async {
    _completeHandshakeUseCase.execute(packet);
  }

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

  Future<void> acceptFriendshipRequest(ChirpRequestPacket request) async {
    log.d(
      "🤝 [Amizade] Aceitando solicitação de amizade de ${request.fromName}...",
    );

    try {
      final tiel = await _tielsRepo.get(request.fromId);

      if (tiel != null) {
        await _confirmFriendshipUseCase.execute(tiel, request);
        _pendingRequests.removeWhere((req) => req.fromId == request.fromId);

        notifyListeners();
      }
    } catch (e) {
      log.e("Falha ao aceitar amizade: $e");
    }
  }
}
