@Tags(['integration'])
library;

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase/supabase.dart';

/// Integration tests for T1→T2: smartphone triggers start_selection.
///
/// Tests hit a real Supabase instance. Set SUPABASE_URL and SUPABASE_ANON_KEY
/// in the .env file.
///
/// Run with: flutter test test/integration/t2_start_selection_test.dart

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

void main() {
  setUpAll(() async {
    await dotenv.load(fileName: '.env');
    _tv = await _createClient();
    _phone1 = await _createClient();
    _phone2 = await _createClient();
  });

  tearDownAll(() {
    _tv.dispose();
    _phone1.dispose();
    _phone2.dispose();
  });

  const liveSessionId = String.fromEnvironment('SESSION_ID');

  group('T1→T2 – start_selection (Smartphone)', () {
    late String sessionId;

    setUp(() async {
      sessionId = await _tv.rpc<String>('create_session');
    });

    test('trainer can start selection', () async {
      await _phone1.rpc('join_session', params: {
        'p_session_id': sessionId,
        'p_display_name': 'Anna',
      });

      await _phone1.rpc('start_selection', params: {
        'p_session_id': sessionId,
      });

      final rows = await _tv
          .from('sessions')
          .select()
          .eq('id', sessionId)
          .limit(1);

      expect(rows.first['status'], 'selecting');
    });

    test('non-trainer cannot start selection', () async {
      // Anna joins first → trainer.
      await _phone1.rpc('join_session', params: {
        'p_session_id': sessionId,
        'p_display_name': 'Anna',
      });

      // Ben joins second → participant.
      await _phone2.rpc('join_session', params: {
        'p_session_id': sessionId,
        'p_display_name': 'Ben',
      });

      // Ben (participant) tries to start selection → should fail.
      expect(
        () => _phone2.rpc('start_selection', params: {
          'p_session_id': sessionId,
        }),
        throwsA(isA<PostgrestException>()),
      );
    });

    test('start_selection on non-existent session does not crash', () async {
      expect(
        () => _phone1.rpc('start_selection', params: {
          'p_session_id': '00000000-0000-0000-0000-000000000000',
        }),
        throwsA(isA<PostgrestException>()),
      );
    });
  });

  group('T1→T2 – Visual verification (needs SESSION_ID)', () {
    test('trainer starts selection — watch TV transition to T2', () async {
      if (liveSessionId.isEmpty) {
        markTestSkipped('Pass --dart-define=SESSION_ID=<id> to run');
        return;
      }

      // ignore: avoid_print
      print('Starting selection on live session: $liveSessionId');

      // Join as trainer first (first joiner gets trainer role).
      // If the T1 join test already ran against this session, phone1 here
      // is a fresh anonymous identity — it joins as a new participant.
      // To guarantee trainer role, we create a dedicated client that joins
      // first on a fresh session, or we accept that the launch script
      // must pass a session where phone1 is already the trainer.
      final trainerResult = await _phone1.rpc<Map<String, dynamic>>(
        'join_session',
        params: {
          'p_session_id': liveSessionId,
          'p_display_name': 'Trainer',
        },
      );

      final role = trainerResult['role'] as String;
      // ignore: avoid_print
      print('Joined as $role');

      if (role != 'trainer') {
        // ignore: avoid_print
        print('WARNING: Not the trainer — skipping start_selection call.');
        print('Run this test on a fresh session where this client joins first.');
        return;
      }

      await _phone1.rpc('start_selection', params: {
        'p_session_id': liveSessionId,
      });

      // ignore: avoid_print
      print('start_selection called — TV should now show T2.');
      // ignore: avoid_print
      print('Waiting 10s for visual check...');
      await Future<void>.delayed(const Duration(seconds: 10));
    }, timeout: const Timeout(Duration(minutes: 1)));
  });
}
