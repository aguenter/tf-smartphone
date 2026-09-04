import 'package:equatable/equatable.dart';

enum ParticipantRole { trainer, participant }

class Participant extends Equatable {
  const Participant({
    required this.id,
    required this.displayName,
    required this.role,
  });

  final String id;
  final String displayName;
  final ParticipantRole role;

  @override
  List<Object?> get props => [id, displayName, role];
}
