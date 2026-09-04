@Tags(['integration'])
library;

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase/supabase.dart';

/// Integration tests for T1: smartphone joins a session created by the TV.
///
/// These tests hit a real Supabase instance (local via `supabase start` or a
/// test project). Set SUPABASE_URL and SUPABASE_ANON_KEY in the .env file.
///
/// Run with: flutter test test/integration/t1_join_session_test.dart

late SupabaseClient _tv;
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
  setUpAll(() async {
    await dotenv.load(fileName: '.env');
    _tv = await _createClient();
    _phone1 = await _createClient();
    _phone2 = await _createClient();
    _phone3 = await _createClient();
    _phone4 = await _createClient();
    _phone5 = await _createClient();
  });

  tearDownAll(() {
    _tv.dispose();
    _phone1.dispose();
    _phone2.dispose();
    _phone3.dispose();
    _phone4.dispose();
    _phone5.dispose();
  });

  const liveSessionId = String.fromEnvironment('SESSION_ID');

  group('T1 – Join Session (Smartphone → TV)', () {
    late String sessionId;

    setUp(() async {
      sessionId = await _tv.rpc<String>('create_session');
    });

    test('create_session returns a valid UUID', () {
      expect(sessionId, isNotEmpty);
      expect(
        RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$')
            .hasMatch(sessionId),
        isTrue,
        reason: 'session_id should be a valid UUID',
      );
    });

    test('first joiner becomes trainer', () async {
      final result = await _phone1.rpc<Map<String, dynamic>>(
        'join_session',
        params: {
          'p_session_id': sessionId,
          'p_display_name': 'Anna',
        },
      );

      expect(result['role'], 'trainer');
      expect(result['participant_id'], isNotEmpty);
      expect(result['initials'], 'AN');
    });

    test('second joiner becomes participant', () async {
      // First joiner (trainer).
      await _phone1.rpc(
        'join_session',
        params: {
          'p_session_id': sessionId,
          'p_display_name': 'Anna',
        },
      );

      // Second joiner (participant).
      final result = await _phone2.rpc<Map<String, dynamic>>(
        'join_session',
        params: {
          'p_session_id': sessionId,
          'p_display_name': 'Ben',
        },
      );

      expect(result['role'], 'participant');
    });

    test('participants table has correct rows after two joins', () async {
      await _phone1.rpc(
        'join_session',
        params: {
          'p_session_id': sessionId,
          'p_display_name': 'Anna',
        },
      );

      await _phone2.rpc(
        'join_session',
        params: {
          'p_session_id': sessionId,
          'p_display_name': 'Ben',
        },
      );

      final rows = await _tv
          .from('participants')
          .select()
          .eq('session_id', sessionId)
          .order('joined_at');

      expect(rows.length, 2);
      final names = rows.map((r) => r['display_name']).toSet();
      expect(names, {'Anna', 'Ben'});

      final trainer = rows.firstWhere((r) => r['role'] == 'trainer');
      final participant = rows.firstWhere((r) => r['role'] == 'participant');
      expect(trainer['display_name'], 'Anna');
      expect(participant['display_name'], 'Ben');
    });

    test('session row has trainer_participant_id set after first join',
        () async {
      final joinResult = await _phone1.rpc<Map<String, dynamic>>(
        'join_session',
        params: {
          'p_session_id': sessionId,
          'p_display_name': 'Anna',
        },
      );

      final sessions = await _tv
          .from('sessions')
          .select()
          .eq('id', sessionId)
          .limit(1);

      expect(sessions.first['trainer_participant_id'],
          joinResult['participant_id']);
    });

  });

  group('T1 – Visual verification (needs SESSION_ID)', () {
    test('staggered joins — watch badges appear on TV', () async {
      if (liveSessionId.isEmpty) {
        markTestSkipped('Pass --dart-define=SESSION_ID=<id> to run');
        return;
      }

      // ignore: avoid_print
      print('Joining live session: $liveSessionId');

      final names = {
        _phone1: 'Anna',
        _phone2: 'Ben',
        _phone3: 'Clara',
        _phone4: 'David',
        _phone5: 'Emma',
      };

      for (final entry in names.entries) {
        final result = await entry.key.rpc<Map<String, dynamic>>(
          'join_session',
          params: {
            'p_session_id': liveSessionId,
            'p_display_name': entry.value,
          },
        );
        // ignore: avoid_print
        print('${entry.value} joined as ${result['role']} '
            '(initials: ${result['initials']})');
        await Future<void>.delayed(const Duration(seconds: 2));
      }

      // ignore: avoid_print
      print('All 5 joined — waiting 10s for visual check...');
      await Future<void>.delayed(const Duration(seconds: 10));
    }, timeout: const Timeout(Duration(minutes: 1)));
  });
}
