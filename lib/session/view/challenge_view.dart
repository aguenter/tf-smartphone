import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/phone_session_bloc.dart';
import '../bloc/phone_session_event.dart';
import '../model/exercise.dart';

class ChallengeView extends StatefulWidget {
  const ChallengeView({
    super.key,
    required this.exercise,
    required this.hasSubmitted,
  });

  final Exercise exercise;
  final bool hasSubmitted;

  @override
  State<ChallengeView> createState() => _ChallengeViewState();
}

class _ChallengeViewState extends State<ChallengeView> {
  final _controller = TextEditingController();

  @override
  void didUpdateWidget(ChallengeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exercise.id != widget.exercise.id) {
      _controller.clear();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = int.tryParse(_controller.text.trim());
    if (value == null || value < 0) return;
    context.read<PhoneSessionBloc>().add(ResultEntered(value));
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.exercise.metricType == MetricType.reps
        ? 'Wiederholungen'
        : 'Sekunden';

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.fitness_center, size: 64),
          const SizedBox(height: 16),
          Text(
            widget.exercise.name,
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            widget.exercise.instruction,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          if (widget.hasSubmitted) ...[
            const Icon(Icons.check_circle, size: 64, color: Colors.green),
            const SizedBox(height: 12),
            Text(
              'Ergebnis eingetragen!',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ] else ...[
            Text(label, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            SizedBox(
              width: 160,
              child: TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: '0',
                  suffixText: widget.exercise.metricType == MetricType.reps
                      ? 'x'
                      : 's',
                ),
                onSubmitted: (_) => _submit(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.send),
              label: const Text('Eintragen'),
            ),
          ],
          const Spacer(),
        ],
      ),
    );
  }
}
