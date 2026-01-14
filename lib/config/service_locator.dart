import 'package:chirp/controllers/chirp_controller.dart';
import 'package:chirp/models/identity.dart';
import 'package:chirp/services/flock_discovery.dart';
import 'package:chirp/services/identity_service.dart';
import 'package:chirp/services/flock_manager.dart';
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

Future<void> setupLocator() async {
  final Identity myIdentity = await IdentityService.getIdentity();

  getIt.registerLazySingleton<FlockDiscovery>(() => FlockDiscoveryService());
  getIt.registerLazySingleton<FlockManager>(
    () => P2PFlockManager(myIdentity.id),
  );

  getIt.registerFactory(
    () => ChirpController(
      getIt<FlockDiscovery>(),
      getIt<FlockManager>(),
      myIdentity,
    ),
  );
}
