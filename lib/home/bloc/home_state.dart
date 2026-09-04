import 'package:equatable/equatable.dart';

import '../model/workout.dart';

abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

class HomeLoadingState extends HomeState {
  const HomeLoadingState();
}

class HomeCatalogLoadedState extends HomeState {
  const HomeCatalogLoadedState(this.workouts);

  final List<Workout> workouts;

  @override
  List<Object?> get props => [workouts];
}
