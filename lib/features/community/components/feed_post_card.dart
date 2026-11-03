// lib/features/community/components/feed_post_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/services/community_feed_service.dart';
import '../../challenges/components/participant_avatars_row.dart';
import 'reaction_bar.dart';

class FeedPostCard extends StatelessWidget {
  const FeedPostCard({super.key, required this.post});

  final FeedPost post;

  String _timeAgo(DateTime at) {
    final age = DateTime.now().difference(at);
    if (age.inMinutes < 60) return '${age.inMinutes}m ago';
    if (age.inHours < 24) return '${age.inHours}h ago';
    if (age.inDays < 7) return '${age.inDays}d ago';
    return DateFormat.MMMd().format(at);
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Card(
      color: Theme.of(context).colorScheme.surface,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                PersonAvatar(name: post.author, size: 36),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.isYou ? '${post.author} (you)' : post.author, style: tt.titleSmall),
                      Text(_timeAgo(post.at), style: tt.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(post.body, style: tt.bodyMedium),
            const SizedBox(height: 4),
            ReactionBar(reactions: post.reactions, comments: post.comments),
          ],
        ),
      ),
    );
  }
}
