@Tags(['integration'])
library;

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase/supabase.dart';

/// Integration tests for submit_result RPC (T5: smartphones submit exercise results).

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

  group('T5 – submit_result (Smartphone)', () {
    late String sessionId;
    late String exerciseId;

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

      // Get the first unlocked workout and its first challenge exercise.
      final workouts = await _tv
          .from('workouts')
          .select('id')
          .eq('is_unlocked', true)
          .order('sort_order', ascending: true)
          .limit(1);
      final workoutId = workouts.first['id'] as String;

      final exercises = await _tv
          .from('exercises')
          .select('id')
          .eq('workout_id', workoutId)
          .order('sort_order', ascending: true);
      // Index 1 = first challenge (index 0 is warmup).
      exerciseId = exercises[1]['id'] as String;
    });

    test('submit_result inserts a result row', () async {
      await _phone1.rpc('submit_result', params: {
        'p_session_id': sessionId,
        'p_exercise_id': exerciseId,
        'p_value': 15,
      });

      final rows = await _tv
          .from('results')
          .select()
          .eq('session_id', sessionId);

      expect(rows.length, 1);
      expect(rows.first['value'], 15);
    });

    test('submit_result upsert updates the value', () async {
      await _phone1.rpc('submit_result', params: {
        'p_session_id': sessionId,
        'p_exercise_id': exerciseId,
        'p_value': 15,
      });

      await _phone1.rpc('submit_result', params: {
        'p_session_id': sessionId,
        'p_exercise_id': exerciseId,
        'p_value': 20,
      });

      final rows = await _tv
          .from('results')
          .select()
          .eq('session_id', sessionId);

      expect(rows.length, 1);
      expect(rows.first['value'], 20);
    });

    test('non-participant cannot submit', () async {
      expect(
        () => _phone3.rpc('submit_result', params: {
          'p_session_id': sessionId,
          'p_exercise_id': exerciseId,
          'p_value': 10,
        }),
        throwsA(isA<PostgrestException>()),
      );
    });

    test('multiple participants can submit for same exercise', () async {
      await _phone1.rpc('submit_result', params: {
        'p_session_id': sessionId,
        'p_exercise_id': exerciseId,
        'p_value': 15,
      });

      await _phone2.rpc('submit_result', params: {
        'p_session_id': sessionId,
        'p_exercise_id': exerciseId,
        'p_value': 22,
      });

      final rows = await _tv
          .from('results')
          .select()
          .eq('session_id', sessionId)
          .eq('exercise_id', exerciseId);

      expect(rows.length, 2);
    });
  });
}
