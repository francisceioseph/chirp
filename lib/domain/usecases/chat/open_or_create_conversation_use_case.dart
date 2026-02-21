import 'package:chirp/domain/entities/conversation.dart';
import 'package:chirp/domain/entities/identity.dart';
import 'package:chirp/domain/entities/participant.dart';
import 'package:chirp/domain/entities/tiel.dart';
import 'package:chirp/infrastructure/repositories/conversation_nest_repository.dart';
import 'package:chirp/infrastructure/repositories/participant_nest_repository.dart';

class OpenOrCreateConversationUseCase {
  final Identity _me;

  final ConversationNestRepository _conversationRepo;
  final ParticipantNestRepository _participantRepo;

  OpenOrCreateConversationUseCase({
    required Identity me,
    required ConversationNestRepository conversationRepo,
    required ParticipantNestRepository particpantRepo,
  }) : _me = me,
       _conversationRepo = conversationRepo,
       _participantRepo = particpantRepo;

  Future<Conversation> execute(Tiel tiel) async {
    final participantsIds = [_me.id, tiel.id]..sort();
    final deterministicId = participantsIds.join("_");

    final existing = await _conversationRepo.get(deterministicId);

    if (existing != null) {
      return existing;
    }

    final conversation = Conversation(
      id: deterministicId,
      title: tiel.name,
      targetId: tiel.id,
      type: ConversationType.individual,
      dateCreated: DateTime.now(),
      dateUpdated: DateTime.now(),
    );

    final p1 = Participant(
      id: "${deterministicId}_${_me.id}",
      tielId: _me.id,
      conversationId: conversation.id,
      joinedAt: DateTime.now(),
    );

    final p2 = Participant(
      id: "${deterministicId}_${tiel.id}",
      tielId: tiel.id,
      conversationId: conversation.id,
      joinedAt: DateTime.now(),
    );

    await _participantRepo.save(p1.id, p1);
    await _participantRepo.save(p2.id, p2);
    await _conversationRepo.save(conversation.id, conversation);

    return conversation;
  }
}
