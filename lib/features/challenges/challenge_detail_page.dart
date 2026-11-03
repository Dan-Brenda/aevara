// lib/features/challenges/challenge_detail_page.dart
import 'package:flutter/material.dart';

import '../../core/demo.dart';
import '../../data/models/challenge.dart';
import 'components/challenge_status_chip.dart';
import 'components/participant_avatars_row.dart';

class ChallengeDetailPage extends StatelessWidget {
  const ChallengeDetailPage({super.key, required this.challenge});

  final Challenge challenge;

  String _number(int n) {
    final s = n.toString();
    final out = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) out.write(',');
      out.write(s[i]);
    }
    return out.toString();
  }

  @override
  Widget build(BuildContext context) {
    final c = challenge;
    final tt = Theme.of(context).textTheme;
    final joined = c.yourRank != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Challenge')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Row(
            children: [
              Expanded(child: Text(c.title, style: tt.headlineSmall)),
              ChallengeStatusChip(status: c.status),
            ],
          ),
          const SizedBox(height: 4),
          Text(c.timeLabel, style: tt.bodySmall),
          const SizedBox(height: 12),
          Text(c.description, style: tt.bodyMedium),
          if (joined) ...[
            const SizedBox(height: 20),
            Text('Your progress', style: tt.titleSmall),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(value: c.fraction, minHeight: 10),
            ),
            const SizedBox(height: 6),
            Text(
              '${_number(c.progress)} of ${_number(c.goal)} ${c.unit}. You\'re #${c.yourRank}.',
              style: tt.bodyMedium,
            ),
          ],
          const SizedBox(height: 20),
          Text('Participants', style: tt.titleSmall),
          const SizedBox(height: 4),
          for (final name in c.participants)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: PersonAvatar(name: name, size: 36),
              title: Text(name),
            ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => showDemoReadOnlyMessage(),
            child: Text(joined ? 'Invite a friend' : 'Join this challenge'),
          ),
        ],
      ),
    );
  }
}
