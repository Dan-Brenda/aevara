// test/demo_data_test.dart
//
// Every demo screen must tell the same story, so these check the mock adapters
// against DemoData instead of checking fixed numbers.
import 'package:aevara_app/data/adapters/mock/challenges_service_mock.dart';
import 'package:aevara_app/data/adapters/mock/community_feed_service_mock.dart';
import 'package:aevara_app/data/adapters/mock/daily_service_mock.dart';
import 'package:aevara_app/data/adapters/mock/devices_service_mock.dart';
import 'package:aevara_app/data/adapters/mock/experiments_service_mock.dart';
import 'package:aevara_app/data/adapters/mock/leaderboard_service_mock.dart';
import 'package:aevara_app/data/demo_data.dart';
import 'package:aevara_app/data/models/leaderboard.dart';
import 'package:aevara_app/data/models/vitality_metrics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const daily = DailyServiceMock();
  const boards = LeaderboardServiceMock();
  const experiments = ExperimentsServiceMock();
  final vitality = DemoData.vitalityAge.toStringAsFixed(1);

  group('Dates', () {
    test('every day is a calendar day, ending today', () {
      final now = DateTime.now();
      final days = DemoData.metricHistory(90);
      expect(days.last.date, DateTime(now.year, now.month, now.day));
      for (var i = 1; i < days.length; i++) {
        expect(days[i].date.hour, 0, reason: 'clock changes must not shift dates');
        expect(days[i].date.difference(days[i - 1].date).inHours, inInclusiveRange(23, 25));
      }
    });

    test('the trend and the 30-day chart start on the same date', () {
      final now = DateTime.now();
      expect(DemoData.vitalityHistory(30).first.date, DateTime(now.year, now.month, now.day - 29));
    });
  });

  group('Vitality Age', () {
    test('is younger than the actual age', () {
      expect(DemoData.vitalityAge, lessThan(DemoData.chronoAge));
    });

    test('the last point of the trend matches the ring', () {
      expect(DemoData.vitalityHistory(30).last.vitalityAge, DemoData.vitalityAge);
    });

    test('rises and falls rather than only improving', () {
      final ages = DemoData.vitalityHistory(30).map((p) => p.vitalityAge).toList();
      var ups = 0, downs = 0;
      for (var i = 1; i < ages.length; i++) {
        if (ages[i] > ages[i - 1]) ups++;
        if (ages[i] < ages[i - 1]) downs++;
      }
      expect(ups, greaterThan(3));
      expect(downs, greaterThan(3));
    });

    test('the sync timeline and the feed quote the same score', () {
      expect(const DevicesServiceMock().syncEvents().first.detail, contains(vitality));
      final yours = const CommunityFeedServiceMock().feed().firstWhere((p) => p.isYou);
      expect(yours.body, contains(vitality));
      expect(yours.body, contains('${DemoData.healthyDays30} healthy days'));
    });

    test('the coach quotes the same gap as the ring', () {
      final gap = (DemoData.chronoAge - DemoData.vitalityAge).toStringAsFixed(1);
      expect(daily.coachInsight(), contains('$gap years younger'));
    });
  });

  group('Healthy Days', () {
    test('the bar colors, the count and the tooltip agree on every sample day', () {
      for (final r in DemoData.riskSeries30) {
        expect(r! < 0.45, r < 0.50, reason: 'risk $r');
      }
    });

    test('ordinary days vary rather than sitting on one value', () {
      final ordinary = DemoData.riskSeries30.cast<double>().where((r) => r < 0.45).toList()..sort();
      expect(ordinary.last - ordinary.first, greaterThan(0.04));
    });

    test('the chart shows all three states', () {
      final risks = DemoData.riskSeries30.cast<double>();
      expect(risks.where((r) => r < 0.45), isNotEmpty);
      expect(risks.where((r) => r >= 0.45 && r <= 0.55), isNotEmpty);
      expect(risks.where((r) => r > 0.55), isNotEmpty);
    });

    test('the count matches the bars', () {
      expect(DemoData.healthyDays30, DemoData.riskSeries30.where((r) => r! < 0.45).length);
    });
  });

  group('Metrics', () {
    MetricSnapshot snapshot(VitalityMetric m) =>
        daily.snapshots().firstWhere((s) => s.metric == m);

    test('tiles show last night\'s values and yesterday\'s steps', () {
      final today = DemoData.today;
      expect(snapshot(VitalityMetric.sleep).value, today.sleepHours);
      expect(snapshot(VitalityMetric.hrv).value, today.hrvMs);
      expect(snapshot(VitalityMetric.restingHr).value, today.restingHrBpm);
      expect(snapshot(VitalityMetric.steps).value, DemoData.yesterday.steps.toDouble());
    });

    test('values stay in a believable range', () {
      for (final d in DemoData.metricHistory(90)) {
        expect(d.sleepHours, inInclusiveRange(4.0, 10.0));
        expect(d.hrvMs, inInclusiveRange(30, 90));
        expect(d.restingHrBpm, inInclusiveRange(48, 75));
        expect(d.steps, inInclusiveRange(3000, 16000));
      }
    });

    test('not every metric is improving', () {
      final hrvWeek = DemoData.average((d) => d.hrvMs, fromDaysAgo: 7);
      final hrvBefore = DemoData.average((d) => d.hrvMs, fromDaysAgo: 30, toDaysAgo: 7);
      final stepsWeek = DemoData.average((d) => d.steps.toDouble(), fromDaysAgo: 8, toDaysAgo: 1);
      final stepsBefore = DemoData.average((d) => d.steps.toDouble(), fromDaysAgo: 30, toDaysAgo: 8);
      expect(stepsWeek, lessThan(stepsBefore));
      expect(hrvWeek, lessThan(hrvBefore + 3));
    });

    test('the coach quotes last night\'s HRV', () {
      expect(daily.coachInsight(), contains('HRV is ${DemoData.today.hrvMs.round()} ms'));
    });
  });

  group('Why today\'s number', () {
    final why = DemoData.why;

    test('drivers add up to the day\'s risk index', () {
      expect(why.totalRisk, closeTo(DemoData.todayScore.risk, 0.005));
    });

    test('drivers\' shares add up to about 100%', () {
      final total = why.drivers.values.map(why.sharePercent).reduce((a, b) => a + b);
      expect(total, inInclusiveRange(99, 101));
    });

    test('the inputs shown are the ones that were scored', () {
      expect(why.sleepHours, DemoData.today.sleepHours);
      expect(why.hrvMs, DemoData.today.hrvMs);
      expect(why.steps, DemoData.yesterday.steps);
    });

    test('the coach names the same largest driver', () {
      final label = VitalityWhy.groupLabel(why.rankedDrivers.first.key);
      expect(daily.coachInsight(), contains('$label is your largest driver'));
    });

    test('confidence matches a day with all four inputs fresh', () {
      expect(why.notFresh, isEmpty);
      expect(DemoData.confidence, 85);
    });
  });

  group('Reading the server\'s day doc', () {
    test('fills every field from what the server writes', () {
      final why = VitalityWhy.fromDayDoc({
        'drivers': {'recovery': 0.2, 'sleep': 0.1, 'activity': 0.1},
        'inputs': {
          'used': {'hrv_rmssd_ms': 50, 'rhr_bpm': 60, 'sleep_total_hours': 7.5, 'steps_count': 9000},
        },
        'stale_days': {'sleep_total_hours': 0, 'hrv_rmssd_ms': 0, 'rhr_bpm': 2, 'steps_count': 1},
        'activity_policy': 'lag_yesterday',
      })!;
      expect(why.sharePercent(0.2), 50);
      expect(why.rankedDrivers.first.key, 'recovery');
      expect(why.hrvMs, 50);
      expect(why.steps, 9000);
      expect(why.activityFromYesterday, isTrue);
      expect(why.notFresh, ['Resting HR']);
    });

    test('is empty when the doc has no drivers', () {
      expect(VitalityWhy.fromDayDoc({'score_confidence': 80}), isNull);
      expect(VitalityWhy.fromDayDoc({'drivers': <String, dynamic>{}}), isNull);
    });
  });

  group('Leaderboards and challenges', () {
    LeaderboardEntry you(List<LeaderboardEntry> board) => board.firstWhere((e) => e.isYou);

    test('each board has one row for the visitor, under the demo name', () {
      for (final board in [boards.weeklySteps(), boards.sleepStreaks(), boards.experimentGains()]) {
        expect(board.where((e) => e.isYou), hasLength(1));
        expect(you(board).name, DemoData.fullName);
        expect(board.map((e) => e.rank), List.generate(board.length, (i) => i + 1));
      }
    });

    test('the steps row is the sum of the last 7 complete days', () {
      final days = DemoData.metricHistory(8);
      final sum = days.sublist(0, 7).map((d) => d.steps).reduce((a, b) => a + b);
      expect(you(boards.weeklySteps()).value.replaceAll(',', ''), '$sum');
    });

    test('the sleep row counts the current streak', () {
      expect(you(boards.sleepStreaks()).value, '${DemoData.sleepStreakNights} nights');
    });

    test('challenges use the same progress and ranks as the boards', () {
      final list = const ChallengesServiceMock().list();
      final steps = list.firstWhere((c) => c.id == 'steps_70k');
      expect(steps.progress, DemoData.weeklySteps);
      expect(steps.yourRank, you(boards.weeklySteps()).rank);
      final sleep = list.firstWhere((c) => c.id == 'sleep_21');
      expect(sleep.progress, DemoData.sleepStreakNights.clamp(0, 21));
      expect(sleep.yourRank, you(boards.sleepStreaks()).rank);
    });
  });

  group('Experiments', () {
    test('one is active and at least one is finished', () {
      final list = experiments.list();
      expect(list.where((e) => e.isActive), hasLength(1));
      expect(list.where((e) => !e.isActive), isNotEmpty);
    });

    test('the walk experiment is a clear improvement', () {
      final walk = experiments.walk();
      expect(walk.improved, isTrue);
      expect(walk.percentChange.abs(), greaterThan(1.0));
      expect(walk.summary, contains('fell'));
    });

    test('the bedtime baseline and result are real averages of the sleep history', () {
      final e = experiments.bedtime();
      expect(e.current, closeTo(DemoData.average((d) => d.sleepHours, fromDaysAgo: 9), 1e-9));
      expect(
        e.baseline,
        closeTo(DemoData.average((d) => d.sleepHours, fromDaysAgo: 23, toDaysAgo: 9), 1e-9),
      );
    });

    test('the gains board and the feed quote the walk result', () {
      final walk = experiments.walk();
      final yours = boards.experimentGains().firstWhere((e) => e.isYou);
      expect(yours.value, '${walk.percentChange.abs().toStringAsFixed(1)}%');
      final posts = const CommunityFeedServiceMock().feed();
      expect(posts.any((p) => p.body.contains(walk.changeLabel)), isTrue);
    });
  });
}
