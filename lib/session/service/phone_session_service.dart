import 'dart:async';
import 'dart:developer' as dev;

import 'package:supabase/supabase.dart' hide Session;

import '../../home/model/workout.dart';
import '../model/exercise.dart';
import '../model/participant.dart';
import '../model/session.dart';

// ---------------------------------------------------------------------------
// Updates emitted to the BLoC
// ---------------------------------------------------------------------------

sealed class PhoneSessionUpdate {}

class PhoneParticipantsChanged extends PhoneSessionUpdate {
  PhoneParticipantsChanged(this.participants);
  final List<Participant> participants;
}

class PhoneSelectionStarted extends PhoneSessionUpdate {}

class PhoneVotesChanged extends PhoneSessionUpdate {
  PhoneVotesChanged({
    required this.voteCounts,
    required this.myVoteWorkoutId,
    required this.trainerWorkoutId,
  });
  final Map<String, int> voteCounts;
  final String? myVoteWorkoutId;
  final String? trainerWorkoutId;
}

class PhonePhaseChanged extends PhoneSessionUpdate {
  PhonePhaseChanged({
    required this.phase,
    this.workoutName,
    this.exercise,
  });
  final SessionPhase phase;
  final String? workoutName;
  final Exercise? exercise;
}

class PhoneSessionEnded extends PhoneSessionUpdate {}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

class PhoneSessionService {
  PhoneSessionService({required String url, required String anonKey})
      : _client = SupabaseClient(url, anonKey);

  final SupabaseClient _client;
  final _controller = StreamController<PhoneSessionUpdate>.broadcast();

  RealtimeChannel? _channel;
  String? _sessionId;
  String? _participantId;
  ParticipantRole? _role;

  String? _cachedWorkoutId;
  String? _cachedWorkoutName;
  List<Exercise> _cachedExercises = [];

  Stream<PhoneSessionUpdate> get updates => _controller.stream;
  String? get participantId => _participantId;
  ParticipantRole? get role => _role;

  Future<ParticipantRole> joinSession(
    String sessionId,
    String displayName,
  ) async {
    await _client.auth.signInAnonymously();
    dev.log('Signed in: ${_client.auth.currentUser?.id}',
        name: 'PhoneSession');

    final result = await _client.rpc<Map<String, dynamic>>(
      'join_session',
      params: {
        'p_session_id': sessionId,
        'p_display_name': displayName,
      },
    );

    _sessionId = sessionId;
    _participantId = result['participant_id'] as String;
    _role = (result['role'] as String) == 'trainer'
        ? ParticipantRole.trainer
        : ParticipantRole.participant;

    dev.log(
        'Joined session $sessionId as $_role (participant: $_participantId)',
        name: 'PhoneSession');

    await _subscribe(sessionId);
    return _role!;
  }

  Future<void> startSelection() async {
    await _client.rpc('start_selection', params: {
      'p_session_id': _sessionId,
    });
  }

  Future<List<Workout>> fetchWorkouts() async {
    final rows = await _client
        .from('workouts')
        .select('id, name, description, is_unlocked')
        .eq('is_unlocked', true)
        .order('sort_order', ascending: true);

    return rows
        .map<Workout>((row) => Workout(
              id: row['id'] as String,
              name: row['name'] as String,
              description: (row['description'] as String?) ?? '',
              isUnlocked: true,
            ))
        .toList();
  }

  Future<void> castVote(String workoutId) async {
    await _client.rpc('cast_vote', params: {
      'p_session_id': _sessionId,
      'p_workout_id': workoutId,
    });
  }

  Future<void> selectWorkout(String workoutId) async {
    await _client.rpc('select_workout', params: {
      'p_session_id': _sessionId,
      'p_workout_id': workoutId,
    });
  }

  Future<void> submitResult(String exerciseId, int value) async {
    await _client.rpc('submit_result', params: {
      'p_session_id': _sessionId,
      'p_exercise_id': exerciseId,
      'p_value': value,
    });
  }

  // -----------------------------------------------------------------------
  // Realtime
  // -----------------------------------------------------------------------

  Future<void> _subscribe(String sessionId) async {
    _channel = _client.channel('session:$sessionId');

    _channel!.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'participants',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'session_id',
        value: sessionId,
      ),
      callback: (_) => _fetchParticipants(sessionId),
    );

    _channel!.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'sessions',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'id',
        value: sessionId,
      ),
      callback: (payload) => _onSessionChanged(payload.newRecord),
    );

    _channel!.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'votes',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'session_id',
        value: sessionId,
      ),
      callback: (_) => _fetchVotes(sessionId),
    );

    _channel!.subscribe((status, [error]) {
      dev.log('Channel status: $status (error: $error)',
          name: 'PhoneSession');
    });
  }

  Future<void> _fetchParticipants(String sessionId) async {
    final rows = await _client
        .from('participants')
        .select()
        .eq('session_id', sessionId)
        .order('joined_at');

    final participants = rows
        .map<Participant>((row) => Participant(
              id: row['id'] as String,
              displayName: row['display_name'] as String,
              role: row['role'] == 'trainer'
                  ? ParticipantRole.trainer
                  : ParticipantRole.participant,
            ))
        .toList();

    _controller.add(PhoneParticipantsChanged(participants));
  }

  Future<void> _fetchVotes(String sessionId) async {
    final rows = await _client
        .from('votes')
        .select('participant_id, workout_id')
        .eq('session_id', sessionId);

    final sessionRows = await _client
        .from('sessions')
        .select('trainer_participant_id')
        .eq('id', sessionId)
        .limit(1);

    final trainerId = sessionRows.isNotEmpty
        ? sessionRows.first['trainer_participant_id'] as String?
        : null;

    final Map<String, int> voteCounts = {};
    String? myVoteWorkoutId;
    String? trainerWorkoutId;

    for (final row in rows) {
      final workoutId = row['workout_id'] as String;
      final participantId = row['participant_id'] as String;
      voteCounts[workoutId] = (voteCounts[workoutId] ?? 0) + 1;
      if (participantId == _participantId) {
        myVoteWorkoutId = workoutId;
      }
      if (participantId == trainerId) {
        trainerWorkoutId = workoutId;
      }
    }

    _controller.add(PhoneVotesChanged(
      voteCounts: voteCounts,
      myVoteWorkoutId: myVoteWorkoutId,
      trainerWorkoutId: trainerWorkoutId,
    ));
  }

  Future<void> _onSessionChanged(Map<String, dynamic> record) async {
    final status = record['status'] as String?;
    dev.log('Session changed: status=$status, record=$record',
        name: 'PhoneSession');

    if (status == 'ended') {
      _controller.add(PhoneSessionEnded());
      return;
    }

    if (status == 'selecting') {
      _controller.add(PhoneSelectionStarted());
      return;
    }

    final phase = record['phase'] as String?;
    if (phase == null) return;

    final sessionPhase = SessionPhase.values.firstWhere(
      (p) => p.name == phase,
      orElse: () => SessionPhase.countdown,
    );

    String? workoutName;
    Exercise? exercise;

    final workoutId = record['workout_id'] as String?;
    final exerciseIndex = record['current_exercise_index'] as int?;

    String? resolvedWorkoutId = workoutId;
    int resolvedIndex = exerciseIndex ?? 0;

    if (resolvedWorkoutId == null && _sessionId != null) {
      final sessionRows = await _client
          .from('sessions')
          .select('workout_id, current_exercise_index')
          .eq('id', _sessionId!)
          .limit(1);
      if (sessionRows.isNotEmpty) {
        resolvedWorkoutId = sessionRows.first['workout_id'] as String?;
        resolvedIndex =
            sessionRows.first['current_exercise_index'] as int? ?? 0;
      }
    }

    if (resolvedWorkoutId != null) {
      await _ensureWorkoutCached(resolvedWorkoutId);
      workoutName = _cachedWorkoutName;
      if (resolvedIndex < _cachedExercises.length) {
        exercise = _cachedExercises[resolvedIndex];
      }
    }

    _controller.add(PhonePhaseChanged(
      phase: sessionPhase,
      workoutName: workoutName,
      exercise: exercise,
    ));
  }

  Future<void> _ensureWorkoutCached(String workoutId) async {
    if (_cachedWorkoutId == workoutId) return;
    _cachedWorkoutId = workoutId;

    final workoutRows = await _client
        .from('workouts')
        .select('name')
        .eq('id', workoutId)
        .limit(1);
    _cachedWorkoutName =
        workoutRows.isNotEmpty ? workoutRows.first['name'] as String : null;

    final exerciseRows = await _client
        .from('exercises')
        .select()
        .eq('workout_id', workoutId)
        .order('sort_order', ascending: true);
    _cachedExercises =
        exerciseRows.map<Exercise>((row) => Exercise.fromRow(row)).toList();
  }

  void dispose() {
    if (_channel != null) {
      _client.removeChannel(_channel!);
      _channel = null;
    }
    _controller.close();
  }
}
