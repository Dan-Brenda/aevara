// lib/data/adapters/mock/challenges_service_mock.dart
import '../../demo_data.dart';
import '../../models/challenge.dart';
import '../../services/challenges_service.dart';
import 'community_people.dart';
import 'leaderboard_service_mock.dart';

class ChallengesServiceMock implements ChallengesService {
  const ChallengesServiceMock();

  @override
  List<Challenge> list() {
    const boards = LeaderboardServiceMock();
    return [
      Challenge(
        id: 'steps_70k',
        title: '70k steps this week',
        description: 'Reach 70,000 steps between Monday and Sunday. Every step your wearable records counts.',
        status: ChallengeStatus.active,
        goal: 70000,
        progress: DemoData.weeklySteps,
        unit: 'steps',
        timeLabel: 'Ends Sunday',
        participants: const [demoMaya, demoJordan, demoPriya, demoSam, demoLena, demoTheo],
        yourRank: boards.weeklySteps().firstWhere((e) => e.isYou).rank,
      ),
      Challenge(
        id: 'sleep_21',
        title: '21 nights of 7+ hours',
        description: 'Sleep at least seven hours a night for three weeks in a row.',
        status: ChallengeStatus.active,
        goal: 21,
        progress: DemoData.sleepStreakNights.clamp(0, 21),
        unit: 'nights',
        timeLabel: 'Ongoing',
        participants: const [demoPriya, demoMaya, demoTheo, demoLena],
        yourRank: boards.sleepStreaks().firstWhere((e) => e.isYou).rank,
      ),
      const Challenge(
        id: 'hrv_month',
        title: 'Recovery month',
        description: 'Keep your overnight HRV at or above your own baseline for 20 of 30 days.',
        status: ChallengeStatus.upcoming,
        goal: 20,
        progress: 0,
        unit: 'days',
        timeLabel: 'Starts next Monday',
        participants: [demoJordan, demoSam, demoMaya],
        yourRank: null,
      ),
    ];
  }
}
