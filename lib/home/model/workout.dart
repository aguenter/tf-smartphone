import 'package:equatable/equatable.dart';

/// Eine Kachel des Workout-Katalogs auf dem Home-Screen.
class Workout extends Equatable {
  const Workout({
    required this.id,
    required this.name,
    required this.description,
    required this.isUnlocked,
  });

  final String id;
  final String name;
  final String description;
  final bool isUnlocked;

  @override
  List<Object?> get props => [id, name, description, isUnlocked];
}
