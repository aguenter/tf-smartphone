import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../home/model/workout.dart';
import '../bloc/phone_session_bloc.dart';
import '../bloc/phone_session_event.dart';
import '../bloc/phone_session_state.dart';

class VoteView extends StatefulWidget {
  const VoteView({super.key, required this.state});

  final PhoneSelectingState state;

  @override
  State<VoteView> createState() => _VoteViewState();
}

class _VoteViewState extends State<VoteView> {
  /// Workout the user just tapped, awaiting the server round-trip to confirm.
  String? _pendingWorkoutId;

  @override
  void didUpdateWidget(VoteView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A new vote snapshot from the server has arrived: the round-trip is done,
    // so stop showing the pending spinner.
    if (widget.state.myVoteWorkoutId != oldWidget.state.myVoteWorkoutId ||
        widget.state.voteCounts != oldWidget.state.voteCounts) {
      _pendingWorkoutId = null;
    }
  }

  void _onVote(String workoutId) {
    setState(() => _pendingWorkoutId = workoutId);
    context.read<PhoneSessionBloc>().add(VoteCast(workoutId));
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Text(
            'CHOOSE WORKOUT',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            '${state.participants.length} Participants',
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
                final isPending =
                    _pendingWorkoutId == workout.id && !isMyVote;
                return _WorkoutVoteCard(
                  workout: workout,
                  votes: votes,
                  isMyVote: isMyVote,
                  isPending: isPending,
                  onTap: () => _onVote(workout.id),
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
    required this.isPending,
    required this.onTap,
  });

  final Workout workout;
  final int votes;
  final bool isMyVote;
  final bool isPending;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Widget leading;
    if (isPending) {
      leading = SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    } else {
      leading = Icon(
        isMyVote ? Icons.check_circle : Icons.radio_button_unchecked,
        color: isMyVote ? Theme.of(context).colorScheme.primary : null,
      );
    }

    return Card(
      color: isMyVote
          ? Theme.of(context).colorScheme.primaryContainer
          : null,
      child: ListTile(
        // Prevent double taps while a vote is in flight.
        onTap: isPending ? null : onTap,
        leading: leading,
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
