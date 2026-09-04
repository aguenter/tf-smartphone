import 'package:flutter_bloc/flutter_bloc.dart';

import '../service/workout_service.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc({required WorkoutService workoutService})
      : _workoutService = workoutService,
        super(const HomeLoadingState()) {
    on<HomeCatalogRequested>(_onCatalogRequested);
  }

  final WorkoutService _workoutService;

  Future<void> _onCatalogRequested(
    HomeCatalogRequested event,
    Emitter<HomeState> emit,
  ) async {
    final workouts = await _workoutService.fetchCatalog();
    emit(HomeCatalogLoadedState(workouts));
  }
}
