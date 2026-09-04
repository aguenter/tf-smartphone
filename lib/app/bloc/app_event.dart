import 'package:equatable/equatable.dart';

abstract class AppEvent extends Equatable {
  const AppEvent();

  @override
  List<Object?> get props => [];
}

/// Wird beim Start der App ausgelöst und stößt den Verbindungsaufbau zu
/// Supabase an.
class AppStarted extends AppEvent {
  const AppStarted();
}
