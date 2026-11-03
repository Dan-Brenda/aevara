// lib/data/adapters/mock/leaderboard_service_mock.dart
//
// The visitor's own rows come from DemoData and the sample experiments, so each
// board agrees with the Data and Experiments tabs.
import '../../demo_data.dart';
import '../../models/leaderboard.dart';
import '../../services/leaderboard_service.dart';
import 'community_people.dart';
import 'experiments_service_mock.dart';

class LeaderboardServiceMock implements LeaderboardService {
  const LeaderboardServiceMock();

  static String _thousands(int n) {
    final s = n.toString();
    final out = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) out.write(',');
      out.write(s[i]);
    }
    return out.toString();
  }

  @override
  List<LeaderboardEntry> weeklySteps() => _rank(
        {
          demoMaya: 74210,
          demoSam: 68940,
          demoLena: 57320,
          demoJordan: 52880,
          demoPriya: 41760,
          demoTheo: 38150,
        },
        DemoData.weeklySteps,
        (v) => _thousands(v.round()),
      );

  @override
  List<LeaderboardEntry> sleepStreaks() => _rank(
        {
          demoPriya: 19,
          demoTheo: 11,
          demoMaya: 8,
          demoLena: 5,
          demoSam: 3,
          demoJordan: 2,
        },
        DemoData.sleepStreakNights,
        (v) => '${v.round()} nights',
      );

  @override
  List<LeaderboardEntry> experimentGains() {
    final walk = const ExperimentsServiceMock().walk();
    return _rank(
      {
        demoLena: 6.4,
        demoSam: 4.1,
        demoJordan: 2.3,
        demoMaya: 1.2,
        demoPriya: 0.6,
      },
      walk.percentChange.abs(),
      (v) => '${v.toStringAsFixed(1)}%',
    );
  }

  List<LeaderboardEntry> _rank(
    Map<String, num> others,
    num yours,
    String Function(num) format,
  ) {
    final rows = <(String, num, bool)>[
      for (final e in others.entries) (e.key, e.value, false),
      (DemoData.fullName, yours, true),
    ]..sort((a, b) => b.$2.compareTo(a.$2));
    return [
      for (var i = 0; i < rows.length; i++)
        LeaderboardEntry(
          rank: i + 1,
          name: rows[i].$1,
          value: format(rows[i].$2),
          isYou: rows[i].$3,
        ),
    ];
  }
}
