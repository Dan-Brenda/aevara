// lib/features/leaderboards/components/sleep_streaks_board.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../state/leaderboards_providers.dart';
import 'leaderboard_entry_tile.dart';

class SleepStreaksBoard extends ConsumerWidget {
  const SleepStreaksBoard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LeaderboardList(
      title: 'Sleep streaks',
      caption: 'Consecutive nights of 7 or more hours.',
      entries: ref.watch(leaderboardServiceProvider).sleepStreaks(),
    );
  }
}
