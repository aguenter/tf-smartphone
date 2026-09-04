import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/shared/loading_indicator.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import '../bloc/home_state.dart';
import '../service/workout_service.dart';
import '../widget/workout_card.dart';

/// Home-Screen: zeigt dem Nutzer die Auswahl der verfügbaren Workouts
/// (9-Kacheln-Katalog).
class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HomeBloc(
        workoutService: WorkoutService(),
      )..add(const HomeCatalogRequested()),
      child: Scaffold(
        appBar: AppBar(title: const Text('Workout wählen')),
        body: BlocBuilder<HomeBloc, HomeState>(
          builder: (context, state) {
            if (state is! HomeCatalogLoadedState) {
              return const LoadingIndicator();
            }
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: state.workouts.length,
              itemBuilder: (context, index) {
                final workout = state.workouts[index];
                return WorkoutCard(workout: workout);
              },
            );
          },
        ),
      ),
    );
  }
}
