import 'package:equatable/equatable.dart';

abstract class AppState extends Equatable {
  const AppState();

  @override
  List<Object?> get props => [];
}

/// Die Verbindung zu Supabase wird aufgebaut, es wird der Loading-Indicator
/// angezeigt.
class AppLoadingState extends AppState {
  const AppLoadingState();
}

/// Die Verbindung steht, die App navigiert in den eigentlichen
/// Anwendungsbereich (Home-Screen mit der Workout-Auswahl).
class AppReadyState extends AppState {
  const AppReadyState();
}
