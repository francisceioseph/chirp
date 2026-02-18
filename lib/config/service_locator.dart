import 'package:chirp/domain/entities/identity.dart';
import 'package:chirp/domain/usecases/chat/offer_file_use_case.dart';
import 'package:chirp/domain/usecases/chat/open_file_picker_use_case.dart';
import 'package:chirp/domain/usecases/chat/parse_incoming_packet_use_case.dart';
import 'package:chirp/domain/usecases/chat/receive_chirp_use_case.dart';
import 'package:chirp/domain/usecases/chat/send_chirp_use_case.dart';
import 'package:chirp/domain/usecases/friendship/accept_friendship_use_case.dart';
import 'package:chirp/domain/usecases/friendship/request_friendship_use_case.dart';
import 'package:chirp/infrastructure/adapters/file_picker_adapter.dart';
import 'package:chirp/app/controllers/chirp_controller.dart';
import 'package:chirp/domain/ports/file_picker_port.dart';
import 'package:chirp/infrastructure/repositories/identity_prefs_repository.dart';
import 'package:chirp/infrastructure/repositories/message_nest_repository.dart';
import 'package:chirp/infrastructure/adapters/secure_nest_hive_adapter.dart';
import 'package:chirp/infrastructure/repositories/tiel_nest_repository.dart';
import 'package:chirp/infrastructure/services/flock_discovery.dart';
import 'package:chirp/infrastructure/services/identity_service.dart';
import 'package:chirp/infrastructure/services/flock_manager.dart';
import 'package:chirp/infrastructure/services/secure_nest.dart';
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

Future<void> setupGlobalLocator() async {
  getIt.registerLazySingleton<FilePickerPort>(() => FilePickerAdapter());
  getIt.registerLazySingleton<FlockDiscovery>(() => FlockDiscoveryService());
  getIt.registerLazySingleton(() => ParseIncomingPacketUseCase());
  getIt.registerLazySingleton(() => OpenFilePickerUseCase(filePicker: getIt()));

  getIt.registerLazySingleton(() => IdentityPrefsRepository());
  getIt.registerLazySingleton(() => IdentityService(getIt()));
}

Future<void> configureSession(Identity myIdentity) async {
  if (getIt.currentScopeName == 'session') {
    await getIt.popScope();
  }

  getIt.pushNewScope(scopeName: 'session');

  final nestAdapter = SecureNestHiveAdapter(myIdentity.id);
  final secureNest = SecureNestService(nestAdapter);
  await secureNest.setup();

  getIt.registerSingleton(myIdentity);
  getIt.registerSingleton<ISecureNest>(secureNest);
  getIt.registerLazySingleton(() => TielNestRepository(getIt()));
  getIt.registerLazySingleton(() => MessageNestRepository(getIt()));

  getIt.registerLazySingleton<FlockManager>(() => P2PFlockManager(getIt()));

  _registerSessionUseCases();

  getIt.registerFactory(
    () => ChirpController(
      flockDiscovery: getIt<FlockDiscovery>(),
      flockManager: getIt<FlockManager>(),
      me: getIt(),
      messagesRepository: getIt<MessageNestRepository>(),
      tielsRepository: getIt<TielNestRepository>(),
      requestFriendshipUseCase: getIt<RequestFriendshipUseCase>(),
      acceptFriendshipUseCase: getIt<AcceptFriendshipUseCase>(),
      sendChirpUseCase: getIt<SendChirpUseCase>(),
      offerFileUseCase: getIt<OfferFileUseCase>(),
      openFilePickerUseCase: getIt<OpenFilePickerUseCase>(),
      parseIncomingPacketUseCase: getIt<ParseIncomingPacketUseCase>(),
      receiveChirpUseCase: getIt<ReceiveChirpUseCase>(),
    ),
  );
}

void _registerSessionUseCases() {
  getIt.registerLazySingleton(
    () => RequestFriendshipUseCase(
      flockManager: getIt(),
      tielsRepo: getIt(),
      identityService: getIt(),
    ),
  );

  getIt.registerLazySingleton(
    () => AcceptFriendshipUseCase(
      flockManager: getIt(),
      tielsRepo: getIt(),
      identityService: getIt(),
    ),
  );

  getIt.registerLazySingleton(
    () => SendChirpUseCase(
      flockManager: getIt(),
      messagesRepo: getIt(),
      identityService: getIt(),
    ),
  );

  getIt.registerLazySingleton(
    () => ReceiveChirpUseCase(messageRepo: getIt(), identityService: getIt()),
  );

  getIt.registerLazySingleton(
    () => OfferFileUseCase(flockManager: getIt(), identityService: getIt()),
  );
}
