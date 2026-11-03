// lib/features/leaderboards/components/leaderboard_entry_tile.dart
import 'package:flutter/material.dart';

import '../../../data/models/leaderboard.dart';
import '../../challenges/components/participant_avatars_row.dart';

class LeaderboardEntryTile extends StatelessWidget {
  const LeaderboardEntryTile({super.key, required this.entry});

  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tt = theme.textTheme;
    final e = entry;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: e.isYou ? theme.colorScheme.primary.withOpacity(0.16) : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text('${e.rank}', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          ),
          PersonAvatar(name: e.name, size: 32),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              e.isYou ? '${e.name} (you)' : e.name,
              overflow: TextOverflow.ellipsis,
              style: tt.bodyMedium?.copyWith(fontWeight: e.isYou ? FontWeight.w700 : null),
            ),
          ),
          Text(e.value, style: tt.titleSmall),
        ],
      ),
    );
  }
}

/// Heading, caption and ranked rows; shared by the three boards.
class LeaderboardList extends StatelessWidget {
  const LeaderboardList({
    super.key,
    required this.title,
    required this.caption,
    required this.entries,
  });

  final String title;
  final String caption;
  final List<LeaderboardEntry> entries;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: tt.titleMedium),
        const SizedBox(height: 2),
        Text(caption, style: tt.bodySmall),
        const SizedBox(height: 12),
        for (final e in entries) LeaderboardEntryTile(entry: e),
      ],
    );
  }
}
