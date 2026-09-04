import 'dart:async';

import 'package:clock/clock.dart';
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
    // Tick und Wiedererscheinen laufen in dieselbe Neuberechnung: Die Restzeit
    // stammt aus dem Ziel-Zeitpunkt, nicht aus einem Herunterzählen, sodass
    // verschluckte Ticks (Hintergrund-Throttling) automatisch ausgeglichen
    // werden.
    on<TimerTick>(_recomputeRemaining);
    on<LifecycleResumed>(_recomputeRemaining);

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
  Timer? _timer;

  /// Ziel-Zeitpunkt der laufenden Timer-Phase (Warm-up/Übung). `null`, wenn
  /// kein Timer läuft oder die Phase abgelaufen ist. Die Restzeit wird stets
  /// hieraus berechnet ([_remainingSeconds]), damit sie auch nach Hintergrund-
  /// Throttling korrekt bleibt.
  DateTime? _phaseDeadline;

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
      emit(PhoneLobbyState(participants: _participants, isTrainer: _isTrainer));
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
        emit(
          PhoneLobbyState(participants: _participants, isTrainer: _isTrainer),
        );
      } else if (current is PhoneSelectingState) {
        emit(current.copyWith(participants: _participants));
      }
    } else if (update is PhoneSelectionStarted) {
      await _enterSelection(emit);
    } else if (update is PhoneVotesChanged) {
      if (state is PhoneSelectingState) {
        emit(
          (state as PhoneSelectingState).copyWith(
            voteCounts: update.voteCounts,
            myVoteWorkoutId: update.myVoteWorkoutId,
            trainerWorkoutId: update.trainerWorkoutId,
          ),
        );
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
    emit(
      PhoneSelectingState(
        workouts: _workouts,
        voteCounts: const {},
        myVoteWorkoutId: null,
        trainerWorkoutId: null,
        isTrainer: _isTrainer,
        participants: _participants,
      ),
    );
  }

  void _startTimer(int seconds) {
    _timer?.cancel();
    // clock statt DateTime.now(): In Tests (fakeAsync) spult async.elapse
    // sowohl den Timer als auch diese Zeitbasis vor.
    _phaseDeadline = clock.now().add(Duration(seconds: seconds));
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      add(const TimerTick());
    });
  }

  /// Verbleibende ganze Sekunden bis zum Ziel-Zeitpunkt (aufgerundet, damit die
  /// Startsekunde die volle Dauer anzeigt). 0, wenn kein Timer läuft oder die
  /// Zeit abgelaufen ist.
  int _remainingSeconds() {
    final deadline = _phaseDeadline;
    if (deadline == null) return 0;
    final ms = deadline.difference(clock.now()).inMilliseconds;
    return ms <= 0 ? 0 : (ms / 1000).ceil();
  }

  void _onPhaseChanged(
    PhonePhaseChanged update,
    Emitter<PhoneSessionState> emit,
  ) {
    _timer?.cancel();
    switch (update.phase) {
      case SessionPhase.countdown:
        emit(PhoneCountdownState(workoutName: update.workoutName ?? ''));
      case SessionPhase.warmup:
        _currentExercise = update.exercise;
        if (_currentExercise != null) {
          final total = _currentExercise!.executionSeconds;
          emit(
            PhoneWarmupState(
              exercise: _currentExercise!,
              secondsRemaining: total,
            ),
          );
          _startTimer(total);
        }
      case SessionPhase.exercise:
        _currentExercise = update.exercise;
        if (_currentExercise != null) {
          final total = _currentExercise!.executionSeconds;
          emit(
            PhoneExerciseState(
              exercise: _currentExercise!,
              secondsRemaining: total,
            ),
          );
          _startTimer(total);
        }
      case SessionPhase.rest:
        _currentExercise = update.exercise;
        if (_currentExercise != null) {
          emit(
            PhoneRestState(exercise: _currentExercise!, hasSubmitted: false),
          );
        }
      case SessionPhase.result:
        emit(const PhoneResultState());
    }
  }

  /// Rechnet die Restzeit der laufenden Timer-Phase neu und emittiert sie.
  ///
  /// Gemeinsamer Handler für [TimerTick] und [LifecycleResumed]. Da die Restzeit
  /// aus [_phaseDeadline] stammt, gleicht jeder Aufruf verschluckte Ticks
  /// (Hintergrund-Throttling) automatisch aus. Das Smartphone ist nur Anzeige –
  /// bei 0 wird der Timer gestoppt; die nächste Phase kommt per Realtime vom TV.
  void _recomputeRemaining(
    PhoneSessionEvent event,
    Emitter<PhoneSessionState> emit,
  ) {
    final current = state;
    if (current is! PhoneWarmupState && current is! PhoneExerciseState) return;
    if (_phaseDeadline == null) return;

    final remaining = _remainingSeconds();
    if (remaining <= 0) {
      _timer?.cancel();
      _phaseDeadline = null;
      return;
    }

    if (current is PhoneWarmupState) {
      emit(
        PhoneWarmupState(
          exercise: current.exercise,
          secondsRemaining: remaining,
        ),
      );
    } else if (current is PhoneExerciseState) {
      emit(
        PhoneExerciseState(
          exercise: current.exercise,
          secondsRemaining: remaining,
        ),
      );
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
    if (state is PhoneRestState) {
      emit(PhoneRestState(exercise: _currentExercise!, hasSubmitted: true));
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    _subscription.cancel();
    _service.dispose();
    return super.close();
  }
}
