// lib/features/leaderboards/components/weekly_steps_board.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../state/leaderboards_providers.dart';
import 'leaderboard_entry_tile.dart';

class WeeklyStepsBoard extends ConsumerWidget {
  const WeeklyStepsBoard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LeaderboardList(
      title: 'Weekly steps',
      caption: 'Total steps over the last 7 days.',
      entries: ref.watch(leaderboardServiceProvider).weeklySteps(),
    );
  }
}
