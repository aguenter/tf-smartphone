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

    test('warmup → challenge (index 1)', () async {
      await _tv.rpc('advance_phase', params: {'p_session_id': sessionId});

      var s = await fetchSession();
      expect(s['phase'], 'warmup');

      await _tv.rpc('advance_phase', params: {'p_session_id': sessionId});

      s = await fetchSession();
      expect(s['phase'], 'challenge');
      expect(s['current_exercise_index'], 1);
    });

    test('challenge cycles through all exercises then reaches result',
        () async {
      // countdown → warmup
      await _tv.rpc('advance_phase', params: {'p_session_id': sessionId});
      // warmup → challenge (index 1)
      await _tv.rpc('advance_phase', params: {'p_session_id': sessionId});

      // Cycle through challenge exercises (index 1..exerciseCount-1).
      // exerciseCount is 4 (1 warmup + 3 challenges).
      // index 1 → 2 → 3 → result
      for (var i = 1; i < exerciseCount - 1; i++) {
        await _tv.rpc('advance_phase', params: {'p_session_id': sessionId});
        final s = await fetchSession();
        expect(s['phase'], 'challenge');
        expect(s['current_exercise_index'], i + 1);
      }

      // Last advance: challenge → result.
      await _tv.rpc('advance_phase', params: {'p_session_id': sessionId});
      final s = await fetchSession();
      expect(s['phase'], 'result');
    });

    test('advance_phase after result throws', () async {
      // Fast-forward to result.
      for (var i = 0; i < exerciseCount + 1; i++) {
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
