import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/phone_session_bloc.dart';
import '../bloc/phone_session_event.dart';
import '../model/participant.dart';

class LobbyView extends StatelessWidget {
  const LobbyView({
    super.key,
    required this.participants,
    required this.isTrainer,
  });

  final List<Participant> participants;
  final bool isTrainer;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 32),
          const Icon(Icons.people, size: 64),
          const SizedBox(height: 16),
          Text(
            participants.length < 2
                ? 'Ready to Start'
                : 'Waiting for Players...',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            '${participants.length} Participants',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: participants.length,
              itemBuilder: (context, index) {
                final p = participants[index];
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      p.displayName.isNotEmpty
                          ? p.displayName[0].toUpperCase()
                          : '?',
                    ),
                  ),
                  title: Text(p.displayName),
                  trailing: p.role == ParticipantRole.trainer
                      ? const Chip(label: Text('Trainer'))
                      : null,
                );
              },
            ),
          ),
          if (isTrainer)
            FilledButton.icon(
              onPressed: () => context
                  .read<PhoneSessionBloc>()
                  .add(const SelectionStartRequested()),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Selection'),
            ),
        ],
      ),
    );
  }
}
