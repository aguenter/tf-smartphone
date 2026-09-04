@Tags(['integration'])
library;

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase/supabase.dart';

/// Integration tests for end_session RPC (TV ends the session after T6).

late SupabaseClient _tv;

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
  });

  tearDownAll(() {
    _tv.dispose();
  });

  group('T6 – end_session', () {
    test('end_session sets status to ended and clears phase', () async {
      final sessionId = await _tv.rpc<String>('create_session');

      await _tv.rpc('end_session', params: {
        'p_session_id': sessionId,
      });

      final session = await _tv
          .from('sessions')
          .select()
          .eq('id', sessionId)
          .single();

      expect(session['status'], 'ended');
      expect(session['phase'], isNull);
      expect(session['phase_started_at'], isNull);
    });
  });
}
