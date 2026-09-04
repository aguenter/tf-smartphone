@Tags(['integration'])
library;

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase/supabase.dart';

/// Integration tests for select_workout RPC (trainer confirms workout, T2 → T3).

late SupabaseClient _tv;
late SupabaseClient _phone1;
late SupabaseClient _phone2;

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
  });

  tearDownAll(() {
    _tv.dispose();
    _phone1.dispose();
    _phone2.dispose();
  });

  group('T2 – select_workout', () {
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

      final workouts = await _tv
          .from('workouts')
          .select('id')
          .eq('is_unlocked', true)
          .order('sort_order', ascending: true)
          .limit(1);
      workoutId = workouts.first['id'] as String;
    });

    test('trainer can select a workout', () async {
      await _phone1.rpc('select_workout', params: {
        'p_session_id': sessionId,
        'p_workout_id': workoutId,
      });

      final session = await _tv
          .from('sessions')
          .select()
          .eq('id', sessionId)
          .single();

      expect(session['status'], 'running');
      expect(session['workout_id'], workoutId);
      expect(session['phase'], 'countdown');
      expect(session['phase_started_at'], isNotNull);
    });

    test('non-trainer cannot select a workout', () async {
      expect(
        () => _phone2.rpc('select_workout', params: {
          'p_session_id': sessionId,
          'p_workout_id': workoutId,
        }),
        throwsA(isA<PostgrestException>()),
      );
    });

    test('non-participant cannot select a workout', () async {
      expect(
        () => _tv.rpc('select_workout', params: {
          'p_session_id': sessionId,
          'p_workout_id': workoutId,
        }),
        throwsA(isA<PostgrestException>()),
      );
    });
  });
}
