import 'package:flutter/material.dart';

import '../../app/shared/constants.dart';
import '../model/exercise.dart';

class ExerciseIcon extends StatelessWidget {
  const ExerciseIcon({
    super.key,
    required this.exercise,
    this.size = 150,
  });

  final Exercise exercise;
  final double size;

  static String _emojiFor(Exercise exercise) {
    switch (exercise.id) {
      case 'hampelmann':
        return '🤸';
      case 'liegestuetze':
        return '💪';
      case 'kniebeugen':
        return '🦵';
      case 'situps':
        return '⚡';
      default:
        return '🏋️';
    }
  }

  @override
  Widget build(BuildContext context) {
    final path = exercise.imagePath;
    if (path != null && path.isNotEmpty) {
      final baseUrl = AppConstants.supabaseUrl;
      if (baseUrl.isNotEmpty) {
        final url = '$baseUrl/storage/v1/object/public/$path';
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(
            url,
            width: size,
            height: size,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Text(
              _emojiFor(exercise),
              style: TextStyle(fontSize: size * 0.5),
            ),
          ),
        );
      }
    }
    return Text(
      _emojiFor(exercise),
      style: TextStyle(fontSize: size * 0.5),
    );
  }
}
