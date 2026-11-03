// lib/data/services/community_feed_service.dart

class FeedPost {
  const FeedPost({
    required this.id,
    required this.author,
    required this.body,
    required this.at,
    required this.reactions,
    required this.comments,
    this.isYou = false,
  });

  final String id;
  final String author;
  final String body;
  final DateTime at;
  final int reactions;
  final int comments;
  final bool isYou;
}

abstract class CommunityFeedService {
  List<FeedPost> feed();
}
