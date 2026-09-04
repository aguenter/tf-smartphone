@Tags(['integration'])
library;

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase/supabase.dart';

/// Integration tests for T2: smartphones cast votes for workouts.
///
/// Run with: flutter test test/integration/t2_cast_vote_test.dart

late SupabaseClient _tv;
late SupabaseClient _phone1;
late SupabaseClient _phone2;
late SupabaseClient _phone3;

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
    _phone2 = await _createClientThrottled();
    _phone3 = await _createClientThrottled();
  });

  tearDownAll(() {
    _tv.dispose();
    _phone1.dispose();
    _phone2.dispose();
    _phone3.dispose();
  });

  group('T2 – cast_vote (Smartphone)', () {
    late String sessionId;
    late String workoutId;

    setUp(() async {
      sessionId = await _tv.rpc<String>('create_session');

      await _phone1.rpc('join_session', params: {
        'p_session_id': sessionId,
        'p_display_name': 'Anna',
      });
      await _phone2.rpc('join_session', params: {
        'p_session_id': sessionId,
        'p_display_name': 'Ben',
      });

      // Get the first unlocked workout.
      final workouts = await _tv
          .from('workouts')
          .select('id')
          .eq('is_unlocked', true)
          .order('sort_order', ascending: true)
          .limit(1);
      workoutId = workouts.first['id'] as String;
    });

    test('cast_vote inserts a vote row', () async {
      await _phone1.rpc('cast_vote', params: {
        'p_session_id': sessionId,
        'p_workout_id': workoutId,
      });

      final rows = await _tv
          .from('votes')
          .select()
          .eq('session_id', sessionId);

      expect(rows.length, 1);
      expect(rows.first['workout_id'], workoutId);
    });

    test('cast_vote upsert changes the workout', () async {
      // Get a second workout.
      final workouts = await _tv
          .from('workouts')
          .select('id')
          .eq('is_unlocked', true)
          .order('sort_order', ascending: true)
          .limit(2);
      final secondWorkoutId = workouts.last['id'] as String;

      await _phone1.rpc('cast_vote', params: {
        'p_session_id': sessionId,
        'p_workout_id': workoutId,
      });

      await _phone1.rpc('cast_vote', params: {
        'p_session_id': sessionId,
        'p_workout_id': secondWorkoutId,
      });

      final rows = await _tv
          .from('votes')
          .select()
          .eq('session_id', sessionId);

      expect(rows.length, 1);
      expect(rows.first['workout_id'], secondWorkoutId);
    });

    test('non-participant cannot vote', () async {
      expect(
        () => _phone3.rpc('cast_vote', params: {
          'p_session_id': sessionId,
          'p_workout_id': workoutId,
        }),
        throwsA(isA<PostgrestException>()),
      );
    });

    test('multiple participants can vote for the same workout', () async {
      await _phone1.rpc('cast_vote', params: {
        'p_session_id': sessionId,
        'p_workout_id': workoutId,
      });

      await _phone2.rpc('cast_vote', params: {
        'p_session_id': sessionId,
        'p_workout_id': workoutId,
      });

      final rows = await _tv
          .from('votes')
          .select()
          .eq('session_id', sessionId)
          .eq('workout_id', workoutId);

      expect(rows.length, 2);
    });
  });
}
