import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/shared/theme.dart';
import '../bloc/phone_session_bloc.dart';
import '../bloc/phone_session_event.dart';
import '../model/exercise.dart';
import '../widget/number_carousel.dart';

class RestInputView extends StatefulWidget {
  const RestInputView({
    super.key,
    required this.exercise,
    required this.hasSubmitted,
  });

  final Exercise exercise;
  final bool hasSubmitted;

  @override
  State<RestInputView> createState() => _RestInputViewState();
}

class _RestInputViewState extends State<RestInputView> {
  static const _defaultValue = 10;

  final _carouselKey = GlobalKey<NumberCarouselState>();
  int _value = _defaultValue;

  @override
  void didUpdateWidget(RestInputView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exercise.id != widget.exercise.id) {
      setState(() => _value = _defaultValue);
      _carouselKey.currentState?.reset(_defaultValue);
    }
  }

  void _submit() {
    if (_value < 0) return;
    context.read<PhoneSessionBloc>().add(ResultEntered(_value));
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.exercise.metricType == MetricType.reps
        ? 'Reps'
        : 'Seconds';

    final exerciseName = widget.exercise.name.toUpperCase();
    final questionPrefix = widget.exercise.metricType == MetricType.reps
        ? 'Wie viele'
        : 'Wie viele Sekunden';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.hasSubmitted) ...[
              const Icon(Icons.check_circle, size: 64, color: Colors.green),
              const SizedBox(height: 12),
              Text(
                'Result Submitted!',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ] else ...[
              Text(
                questionPrefix,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              Text(
                exerciseName,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: TeamfitColors.streak500,
                    ),
                textAlign: TextAlign.center,
              ),
              Text(
                'geschafft?',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Text(label, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              NumberCarousel(
                key: _carouselKey,
                initial: _defaultValue,
                onChanged: (value) => _value = value,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.send),
                label: const Text('Submit'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
