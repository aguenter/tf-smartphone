import 'package:flutter/material.dart';

import '../../app/shared/theme.dart';

class CountdownView extends StatelessWidget {
  const CountdownView({super.key, required this.workoutName});

  final String workoutName;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              workoutName.toUpperCase(),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Icon(
              Icons.timer,
              size: 64,
              color: TeamfitColors.streak500,
            ),
            const SizedBox(height: 24),
            Text(
              'Watch the TV',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
