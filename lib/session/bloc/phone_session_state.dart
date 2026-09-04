import 'package:equatable/equatable.dart';

import '../../home/model/workout.dart';
import '../model/exercise.dart';
import '../model/participant.dart';

sealed class PhoneSessionState extends Equatable {
  const PhoneSessionState();

  @override
  List<Object?> get props => [];
}

class PhoneInitialState extends PhoneSessionState {
  const PhoneInitialState();
}

class PhoneJoiningState extends PhoneSessionState {
  const PhoneJoiningState();
}

class PhoneErrorState extends PhoneSessionState {
  const PhoneErrorState(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

class PhoneLobbyState extends PhoneSessionState {
  const PhoneLobbyState({
    required this.participants,
    required this.isTrainer,
  });

  final List<Participant> participants;
  final bool isTrainer;

  @override
  List<Object?> get props => [participants, isTrainer];
}

class PhoneSelectingState extends PhoneSessionState {
  const PhoneSelectingState({
    required this.workouts,
    required this.voteCounts,
    required this.myVoteWorkoutId,
    required this.trainerWorkoutId,
    required this.isTrainer,
    required this.participants,
  });

  final List<Workout> workouts;
  final Map<String, int> voteCounts;
  final String? myVoteWorkoutId;
  final String? trainerWorkoutId;
  final bool isTrainer;
  final List<Participant> participants;

  PhoneSelectingState copyWith({
    Map<String, int>? voteCounts,
    String? myVoteWorkoutId,
    String? trainerWorkoutId,
    List<Participant>? participants,
  }) {
    return PhoneSelectingState(
      workouts: workouts,
      voteCounts: voteCounts ?? this.voteCounts,
      myVoteWorkoutId: myVoteWorkoutId ?? this.myVoteWorkoutId,
      trainerWorkoutId: trainerWorkoutId ?? this.trainerWorkoutId,
      isTrainer: isTrainer,
      participants: participants ?? this.participants,
    );
  }

  @override
  List<Object?> get props =>
      [workouts, voteCounts, myVoteWorkoutId, trainerWorkoutId, isTrainer, participants];
}

class PhoneCountdownState extends PhoneSessionState {
  const PhoneCountdownState({required this.workoutName});
  final String workoutName;

  @override
  List<Object?> get props => [workoutName];
}

class PhoneWarmupState extends PhoneSessionState {
  const PhoneWarmupState({
    required this.exercise,
    required this.secondsRemaining,
  });

  final Exercise exercise;
  final int secondsRemaining;

  @override
  List<Object?> get props => [exercise, secondsRemaining];
}

class PhoneExerciseState extends PhoneSessionState {
  const PhoneExerciseState({
    required this.exercise,
    required this.secondsRemaining,
  });

  final Exercise exercise;
  final int secondsRemaining;

  @override
  List<Object?> get props => [exercise, secondsRemaining];
}

class PhoneRestState extends PhoneSessionState {
  const PhoneRestState({
    required this.exercise,
    required this.hasSubmitted,
  });

  final Exercise exercise;
  final bool hasSubmitted;

  @override
  List<Object?> get props => [exercise, hasSubmitted];
}

class PhoneResultState extends PhoneSessionState {
  const PhoneResultState();
}

class PhoneEndedState extends PhoneSessionState {
  const PhoneEndedState();
}
