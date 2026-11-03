import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/demo.dart';
import '../../state/challenges_providers.dart';
import '../../state/community_providers.dart';
import '../challenges/challenge_detail_page.dart';
import '../challenges/components/challenge_card.dart';
import '../leaderboards/components/experiment_gains_board.dart';
import '../leaderboards/components/sleep_streaks_board.dart';
import '../leaderboards/components/weekly_steps_board.dart';
import 'components/feed_post_card.dart';

class CommunityPage extends StatelessWidget {
  const CommunityPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (isDemoSession) return const _DemoCommunity();
    return const Center(
      child: Text('Community placeholder'),
    );
  }
}

class _DemoCommunity extends StatelessWidget {
  const _DemoCommunity();

  @override
  Widget build(BuildContext context) {
    return const DefaultTabController(
      length: 3,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(text: 'Feed'),
              Tab(text: 'Challenges'),
              Tab(text: 'Leaderboards'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [_FeedTab(), _ChallengesTab(), _LeaderboardsTab()],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedTab extends ConsumerWidget {
  const _FeedTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(communityFeedServiceProvider).feed();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        OutlinedButton.icon(
          onPressed: () => showDemoReadOnlyMessage(),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Share an update'),
        ),
        const SizedBox(height: 12),
        for (final p in posts)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: FeedPostCard(post: p),
          ),
      ],
    );
  }
}

class _ChallengesTab extends ConsumerWidget {
  const _ChallengesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challenges = ref.watch(challengesServiceProvider).list();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        for (final c in challenges)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ChallengeCard(
              challenge: c,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => ChallengeDetailPage(challenge: c)),
              ),
            ),
          ),
        OutlinedButton.icon(
          onPressed: () => showDemoReadOnlyMessage(),
          icon: const Icon(Icons.add),
          label: const Text('Create a challenge'),
        ),
      ],
    );
  }
}

enum _Board { steps, sleep, experiments }

class _LeaderboardsTab extends StatefulWidget {
  const _LeaderboardsTab();

  @override
  State<_LeaderboardsTab> createState() => _LeaderboardsTabState();
}

class _LeaderboardsTabState extends State<_LeaderboardsTab> {
  _Board _board = _Board.steps;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        SegmentedButton<_Board>(
          segments: const [
            ButtonSegment(value: _Board.steps, label: Text('Steps')),
            ButtonSegment(value: _Board.sleep, label: Text('Sleep')),
            ButtonSegment(value: _Board.experiments, label: Text('Gains')),
          ],
          selected: {_board},
          onSelectionChanged: (v) => setState(() => _board = v.first),
        ),
        const SizedBox(height: 16),
        switch (_board) {
          _Board.steps => const WeeklyStepsBoard(),
          _Board.sleep => const SleepStreaksBoard(),
          _Board.experiments => const ExperimentGainsBoard(),
        },
      ],
    );
  }
}
