import 'package:equatable/equatable.dart';

enum MetricType { reps, seconds }

class Exercise extends Equatable {
  const Exercise({
    required this.id,
    required this.name,
    required this.instruction,
    required this.metricType,
  });

  factory Exercise.fromRow(Map<String, dynamic> row) {
    return Exercise(
      id: row['id'] as String,
      name: row['name'] as String,
      instruction: (row['instruction'] as String?) ?? '',
      metricType: (row['metric_type'] as String?) == 'seconds'
          ? MetricType.seconds
          : MetricType.reps,
    );
  }

  final String id;
  final String name;
  final String instruction;
  final MetricType metricType;

  @override
  List<Object?> get props => [id, name, instruction, metricType];
}
