import 'package:chirp/domain/usecases/friendship/accept_friendship_use_case.dart';
import 'package:chirp/domain/usecases/friendship/request_friendship_use_case.dart';
import 'package:chirp/infrastructure/adapters/file_picker_adapter.dart';
import 'package:chirp/app/controllers/chirp_controller.dart';
import 'package:chirp/domain/entities/identity.dart';
import 'package:chirp/domain/ports/file_picker_port.dart';
import 'package:chirp/infrastructure/repositories/message_nest_repository.dart';
import 'package:chirp/infrastructure/adapters/secure_nest_hive_adapter.dart';
import 'package:chirp/domain/ports/secure_nest_port.dart';
import 'package:chirp/infrastructure/repositories/tiel_nest_repository.dart';
import 'package:chirp/infrastructure/services/flock_discovery.dart';
import 'package:chirp/infrastructure/services/identity_service.dart';
import 'package:chirp/infrastructure/services/flock_manager.dart';
import 'package:chirp/infrastructure/services/secure_nest.dart';
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

Future<void> setupLocator() async {
  final Identity myIdentity = await IdentityService.getIdentity();

  getIt.registerLazySingleton<FlockDiscovery>(() => FlockDiscoveryService());

  getIt.registerLazySingleton<FlockManager>(() => P2PFlockManager(myIdentity));

  getIt.registerLazySingleton<SecureNestPort>(
    () => SecureNestHiveAdapter(myIdentity.id),
  );

  final secureNest = SecureNestService(getIt<SecureNestPort>());
  await secureNest.setup();

  getIt.registerLazySingleton<ISecureNest>(() => secureNest);

  getIt.registerLazySingleton(() => TielNestRepository(getIt<ISecureNest>()));

  getIt.registerLazySingleton(
    () => MessageNestRepository(getIt<ISecureNest>()),
  );

  getIt.registerLazySingleton<FilePickerPort>(() => FilePickerAdapter());

  getIt.registerLazySingleton<RequestFriendshipUseCase>(
    () => RequestFriendshipUseCase(
      flockManager: getIt<FlockManager>(),
      tielsRepo: getIt<TielNestRepository>(),
      me: myIdentity,
    ),
  );

  getIt.registerLazySingleton<AcceptFriendshipUseCase>(
    () => AcceptFriendshipUseCase(
      flockManager: getIt<FlockManager>(),
      tielsRepo: getIt<TielNestRepository>(),
      me: myIdentity,
    ),
  );

  getIt.registerFactory(
    () => ChirpController(
      flockDiscovery: getIt<FlockDiscovery>(),
      flockManager: getIt<FlockManager>(),
      me: myIdentity,

      messagesRepository: getIt<MessageNestRepository>(),
      tielsRepository: getIt<TielNestRepository>(),
      filePicker: getIt<FilePickerPort>(),

      requestFriendshipUseCase: getIt<RequestFriendshipUseCase>(),
      acceptFriendshipUseCase: getIt<AcceptFriendshipUseCase>(),
    ),
  );
}
