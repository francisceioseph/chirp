import 'package:flutter/material.dart';
import 'package:chirp/domain/entities/tiel.dart';
import 'package:chirp/domain/models/chirp_packet.dart';
import 'package:chirp/domain/usecases/friendship/accept_friendship_use_case.dart';
import 'package:chirp/domain/usecases/friendship/request_friendship_use_case.dart';
import 'package:chirp/infrastructure/repositories/tiel_nest_repository.dart';
import 'package:chirp/utils/app_logger.dart';

class FriendshipController extends ChangeNotifier {
  final RequestFriendshipUseCase _requestUseCase;
  final AcceptFriendshipUseCase _acceptUseCase;
  final TielNestRepository _tielRepo;

  final List<ChirpRequestPacket> _pendingRequests = [];

  FriendshipController({
    required RequestFriendshipUseCase requestUseCase,
    required AcceptFriendshipUseCase acceptUseCase,
    required TielNestRepository tielRepo,
  }) : _requestUseCase = requestUseCase,
       _acceptUseCase = acceptUseCase,
       _tielRepo = tielRepo;

  // --- Getters ---

  List<ChirpRequestPacket> get pendingRequests =>
      List.unmodifiable(_pendingRequests);

  int get notificationCount => _pendingRequests.length;

  // --- Ações de Amizade ---

  Future<void> requestFriendship(Tiel target) async {
    _log("🤝 Solicitando amizade para ${target.name} (${target.id})...");

    try {
      final updatedTiel = await _requestUseCase.execute(target);

      await _tielRepo.save(updatedTiel);

      _log("📩 Convite enviado com sucesso para ${target.name}.");
      notifyListeners();
    } catch (e) {
      _log(
        "⚠️ Falha ao solicitar amizade com ${target.name}",
        isError: true,
        error: e,
      );
      rethrow;
    }
  }

  Future<Tiel> acceptFriendship(Tiel tiel, ChirpRequestPacket request) async {
    _log("✅ Aceitando amizade de ${tiel.name}...");

    try {
      final authorizedTiel = await _acceptUseCase.execute(tiel, request);

      await _tielRepo.save(authorizedTiel);

      _pendingRequests.removeWhere((req) => req.fromId == request.fromId);

      _log("✨ Agora você e ${tiel.name} estão conectados no bando!");
      notifyListeners();

      return authorizedTiel;
    } catch (e) {
      _log(
        "💥 Erro ao aceitar amizade de ${tiel.name}",
        isError: true,
        error: e,
      );
      rethrow;
    }
  }

  void addIncomingRequest(ChirpRequestPacket packet) {
    if (_pendingRequests.any((req) => req.fromId == packet.fromId)) return;

    _log("🔔 Novo pedido de amizade recebido de ${packet.fromId}");
    _pendingRequests.add(packet);
    notifyListeners();
  }

  void dismissRequest(String fromId) {
    _pendingRequests.removeWhere((req) => req.fromId == fromId);
    notifyListeners();
  }

  // --- Helpers ---

  void _log(String message, {bool isError = false, dynamic error}) {
    if (isError) {
      log.e("[Friendship] $message", error: error);
    } else {
      log.d("[Friendship] $message");
    }
  }

  void clear() {
    _pendingRequests.clear();
    _log("🧹 Lista de amizades pendentes limpa.");
  }
}
