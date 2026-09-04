import 'package:flutter/material.dart';

import '../model/workout.dart';

/// Kachel des Workout-Katalogs im 3×3-Grid der Workout-Auswahl.
class WorkoutCard extends StatelessWidget {
  const WorkoutCard({super.key, required this.workout, this.onTap});

  final Workout workout;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Icon(
                  workout.isUnlocked ? Icons.lock_open : Icons.lock,
                  size: 18,
                ),
              ),
              const Spacer(),
              Text(
                workout.name,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                workout.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
