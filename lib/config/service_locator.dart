import 'package:chirp/controllers/chirp_controller.dart';
import 'package:chirp/services/flock_discovery.dart';
import 'package:chirp/services/identity_service.dart';
import 'package:chirp/services/flock_manager.dart';
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

Future<void> setupLocator() async {
  final String tielId = await IdentityService.getUniqueId();

  getIt.registerLazySingleton<FlockDiscovery>(() => FlockDiscoveryService());
  getIt.registerLazySingleton<FlockManager>(() => P2PFlockManager(tielId));

  getIt.registerFactory(
    () =>
        ChirpController(getIt<FlockDiscovery>(), getIt<FlockManager>(), tielId),
  );
}
