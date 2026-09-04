import 'package:go_router/go_router.dart';

import '../../home/view/home_view.dart';
import '../../session/view/session_page.dart';
import '../view/app_view.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const AppView()),
    GoRoute(
      path: '/join',
      builder: (context, state) {
        final sessionId = state.uri.queryParameters['session'];
        return SessionPage(sessionId: sessionId);
      },
    ),
    GoRoute(path: '/home', builder: (context, state) => const HomeView()),
  ],
);
