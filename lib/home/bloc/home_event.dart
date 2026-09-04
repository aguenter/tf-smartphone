import 'package:equatable/equatable.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

/// Wird beim Betreten des Home-Screens ausgelöst und lädt den
/// Workout-Katalog.
class HomeCatalogRequested extends HomeEvent {
  const HomeCatalogRequested();
}
