// lib/features/leaderboards/components/experiment_gains_board.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../state/leaderboards_providers.dart';
import 'leaderboard_entry_tile.dart';

class ExperimentGainsBoard extends ConsumerWidget {
  const ExperimentGainsBoard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LeaderboardList(
      title: 'Experiment gains',
      caption: 'Biggest change in a target metric from a finished experiment.',
      entries: ref.watch(leaderboardServiceProvider).experimentGains(),
    );
  }
}
