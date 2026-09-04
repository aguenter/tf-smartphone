import 'package:equatable/equatable.dart';

enum SessionStatus { waiting, selecting, running, ended }

enum SessionPhase { countdown, warmup, challenge, result }

class Session extends Equatable {
  const Session({
    required this.id,
    required this.status,
    this.phase,
    this.workoutId,
  });

  final String id;
  final SessionStatus status;
  final SessionPhase? phase;
  final String? workoutId;

  @override
  List<Object?> get props => [id, status, phase, workoutId];
}
