import 'package:chirp/app/controllers/friendship_controller.dart';
import 'package:chirp/domain/usecases/chat/offer_file_use_case.dart';
import 'package:chirp/domain/usecases/chat/open_file_picker_use_case.dart';
import 'package:chirp/domain/usecases/chat/parse_incoming_packet_use_case.dart';
import 'package:chirp/domain/usecases/chat/receive_chirp_use_case.dart';
import 'package:chirp/domain/usecases/chat/send_chirp_use_case.dart';
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
import 'package:chirp/infrastructure/data/tiels_store.dart';
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

  getIt.registerLazySingleton<TielsStore>(() => TielsStore(getIt()));
  getIt.registerLazySingleton<FilePickerPort>(() => FilePickerAdapter());

  getIt.registerLazySingleton<RequestFriendshipUseCase>(
    () => RequestFriendshipUseCase(
      flockManager: getIt<FlockManager>(),
      store: getIt<TielsStore>(),
      me: myIdentity,
    ),
  );

  getIt.registerLazySingleton<AcceptFriendshipUseCase>(
    () => AcceptFriendshipUseCase(
      flockManager: getIt<FlockManager>(),
      store: getIt<TielsStore>(),
      me: myIdentity,
    ),
  );

  getIt.registerLazySingleton<SendChirpUseCase>(
    () => SendChirpUseCase(
      flockManager: getIt<FlockManager>(),
      messagesRepo: getIt<MessageNestRepository>(),
      me: myIdentity,
    ),
  );

  getIt.registerLazySingleton<ReceiveChirpUseCase>(
    () => ReceiveChirpUseCase(
      messageRepo: getIt<MessageNestRepository>(),
      me: myIdentity,
    ),
  );

  getIt.registerLazySingleton<OpenFilePickerUseCase>(
    () => OpenFilePickerUseCase(filePicker: getIt<FilePickerPort>()),
  );

  getIt.registerLazySingleton<OfferFileUseCase>(
    () => OfferFileUseCase(flockManager: getIt<FlockManager>(), me: myIdentity),
  );

  getIt.registerLazySingleton<ParseIncomingPacketUseCase>(
    () => ParseIncomingPacketUseCase(),
  );

  getIt.registerLazySingleton(
    () => FriendshipController(
      acceptFriendshipUseCase: getIt(),
      requestFriendshipUseCase: getIt(),
      store: getIt(),
    ),
  );

  getIt.registerFactory(
    () => ChirpController(
      flockDiscovery: getIt<FlockDiscovery>(),
      flockManager: getIt<FlockManager>(),
      me: myIdentity,

      messagesRepository: getIt<MessageNestRepository>(),
      tielsRepository: getIt<TielNestRepository>(),

      sendChirpUseCase: getIt<SendChirpUseCase>(),
      offerFileUseCase: getIt<OfferFileUseCase>(),
      openFilePickerUseCase: getIt<OpenFilePickerUseCase>(),
      parseIncomingPacketUseCase: getIt<ParseIncomingPacketUseCase>(),
      receiveChirpUseCase: getIt<ReceiveChirpUseCase>(),

      friendshipCtrl: getIt(),
    ),
  );
}
