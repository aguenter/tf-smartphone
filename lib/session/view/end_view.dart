import 'package:flutter/material.dart';

import '../../app/shared/constants.dart';
import '../../app/shared/theme.dart';

class EndView extends StatelessWidget {
  const EndView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'THANKS!',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 16),
            Text(
              'See you next time!',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: TeamfitColors.textOnInverseMuted,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Text(
              AppConstants.appName.toUpperCase(),
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: TeamfitColors.streak500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
