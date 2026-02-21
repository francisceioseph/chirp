import 'dart:async';

import 'package:chirp/domain/entities/identity.dart';
import 'package:chirp/domain/usecases/presence/tiel_found_use_case.dart';
import 'package:chirp/domain/usecases/presence/update_tiels_status_use_case.dart';
import 'package:chirp/infrastructure/services/flock_discovery.dart';
import 'package:chirp/utils/app_logger.dart';
import 'package:flutter/foundation.dart';

class PresenceController extends ChangeNotifier {
  final Identity _identity;
  final FlockDiscovery _flockDiscovery;
  final TielFoundUseCase _tielFoundUseCase;
  final UpdateTielsStatusUseCase _updateTielsStatusUseCase;

  Timer? _presenceHeartbeat;
  bool _isUpdating = false;

  PresenceController({
    required Identity identity,
    required FlockDiscovery flockDiscovery,
    required TielFoundUseCase tielFoundUseCase,
    required UpdateTielsStatusUseCase updateTielsStatusUseCase,
  }) : _identity = identity,
       _flockDiscovery = flockDiscovery,
       _tielFoundUseCase = tielFoundUseCase,
       _updateTielsStatusUseCase = updateTielsStatusUseCase;

  Future<void> start() async {
    log.i("📡 [Presença] Iniciando serviços de descoberta...");

    try {
      await _flockDiscovery.advertise(_identity.id, _identity.name);
      await _flockDiscovery.discover(_onTielDiscovered);

      _presenceHeartbeat?.cancel();

      _presenceHeartbeat = Timer.periodic(
        const Duration(seconds: 10),
        _onHeartbeatTick,
      );

      log.i("✅ [Presença] Radar operando normalmente.");
    } catch (e) {
      log.e("💥 [Presença] Falha crítica ao iniciar radar", error: e);
    }
  }

  Future<void> _onTielDiscovered(String id, String name, String address) async {
    try {
      await _tielFoundUseCase.execute(id, name, address);
    } catch (e) {
      log.e("❌ [Presença] Erro ao processar Tiel encontrado: $id", error: e);
    }
  }

  Future<void> _onHeartbeatTick(Timer t) async {
    if (_isUpdating) return;

    try {
      _isUpdating = true;
      await _updateTielsStatusUseCase.execute();
    } catch (e) {
      log.e("❌ [Presença] Erro no timer de limpeza", error: e);
    } finally {
      _isUpdating = false;
    }
  }

  @override
  void dispose() {
    _presenceHeartbeat?.cancel();
    _flockDiscovery.stop();
    super.dispose();
  }
}
