@Tags(['integration'])
library;

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase/supabase.dart';

/// Combined visual verification test: 5 players join (T1), then the trainer
/// starts selection (T1→T2). Run against a live TV session.
///
/// Usage (via launch script):
///   flutter test --tags=integration --run-skipped \
///     --dart-define=SESSION_ID=<id> \
///     test/integration/t1_t2_visual_test.dart

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
  const liveSessionId = String.fromEnvironment('SESSION_ID');

  setUpAll(() async {
    await dotenv.load(fileName: '.env');
    _phone1 = await _createClient();
    _phone2 = await _createClient();
    _phone3 = await _createClient();
    _phone4 = await _createClient();
    _phone5 = await _createClient();
  });

  tearDownAll(() {
    _phone1.dispose();
    _phone2.dispose();
    _phone3.dispose();
    _phone4.dispose();
    _phone5.dispose();
  });

  test('T1→T2 visual: 5 players join, trainer starts selection', () async {
    if (liveSessionId.isEmpty) {
      markTestSkipped('Pass --dart-define=SESSION_ID=<id> to run');
      return;
    }

    // ignore: avoid_print
    print('Live session: $liveSessionId');

    // --- T1: 5 players join with staggered delays ---
    final phones = {
      _phone1: 'Anna',
      _phone2: 'Ben',
      _phone3: 'Clara',
      _phone4: 'David',
      _phone5: 'Emma',
    };

    String? trainerId;

    for (final entry in phones.entries) {
      final result = await entry.key.rpc<Map<String, dynamic>>(
        'join_session',
        params: {
          'p_session_id': liveSessionId,
          'p_display_name': entry.value,
        },
      );
      final role = result['role'] as String;
      // ignore: avoid_print
      print('${entry.value} joined as $role '
          '(initials: ${result['initials']})');
      if (role == 'trainer') trainerId = entry.value;
      await Future<void>.delayed(const Duration(seconds: 2));
    }

    // ignore: avoid_print
    print('All 5 joined — $trainerId is trainer.');
    print('Waiting 5s before starting selection...');
    await Future<void>.delayed(const Duration(seconds: 5));

    // --- T1→T2: Trainer starts selection ---
    // Phone1 is first joiner → trainer.
    await _phone1.rpc('start_selection', params: {
      'p_session_id': liveSessionId,
    });

    // ignore: avoid_print
    print('start_selection called — TV should transition to T2.');
    print('Waiting 10s for visual check...');
    await Future<void>.delayed(const Duration(seconds: 10));
  }, timeout: const Timeout(Duration(minutes: 2)));
}
