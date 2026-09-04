@Tags(['integration'])
library;

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase/supabase.dart';

/// Integration tests for advance_phase RPC — validates the full phase cycle
/// including exercise-aware challenge→challenge cycling.

late SupabaseClient _tv;
late SupabaseClient _phone1;

Future<SupabaseClient> _createClient() async {
  final url = dotenv.get('SUPABASE_URL');
  final key = dotenv.get('SUPABASE_ANON_KEY');
  final client = SupabaseClient(url, key);
  await client.auth.signInAnonymously();
  return client;
}

Future<SupabaseClient> _createClientThrottled() async {
  await Future<void>.delayed(const Duration(seconds: 1));
  for (var attempt = 0; attempt < 3; attempt++) {
    try {
      return await _createClient();
    } on AuthException catch (e) {
      if (e.statusCode == '429' && attempt < 2) {
        await Future<void>.delayed(const Duration(seconds: 4));
        continue;
      }
      rethrow;
    }
  }
  return _createClient();
}

void main() {
  setUpAll(() async {
    await dotenv.load(fileName: '.env');
    _tv = await _createClient();
    _phone1 = await _createClientThrottled();
  });

  tearDownAll(() {
    _tv.dispose();
    _phone1.dispose();
  });

  group('advance_phase – full cycle', () {
    late String sessionId;
    late String workoutId;
    late int exerciseCount;

    setUp(() async {
      sessionId = await _tv.rpc<String>('create_session');

      await _phone1.rpc('join_session', params: {
        'p_session_id': sessionId,
        'p_display_name': 'Anna',
      });

      final workouts = await _tv
          .from('workouts')
          .select('id')
          .eq('is_unlocked', true)
          .order('sort_order', ascending: true)
          .limit(1);
      workoutId = workouts.first['id'] as String;

      final exercises = await _tv
          .from('exercises')
          .select('id')
          .eq('workout_id', workoutId)
          .order('sort_order', ascending: true);
      exerciseCount = exercises.length;

      // Trainer selects workout → status=running, phase=countdown, index=0.
      await _phone1.rpc('select_workout', params: {
        'p_session_id': sessionId,
        'p_workout_id': workoutId,
      });
    });

    Future<Map<String, dynamic>> fetchSession() async {
      return await _tv
          .from('sessions')
          .select()
          .eq('id', sessionId)
          .single();
    }

    test('countdown → warmup (index 0)', () async {
      var s = await fetchSession();
      expect(s['phase'], 'countdown');
      expect(s['current_exercise_index'], 0);

      await _tv.rpc('advance_phase', params: {'p_session_id': sessionId});

      s = await fetchSession();
      expect(s['phase'], 'warmup');
      expect(s['current_exercise_index'], 0);
    });

    test('warmup → countdown (index 1)', () async {
      // countdown → warmup
      await _tv.rpc('advance_phase', params: {'p_session_id': sessionId});

      var s = await fetchSession();
      expect(s['phase'], 'warmup');

      // warmup → second countdown
      await _tv.rpc('advance_phase', params: {'p_session_id': sessionId});

      s = await fetchSession();
      expect(s['phase'], 'countdown');
      expect(s['current_exercise_index'], 1);
    });

    test('second countdown → exercise (index 1)', () async {
      // countdown → warmup → countdown
      await _tv.rpc('advance_phase', params: {'p_session_id': sessionId});
      await _tv.rpc('advance_phase', params: {'p_session_id': sessionId});

      var s = await fetchSession();
      expect(s['phase'], 'countdown');

      // second countdown → exercise
      await _tv.rpc('advance_phase', params: {'p_session_id': sessionId});

      s = await fetchSession();
      expect(s['phase'], 'exercise');
      expect(s['current_exercise_index'], 1);
    });

    test('exercise/rest cycles through all exercises then reaches result',
        () async {
      // countdown → warmup → countdown → exercise (index 1)
      await _tv.rpc('advance_phase', params: {'p_session_id': sessionId});
      await _tv.rpc('advance_phase', params: {'p_session_id': sessionId});
      await _tv.rpc('advance_phase', params: {'p_session_id': sessionId});

      // exerciseCount is 4 (1 warmup + 3 challenges).
      // exercise(1) → rest(1) → exercise(2) → rest(2) → exercise(3) → rest(3) → result
      final challengeCount = exerciseCount - 1; // excluding warmup

      for (var i = 0; i < challengeCount; i++) {
        var s = await fetchSession();
        expect(s['phase'], 'exercise');
        expect(s['current_exercise_index'], i + 1);

        // exercise → rest
        await _tv.rpc('advance_phase', params: {'p_session_id': sessionId});
        s = await fetchSession();
        expect(s['phase'], i < challengeCount - 1 ? 'rest' : 'rest');

        if (i < challengeCount - 1) {
          // rest → next exercise
          await _tv.rpc('advance_phase', params: {'p_session_id': sessionId});
        }
      }

      // Last rest → result
      await _tv.rpc('advance_phase', params: {'p_session_id': sessionId});
      final s = await fetchSession();
      expect(s['phase'], 'result');
    });

    test('advance_phase after result throws', () async {
      // Fast-forward to result:
      // countdown → warmup → countdown → [exercise → rest] × N → result
      // 3 initial phases + 2 per challenge exercise
      await _tv.rpc('advance_phase', params: {'p_session_id': sessionId});
      await _tv.rpc('advance_phase', params: {'p_session_id': sessionId});
      await _tv.rpc('advance_phase', params: {'p_session_id': sessionId});
      final challengeCount = exerciseCount - 1;
      for (var i = 0; i < challengeCount; i++) {
        await _tv.rpc('advance_phase', params: {'p_session_id': sessionId});
        await _tv.rpc('advance_phase', params: {'p_session_id': sessionId});
      }
      final s = await fetchSession();
      expect(s['phase'], 'result');

      expect(
        () => _tv.rpc('advance_phase', params: {'p_session_id': sessionId}),
        throwsA(isA<PostgrestException>()),
      );
    });
  });
}
