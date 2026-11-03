// lib/data/adapters/mock/community_feed_service_mock.dart
import '../../demo_data.dart';
import '../../services/community_feed_service.dart';
import 'community_people.dart';
import 'experiments_service_mock.dart';

class CommunityFeedServiceMock implements CommunityFeedService {
  const CommunityFeedServiceMock();

  @override
  List<FeedPost> feed() {
    final now = DateTime.now();
    final walk = const ExperimentsServiceMock().walk();
    return [
      FeedPost(
        id: 'p1',
        author: demoMaya,
        body: 'Third week of the sleep challenge and my HRV finally looks like it did before the new job. Consistent bedtimes are boring, and they work.',
        at: now.subtract(const Duration(minutes: 42)),
        reactions: 14,
        comments: 3,
      ),
      FeedPost(
        id: 'p2',
        author: DemoData.fullName,
        isYou: true,
        body: 'Vitality Age is down to ${DemoData.vitalityAge.toStringAsFixed(1)}, and I\'ve had ${DemoData.healthyDays30} healthy days in the last 30. Next up: earlier bedtimes.',
        at: now.subtract(const Duration(hours: 3)),
        reactions: 9,
        comments: 2,
      ),
      FeedPost(
        id: 'p3',
        author: demoJordan,
        body: 'Finished a two-week no-late-caffeine experiment. Honest result: no real change in my numbers, though I fell asleep faster. Trying a morning walk next.',
        at: now.subtract(const Duration(hours: 8)),
        reactions: 21,
        comments: 6,
      ),
      FeedPost(
        id: 'p4',
        author: demoPriya,
        body: 'Who else is in the 70k steps challenge this week? I\'m a bit behind after two days of travel.',
        at: now.subtract(const Duration(days: 1, hours: 2)),
        reactions: 7,
        comments: 4,
      ),
      FeedPost(
        id: 'p5',
        author: DemoData.fullName,
        isYou: true,
        body: 'Wrapped up my ${walk.totalDays}-day morning walk experiment. Average resting heart rate changed by ${walk.changeLabel}.',
        at: now.subtract(const Duration(days: 12)),
        reactions: 18,
        comments: 5,
      ),
    ];
  }
}
