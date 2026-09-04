@Tags(['integration'])
library;

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase/supabase.dart';

/// Fast-forward helper: advances a live TV session to a target screen.
/// Used by the launch script.
///
/// Usage:
///   flutter test --tags=integration --run-skipped \
///     --dart-define=SESSION_ID=`<id>` \
///     --dart-define=TARGET_SCREEN=2 \
///     test/integration/advance_to_screen_test.dart

late SupabaseClient _phone1;
late SupabaseClient _phone2;
late SupabaseClient _phone3;
late SupabaseClient _phone4;
late SupabaseClient _phone5;

Future<SupabaseClient> _createClient() async {
  final url = dotenv.get('SUPABASE_URL');
  final key = dotenv.get('SUPABASE_ANON_KEY');
  final client = SupabaseClient(url, key);
  await client.auth.signInAnonymously();
  return client;
}

void main() {
  const sessionId = String.fromEnvironment('SESSION_ID');
  const targetScreen = int.fromEnvironment('TARGET_SCREEN', defaultValue: 1);

  setUpAll(() async {
    await dotenv.load(fileName: '.env');
    _phone1 = await _createClient();
    _phone2 = await _createClient();
    _phone3 = await _createClient();
    _phone4 = await _createClient();
    _phone5 = await _createClient();
    // ignore: avoid_print
    print('All 5 clients created.');
  });

  tearDownAll(() {
    _phone1.dispose();
    _phone2.dispose();
    _phone3.dispose();
    _phone4.dispose();
    _phone5.dispose();
  });

  test('advance to T$targetScreen', () async {
    if (sessionId.isEmpty) {
      fail('SESSION_ID is required');
    }

    final phones = [_phone1, _phone2, _phone3, _phone4, _phone5];
    final names = ['Anna', 'Ben', 'Clara', 'David', 'Emma'];

    // ------------------------------------------------------------------
    // T2: Join players, start selection, cast votes, select workout
    // ------------------------------------------------------------------
    if (targetScreen >= 2) {
      for (var i = 0; i < phones.length; i++) {
        final result = await phones[i].rpc<Map<String, dynamic>>(
          'join_session',
          params: {
            'p_session_id': sessionId,
            'p_display_name': names[i],
          },
        );
        // ignore: avoid_print
        print('${names[i]} → ${result['role']}');
      }

      await Future<void>.delayed(const Duration(seconds: 2));

      await _phone1.rpc('start_selection', params: {
        'p_session_id': sessionId,
      });
      // ignore: avoid_print
      print('T2: selection started.');

      await Future<void>.delayed(const Duration(seconds: 2));

      // Cast votes: 3× workout 1, 1× workout 2, 1× workout 3.
      final workouts = await _phone1
          .from('workouts')
          .select('id')
          .eq('is_unlocked', true)
          .order('sort_order', ascending: true)
          .limit(3);

      final w1 = workouts[0]['id'] as String;
      final w2 = workouts[1]['id'] as String;
      final w3 = workouts[2]['id'] as String;

      final voteMap = {
        _phone1: w1,
        _phone2: w1,
        _phone3: w1,
        _phone4: w2,
        _phone5: w3,
      };

      for (final entry in voteMap.entries) {
        await entry.key.rpc('cast_vote', params: {
          'p_session_id': sessionId,
          'p_workout_id': entry.value,
        });
      }
      // ignore: avoid_print
      print('Votes cast: 3× w1, 1× w2, 1× w3');

      if (targetScreen == 2) return;

      await Future<void>.delayed(const Duration(seconds: 3));

      // Trainer confirms workout → T3 (countdown).
      await _phone1.rpc('select_workout', params: {
        'p_session_id': sessionId,
        'p_workout_id': w1,
      });
      // ignore: avoid_print
      print('T3: workout selected, countdown started.');
    }

    // ------------------------------------------------------------------
    // T3+: Fast-forward by calling advance_phase directly from the test
    // instead of waiting for TV timers. The TV picks up each phase change
    // via Realtime and renders accordingly.
    // ------------------------------------------------------------------

    if (targetScreen >= 4) {
      // Let the TV show countdown briefly.
      await Future<void>.delayed(const Duration(seconds: 3));

      // countdown → warmup
      await _phone1.rpc('advance_phase', params: {
        'p_session_id': sessionId,
      });
      // ignore: avoid_print
      print('T4: warmup started.');
    }

    if (targetScreen == 3 || targetScreen == 4) return;

    // T5+: advance through warmup → challenges with result submission.
    if (targetScreen >= 5) {
      // Let the TV show warmup briefly.
      await Future<void>.delayed(const Duration(seconds: 3));

      // warmup → challenge (index 1)
      await _phone1.rpc('advance_phase', params: {
        'p_session_id': sessionId,
      });
      // ignore: avoid_print
      print('T5: first challenge started.');

      // Fetch exercises to know how many challenges and their IDs.
      final w1Id = (await _phone1
          .from('workouts')
          .select('id')
          .eq('is_unlocked', true)
          .order('sort_order', ascending: true)
          .limit(1))
          .first['id'] as String;

      final exercises = await _phone1
          .from('exercises')
          .select('id, name')
          .eq('workout_id', w1Id)
          .order('sort_order', ascending: true);

      final challenges = exercises.sublist(1); // skip warmup at index 0

      for (var c = 0; c < challenges.length; c++) {
        final exId = challenges[c]['id'] as String;

        // Let the TV show the exercise briefly.
        await Future<void>.delayed(const Duration(seconds: 2));

        // Submit results from all phones.
        for (var i = 0; i < phones.length; i++) {
          await phones[i].rpc('submit_result', params: {
            'p_session_id': sessionId,
            'p_exercise_id': exId,
            'p_value': 10 + i * 3,
          });
        }
        // ignore: avoid_print
        print('Challenge ${c + 1}/${challenges.length}: ${challenges[c]['name']} — results submitted.');

        await Future<void>.delayed(const Duration(seconds: 1));

        // Advance to next challenge or result.
        await _phone1.rpc('advance_phase', params: {
          'p_session_id': sessionId,
        });
      }
      // ignore: avoid_print
      print('T6: result screen.');
    }

    if (targetScreen == 5) return;

    // ------------------------------------------------------------------
    // T6: Result screen is now showing. Let it display.
    // ------------------------------------------------------------------
    if (targetScreen == 6) {
      // ignore: avoid_print
      print('T6 is live. Results on screen.');
      return;
    }

    // ------------------------------------------------------------------
    // T7: End session.
    // ------------------------------------------------------------------
    if (targetScreen >= 7) {
      await Future<void>.delayed(const Duration(seconds: 5));
      await _phone1.rpc('end_session', params: {
        'p_session_id': sessionId,
      });
      // ignore: avoid_print
      print('T7: session ended.');
    }
  }, timeout: const Timeout(Duration(minutes: 3)));
}
