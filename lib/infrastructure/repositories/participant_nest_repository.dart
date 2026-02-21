import 'package:chirp/domain/entities/participant.dart';
import 'package:chirp/infrastructure/repositories/nest_repository.dart';

class ParticipantNestRepository extends NestRepository<Participant> {
  ParticipantNestRepository({required super.nest})
    : super(boxName: "participant_vault", fromJson: Participant.fromJson);
}
