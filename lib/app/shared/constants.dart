import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  const AppConstants._();

  static const String appName = 'Teamfit';

  // Werte kommen aus der .env-Datei (siehe .env.template), geladen via
  // dotenv.load() in main.dart. `.env` selbst ist nicht versioniert.
  static String get supabaseUrl => dotenv.get('SUPABASE_URL', fallback: '');
  static String get supabaseAnonKey =>
      dotenv.get('SUPABASE_ANON_KEY', fallback: '');
}
