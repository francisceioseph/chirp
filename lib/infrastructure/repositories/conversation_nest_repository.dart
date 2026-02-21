import 'package:chirp/domain/entities/conversation.dart';
import 'package:chirp/infrastructure/repositories/nest_repository.dart';

class ConversationNestRepository extends NestRepository<Conversation> {
  ConversationNestRepository({required super.nest})
    : super(boxName: 'conversations_vault', fromJson: Conversation.fromJson);
}
