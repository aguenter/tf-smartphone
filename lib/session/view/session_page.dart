import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/shared/constants.dart';
import '../../app/shared/lifecycle_reporter.dart';
import '../bloc/phone_session_bloc.dart';
import '../bloc/phone_session_event.dart';
import '../bloc/phone_session_state.dart';
import '../service/phone_session_service.dart';
import 'countdown_view.dart';
import 'end_view.dart';
import 'exercise_mirror_view.dart';
import 'join_view.dart';
import 'lobby_view.dart';
import 'rest_input_view.dart';
import 'result_view.dart';
import 'vote_view.dart';
import 'warmup_view.dart';

class SessionPage extends StatelessWidget {
  const SessionPage({super.key, this.sessionId});

  final String? sessionId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PhoneSessionBloc(
        service: PhoneSessionService(
          url: AppConstants.supabaseUrl,
          anonKey: AppConstants.supabaseAnonKey,
        ),
      ),
      // Builder, damit der Kontext unterhalb des BlocProvider liegt und den
      // PhoneSessionBloc lesen kann; LifecycleReporter stößt beim
      // Wiedererscheinen die sofortige Restzeit-Neuberechnung an.
      child: Builder(
        builder: (context) => LifecycleReporter(
          onResume: () =>
              context.read<PhoneSessionBloc>().add(const LifecycleResumed()),
          child: Scaffold(
            body: SafeArea(
              child: BlocBuilder<PhoneSessionBloc, PhoneSessionState>(
                builder: (context, state) => switch (state) {
                  PhoneInitialState() => JoinView(prefillSessionId: sessionId),
                  PhoneJoiningState() => const _Loading('Beitreten...'),
                  PhoneErrorState(:final message) => _ErrorView(
                    message: message,
                  ),
                  PhoneLobbyState() => LobbyView(
                    participants: state.participants,
                    isTrainer: state.isTrainer,
                  ),
                  PhoneSelectingState() => VoteView(state: state),
                  PhoneCountdownState() => CountdownView(
                    workoutName: state.workoutName,
                  ),
                  PhoneWarmupState() => WarmupView(
                    exercise: state.exercise,
                    secondsRemaining: state.secondsRemaining,
                  ),
                  PhoneExerciseState() => ExerciseMirrorView(
                    exercise: state.exercise,
                    secondsRemaining: state.secondsRemaining,
                  ),
                  PhoneRestState() => RestInputView(
                    exercise: state.exercise,
                    hasSubmitted: state.hasSubmitted,
                  ),
                  PhoneResultState() => const ResultView(),
                  PhoneEndedState() => const EndView(),
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(text, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Failed to Join',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
