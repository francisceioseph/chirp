import 'package:chirp/app/controllers/chirp_controller.dart';
import 'package:chirp/app/controllers/friendship_controller.dart';
import 'package:chirp/app/controllers/presence_controller.dart';
import 'package:chirp/domain/entities/identity.dart';
import 'package:chirp/domain/ports/file_picker_port.dart';
import 'package:chirp/domain/ports/secure_nest_port.dart';
import 'package:chirp/domain/usecases/chat/offer_file_use_case.dart';
import 'package:chirp/domain/usecases/chat/open_file_picker_use_case.dart';
import 'package:chirp/domain/usecases/chat/parse_incoming_packet_use_case.dart';
import 'package:chirp/domain/usecases/chat/receive_chirp_use_case.dart';
import 'package:chirp/domain/usecases/chat/send_chirp_use_case.dart';
import 'package:chirp/domain/usecases/friendship/complete_handshake_use_case.dart';
import 'package:chirp/domain/usecases/friendship/confirm_friendship_use_case.dart';
import 'package:chirp/domain/usecases/friendship/request_friendship_use_case.dart';
import 'package:chirp/domain/usecases/presence/tiel_found_use_case.dart';
import 'package:chirp/domain/usecases/presence/update_tiels_status_use_case.dart';
import 'package:chirp/infrastructure/adapters/file_picker_adapter.dart';
import 'package:chirp/infrastructure/adapters/secure_nest_hive_adapter.dart';
import 'package:chirp/infrastructure/repositories/conversation_nest_repository.dart';
import 'package:chirp/infrastructure/repositories/message_nest_repository.dart';
import 'package:chirp/infrastructure/repositories/participant_nest_repository.dart';
import 'package:chirp/infrastructure/repositories/tiel_nest_repository.dart';
import 'package:chirp/infrastructure/services/flock_discovery.dart';
import 'package:chirp/infrastructure/services/flock_manager.dart';
import 'package:chirp/infrastructure/services/identity_service.dart';
import 'package:chirp/infrastructure/services/secure_nest.dart';
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

class DependencyManager {
  static final DependencyManager _instance = DependencyManager._internal();
  factory DependencyManager() => _instance;
  DependencyManager._internal();

  Future<void> setup() async {
    final Identity myIdentity = await IdentityService.getIdentity();
    getIt.registerSingleton<Identity>(myIdentity);

    getIt.registerLazySingleton<SecureNestPort>(
      () => SecureNestHiveAdapter(myIdentity.id),
    );

    final secureNest = SecureNestService(getIt<SecureNestPort>());
    await secureNest.setup();
    getIt.registerLazySingleton<ISecureNest>(() => secureNest);

    _registerRepositories();
    _registerP2PServices();
    _registerFileServices();
    _registerUseCases();
    _registerControllers();

    await _warmupCaches();
  }

  void _registerRepositories() {
    getIt.registerLazySingleton(() => TielNestRepository(nest: getIt()));
    getIt.registerLazySingleton(() => MessageNestRepository(nest: getIt()));
    getIt.registerLazySingleton(
      () => ConversationNestRepository(nest: getIt()),
    );
    getIt.registerLazySingleton(() => ParticipantNestRepository(nest: getIt()));
  }

  void _registerP2PServices() {
    getIt.registerLazySingleton<FlockDiscovery>(() => FlockDiscoveryService());
    getIt.registerLazySingleton<FlockManager>(() => P2PFlockManager(getIt()));
  }

  void _registerFileServices() {
    getIt.registerLazySingleton<FilePickerPort>(() => FilePickerAdapter());
  }

  void _registerUseCases() {
    getIt.registerLazySingleton(
      () => RequestFriendshipUseCase(
        flockManager: getIt(),
        tielsRepo: getIt(),
        me: getIt(),
      ),
    );

    getIt.registerLazySingleton(
      () => ConfirmFriendshipUseCase(
        flockManager: getIt(),
        tielsRepo: getIt(),
        me: getIt(),
      ),
    );

    getIt.registerLazySingleton(
      () => SendChirpUseCase(
        flockManager: getIt(),
        messagesRepo: getIt<MessageNestRepository>(),
        me: getIt(),
      ),
    );

    getIt.registerLazySingleton(
      () => ReceiveChirpUseCase(
        messageRepo: getIt<MessageNestRepository>(),
        me: getIt(),
      ),
    );

    getIt.registerLazySingleton(
      () => OpenFilePickerUseCase(filePicker: getIt()),
    );

    getIt.registerLazySingleton(
      () => OfferFileUseCase(flockManager: getIt(), me: getIt()),
    );

    getIt.registerLazySingleton(() => ParseIncomingPacketUseCase());

    getIt.registerLazySingleton(
      () => TielFoundUseCase(identity: getIt(), tielsRepository: getIt()),
    );

    getIt.registerLazySingleton(
      () => UpdateTielsStatusUseCase(tielsRepository: getIt()),
    );

    getIt.registerLazySingleton(
      () => CompleteHandshakeUseCase(tielsRepo: getIt()),
    );
  }

  void _registerControllers() {
    getIt.registerLazySingleton(
      () => FriendshipController(
        confirmFriendshipUseCase: getIt(),
        requestFriendshipUseCase: getIt(),
        completeHandshakeUseCase: getIt(),
        tielsRepo: getIt(),
      ),
    );

    getIt.registerLazySingleton(
      () => PresenceController(
        identity: getIt(),
        flockDiscovery: getIt(),
        tielFoundUseCase: getIt(),
        updateTielsStatusUseCase: getIt(),
      ),
    );

    getIt.registerFactory(
      () => ChirpController(
        flockManager: getIt(),
        me: getIt(),
        messagesRepository: getIt<MessageNestRepository>(),
        tielsRepository: getIt<TielNestRepository>(),
        sendChirpUseCase: getIt(),
        offerFileUseCase: getIt(),
        openFilePickerUseCase: getIt(),
        parseIncomingPacketUseCase: getIt(),
        receiveChirpUseCase: getIt(),
        friendshipCtrl: getIt(),
      ),
    );
  }

  Future<void> _warmupCaches() async {
    await getIt<ConversationNestRepository>().init();
    await getIt<MessageNestRepository>().init();
    await getIt<ParticipantNestRepository>().init();
    await getIt<TielNestRepository>().init();
  }
}
