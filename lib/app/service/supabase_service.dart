import 'package:supabase/supabase.dart';

class SupabaseService {
  SupabaseService({required String url, required String anonKey})
      : client = SupabaseClient(url, anonKey);

  final SupabaseClient client;

  Future<void> connect() async {
    if (client.auth.currentSession != null) return;
    await client.auth.signInAnonymously();
  }
}
