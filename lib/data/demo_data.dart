// lib/data/demo_data.dart
//
// The demo's one dataset. Sample wearable values go through the ported server scoring
// in demo_scoring.dart, and every screen reads the results, directly or through the
// mock adapters in data/adapters/mock. Dates are relative to today. Nothing here is
// ever written to Firestore.
import 'dart:math' as math;

import 'package:aevara_app/charts/delta_bar.dart' show VitalityPoint;

import 'demo_scoring.dart';
import 'models/user_profile.dart';
import 'models/vitality_metrics.dart';

/// One calendar day. Steps and active minutes are that day's totals, so today's
/// aren't final; the score for a date uses the totals from the day before it.
class DemoDayMetrics {
  const DemoDayMetrics({
    required this.date,
    required this.sleepHours,
    required this.hrvMs,
    required this.restingHrBpm,
    required this.steps,
    required this.activeMinutes,
  });

  final DateTime date;
  final double sleepHours;
  final double hrvMs;
  final double restingHrBpm;
  final int steps;
  final int activeMinutes;

  DemoDayMetrics copyWith({double? sleepHours, double? hrvMs, double? restingHrBpm}) =>
      DemoDayMetrics(
        date: date,
        sleepHours: sleepHours ?? this.sleepHours,
        hrvMs: hrvMs ?? this.hrvMs,
        restingHrBpm: restingHrBpm ?? this.restingHrBpm,
        steps: steps,
        activeMinutes: activeMinutes,
      );
}

class DemoData {
  DemoData._();

  static const String firstName = 'Alex';
  static const String lastName = 'Demo';
  static const String username = 'demo_user';
  static String get fullName => '$firstName $lastName';

  static const double chronoAge = 38.0;

  /// The sample user's calibrated starting point, which the server stores per user.
  static const double baselineVitalityAge = 33.4;

  static const int _historyDays = 90;

  /// Days ago that were rough, so the Healthy Days chart shows every state.
  /// Values are the risk band each should land in.
  static const Map<int, (double, double)> _roughDays = {
    4: (0.50, 0.55),
    11: (0.56, 0.70),
    18: (0.50, 0.55),
    41: (0.50, 0.55),
    66: (0.56, 0.70),
  };

  static final List<DemoDayMetrics> _metrics = [];
  static final List<DayScore> _scores = [];
  static bool _built = false;

  static void _ensureBuilt() {
    if (_built) return;
    _built = true;

    final rng = math.Random(11);
    final now = DateTime.now();
    double jitter(double range) => range * (rng.nextDouble() - 0.5);

    Ema7? ema;
    double? previousAge;

    for (var i = 0; i < _historyDays; i++) {
      final daysAgo = _historyDays - 1 - i;
      final weekly = math.sin(i * 2 * math.pi / 7);
      final slow = math.sin(i * 2 * math.pi / 23);
      final band = _roughDays[daysAgo];

      // Not everything improves: HRV drifts and dips this week, steps fall away this
      // week. Sleep lifts during the sample bedtime experiment, and resting heart rate
      // sits lower after the sample walking experiment.
      var day = DemoDayMetrics(
        date: DateTime(now.year, now.month, now.day - daysAgo),
        sleepHours: _round1(7.8 + 0.25 * weekly + jitter(0.8) + (daysAgo < 9 ? 0.3 : 0)),
        hrvMs: (58 + 3 * slow + jitter(11) - (daysAgo < 7 ? 3 : 0)).roundToDouble(),
        restingHrBpm: (54 + jitter(4) + (daysAgo >= 40 ? 2.5 : 0)).roundToDouble(),
        steps: (12800 + 1100 * weekly + jitter(1800) - (daysAgo < 8 ? 3400 : 0)).round(),
        activeMinutes: (52 + 10 * weekly + jitter(16)).round(),
      );

      if (band != null) {
        day = day.copyWith(sleepHours: 6.2, hrvMs: day.hrvMs - 9, restingHrBpm: day.restingHrBpm + 5);
      }

      // Activity comes from the day before, as on the server.
      final yesterday = _metrics.isEmpty ? day : _metrics.last;
      DayScore score() => DemoScoring.scoreDay(
            inputs: ScoreInputs(
              hrvMs: day.hrvMs,
              restingHrBpm: day.restingHrBpm,
              sleepHours: day.sleepHours,
              steps: yesterday.steps.toDouble(),
              activeMinutes: yesterday.activeMinutes.toDouble(),
            ),
            previousEma: ema,
            previousVitalityAge: previousAge,
            baselineVitalityAge: baselineVitalityAge,
          );

      // Keep ordinary days under the chart's 0.45 line and rough days in their band, so
      // the bar colors, the count and the tooltip agree. See KNOWN_ISSUES.md.
      var result = score();
      for (var tries = 0; tries < 60; tries++) {
        if (band != null) {
          if (result.risk < band.$1) {
            day = day.copyWith(sleepHours: _round1(day.sleepHours - 0.1));
          } else if (result.risk > band.$2) {
            day = day.copyWith(sleepHours: _round1(day.sleepHours + 0.1));
          } else {
            break;
          }
        } else if (result.risk >= 0.45) {
          day = day.copyWith(sleepHours: _round1(day.sleepHours + 0.1), hrvMs: day.hrvMs + 1);
        } else {
          break;
        }
        result = score();
      }

      _metrics.add(day);
      _scores.add(result);
      ema = result.ema7;
      previousAge = result.vitalityAge;
    }
  }

  static double _round1(double v) => (v * 10).round() / 10;

  static List<DemoDayMetrics> get _days {
    _ensureBuilt();
    return _metrics;
  }

  static List<DayScore> get _scored {
    _ensureBuilt();
    return _scores;
  }

  /// Today's score.
  static DayScore get todayScore => _scored.last;

  static double get vitalityAge => todayScore.vitalityAge;
  static int get confidence => todayScore.confidence;

  static Map<String, int> get scores => {
        'recovery': (todayScore.recovery * 100).round(),
        'sleep': (todayScore.sleep * 100).round(),
        'activity': (todayScore.activity * 100).round(),
      };

  static const Map<String, double> weightsUsed = {
    'recovery': DemoScoring.weightRecovery,
    'sleep': DemoScoring.weightSleep,
    'activity': DemoScoring.weightActivity,
  };

  static const Map<String, num> constants = {
    'pivot_risk': DemoScoring.pivotRisk,
    'scale_years': DemoScoring.scaleYears,
  };

  /// The last 30 days of risk, oldest first.
  static List<double?> get riskSeries30 =>
      _scored.sublist(_historyDays - 30).map<double?>((s) => s.risk).toList();

  static int get healthyDays30 =>
      _scored.sublist(_historyDays - 30).where((s) => s.risk < 0.45).length;

  static List<VitalityPoint> vitalityHistory(int days) {
    final n = days.clamp(1, _historyDays);
    return List<VitalityPoint>.generate(n, (i) {
      final index = _historyDays - n + i;
      return VitalityPoint(
        date: _days[index].date,
        vitalityAge: _scored[index].vitalityAge,
        chronoAge: chronoAge,
      );
    });
  }

  /// Everything up to and including today, oldest first.
  static List<DemoDayMetrics> metricHistory(int days) =>
      _days.sublist(_historyDays - days.clamp(1, _historyDays));

  static DemoDayMetrics get today => _days.last;

  /// The last complete day, which is what today's activity score reads.
  static DemoDayMetrics get yesterday => _days[_historyDays - 2];

  /// Average of [value] from [fromDaysAgo] up to, not including, [toDaysAgo].
  static double average(
    double Function(DemoDayMetrics) value, {
    required int fromDaysAgo,
    int toDaysAgo = 0,
  }) {
    final window = _days.sublist(_historyDays - fromDaysAgo, _historyDays - toDaysAgo);
    return window.map(value).reduce((a, b) => a + b) / window.length;
  }

  /// Steps over the last 7 complete days.
  static int get weeklySteps =>
      _days.sublist(_historyDays - 8, _historyDays - 1).map((d) => d.steps).reduce((a, b) => a + b);

  /// Consecutive nights of 7+ hours, counting back from last night.
  static int get sleepStreakNights {
    var streak = 0;
    for (final day in _days.reversed) {
      if (day.sleepHours < 7.0) break;
      streak++;
    }
    return streak;
  }

  /// The group with the largest share of today's risk.
  static String get largestDriver =>
      todayScore.drivers.entries.reduce((a, b) => b.value > a.value ? b : a).key;

  /// Why today's number is what it is, in the same shape the server's day doc gives.
  static VitalityWhy get why => VitalityWhy(
        drivers: todayScore.drivers,
        hrvMs: today.hrvMs,
        restingHrBpm: today.restingHrBpm,
        sleepHours: today.sleepHours,
        steps: yesterday.steps,
        staleDays: const {'sleep': 0, 'hrv': 0, 'restingHr': 0, 'steps': 1},
        activityFromYesterday: true,
      );

  static int get _roughestIndex {
    var worst = _historyDays - 30;
    for (var i = worst; i < _historyDays; i++) {
      if (_scored[i].risk > _scored[worst].risk) worst = i;
    }
    return worst;
  }

  /// The highest-risk day in the last 30, for the Healthy Days detail.
  static DateTime get roughestDayDate => _days[_roughestIndex].date;

  static String get roughestDayNote {
    final s = _scored[_roughestIndex];
    final top = s.drivers.entries.reduce((a, b) => b.value > a.value ? b : a).key;
    return 'Risk index ${s.risk.toStringAsFixed(2)}, with ${VitalityWhy.groupLabel(top).toLowerCase()} '
        'as its largest driver.';
  }

  /// Every scored day with the day its activity came from, for the parity test.
  static List<(DemoDayMetrics, DemoDayMetrics, DayScore)> debugAllDays() => [
        for (var i = 0; i < _historyDays; i++) (_days[i], i == 0 ? _days[0] : _days[i - 1], _scored[i]),
      ];

  static UserProfile profile(String uid) {
    final now = DateTime.now();
    return UserProfile(
      uid: uid,
      email: '',
      username: username,
      usernameLower: username,
      firstName: firstName,
      lastName: lastName,
      dob: DateTime(now.year - chronoAge.toInt(), 1, 1),
      createdAt: now,
      updatedAt: now,
    );
  }
}
