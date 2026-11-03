// lib/features/challenges/components/challenge_status_chip.dart
import 'package:flutter/material.dart';

import '../../../data/models/challenge.dart';

class ChallengeStatusChip extends StatelessWidget {
  const ChallengeStatusChip({super.key, required this.status});

  final ChallengeStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      ChallengeStatus.active => ('Active', const Color(0xFF24A699)),
      ChallengeStatus.upcoming => ('Upcoming', const Color(0xFFF6B56B)),
      ChallengeStatus.completed => ('Finished', const Color(0xFF9E9E9E)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color)),
    );
  }
}
