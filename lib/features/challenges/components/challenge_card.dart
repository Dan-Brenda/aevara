// lib/features/challenges/components/challenge_card.dart
import 'package:flutter/material.dart';

import '../../../data/models/challenge.dart';
import 'challenge_status_chip.dart';
import 'participant_avatars_row.dart';

class ChallengeCard extends StatelessWidget {
  const ChallengeCard({super.key, required this.challenge, required this.onTap});

  final Challenge challenge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = challenge;
    final tt = Theme.of(context).textTheme;

    return Card(
      color: Theme.of(context).colorScheme.surface,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(c.title, style: tt.titleMedium)),
                  ChallengeStatusChip(status: c.status),
                ],
              ),
              const SizedBox(height: 2),
              Text(c.timeLabel, style: tt.bodySmall),
              const SizedBox(height: 12),
              if (c.status == ChallengeStatus.active) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(value: c.fraction, minHeight: 8),
                ),
                const SizedBox(height: 10),
              ],
              Row(
                children: [
                  ParticipantAvatarsRow(names: c.participants),
                  const Spacer(),
                  if (c.yourRank != null) Text('You\'re #${c.yourRank}', style: tt.labelLarge),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
