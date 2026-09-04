import 'package:flutter/material.dart';

import '../model/exercise.dart';
import '../widget/exercise_icon.dart';
import '../widget/progress_ring.dart';

class ExerciseMirrorView extends StatelessWidget {
  const ExerciseMirrorView({
    super.key,
    required this.exercise,
    required this.secondsRemaining,
  });

  final Exercise exercise;
  final int secondsRemaining;

  @override
  Widget build(BuildContext context) {
    final displaySeconds = secondsRemaining - 1;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExerciseIcon(exercise: exercise, size: 150),
            const SizedBox(height: 24),
            Text(
              exercise.name.toUpperCase(),
              style: Theme.of(context).textTheme.displaySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              exercise.instruction,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ProgressRing(
              value: exercise.executionSeconds > 0
                  ? secondsRemaining / exercise.executionSeconds
                  : 0,
              totalSeconds: exercise.executionSeconds,
              label: '$displaySeconds',
              sublabel: 'SEC',
              showTenths: true,
            ),
          ],
        ),
      ),
    );
  }
}
