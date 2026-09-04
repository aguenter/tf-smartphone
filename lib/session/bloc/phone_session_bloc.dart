import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../home/model/workout.dart';
import '../model/exercise.dart';
import '../model/participant.dart';
import '../model/session.dart';
import '../service/phone_session_service.dart';
import 'phone_session_event.dart';
import 'phone_session_state.dart';

class PhoneSessionBloc extends Bloc<PhoneSessionEvent, PhoneSessionState> {
  PhoneSessionBloc({required PhoneSessionService service})
      : _service = service,
        super(const PhoneInitialState()) {
    on<JoinRequested>(_onJoinRequested);
    on<PhoneUpdateReceived>(_onUpdateReceived);
    on<VoteCast>(_onVoteCast);
    on<SelectionStartRequested>(_onSelectionStartRequested);
    on<WorkoutSelected>(_onWorkoutSelected);
    on<ResultEntered>(_onResultEntered);

    _subscription = _service.updates.listen(
      (update) => add(PhoneUpdateReceived(update)),
    );
  }

  final PhoneSessionService _service;
  late final StreamSubscription<PhoneSessionUpdate> _subscription;

  List<Participant> _participants = [];
  List<Workout> _workouts = [];
  bool _isTrainer = false;
  Exercise? _currentExercise;

  Future<void> _onJoinRequested(
    JoinRequested event,
    Emitter<PhoneSessionState> emit,
  ) async {
    emit(const PhoneJoiningState());
    try {
      final role = await _service.joinSession(
        event.sessionId,
        event.displayName,
      );
      _isTrainer = role == ParticipantRole.trainer;
      emit(PhoneLobbyState(
        participants: _participants,
        isTrainer: _isTrainer,
      ));
    } on Exception catch (e) {
      emit(PhoneErrorState(e.toString()));
    }
  }

  Future<void> _onUpdateReceived(
    PhoneUpdateReceived event,
    Emitter<PhoneSessionState> emit,
  ) async {
    final update = event.update;

    if (update is PhoneParticipantsChanged) {
      _participants = update.participants;
      final current = state;
      if (current is PhoneLobbyState) {
        emit(PhoneLobbyState(
          participants: _participants,
          isTrainer: _isTrainer,
        ));
      } else if (current is PhoneSelectingState) {
        emit(current.copyWith(participants: _participants));
      }
    } else if (update is PhoneSelectionStarted) {
      await _enterSelection(emit);
    } else if (update is PhoneVotesChanged) {
      if (state is PhoneSelectingState) {
        emit((state as PhoneSelectingState).copyWith(
          voteCounts: update.voteCounts,
          myVoteWorkoutId: update.myVoteWorkoutId,
          trainerWorkoutId: update.trainerWorkoutId,
        ));
      }
    } else if (update is PhonePhaseChanged) {
      _onPhaseChanged(update, emit);
    } else if (update is PhoneSessionEnded) {
      emit(const PhoneEndedState());
    }
  }

  Future<void> _enterSelection(Emitter<PhoneSessionState> emit) async {
    _workouts = await _service.fetchWorkouts();
    if (emit.isDone) return;
    emit(PhoneSelectingState(
      workouts: _workouts,
      voteCounts: const {},
      myVoteWorkoutId: null,
      trainerWorkoutId: null,
      isTrainer: _isTrainer,
      participants: _participants,
    ));
  }

  void _onPhaseChanged(PhonePhaseChanged update, Emitter<PhoneSessionState> emit) {
    switch (update.phase) {
      case SessionPhase.countdown:
        emit(PhoneCountdownState(workoutName: update.workoutName ?? ''));
      case SessionPhase.warmup:
        _currentExercise = update.exercise;
        if (_currentExercise != null) {
          emit(PhoneWarmupState(exercise: _currentExercise!));
        }
      case SessionPhase.challenge:
        _currentExercise = update.exercise;
        if (_currentExercise != null) {
          emit(PhoneChallengeState(
            exercise: _currentExercise!,
            hasSubmitted: false,
          ));
        }
      case SessionPhase.result:
        emit(const PhoneResultState());
    }
  }

  Future<void> _onVoteCast(
    VoteCast event,
    Emitter<PhoneSessionState> emit,
  ) async {
    await _service.castVote(event.workoutId);
  }

  Future<void> _onSelectionStartRequested(
    SelectionStartRequested event,
    Emitter<PhoneSessionState> emit,
  ) async {
    await _service.startSelection();
  }

  Future<void> _onWorkoutSelected(
    WorkoutSelected event,
    Emitter<PhoneSessionState> emit,
  ) async {
    await _service.selectWorkout(event.workoutId);
  }

  Future<void> _onResultEntered(
    ResultEntered event,
    Emitter<PhoneSessionState> emit,
  ) async {
    if (_currentExercise == null) return;
    await _service.submitResult(_currentExercise!.id, event.value);
    if (emit.isDone) return;
    if (state is PhoneChallengeState) {
      emit(PhoneChallengeState(
        exercise: _currentExercise!,
        hasSubmitted: true,
      ));
    }
  }

  @override
  Future<void> close() {
    _subscription.cancel();
    _service.dispose();
    return super.close();
  }
}
