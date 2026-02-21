import 'package:chirp/domain/entities/chirp_message.dart';
import 'package:chirp/infrastructure/repositories/nest_repository.dart';

class MessageNestRepository extends NestRepository<ChirpMessage> {
  MessageNestRepository({required super.nest})
    : super(boxName: "messages_vault", fromJson: ChirpMessage.fromJson);
}
