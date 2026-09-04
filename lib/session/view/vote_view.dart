import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../home/model/workout.dart';
import '../bloc/phone_session_bloc.dart';
import '../bloc/phone_session_event.dart';
import '../bloc/phone_session_state.dart';

class VoteView extends StatelessWidget {
  const VoteView({super.key, required this.state});

  final PhoneSelectingState state;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Text(
            'Workout wählen',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            '${state.participants.length} Teilnehmer',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: state.workouts.length,
              itemBuilder: (context, index) {
                final workout = state.workouts[index];
                final votes = state.voteCounts[workout.id] ?? 0;
                final isMyVote = state.myVoteWorkoutId == workout.id;
                return _WorkoutVoteCard(
                  workout: workout,
                  votes: votes,
                  isMyVote: isMyVote,
                  onTap: () => context
                      .read<PhoneSessionBloc>()
                      .add(VoteCast(workout.id)),
                );
              },
            ),
          ),
          if (state.isTrainer && state.trainerWorkoutId != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: FilledButton.icon(
                onPressed: () => context
                    .read<PhoneSessionBloc>()
                    .add(WorkoutSelected(state.trainerWorkoutId!)),
                icon: const Icon(Icons.check),
                label: const Text('Workout bestätigen'),
              ),
            ),
        ],
      ),
    );
  }
}

class _WorkoutVoteCard extends StatelessWidget {
  const _WorkoutVoteCard({
    required this.workout,
    required this.votes,
    required this.isMyVote,
    required this.onTap,
  });

  final Workout workout;
  final int votes;
  final bool isMyVote;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isMyVote
          ? Theme.of(context).colorScheme.primaryContainer
          : null,
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          isMyVote ? Icons.check_circle : Icons.radio_button_unchecked,
          color: isMyVote
              ? Theme.of(context).colorScheme.primary
              : null,
        ),
        title: Text(
          workout.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(workout.description),
        trailing: votes > 0
            ? CircleAvatar(
                radius: 14,
                child: Text('$votes', style: const TextStyle(fontSize: 12)),
              )
            : null,
      ),
    );
  }
}
