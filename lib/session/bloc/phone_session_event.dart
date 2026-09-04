import 'package:equatable/equatable.dart';

import '../service/phone_session_service.dart';

sealed class PhoneSessionEvent extends Equatable {
  const PhoneSessionEvent();

  @override
  List<Object?> get props => [];
}

class JoinRequested extends PhoneSessionEvent {
  const JoinRequested({required this.sessionId, required this.displayName});
  final String sessionId;
  final String displayName;

  @override
  List<Object?> get props => [sessionId, displayName];
}

class PhoneUpdateReceived extends PhoneSessionEvent {
  const PhoneUpdateReceived(this.update);
  final PhoneSessionUpdate update;
}

class VoteCast extends PhoneSessionEvent {
  const VoteCast(this.workoutId);
  final String workoutId;

  @override
  List<Object?> get props => [workoutId];
}

class SelectionStartRequested extends PhoneSessionEvent {
  const SelectionStartRequested();
}

class WorkoutSelected extends PhoneSessionEvent {
  const WorkoutSelected(this.workoutId);
  final String workoutId;

  @override
  List<Object?> get props => [workoutId];
}

class ResultEntered extends PhoneSessionEvent {
  const ResultEntered(this.value);
  final int value;

  @override
  List<Object?> get props => [value];
}

class TimerTick extends PhoneSessionEvent {
  const TimerTick();
}
