import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app/service/supabase_service.dart';
import 'app/shared/constants.dart';
import 'app/shared/router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(const TeamfitApp());
}

class TeamfitApp extends StatelessWidget {
  const TeamfitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<SupabaseService>(
      create: (_) => SupabaseService(
        url: AppConstants.supabaseUrl,
        anonKey: AppConstants.supabaseAnonKey,
      ),
      child: MaterialApp.router(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        routerConfig: appRouter,
      ),
    );
  }
}
