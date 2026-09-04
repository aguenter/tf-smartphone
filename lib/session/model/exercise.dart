import 'package:equatable/equatable.dart';

enum MetricType { reps, seconds }

class Exercise extends Equatable {
  const Exercise({
    required this.id,
    required this.name,
    required this.instruction,
    required this.metricType,
    this.executionSeconds = 0,
    this.inputWindowSeconds = 0,
    this.imagePath,
  });

  factory Exercise.fromRow(Map<String, dynamic> row) {
    return Exercise(
      id: row['id'] as String,
      name: row['name'] as String,
      instruction: (row['instruction'] as String?) ?? '',
      metricType: (row['metric_type'] as String?) == 'seconds'
          ? MetricType.seconds
          : MetricType.reps,
      executionSeconds: (row['execution_seconds'] as int?) ?? 0,
      inputWindowSeconds: (row['input_window_seconds'] as int?) ?? 0,
      imagePath: row['image_path'] as String?,
    );
  }

  final String id;
  final String name;
  final String instruction;
  final MetricType metricType;
  final int executionSeconds;
  final int inputWindowSeconds;
  final String? imagePath;

  @override
  List<Object?> get props => [id, name, instruction, metricType, executionSeconds, inputWindowSeconds, imagePath];
}
